/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/providers/bms_provider.dart
 * Description: Provider class that manages BMS data state and handles BLE communication through the service.
 * Author: Shishir Dey
 * License: MIT
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/bms_data.dart';
import '../protocol/bms_protocol.dart';
import '../services/ble_service.dart';

class BmsProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  BluetoothDevice? _device;
  BmsBaseInfo? _baseInfo;
  BmsCellVoltages? _cellVoltages;
  BmsHardwareVersion? _hardwareVersion;
  bool _isConnected = false;
  bool _isAuthenticated = false;

  Timer? _pollingTimer;
  StreamSubscription? _responseSubscription;
  StreamSubscription? _authSubscription;

  BluetoothDevice? get device => _device;
  BmsBaseInfo? get baseInfo => _baseInfo;
  BmsCellVoltages? get cellVoltages => _cellVoltages;
  BmsHardwareVersion? get hardwareVersion => _hardwareVersion;
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> scan() async {
    await _bleService.startScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    debugPrint("Provider: Stopping scan...");
    await _bleService.stopScan();
    try {
      _device = device;
      _isConnected = true;
      _isAuthenticated = false;

      // Start listening FIRST
      debugPrint("Provider: Starting listeners...");
      _startListening();
      _startAuthListening();

      // THEN connect (which triggers auth)
      debugPrint("Provider: Calling BleService.connect...");
      await _bleService.connect(device);

      notifyListeners();
      debugPrint("Provider: Connection setup complete.");
    } catch (e) {
      debugPrint("Provider: Connection error caught: $e");
      _isConnected = false;
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _stopPolling();
    await _responseSubscription?.cancel();
    await _authSubscription?.cancel();
    await _bleService.disconnect();
    _device = null;
    _isConnected = false;
    _isAuthenticated = false;
    _baseInfo = null;
    _cellVoltages = null;
    _hardwareVersion = null;
    notifyListeners();
  }

  void _startListening() {
    _responseSubscription = _bleService.responseStream.listen((data) {
      debugPrint(
        "Provider: Received data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}",
      );
      try {
        final packet = BmsProtocol.parseResponse(data);
        final cmd = packet['command'];
        final payload = packet['data'] as List<int>;

        if (cmd == BmsProtocol.CMD_READ_BASE_INFO) {
          _baseInfo = BmsBaseInfo.fromBytes(payload);
          debugPrint("Provider: Parsed base info: $_baseInfo");
        } else if (cmd == BmsProtocol.CMD_READ_CELL_VOLTAGES) {
          _cellVoltages = BmsCellVoltages.fromBytes(payload);
        } else if (cmd == BmsProtocol.CMD_READ_HARDWARE_VERSION) {
          _hardwareVersion = BmsHardwareVersion.fromBytes(payload);
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Parse error: $e");
      }
    });
  }

  void _startAuthListening() {
    debugPrint("Provider: Starting auth listening...");
    _authSubscription = _bleService.authStatusStream.listen((isAuth) {
      debugPrint("Provider: Auth status received: $isAuth");
      _isAuthenticated = isAuth;
      if (isAuth) {
        debugPrint("Provider: Authenticated, starting polling...");
        _startPolling();
      }
      notifyListeners();
    });
  }

  void _startPolling() {
    debugPrint("Provider: Starting polling...");
    _pollingTimer?.cancel();
    // Poll every 5 seconds by re-requesting data
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _requestInitialData();
    });

    // Request initial data
    _requestInitialData();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _requestInitialData() async {
    debugPrint("Provider: Requesting initial data...");
    try {
      // Request base info
      final baseInfoPacket = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_BASE_INFO,
      );
      await _bleService.write(baseInfoPacket);

      // Request cell voltages
      final cellVoltagesPacket = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_CELL_VOLTAGES,
      );
      await _bleService.write(cellVoltagesPacket);

      // Request hardware version
      final hardwareVersionPacket = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_HARDWARE_VERSION,
      );
      await _bleService.write(hardwareVersionPacket);
    } catch (e) {
      debugPrint("Error requesting initial data: $e");
    }
  }

  /// Send MOS control command
  Future<void> sendMosControl(int controlValue) async {
    try {
      final mosPacket = BmsProtocol.createMosControlPacket(controlValue);
      await _bleService.write(mosPacket);
    } catch (e) {
      debugPrint("Error sending MOS control: $e");
      rethrow;
    }
  }

  /// Request base info manually
  Future<void> requestBaseInfo() async {
    try {
      final packet = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_BASE_INFO,
      );
      await _bleService.write(packet);
    } catch (e) {
      debugPrint("Error requesting base info: $e");
      rethrow;
    }
  }

  /// Request cell voltages manually
  Future<void> requestCellVoltages() async {
    try {
      final packet = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_CELL_VOLTAGES,
      );
      await _bleService.write(packet);
    } catch (e) {
      debugPrint("Error requesting cell voltages: $e");
      rethrow;
    }
  }

  /// Request hardware version manually
  Future<void> requestHardwareVersion() async {
    try {
      final packet = BmsProtocol.createReadPacket(
        BmsProtocol.CMD_READ_HARDWARE_VERSION,
      );
      await _bleService.write(packet);
    } catch (e) {
      debugPrint("Error requesting hardware version: $e");
      rethrow;
    }
  }
}
