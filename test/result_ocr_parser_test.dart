import 'package:flutter_test/flutter_test.dart';
import 'package:tc_whatsapp/services/result_ocr_parser.dart';

OcrToken t(String text, int x, int y) => OcrToken(
      text: text,
      left: x,
      top: y,
      right: x + 40,
      bottom: y + 24,
    );

void main() {
  test('fills prizes and 30 compliments column-major from a result screenshot', () {
    final tokens = <OcrToken>[
      t('6', 20, 10),
      t('PM', 50, 10),
      t('08-10-2026', 40, 80),
      t('1', 80, 140),
      t(':', 110, 140),
      t('018', 140, 140),
      t('2', 80, 180),
      t(':', 110, 180),
      t('101', 140, 180),
      t('3', 80, 220),
      t(':', 110, 220),
      t('493', 140, 220),
      t('4', 80, 260),
      t(':', 110, 260),
      t('432', 140, 260),
      t('5', 80, 300),
      t(':', 110, 300),
      t('809', 140, 300),
      t('COMPLIMENTS', 80, 360),
    ];

    const col1 = [
      '007', '045', '055', '122', '179', '186', '200', '206', '277', '300',
    ];
    const col2 = [
      '320', '351', '366', '371', '407', '513', '519', '554', '611', '703',
    ];
    const col3 = [
      '715', '748', '792', '826', '828', '854', '879', '891', '943', '978',
    ];
    for (var row = 0; row < 10; row++) {
      final y = 420 + row * 36;
      tokens.add(t(col1[row], 40, y));
      tokens.add(t(col2[row], 180, y));
      tokens.add(t(col3[row], 320, y));
    }

    final parsed = ResultOcrParser.parse(tokens);
    expect(parsed.prizes, ['018', '101', '493', '432', '809']);
    expect(parsed.compliments, [...col1, ...col2, ...col3]);
    expect(parsed.date, DateTime(2026, 10, 8));
  });
}
