import 'dart:convert';
import 'dart:typed_data';

import 'package:dndappcompanion/services/networking/framing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('framePayload', () {
    test('frames a JSON string with 4-byte big-endian length prefix', () {
      const jsonString = '{"type":"hello","payload":{}}';
      final framed = framePayload(jsonString);

      final header = ByteData.sublistView(Uint8List.fromList(framed.sublist(0, 4)));
      final length = header.getUint32(0, Endian.big);
      final payload = String.fromCharCodes(framed.sublist(4));

      expect(length, equals(utf8.encode(jsonString).length));
      expect(payload, equals(jsonString));
    });

    test('frames an empty JSON object', () {
      const jsonString = '{}';
      final framed = framePayload(jsonString);

      expect(framed.length, equals(6));
      final header = ByteData.sublistView(Uint8List.fromList(framed.sublist(0, 4)));
      expect(header.getUint32(0, Endian.big), equals(2));
    });

    test('throws on payload exceeding 16 MiB', () {
      final largePayload = '{"data":"${'x' * (16 * 1024 * 1024)}"}';
      expect(() => framePayload(largePayload), throwsArgumentError);
    });
  });

  group('FramingDecoder', () {
    test('decodes a single framed message', () {
      const jsonString = '{"type":"welcome","payload":{}}';
      final framed = framePayload(jsonString);

      final decoder = FramingDecoder();
      final messages = decoder.feed(framed);

      expect(messages, hasLength(1));
      expect(messages[0], equals(jsonString));
    });

    test('decodes multiple messages from a single feed', () {
      const json1 = '{"type":"hello"}';
      const json2 = '{"type":"welcome"}';
      const json3 = '{"type":"ping"}';

      final framed1 = framePayload(json1);
      final framed2 = framePayload(json2);
      final framed3 = framePayload(json3);

      final combined = [...framed1, ...framed2, ...framed3];

      final decoder = FramingDecoder();
      final messages = decoder.feed(combined);

      expect(messages, hasLength(3));
      expect(messages[0], equals(json1));
      expect(messages[1], equals(json2));
      expect(messages[2], equals(json3));
    });

    test('decodes messages from partial chunks', () {
      const json1 = '{"type":"hello"}';
      const json2 = '{"type":"welcome"}';

      final framed1 = framePayload(json1);
      final framed2 = framePayload(json2);

      final decoder = FramingDecoder();

      final chunk1 = framed1.sublist(0, 5);
      final chunk2 = [...framed1.sublist(5), ...framed2];

      final messages1 = decoder.feed(chunk1);
      expect(messages1, isEmpty);

      final messages2 = decoder.feed(chunk2);
      expect(messages2, hasLength(2));
      expect(messages2[0], equals(json1));
      expect(messages2[1], equals(json2));
    });

    test('handles incomplete message gracefully', () {
      const jsonString = '{"type":"hello"}';
      final framed = framePayload(jsonString);

      final decoder = FramingDecoder();
      final partial = framed.sublist(0, framed.length - 5);

      final messages = decoder.feed(partial);
      expect(messages, isEmpty);
    });

    test('reset clears buffer', () {
      const jsonString = '{"type":"hello"}';
      final framed = framePayload(jsonString);

      final decoder = FramingDecoder();
      decoder.feed(framed.sublist(0, 6));
      decoder.reset();

      final messages = decoder.feed(framed);
      expect(messages, hasLength(1));
      expect(messages[0], equals(jsonString));
    });
  });
}
