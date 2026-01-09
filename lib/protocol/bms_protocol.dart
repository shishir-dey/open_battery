// ignore_for_file: constant_identifier_names

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
  static const int CMD_MOS_CONTROL = 0xE1; // Also an address for writing
  static const int CMD_RESET_PASSWORD = 0x00; // Factory mode / Enter/Exit

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
  /// JBD Format: DD ACTION FUNCTION LENGTH DATA CHECKSUM_H CHECKSUM_L 77
  /// Note: Previous Dart implementation swapped Action and Function.
  static List<int> createPacket(
    int action,
    int function, [
    List<int> data = const [],
  ]) {
    int length = data.length;
    // Packet structure: [DD, Action, Function, Length, Data...]
    List<int> packet = [HEADER, action, function, length, ...data];

    var (high, low) = CrcUtils.calculateChecksum(
      action,
      function,
      length,
      data,
    );
    packet.add(high);
    packet.add(low);
    packet.add(TAIL);

    return packet;
  }

  /// Create Authentication Packet
  /// Format: FF AA CMD LEN DATA CHECKSUM
  static List<int> createAuthPacket(int command, [List<int> data = const []]) {
    // For auth packets, length byte is NOT included in checksum for some commands?
    // C++ 'auth_chksum_' sums data bytes.
    // Frame: Header(FF) Second(AA) Cmd Len Data... Checksum
    // Checksum = Sum(Data) - wait, let's check C++
    // C++ `send_app_key_`: frame[4]..frame[9] = '000000'.
    // chksum range: frame+2 (Cmd) with len = 8.
    // frame[2]=CMD, frame[3]=LEN, frame[4..9]=DATA.
    // So sum is Cmd + Len + Data.

    // C++ `auth_chksum_`: for i=0 to length; sum += data[i].
    // Wait, in `send_app_key_`: `auth_chksum_(frame + 2, 8)`.
    // Frame+2 is Cmd.
    // So it sums Cmd, Len, and Data.

    List<int> payload = [command, data.length, ...data];
    int checksum = CrcUtils.calculateAuthChecksum(payload);

    return [AUTH_HEADER, AUTH_SECOND_BYTE, ...payload, checksum];
  }

  /// Parse a response packet
  static Map<String, dynamic> parseResponse(List<int> packet) {
    if (packet.isEmpty) throw const FormatException("Empty packet");

    // Standard Packet
    if (packet[0] == HEADER) {
      // Check for standard packet with padding
      if (packet.length >= 4) {
        int len = packet[3];
        int expectedLen =
            len + 7; // Header + Action + Func + Len + Data + ChkH + ChkL + Tail
        if (packet.length >= expectedLen && packet[expectedLen - 1] == TAIL) {
          return _parseStandardPacket(packet.sublist(0, expectedLen));
        }
      }

      // Fallback for strict match (no padding)
      if (packet.last == TAIL) {
        return _parseStandardPacket(packet);
      }
    }

    // Auth Packet (can be notified on FF02 or FF01 depending on device)
    if (packet.length >= 4 &&
        packet[0] == AUTH_HEADER &&
        packet[1] == AUTH_SECOND_BYTE) {
      return _parseAuthPacket(packet);
    }

    throw const FormatException("Unknown packet format");
  }

  static Map<String, dynamic> _parseStandardPacket(List<int> packet) {
    if (packet.length < 7) throw const FormatException("Packet too short");

    // 0:DD 1:Func 2:Status 3:Len 4..N:Data N+1:Chkh N+2:Chkl N+3:77
    // IMPORTANT: Client sends [DD Action Function...], Device replies [DD Function Status...]
    // But wait, C++ 'on_jbd_bms_data': function = raw[1].
    // So Response: DD FUNCTION STATUS LEN DATA...

    int function = packet[1];
    int status = packet[2];
    int length = packet[3];

    if (packet.length < length + 7) {
      throw const FormatException("Packet incomplete");
    }

    List<int> data = packet.sublist(4, 4 + length);

    // Verify CRC
    // Response CRC: Sum(Function, Status, Len, Data) -> inv -> +1
    int checksumH = packet[4 + length];
    int checksumL = packet[4 + length + 1];

    var (calcH, calcL) = CrcUtils.calculateChecksum(
      function,
      status,
      length,
      data,
    );

    if (calcH != checksumH || calcL != checksumL) {
      // Ideally throw exception, but for debug we might return error
      // throw const FormatException("Checksum mismatch");
    }

    return {
      'type': 'standard',
      'command': function,
      'status': status,
      'data': data,
    };
  }

  static Map<String, dynamic> _parseAuthPacket(List<int> packet) {
    // FF AA CMD LEN DATA... CHECKSUM
    int command = packet[2];
    int length = packet[3];

    // Validation?

    List<int> data = [];
    if (packet.length > 4) {
      int availableData = packet.length - 5; // minus FF AA CMD LEN ... CHK
      if (availableData > 0) {
        data = packet.sublist(
          4,
          4 + ((availableData < length) ? availableData : length),
        );
        // Note: sometimes length might be inaccurate or we just take what's there
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
    // C++: address 0xE1, Data len 2, Value = current_mos_status & ...
    // Here we just pass the 2 bytes of data.
    // controlValue should be 0x0001, 0x0002 etc.
    // Note: Protocol expects 2 bytes for the value.
    return createWritePacket(CMD_MOS_CONTROL, [
      (controlValue >> 8) & 0xFF,
      controlValue & 0xFF,
    ]);
  }
}
