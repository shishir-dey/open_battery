import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_battery/protocol/bms_protocol.dart';
import 'package:open_battery/protocol/crc_utils.dart';

void main() {
  group('CrcUtils', () {
    group('calculateChecksum', () {
      // Test against Adafruit reference packet: {0xdd, 0xa5, 0x03, 0x00, 0xff, 0xfd, 0x77}
      // Checksum covers function=0x03 + length=0x00 = 0x10000 - 0x03 = 0xFFFD
      test(
        'should calculate correct checksum for base info request (from Adafruit)',
        () {
          final (high, low) = CrcUtils.calculateRequestChecksum(0x03, 0x00, []);
          expect(high, equals(0xFF));
          expect(low, equals(0xFD)); // Matches Adafruit: 0xff, 0xfd
        },
      );

      // Test against Adafruit reference packet: {0xdd, 0xa5, 0x04, 0x00, 0xff, 0xfc, 0x77}
      test(
        'should calculate correct checksum for cell voltages request (from Adafruit)',
        () {
          final (high, low) = CrcUtils.calculateRequestChecksum(0x04, 0x00, []);
          expect(high, equals(0xFF));
          expect(low, equals(0xFC)); // Matches Adafruit: 0xff, 0xfc
        },
      );

      test('should calculate checksum with data bytes', () {
        // 0x10000 - (0x03 + 0x02 + 0x01 + 0x02) = 0x10000 - 0x08 = 0xFFF8
        final (high, low) = CrcUtils.calculateRequestChecksum(0x03, 0x02, [
          0x01,
          0x02,
        ]);
        expect(high, equals(0xFF));
        expect(low, equals(0xF8));
      });

      test('should handle overflow correctly', () {
        // 0x10000 - (0xFF + 0xFF + 0xFF + 0xFF + 0xFF) = 0x10000 - 0x4FB = 0xFB05
        final (high, low) = CrcUtils.calculateRequestChecksum(0xFF, 0xFF, [
          0xFF,
          0xFF,
          0xFF,
        ]);
        expect(high, equals(0xFB));
        expect(low, equals(0x05));
      });
    });

    group('calculateAuthChecksum', () {
      test('should calculate 8-bit checksum for auth payload', () {
        final checksum = CrcUtils.calculateAuthChecksum([0x15, 0x06]);
        expect(checksum, equals(0x1B));
      });

      test('should handle overflow by masking to 8 bits', () {
        final checksum = CrcUtils.calculateAuthChecksum([0xFF, 0xFF, 0xFF]);
        expect(checksum, equals(0xFD));
      });
    });
  });

  group('BmsProtocol', () {
    group('Constants', () {
      test('should have correct standard protocol constants', () {
        expect(BmsProtocol.HEADER, equals(0xDD));
        expect(BmsProtocol.TAIL, equals(0x77));
        expect(BmsProtocol.ACTION_READ, equals(0xA5));
        expect(BmsProtocol.ACTION_WRITE, equals(0x5A));
      });

      test('should have correct command constants', () {
        expect(BmsProtocol.CMD_READ_BASE_INFO, equals(0x03));
        expect(BmsProtocol.CMD_READ_CELL_VOLTAGES, equals(0x04));
        expect(BmsProtocol.CMD_READ_HARDWARE_VERSION, equals(0x05));
        expect(BmsProtocol.CMD_MOS_CONTROL, equals(0xE1));
      });

      test('should have correct auth protocol constants', () {
        expect(BmsProtocol.AUTH_HEADER, equals(0xFF));
        expect(BmsProtocol.AUTH_SECOND_BYTE, equals(0xAA));
      });
    });

    group('createPacket', () {
      test('should create request packet with no data', () {
        final packet = BmsProtocol.createPacket(0xA5, 0x03);

        expect(packet[0], equals(0xDD)); // Header
        expect(packet[1], equals(0xA5)); // Action
        expect(packet[2], equals(0x03)); // Function
        expect(packet[3], equals(0x00)); // Length
        expect(packet[packet.length - 1], equals(0x77)); // Tail
        expect(packet.length, equals(7));
      });

      test('should create request packet with data', () {
        final packet = BmsProtocol.createPacket(0x5A, 0xE1, [0x00, 0x01]);

        expect(packet[0], equals(0xDD));
        expect(packet[1], equals(0x5A));
        expect(packet[2], equals(0xE1));
        expect(packet[3], equals(0x02));
        expect(packet[4], equals(0x00));
        expect(packet[5], equals(0x01));
        expect(packet.length, equals(9));
      });

      test('should include correct checksum', () {
        final packet = BmsProtocol.createPacket(0xA5, 0x03, []);

        // Checksum covers function + length, not action
        final (expectedH, expectedL) = CrcUtils.calculateRequestChecksum(
          0x03,
          0,
          [],
        );
        expect(packet[4], equals(expectedH));
        expect(packet[5], equals(expectedL));
      });
    });

    group('parseResponse - Real Device Responses', () {
      test('should parse actual BMS response DD A5 05 00 FF 56 77', () {
        // Your actual received packet
        final packet = [0xDD, 0xA5, 0x05, 0x00, 0xFF, 0x56, 0x77];
        final result = BmsProtocol.parseResponse(packet);

        expect(result['type'], equals('standard'));
        expect(
          result['command'],
          equals(0xA5),
        ); // Function from request echoed back
        expect(result['status'], equals(0x05)); // Hardware version command
        expect(result['data'], isEmpty);

        debugPrint(
          '✓ Parsed response: CMD=0x${result['command'].toRadixString(16)}, STATUS=0x${result['status'].toRadixString(16)}',
        );
      });

      test('should handle padded response packet', () {
        // Response with trailing padding bytes
        final packet = [
          0xDD,
          0xA5,
          0x05,
          0x00,
          0xFF,
          0x56,
          0x77,
          0x00,
          0x00,
          0x00,
        ];
        final result = BmsProtocol.parseResponse(packet);

        expect(result['type'], equals('standard'));
        expect(result['command'], equals(0xA5));
        expect(result['status'], equals(0x05));
        expect(result['data'], isEmpty);
      });

      test('should parse response with data payload', () {
        // Simulated response with 3 bytes of data
        // Response checksum covers only length + data
        final data = [0x01, 0x02, 0x03];
        final (checkH, checkL) = CrcUtils.calculateResponseChecksum(
          3, // length
          data,
        );
        final packet = [0xDD, 0x03, 0x00, 0x03, ...data, checkH, checkL, 0x77];

        final result = BmsProtocol.parseResponse(packet);

        expect(result['command'], equals(0x03));
        expect(result['status'], equals(0x00));
        expect(result['data'], equals([0x01, 0x02, 0x03]));
      });

      test('should log warning on checksum mismatch but still parse', () {
        // Checksum validation now logs warning but continues parsing
        // This matches behavior of some BMS units with non-standard checksums
        final packet = [0xDD, 0x05, 0x00, 0x00, 0xFF, 0xFF, 0x77];
        final result = BmsProtocol.parseResponse(packet);

        // Should still parse successfully even with bad checksum
        expect(result['type'], equals('standard'));
        expect(result['command'], equals(0x05));
      });
    });

    group('createReadPacket', () {
      // Verified against Adafruit reference: {0xdd, 0xa5, 0x03, 0x00, 0xff, 0xfd, 0x77}
      test(
        'should create read base info packet (matches Adafruit reference)',
        () {
          final packet = BmsProtocol.createReadPacket(
            BmsProtocol.CMD_READ_BASE_INFO,
          );

          expect(
            BmsProtocol.packetToHex(packet),
            equals('DD A5 03 00 FF FD 77'),
          );
          debugPrint('✓ Read Base Info: ${BmsProtocol.packetToHex(packet)}');
        },
      );

      // Verified against Adafruit reference: {0xdd, 0xa5, 0x04, 0x00, 0xff, 0xfc, 0x77}
      test(
        'should create read cell voltages packet (matches Adafruit reference)',
        () {
          final packet = BmsProtocol.createReadPacket(
            BmsProtocol.CMD_READ_CELL_VOLTAGES,
          );

          expect(
            BmsProtocol.packetToHex(packet),
            equals('DD A5 04 00 FF FC 77'),
          );
          debugPrint(
            '✓ Read Cell Voltages: ${BmsProtocol.packetToHex(packet)}',
          );
        },
      );

      test('should create read hardware version packet', () {
        final packet = BmsProtocol.createReadPacket(
          BmsProtocol.CMD_READ_HARDWARE_VERSION,
        );

        // 0x10000 - 0x05 = 0xFFFB
        expect(BmsProtocol.packetToHex(packet), equals('DD A5 05 00 FF FB 77'));
        debugPrint(
          '✓ Read Hardware Version: ${BmsProtocol.packetToHex(packet)}',
        );
      });
    });

    group('createWritePacket', () {
      test('should create write packet with data', () {
        final packet = BmsProtocol.createWritePacket(0xE1, [0x00, 0x02]);

        expect(packet[1], equals(BmsProtocol.ACTION_WRITE));
        expect(packet[2], equals(0xE1));
        expect(packet[3], equals(0x02));
        expect(packet[4], equals(0x00));
        expect(packet[5], equals(0x02));
      });
    });

    group('createMosControlPacket', () {
      test('should create MOS control packet with 16-bit value', () {
        final packet = BmsProtocol.createMosControlPacket(0x0001);

        expect(packet[1], equals(BmsProtocol.ACTION_WRITE));
        expect(packet[2], equals(BmsProtocol.CMD_MOS_CONTROL));
        expect(packet[3], equals(0x02));
        expect(packet[4], equals(0x00));
        expect(packet[5], equals(0x01));
      });

      test('should split 16-bit value correctly', () {
        final packet = BmsProtocol.createMosControlPacket(0x1234);

        expect(packet[4], equals(0x12));
        expect(packet[5], equals(0x34));
      });
    });

    group('createAuthPacket', () {
      test('should create get random auth packet', () {
        final packet = BmsProtocol.createAuthPacket(
          BmsProtocol.AUTH_CMD_GET_RANDOM,
        );

        expect(packet[0], equals(0xFF));
        expect(packet[1], equals(0xAA));
        expect(packet[2], equals(0x17)); // GET_RANDOM command
        expect(packet[3], equals(0x00));
        expect(packet.length, equals(5));

        debugPrint('✓ Get Random: ${BmsProtocol.packetToHex(packet)}');
      });

      test('should create send app key packet', () {
        final appKeyData = [0x30, 0x30, 0x30, 0x30, 0x30, 0x30]; // "000000"
        final packet = BmsProtocol.createAuthPacket(
          BmsProtocol.AUTH_CMD_SEND_APP_KEY,
          appKeyData,
        );

        expect(packet[0], equals(0xFF));
        expect(packet[1], equals(0xAA));
        expect(packet[2], equals(0x15)); // SEND_APP_KEY command
        expect(packet[3], equals(0x06));
        expect(packet.length, equals(11));

        debugPrint('✓ Send App Key: ${BmsProtocol.packetToHex(packet)}');
      });
    });

    group('parseResponse - Auth Packets', () {
      test('should parse get random response', () {
        // FF AA 17 01 XX CHECKSUM (XX is random byte)
        final packet = [0xFF, 0xAA, 0x17, 0x01, 0x42, 0x5A];
        final result = BmsProtocol.parseResponse(packet);

        expect(result['type'], equals('auth'));
        expect(result['command'], equals(0x17));
        expect(result['data'], equals([0x42]));
      });

      test('should parse app key check response', () {
        // FF AA 15 01 00 CHECKSUM (00 = success)
        final packet = [0xFF, 0xAA, 0x15, 0x01, 0x00, 0x16];
        final result = BmsProtocol.parseResponse(packet);

        expect(result['type'], equals('auth'));
        expect(result['command'], equals(0x15));
        expect(result['data'], equals([0x00]));
      });
    });

    group('Integration Tests', () {
      test('should handle complete read hardware version flow', () {
        // Create request
        final request = BmsProtocol.createReadPacket(
          BmsProtocol.CMD_READ_HARDWARE_VERSION,
        );
        debugPrint('\n=== Hardware Version Flow ===');
        debugPrint('Request:  ${BmsProtocol.packetToHex(request)}');

        // Simulate actual device response
        final response = [0xDD, 0xA5, 0x05, 0x00, 0xFF, 0x56, 0x77];
        debugPrint('Response: ${BmsProtocol.packetToHex(response)}');

        // Parse response
        final parsed = BmsProtocol.parseResponse(response);

        debugPrint('Command:  0x${parsed['command'].toRadixString(16)}');
        debugPrint('Status:   0x${parsed['status'].toRadixString(16)}');
        debugPrint('Data:     ${parsed['data']}');

        expect(parsed['type'], equals('standard'));
        expect(parsed['command'], equals(0xA5));
        expect(parsed['status'], equals(0x05));
      });

      test('should verify request-response command matching', () {
        // When we send READ (0xA5) + FUNCTION (0x03)
        final request = BmsProtocol.createReadPacket(0x03);

        // Response format: DD CMD STATUS LEN DATA... CHK_H CHK_L 77
        final data = [0x01, 0x02];
        final (checkH, checkL) = CrcUtils.calculateResponseChecksum(
          2, // length
          data,
        );
        final response = [
          0xDD,
          0x03, // CMD echoes the function
          0x00, // STATUS (0x00 = OK)
          0x02, // LEN
          ...data,
          checkH,
          checkL,
          0x77,
        ];

        final parsed = BmsProtocol.parseResponse(response);

        // The response command (0x03) matches our request function
        expect(
          parsed['command'],
          equals(request[2]),
        ); // request[2] is the function
      });

      test('should handle zero-length data response', () {
        // Zero length data, checksum covers just length byte (0x00)
        final (checkH, checkL) = CrcUtils.calculateResponseChecksum(0x00, []);
        final packet = [0xDD, 0x03, 0x00, 0x00, checkH, checkL, 0x77];
        final result = BmsProtocol.parseResponse(packet);

        expect(result['data'], isEmpty);
      });

      test('should handle maximum data length', () {
        final data = List.filled(255, 0x42);
        final (checkH, checkL) = CrcUtils.calculateResponseChecksum(255, data);
        final packet = [0xDD, 0x04, 0x00, 0xFF, ...data, checkH, checkL, 0x77];

        final result = BmsProtocol.parseResponse(packet);
        expect(result['data'].length, equals(255));
      });

      test('should reject packet with wrong header', () {
        final packet = [0xDE, 0xA5, 0x05, 0x00, 0xFF, 0x56, 0x77];

        expect(
          () => BmsProtocol.parseResponse(packet),
          throwsA(isA<FormatException>()),
        );
      });

      test('should reject packet with missing tail', () {
        final packet = [0xDD, 0xA5, 0x05, 0x00, 0xFF, 0x56, 0x78];

        expect(
          () => BmsProtocol.parseResponse(packet),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('packetToHex helper', () {
      test('should format packet as hex string', () {
        final packet = [0xDD, 0xA5, 0x05, 0x00, 0xFF, 0x56, 0x77];
        expect(BmsProtocol.packetToHex(packet), equals('DD A5 05 00 FF 56 77'));
      });

      test('should handle single digit hex values', () {
        final packet = [0x01, 0x02, 0x0A, 0x0F];
        expect(BmsProtocol.packetToHex(packet), equals('01 02 0A 0F'));
      });
    });
  });
}
