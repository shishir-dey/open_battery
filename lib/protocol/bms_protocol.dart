// ignore_for_file: constant_identifier_names

/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/protocol/bms_protocol.dart
 * Description: Implements the BMS protocol for communicating with Jiabaida BMS devices, including packet creation and parsing.
 * Author: Shishir Dey
 * License: MIT
 */

import 'package:flutter/foundation.dart';
import 'crc_utils.dart';

/// BMS Protocol Handler for Jiabaida BMS
class BmsProtocol {
  // === Standard Protocol ===
  static const int HEADER = 0xDD;
  static const int TAIL = 0x77;

  // Action (Byte 1)
  static const int ACTION_READ = 0xA5;
  static const int ACTION_WRITE = 0x5A;

  // Functions / Addresses (Byte 2)
  static const int CMD_READ_BASE_INFO = 0x03;
  static const int CMD_READ_CELL_VOLTAGES = 0x04;
  static const int CMD_READ_HARDWARE_VERSION = 0x05;
  static const int CMD_MOS_CONTROL = 0xE1;
  static const int CMD_RESET_PASSWORD = 0x00;

  // === Authentication Protocol ===
  static const int AUTH_HEADER = 0xFF;
  static const int AUTH_SECOND_BYTE = 0xAA;
  static const int AUTH_TAIL = 0x77;

  // Auth Commands
  static const int AUTH_CMD_SEND_APP_KEY = 0x15;
  static const int AUTH_CMD_CHANGE_PASSWORD = 0x16;
  static const int AUTH_CMD_GET_RANDOM = 0x17;
  static const int AUTH_CMD_SEND_PASSWORD = 0x18;
  static const int AUTH_CMD_SEND_ROOT_PASSWORD = 0x1D;

  /// Create a request packet
  /// Request Format: DD ACTION FUNCTION LENGTH DATA CHECKSUM_H CHECKSUM_L 77
  /// Checksum covers: FUNCTION + LENGTH + DATA (per protocol spec)
  static List<int> createPacket(
    int action,
    int function, [
    List<int> data = const [],
  ]) {
    int length = data.length;
    List<int> packet = [HEADER, action, function, length, ...data];

    // Checksum covers function + length + data (matching Adafruit/ESPHome)
    var (high, low) = CrcUtils.calculateRequestChecksum(function, length, data);
    packet.add(high);
    packet.add(low);
    packet.add(TAIL);

    return packet;
  }

  /// Create Authentication Packet
  /// Format: FF AA CMD LEN DATA CHECKSUM
  static List<int> createAuthPacket(int command, [List<int> data = const []]) {
    List<int> payload = [command, data.length, ...data];
    int checksum = CrcUtils.calculateAuthChecksum(payload);

    return [AUTH_HEADER, AUTH_SECOND_BYTE, ...payload, checksum];
  }

  /// Parse a response packet
  static Map<String, dynamic> parseResponse(List<int> packet) {
    if (packet.isEmpty) throw const FormatException("Empty packet");

    // Standard Packet - Response starts with DD
    if (packet[0] == HEADER) {
      // Check minimum packet size (DD CMD STATUS LEN CHK_H CHK_L 77)
      if (packet.length >= 7) {
        int len = packet[3];
        int expectedLen =
            len + 7; // DD + CMD + STATUS + LEN + DATA + CHK_H + CHK_L + 77

        // Handle padded packets
        if (packet.length >= expectedLen && packet[expectedLen - 1] == TAIL) {
          return _parseStandardPacket(packet.sublist(0, expectedLen));
        }

        // Fallback for exact length packets
        if (packet.length == expectedLen && packet.last == TAIL) {
          return _parseStandardPacket(packet);
        }
      }
    }

    // Auth Packet
    if (packet.length >= 4 &&
        packet[0] == AUTH_HEADER &&
        packet[1] == AUTH_SECOND_BYTE) {
      return _parseAuthPacket(packet);
    }

    throw const FormatException("Unknown packet format");
  }

  static Map<String, dynamic> _parseStandardPacket(List<int> packet) {
    if (packet.length < 7) throw const FormatException("Packet too short");

    // Response format from Java: DD COMMAND STATUS LENGTH DATA CHECKSUM_H CHECKSUM_L 77
    // Where COMMAND echoes back the function from the request
    int command = packet[1];
    int status = packet[2];
    int length = packet[3];

    if (packet.length < length + 7) {
      throw FormatException(
        "Packet incomplete: expected ${length + 7}, got ${packet.length}",
      );
    }

    List<int> data = packet.sublist(4, 4 + length);

    // Verify CRC - checksum covers length + data bytes only
    int checksumH = packet[4 + length];
    int checksumL = packet[4 + length + 1];

    var (calcH, calcL) = CrcUtils.calculateResponseChecksum(length, data);

    // Log checksum validation for debugging
    if (calcH != checksumH || calcL != checksumL) {
      debugPrint(
        "⚠️ Checksum: received=0x${checksumH.toRadixString(16)}${checksumL.toRadixString(16)}, "
        "calculated=0x${calcH.toRadixString(16)}${calcL.toRadixString(16)}",
      );
      // Continue processing - some BMS units have non-standard checksums
    }

    return {
      'type': 'standard',
      'command': command,
      'status': status,
      'data': data,
    };
  }

  static Map<String, dynamic> _parseAuthPacket(List<int> packet) {
    // FF AA CMD LEN DATA... CHECKSUM
    int command = packet[2];
    int length = packet[3];

    List<int> data = [];
    if (packet.length > 4) {
      int availableData = packet.length - 5;
      if (availableData > 0) {
        data = packet.sublist(
          4,
          4 + ((availableData < length) ? availableData : length),
        );
      }
    }

    return {'type': 'auth', 'command': command, 'data': data};
  }

  /// Create a read request packet
  static List<int> createReadPacket(int function) {
    return createPacket(ACTION_READ, function);
  }

  /// Create a write request packet
  static List<int> createWritePacket(int address, List<int> data) {
    return createPacket(ACTION_WRITE, address, data);
  }

  /// Create MOS control packet
  static List<int> createMosControlPacket(int controlValue) {
    return createWritePacket(CMD_MOS_CONTROL, [
      (controlValue >> 8) & 0xFF,
      controlValue & 0xFF,
    ]);
  }

  /// Helper method to format packet as hex string for debugging
  static String packetToHex(List<int> packet) {
    return packet
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
  }
}
