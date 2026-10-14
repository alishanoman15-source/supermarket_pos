import 'dart:convert';
import 'dart:typed_data';

/// Minimal ESC/POS encoder (SPEC §39) for 58 mm / 80 mm thermal printers.
///
/// The produced byte stream is printer-agnostic: it can be written to any raw
/// channel (Bluetooth SPP, USB bulk transfer, network port 9100) without a
/// vendor SDK. Text is emitted ASCII-safe, so product names written in a
/// non-Latin script fall back to `?` instead of corrupting the receipt.
class EscPosEncoder {
  EscPosEncoder({this.charsPerLine = 48});

  /// Characters per line — 48 for 80 mm paper, 32 for 58 mm.
  final int charsPerLine;

  final BytesBuilder _out = BytesBuilder();

  static const List<int> _init = [0x1B, 0x40]; // ESC @
  static const List<int> _cut = [0x1D, 0x56, 0x42, 0x00]; // GS V B 0

  /// ESC @ — resets the printer to power-on state.
  void initialize() => _write(_init);

  /// GS a n — 0 = left, 1 = center, 2 = right.
  void align(int alignment) => _write([0x1B, 0x61, alignment]);

  /// ESC E n — bold on/off.
  void bold(bool enabled) => _write([0x1B, 0x45, enabled ? 1 : 0]);

  /// GS ! n — character size; 0 = single, 0x11 = double width and height.
  void doubleSize(bool enabled) => _write([0x1D, 0x21, enabled ? 0x11 : 0x00]);

  /// ESC d n — feed n lines.
  void feed(int lines) => _write([0x1B, 0x64, lines]);

  /// Prints [text] (wrapped to [charsPerLine]) followed by a line feed.
  void line(
    String text, {
    bool bold = false,
    bool center = false,
    bool large = false,
  }) {
    this.bold(bold);
    align(center ? 1 : 0);
    doubleSize(large);
    for (final chunk in wrapAscii(text, charsPerLine)) {
      _write(asciiBytes(chunk));
      _write(const [0x0A]);
    }
    this.bold(false);
    doubleSize(false);
  }

  /// A dashed rule across the paper.
  void rule() => line('-' * charsPerLine);

  /// `key` on the left, `value` on the right of one line.
  void keyValue(String key, String value, {bool bold = false}) {
    final left = wrapAscii(key, charsPerLine - 1).first;
    final right = wrapAscii(value, charsPerLine - 1).last;
    final gap = charsPerLine - _width(left) - _width(right);
    line('$left${' ' * (gap < 1 ? 1 : gap)}$right', bold: bold);
  }

  void cut() {
    feed(3);
    _write(_cut);
  }

  /// The complete ticket.
  List<int> toBytes() => _out.toBytes();

  void _write(List<int> bytes) => _out.add(bytes);

  /// ASCII with `?` in place of anything the printer cannot render, so a
  /// non-Latin product name never shifts the columns.
  static String asciiSafe(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      buffer.writeCharCode(rune >= 0x20 && rune <= 0x7E ? rune : 0x3F);
    }
    return buffer.toString();
  }

  static List<int> asciiBytes(String text) => ascii.encode(asciiSafe(text));

  /// Splits [text] into display lines of at most [width] characters, breaking
  /// on spaces where possible.
  static List<String> wrapAscii(String text, int width) {
    if (width <= 0) return [asciiSafe(text)];
    final safe = asciiSafe(text);
    if (safe.length <= width) return [safe];

    final lines = <String>[];
    var remaining = safe;
    while (remaining.length > width) {
      var cut = remaining.lastIndexOf(' ', width);
      if (cut <= 0) cut = width;
      lines.add(remaining.substring(0, cut));
      remaining = remaining.substring(cut).trimLeft();
    }
    if (remaining.isNotEmpty) lines.add(remaining);
    return lines;
  }

  static int _width(String text) => text.length;
}
