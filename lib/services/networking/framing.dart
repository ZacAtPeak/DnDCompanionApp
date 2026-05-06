import 'dart:convert';
import 'dart:typed_data';

const int kMaxPayloadSize = 16 * 1024 * 1024; // 16 MiB

List<int> framePayload(String jsonString) {
  final payloadBytes = utf8.encode(jsonString);
  if (payloadBytes.length > kMaxPayloadSize) {
    throw ArgumentError(
        'Payload size ${payloadBytes.length} exceeds maximum $kMaxPayloadSize');
  }
  final header = ByteData(4);
  header.setUint32(0, payloadBytes.length, Endian.big);
  return [...header.buffer.asUint8List(), ...payloadBytes];
}

class FramingDecoder {
  final List<int> _buffer = [];
  int? _expectedLength;

  List<String> feed(List<int> data) {
    _buffer.addAll(data);
    final messages = <String>[];

    while (true) {
      if (_expectedLength == null) {
        if (_buffer.length < 4) break;
        final header = ByteData.sublistView(Uint8List.fromList(_buffer.sublist(0, 4)));
        _expectedLength = header.getUint32(0, Endian.big);
        _buffer.removeRange(0, 4);
      }

      if (_buffer.length < _expectedLength!) break;

      final payloadBytes = _buffer.sublist(0, _expectedLength!);
      _buffer.removeRange(0, _expectedLength!);
      messages.add(utf8.decode(payloadBytes));
      _expectedLength = null;
    }

    return messages;
  }

  void reset() {
    _buffer.clear();
    _expectedLength = null;
  }
}
