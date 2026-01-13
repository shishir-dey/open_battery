/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/protocol/crc_utils.dart
 * Description: Provides CRC utilities for calculating checksums used in the BMS protocol.
 * Author: Shishir Dey
 * License: MIT
 */

/// CRC Utils for calculating 16-bit checksum
class CrcUtils {
  /// Calculate 16-bit checksum for REQUEST packets
  /// Protocol: 0x10000 - sum(function + length + data)
  /// Reference: Adafruit nrf52 and ESPHome implementations
  static (int high, int low) calculateRequestChecksum(
    int function,
    int length,
    List<int> data,
  ) {
    int sum = function + length;
    for (int byte in data) {
      sum += byte;
    }

    // Protocol formula: 0x10000 - sum
    int checksum = (0x10000 - sum) & 0xFFFF;
    int highByte = (checksum >> 8) & 0xFF;
    int lowByte = checksum & 0xFF;

    return (highByte, lowByte);
  }

  /// Calculate 16-bit checksum for RESPONSE validation
  /// Protocol: 0x10000 - sum(length + data)
  /// The checksum includes the length byte and all data bytes
  static (int high, int low) calculateResponseChecksum(
    int length,
    List<int> data,
  ) {
    int sum = length;
    for (int byte in data) {
      sum += byte;
    }

    // Protocol formula: 0x10000 - sum
    int checksum = (0x10000 - sum) & 0xFFFF;
    int highByte = (checksum >> 8) & 0xFF;
    int lowByte = checksum & 0xFF;

    return (highByte, lowByte);
  }

  /// Legacy method - kept for backwards compatibility with tests
  /// Uses the request checksum logic
  static (int high, int low) calculateChecksum(
    int command,
    int modeOrStatus,
    int length,
    List<int> data,
  ) {
    // For request packets, the checksum covers: function + length + data
    // The 'command' param is actually the function in request context
    return calculateRequestChecksum(command, length, data);
  }

  /// Calculate 8-bit checksum for Auth packets
  /// Sum of all payload bytes (starting after header/type)
  static int calculateAuthChecksum(List<int> payload) {
    int checksum = 0;
    for (int byte in payload) {
      checksum += byte;
    }
    return checksum & 0xFF;
  }
}
