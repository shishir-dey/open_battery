/// CRC Utils for calculating 16-bit checksum
class CrcUtils {
  /// Calculate 16-bit checksum: sum of all bytes (Cmd, Mode, Len, Data), invert, +1 (Jiabaida protocol)
  /// Note: The command, mode/status, and length bytes are included in the sum.
  static (int high, int low) calculateChecksum(
    int command,
    int modeOrStatus,
    int length,
    List<int> data,
  ) {
    int checksum = command + modeOrStatus + length;
    for (int byte in data) {
      checksum += byte;
    }

    // Jiabaida checksum: sum → invert → +1
    checksum = ~checksum + 1;
    checksum = checksum & 0xFFFF; // Ensure 16-bit
    int highByte = (checksum >> 8) & 0xFF;
    int lowByte = checksum & 0xFF;

    return (highByte, lowByte);
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
