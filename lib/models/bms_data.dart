/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/models/bms_data.dart
 * Description: Defines data models for BMS information including base info, cell voltages, and hardware version.
 * Author: Shishir Dey
 * License: MIT
 */

/// Represents the Base Information from Command 0x03 (Jiabaida BMS)
class BmsBaseInfo {
  final double totalVoltage; // V
  final double current; // A
  final double remainingCapacity; // Ah
  final double nominalCapacity; // Ah
  final int cycleCount;
  final int rsoc; // %
  final List<double> temperatures; // deg C
  final bool isCharging;
  final bool isDischarging;
  final int protectionState;
  final String softwareVersion;
  final int cellCount;
  final int ntcCount;

  BmsBaseInfo({
    required this.totalVoltage,
    required this.current,
    required this.remainingCapacity,
    required this.nominalCapacity,
    required this.cycleCount,
    required this.rsoc,
    required this.temperatures,
    required this.isCharging,
    required this.isDischarging,
    required this.protectionState,
    required this.softwareVersion,
    required this.cellCount,
    required this.ntcCount,
  });

  factory BmsBaseInfo.fromBytes(List<int> data) {
    // Jiabaida BMS data format from protocol spec
    // 0-1: Total Voltage (10 mV units, high byte first)
    int voltageRaw = (data[0] << 8) | data[1];
    double totalVoltage = voltageRaw / 100.0; // Convert 10mV to V

    // 2-3: Current (10 mA units, signed, high byte first)
    int currentRaw = (data[2] << 8) | data[3];
    // Handle signed 16-bit integer
    if (currentRaw >= 0x8000) currentRaw -= 0x10000;
    double current = currentRaw / 100.0; // Convert 10mA to A

    // 4-5: Remaining Capacity (10 mAh units, high byte first)
    int remainingCapRaw = (data[4] << 8) | data[5];
    double remainingCapacity = remainingCapRaw / 100.0; // Convert 10mAh to Ah

    // 6-7: Nominal Capacity (10 mAh units, high byte first)
    int nominalCapRaw = (data[6] << 8) | data[7];
    double nominalCapacity = nominalCapRaw / 100.0; // Convert 10mAh to Ah

    // 8-9: Cycle Count (high byte first)
    int cycleCount = (data[8] << 8) | data[9];

    // 10-11: Production Date (encoded)
    // int prodDateRaw = (data[10] << 8) | data[11];
    // Date decoding: Date = value & 0x1F, Month = (value >> 5) & 0x0F, Year = 2000 + (value >> 9)
    // Note: Production date is parsed but not stored in the model for now
    // int date = prodDateRaw & 0x1F;
    // int month = (prodDateRaw >> 5) & 0x0F;
    // int year = 2000 + (prodDateRaw >> 9);

    // 12-13: Balance Low (bits 1-16)
    // Note: Balance status is parsed but not stored in the model for now
    // int balanceLow = (data[12] << 8) | data[13];

    // 14-15: Balance High (bits 17-32)
    // Note: Balance status is parsed but not stored in the model for now
    // int balanceHigh = (data[14] << 8) | data[15];

    // 16-17: Protection Status (bit flags)
    int protectionState = (data[16] << 8) | data[17];

    // 18: Software Version
    int softwareVersionRaw = data[18];
    String softwareVersion =
        'v${(softwareVersionRaw >> 4).toString()}.${(softwareVersionRaw & 0x0F).toString()}';

    // 19: RSOC (%)
    int rsoc = data[19];

    // 20: MOS Status
    int mosStatus = data[20];
    bool isCharging = (mosStatus & 0x01) != 0;
    bool isDischarging = (mosStatus & 0x02) != 0;

    // 21: Cell Count
    int cellCount = data[21];

    // 22: NTC Count
    int ntcCount = data[22];

    // 23 onwards: NTC Values (2 bytes each, 0.1K units)
    List<double> temperatures = [];
    for (int i = 0; i < ntcCount; i++) {
      int tempIdx = 23 + (i * 2);
      if (tempIdx + 1 < data.length) {
        int tempRaw = (data[tempIdx] << 8) | data[tempIdx + 1];
        // Convert from 0.1K absolute temperature to Celsius
        double tempKelvin = tempRaw / 10.0;
        double tempCelsius = tempKelvin - 273.15;
        temperatures.add(tempCelsius);
      }
    }

    return BmsBaseInfo(
      totalVoltage: totalVoltage,
      current: current,
      remainingCapacity: remainingCapacity,
      nominalCapacity: nominalCapacity,
      cycleCount: cycleCount,
      rsoc: rsoc,
      temperatures: temperatures,
      isCharging: isCharging,
      isDischarging: isDischarging,
      protectionState: protectionState,
      softwareVersion: softwareVersion,
      cellCount: cellCount,
      ntcCount: ntcCount,
    );
  }
}

/// Represents individual Cell Voltages from Command 0x04 (Jiabaida BMS)
class BmsCellVoltages {
  final List<double> voltages; // V (converted from mV)

  BmsCellVoltages({required this.voltages});

  factory BmsCellVoltages.fromBytes(List<int> data) {
    // Jiabaida format: data is just cell voltage values (2 bytes each, mV units)
    // No count byte at the beginning
    List<double> voltages = [];

    for (int i = 0; i < data.length; i += 2) {
      if (i + 1 < data.length) {
        int vRaw = (data[i] << 8) | data[i + 1];
        voltages.add(vRaw / 1000.0); // Convert mV to V
      }
    }

    return BmsCellVoltages(voltages: voltages);
  }
}

/// Represents Hardware Version from Command 0x05
class BmsHardwareVersion {
  final String version;

  BmsHardwareVersion({required this.version});

  factory BmsHardwareVersion.fromBytes(List<int> data) {
    // Convert ASCII bytes to string
    String version = String.fromCharCodes(data);
    return BmsHardwareVersion(version: version);
  }
}
