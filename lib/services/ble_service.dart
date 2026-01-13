/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/services/ble_service.dart
 * Description: Service class for handling Bluetooth Low Energy (BLE) communication with BMS devices.
 * Author: Shishir Dey
 * License: MIT
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../protocol/bms_protocol.dart';

enum AuthState { notAuthenticated, authenticated }

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _notificationSubscription;

  // Packet assembly buffer for handling fragmented BLE notifications
  List<int> _frameBuffer = [];
  int _expectedLength = 0;
  static const int _maxBufferSize = 100;

  // Auth State
  AuthState _authState = AuthState.notAuthenticated;

  // UUIDs
  final String serviceUuid = "0000ff00-0000-1000-8000-00805f9b34fb";
  final String rxCharUuid = "0000ff01-0000-1000-8000-00805f9b34fb";
  final String txCharUuid = "0000ff02-0000-1000-8000-00805f9b34fb";

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  // Expose parsed data stream
  final _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get responseStream => _dataController.stream;

  // Expose auth status
  final _authStatusController = StreamController<bool>.broadcast();
  Stream<bool> get authStatusStream => _authStatusController.stream;

  Future<void> startScan() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => BluetoothAdapterState.on,
          );

      if (adapterState != BluetoothAdapterState.on) {
        debugPrint("BleService: Bluetooth is not on, state: $adapterState");
      }

      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("BleService: Error starting scan: $e");
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
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

    // Skip authentication - this BMS doesn't respond to auth packets
    debugPrint("⚠️  Skipping authentication - BMS accepts direct commands");
    _authState = AuthState.authenticated;

    // Small delay to ensure provider is subscribed
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint("📡 Marking as authenticated");
    _authStatusController.add(true);
  }

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _authState = AuthState.notAuthenticated;
    _resetBuffer();
  }

  Future<void> write(List<int> data) async {
    if (_txCharacteristic == null) {
      debugPrint("❌ TX characteristic is null!");
      return;
    }

    debugPrint(
      "📤 TX: ${data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ')}",
    );

    await _txCharacteristic!.write(data, withoutResponse: true);
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
    debugPrint(
      "📥 RX: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}",
    );

    try {
      // Check for Standard Packet
      if (data.length >= 7 && data[0] == 0xDD && data.last == 0x77) {
        int status = data[2];
        debugPrint(
          "   Type: STANDARD, Status: 0x${status.toRadixString(16).toUpperCase()}",
        );

        if (status == 0x80) {
          debugPrint(
            "   ⚠️  Status 0x80 - Command rejected (may need auth or invalid)",
          );
        } else if (status == 0x00) {
          debugPrint("   ✅ Status 0x00 - Success");
        }

        _assemblePacket(data);
        return;
      }

      // May be fragmented - try to assemble
      debugPrint("   Type: Fragment or unknown");
      _assemblePacket(data);
    } catch (e) {
      debugPrint("❌ Error handling data: $e");
      _resetBuffer();
    }
  }

  void _assemblePacket(List<int> data) {
    // Buffer overflow protection
    if (_frameBuffer.length + data.length > _maxBufferSize) {
      debugPrint("⚠️  Buffer overflow, resetting");
      _resetBuffer();
    }

    // Check if this is a new packet
    bool isNewFrame = data.length >= 3 && data[0] == 0xDD && data[2] == 0x00;

    if (isNewFrame) {
      _frameBuffer.clear();
      if (data.length >= 4) {
        _expectedLength = data[3];
      }
    }

    _frameBuffer.addAll(data);

    // Check if we have a complete packet
    int expectedTotalLength = _expectedLength + 7;

    if (_frameBuffer.length >= 7 &&
        _frameBuffer[0] == 0xDD &&
        _frameBuffer.length >= expectedTotalLength) {
      if (_frameBuffer[expectedTotalLength - 1] == 0x77) {
        List<int> completePacket = _frameBuffer.sublist(0, expectedTotalLength);
        debugPrint(
          "✅ Complete packet assembled (${completePacket.length} bytes)",
        );
        _dataController.add(completePacket);
        _resetBuffer();
      } else if (_frameBuffer.last == 0x77) {
        debugPrint("✅ Found tail at end, forwarding");
        _dataController.add(List<int>.from(_frameBuffer));
        _resetBuffer();
      }
    }
  }

  void _resetBuffer() {
    _frameBuffer.clear();
    _expectedLength = 0;
  }
}
