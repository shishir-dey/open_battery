import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _notificationSubscription;

  // UUIDs from spec
  // Standard JBD/Xiaoxiang
  final String serviceUuid = "0000ff00-0000-1000-8000-00805f9b34fb";
  final String rxCharUuid = "0000ff01-0000-1000-8000-00805f9b34fb";
  final String txCharUuid = "0000ff02-0000-1000-8000-00805f9b34fb";

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<void> startScan() async {
    // Wait for Bluetooth to be turned on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        // If timeout or error, continue
      }
    }

    // Filter by service UUID to find irrelevant devices matching others
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
    await device.connect(license: License.free);

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      // Strict check for FF00 service to avoid interacting with others
      if (service.uuid == Guid(serviceUuid) ||
          service.uuid.toString().contains("ff00")) {
        debugPrint("Found Service: ${service.uuid}");
        for (var c in service.characteristics) {
          debugPrint("  Found Characteristic: ${c.uuid}");
          debugPrint(
            "    Props: read=${c.properties.read}, write=${c.properties.write}, writeNoResp=${c.properties.writeWithoutResponse}, notify=${c.properties.notify}",
          );

          // FF01 is Rx (Notify)
          if (c.uuid == Guid(rxCharUuid) ||
              c.uuid.toString().contains("ff01")) {
            _rxCharacteristic = c;
            if (c.properties.notify) {
              await c.setNotifyValue(true);
            }
          }

          // FF02 is Tx (Write)
          if (c.uuid == Guid(txCharUuid) ||
              c.uuid.toString().contains("ff02")) {
            _txCharacteristic = c;
          }
        }
      }
    }

    if (_rxCharacteristic == null || _txCharacteristic == null) {
      if (_rxCharacteristic == null)
        throw Exception("Rx characteristic (ff01) not found");
      if (_txCharacteristic == null)
        throw Exception("Tx characteristic (ff02) not found");
    }
  }

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
  }

  /// Send raw bytes to the BMS
  Future<void> write(List<int> data) async {
    if (_txCharacteristic == null) throw Exception("Not connected");

    // Determine write type based on properties
    // BMS often prefers WriteWithoutResponse for command throughput
    bool canWriteNoResp = _txCharacteristic!.properties.writeWithoutResponse;
    bool canWriteResp = _txCharacteristic!.properties.write;

    if (canWriteNoResp) {
      await _txCharacteristic!.write(data, withoutResponse: true);
    } else if (canWriteResp) {
      await _txCharacteristic!.write(data, withoutResponse: false);
    } else {
      throw Exception(
        "Characteristic does not support Write or WriteWithoutResponse",
      );
    }
  }

  /// Read data from the BMS manually (from FF02)
  Future<List<int>> read() async {
    if (_txCharacteristic == null) throw Exception("Not connected");
    return await _txCharacteristic!.read();
  }

  /// Stream of incoming data
  Stream<List<int>>? get responseStream => _rxCharacteristic?.onValueReceived;
}
