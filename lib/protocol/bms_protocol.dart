// ignore_for_file: constant_identifier_names

import 'crc_utils.dart';

/// BMS Protocol Handler for Jiabaida BMS
class BmsProtocol {
  static const int HEADER = 0xDD;
  static const int TAIL = 0x77;
  static const int MODE_READ = 0xA5;
  static const int MODE_WRITE = 0x5A;
  static const int CMD_READ_BASE_INFO = 0x03;
  static const int CMD_READ_CELL_VOLTAGES = 0x04;
  static const int CMD_READ_HARDWARE_VERSION = 0x05;
  static const int CMD_MOS_CONTROL = 0xE1;

  /// Create a request packet
  /// For Jiabaida protocol: DD CMD MODE LEN DATA CHECKSUM_H CHECKSUM_L 77
  static List<int> createPacket(
    int command,
    int mode, [
    List<int> data = const [],
  ]) {
    int length = data.length;
    List<int> packet = [HEADER, command, mode, length, ...data];

    var (high, low) = CrcUtils.calculateChecksum(command, data);
    packet.add(high);
    packet.add(low);
    packet.add(TAIL);

    return packet;
  }

  /// Parse a response packet
  /// Returns a map with 'command', 'status', and 'data' if valid
  /// Throws FormatException if invalid
  static Map<String, dynamic> parseResponse(List<int> packet) {
    if (packet.length < 7) {
      throw const FormatException("Packet too short");
    }

    if (packet[0] != HEADER || packet.last != TAIL) {
      throw const FormatException("Invalid header/tail");
    }

    int responseCmd = packet[1];
    int status = packet[2];
    int length = packet[3];

    // Validate length consistency (Header(1) + Cmd(1) + Status(1) + Len(1) + Data(N) + Checksum(2) + Tail(1) = N + 7)
    if (packet.length != length + 7) {
      // Note: Sometimes devices might send extra bytes or fragmentation might occur.
      // For this implementation, we assume a complete frame is passed.
      // We can also just take the slice based on length.
    }

    if (packet.length < length + 7) {
      throw const FormatException("Packet data incomplete");
    }

    List<int> data = packet.sublist(4, 4 + length);
    int checksumH = packet[4 + length];
    int checksumL = packet[4 + length + 1];

    var (calcH, calcL) = CrcUtils.calculateChecksum(responseCmd, data);

    if (calcH != checksumH || calcL != checksumL) {
      // throw const FormatException("Checksum mismatch");
      // User requested to skip checksum validation
      // print("Warning: Checksum mismatch. Expected ${checksumH.toRadixString(16)}${checksumL.toRadixString(16)}, got ${calcH.toRadixString(16)}${calcL.toRadixString(16)}");
    }

    return {'command': responseCmd, 'status': status, 'data': data};
  }

  /// Create a read request packet (convenience method)
  static List<int> createReadPacket(int command) {
    return createPacket(command, MODE_READ);
  }

  /// Create a write request packet (convenience method)
  static List<int> createWritePacket(int command, List<int> data) {
    return createPacket(command, MODE_WRITE, data);
  }

  /// Create MOS control packet
  static List<int> createMosControlPacket(int controlValue) {
    return createWritePacket(CMD_MOS_CONTROL, [0x00, controlValue]);
  }
}
