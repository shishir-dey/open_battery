/// CRC Utils for calculating 16-bit checksum
class CrcUtils {
  /// Calculate 16-bit checksum: sum of all bytes, invert, +1 (Jiabaida protocol)
  static (int high, int low) calculateChecksum(int command, List<int> data) {
    int checksum = command;
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
}
