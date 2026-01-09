/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/services/ble_service.dart
 * Description: Service class for handling Bluetooth Low Energy (BLE) communication with BMS devices, including authentication and data streaming.
 * Author: Shishir Dey
 * License: MIT
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../protocol/bms_protocol.dart';

enum AuthState {
  notAuthenticated,
  sendingAppKey,
  requestingRandom,
  sendingPassword,
  requestingRootRandom,
  sendingRootPassword,
  authenticated,
}

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _notificationSubscription;

  // Auth State
  AuthState _authState = AuthState.notAuthenticated;
  int _randomByte = 0;
  final String _password = "123123"; // Default user password

  // Standard JBD Root Password
  final List<int> _rootPassword = [
    0x4a,
    0x42,
    0x44,
    0x62,
    0x74,
    0x70,
    0x77,
    0x64,
    0x21,
    0x40,
    0x23,
    0x32,
    0x30,
    0x32,
    0x33,
  ]; // "JBDbtpwd!@#2023"

  // UUIDs
  final String serviceUuid = "0000ff00-0000-1000-8000-00805f9b34fb";
  final String rxCharUuid = "0000ff01-0000-1000-8000-00805f9b34fb";
  final String txCharUuid = "0000ff02-0000-1000-8000-00805f9b34fb";

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  // Expose parsed data stream (only when authenticated)
  final _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get responseStream => _dataController.stream;

  // Expose auth status
  final _authStatusController = StreamController<bool>.broadcast();
  Stream<bool> get authStatusStream => _authStatusController.stream;

  Future<void> startScan() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      // logic to wait for bt
    }
    await FlutterBluePlus.startScan(
      withServices: [Guid(serviceUuid)],
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    // Reset state
    _authState = AuthState.notAuthenticated;
    _authStatusController.add(false);

    await device.connect(license: License.free, autoConnect: false);

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid == Guid(serviceUuid) ||
          service.uuid.toString().contains("ff00")) {
        for (var c in service.characteristics) {
          if (c.uuid == Guid(rxCharUuid) ||
              c.uuid.toString().contains("ff01")) {
            _rxCharacteristic = c;
            if (c.properties.notify) {
              await c.setNotifyValue(true);
            }
          }
          if (c.uuid == Guid(txCharUuid) ||
              c.uuid.toString().contains("ff02")) {
            _txCharacteristic = c;
          }
        }
      }
    }

    if (_rxCharacteristic == null || _txCharacteristic == null) {
      throw Exception("Required characteristics not found");
    }

    // Listen to notifications
    _notificationSubscription = _rxCharacteristic!.onValueReceived.listen((
      data,
    ) {
      _handleIncomingData(data);
    });

    // Start Authentication
    _startAuthentication();
  }

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _authState = AuthState.notAuthenticated;
  }

  Future<void> write(List<int> data) async {
    if (_txCharacteristic == null) return;
    if (_authState != AuthState.authenticated) {
      debugPrint("Warning: Writing before authenticated");
    }
    await _txCharacteristic!.write(
      data,
      withoutResponse: true,
    ); // usually WriteNoResp
  }

  Future<List<int>> read() async {
    if (_txCharacteristic != null) {
      return await _txCharacteristic!.read();
    }
    if (_rxCharacteristic != null) {
      return await _rxCharacteristic!.read();
    }
    throw Exception("No characteristic available for reading");
  }

  void _handleIncomingData(List<int> data) {
    try {
      // Check for Auth Packet
      if (data.length >= 4 && data[0] == 0xFF && data[1] == 0xAA) {
        _handleAuthResponse(data);
        return;
      }

      // Check for Standard Packet
      if (data.length >= 7 && data[0] == 0xDD && data.last == 0x77) {
        if (_authState == AuthState.authenticated) {
          _dataController.add(data);
        }
        return;
      }
    } catch (e) {
      debugPrint("Error handling data: $e");
    }
  }

  void _startAuthentication() {
    debugPrint("Starting Authentication...");
    _authState = AuthState.sendingAppKey;
    // Send App Key: 00 00 00 00
    // Packet: FF AA 15 06 30 30 30 30 30 30 CRC
    // Wait, C++ sends `0x30 0x30...` which is ASCII '0'.
    // C++: frame[4..9] = 0x30.
    List<int> appKeyData = List.filled(6, 0x30);
    _sendAuthCommand(BmsProtocol.AUTH_CMD_SEND_APP_KEY, appKeyData);
  }

  void _handleAuthResponse(List<int> packet) {
    int command = packet[2];
    int length = packet[3];
    List<int> data = (packet.length >= 4 + length)
        ? packet.sublist(4, 4 + length)
        : [];

    debugPrint("Auth Response: Cmd=${command.toRadixString(16)} Data=$data");

    switch (command) {
      case BmsProtocol.AUTH_CMD_SEND_APP_KEY:
        if (data.isNotEmpty && data[0] == 0x00) {
          // OK, need pwd
          _authState = AuthState.requestingRandom;
          _sendAuthCommand(BmsProtocol.AUTH_CMD_GET_RANDOM, []);
        } else if (data.isNotEmpty && data[0] == 0x02) {
          // OK, no pwd
          _onAuthenticated();
        } else {
          debugPrint("Auth Failed: App Key Rejected");
        }
        break;

      case BmsProtocol.AUTH_CMD_GET_RANDOM:
        if (data.isNotEmpty) {
          _randomByte = data[0];
          if (_authState == AuthState.requestingRandom) {
            _sendUserPassword();
          } else if (_authState == AuthState.requestingRootRandom) {
            _sendRootPassword();
          }
        }
        break;

      case BmsProtocol.AUTH_CMD_SEND_PASSWORD:
        if (data.isNotEmpty && data[0] == 0x00) {
          // User Pwd OK, Try Root Pwd
          _authState = AuthState.requestingRootRandom;
          _sendAuthCommand(BmsProtocol.AUTH_CMD_GET_RANDOM, []);
        } else {
          debugPrint("Auth Failed: User Password Rejected");
        }
        break;

      case BmsProtocol.AUTH_CMD_SEND_ROOT_PASSWORD:
        if (data.isNotEmpty && data[0] == 0x00) {
          _onAuthenticated();
        } else {
          debugPrint("Auth Failed: Root Password Rejected");
        }
        break;
    }
  }

  void _sendUserPassword() {
    _authState = AuthState.sendingPassword;
    // Encrypt Password
    // Password bytes XOR MAC bytes + Random
    // Need MAC address... FlutterBluePlus device.remoteId is the MAC.
    // E.g. "A4:C1:38:..."
    List<int> macBytes = _getMacBytes(_connectedDevice!.remoteId.str);
    List<int> pwdBytes = _password.codeUnits;

    // Pad pwd to 6 bytes if needed (assumed 123123 is 6 bytes)

    List<int> encrypted = [];
    for (int i = 0; i < 6; i++) {
      int macByte = (i < macBytes.length) ? macBytes[i] : 0;
      int pwdByte = (i < pwdBytes.length)
          ? pwdBytes[i]
          : 0; // Or '0' char? C++: string[i]
      int enc = ((macByte ^ pwdByte) + _randomByte) & 0xFF;
      encrypted.add(enc);
    }

    _sendAuthCommand(BmsProtocol.AUTH_CMD_SEND_PASSWORD, encrypted);
  }

  void _sendRootPassword() {
    _authState = AuthState.sendingRootPassword;
    List<int> macBytes = _getMacBytes(_connectedDevice!.remoteId.str);
    List<int> encrypted = [];

    for (int i = 0; i < _rootPassword.length; i++) {
      int macByte = (i < 6) ? macBytes[i] : 0;
      int pwdByte = _rootPassword[i];
      int enc = ((macByte ^ pwdByte) + _randomByte) & 0xFF;
      encrypted.add(enc);
    }

    _sendAuthCommand(BmsProtocol.AUTH_CMD_SEND_ROOT_PASSWORD, encrypted);
  }

  void _onAuthenticated() {
    debugPrint("Authentication Successful!");
    _authState = AuthState.authenticated;
    _authStatusController.add(true);

    // Trigger initial read
    // sendCommand(BmsProtocol.createReadPacket(BmsProtocol.CMD_READ_BASE_INFO));
    // But user of this service should drive this.
  }

  void _sendAuthCommand(int command, List<int> data) async {
    List<int> packet = BmsProtocol.createAuthPacket(command, data);
    if (_txCharacteristic != null) {
      await _txCharacteristic!.write(packet, withoutResponse: true);
    }
  }

  List<int> _getMacBytes(String id) {
    // ID: "A4:C1:38:..." or "A4C138..."
    // Extract hex bytes.
    String clean = id.replaceAll(":", "").replaceAll("-", "");
    List<int> bytes = [];
    for (int i = 0; i < clean.length; i += 2) {
      if (i + 2 <= clean.length) {
        bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
      }
    }
    return bytes;
  }
}
