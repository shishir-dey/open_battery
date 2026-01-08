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

  Timer? _pollingTimer;
  StreamSubscription? _responseSubscription;

  BluetoothDevice? get device => _device;
  BmsBaseInfo? get baseInfo => _baseInfo;
  BmsCellVoltages? get cellVoltages => _cellVoltages;
  BmsHardwareVersion? get hardwareVersion => _hardwareVersion;
  bool get isConnected => _isConnected;

  Future<void> scan() async {
    await _bleService.startScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    debugPrint("Provider: Stopping scan...");
    await _bleService.stopScan();
    try {
      debugPrint("Provider: Calling BleService.connect...");
      await _bleService.connect(device);
      debugPrint("Provider: BleService connected. Setting state...");

      _device = device;
      _isConnected = true;
      notifyListeners();

      debugPrint("Provider: Starting listeners and polling...");
      _startListening();
      _startPolling();
      debugPrint("Provider: Connection setup complete.");
    } catch (e) {
      debugPrint("Provider: Connection error caught: $e");
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _stopPolling();
    await _responseSubscription?.cancel();
    await _bleService.disconnect();
    _device = null;
    _isConnected = false;
    _baseInfo = null;
    _cellVoltages = null;
    _hardwareVersion = null;
    notifyListeners();
  }

  void _startListening() {
    _responseSubscription = _bleService.responseStream.listen((data) {
      try {
        final packet = BmsProtocol.parseResponse(data);
        final cmd = packet['command'];
        final payload = packet['data'] as List<int>;

        if (cmd == BmsProtocol.CMD_READ_BASE_INFO) {
          _baseInfo = BmsBaseInfo.fromBytes(payload);
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

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 5 seconds using explicit Read from FF02
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _readData();
    });

    // Request initial data
    _requestInitialData();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _readData() async {
    try {
      // Read from FF02
      final data = await _bleService.read();
      _handleResponse(data);
    } catch (e) {
      debugPrint("Read error: $e");
    }
  }

  // Handle incoming data (shared by notify and manual read)
  void _handleResponse(List<int> data) {
    if (data.isEmpty) return;
    // DEBUG: Print raw bits
    final hex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
    debugPrint("RX RAW: $hex");

    try {
      if (data.isNotEmpty && data[0] == 0xDD) {
        final packet = BmsProtocol.parseResponse(data);
        final cmd = packet['command'];
        final payload = packet['data'] as List<int>;

        if (cmd == BmsProtocol.CMD_READ_BASE_INFO) {
          _baseInfo = BmsBaseInfo.fromBytes(payload);
        } else if (cmd == BmsProtocol.CMD_READ_CELL_VOLTAGES) {
          _cellVoltages = BmsCellVoltages.fromBytes(payload);
        } else if (cmd == BmsProtocol.CMD_READ_HARDWARE_VERSION) {
          _hardwareVersion = BmsHardwareVersion.fromBytes(payload);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Parse error: $e");
    }
  }

  Future<void> _requestInitialData() async {
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
