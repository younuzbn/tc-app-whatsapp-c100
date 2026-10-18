class OcrToken {
  const OcrToken({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final int left;
  final int top;
  final int right;
  final int bottom;

  double get cx => (left + right) / 2;
  double get cy => (top + bottom) / 2;
  double get height => (bottom - top).toDouble().clamp(8, 200);

  factory OcrToken.fromMap(Map<dynamic, dynamic> json) {
    int n(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return OcrToken(
      text: json['text']?.toString() ?? '',
      left: n(json['left']),
      top: n(json['top']),
      right: n(json['right']),
      bottom: n(json['bottom']),
    );
  }
}

class ParsedResultSheet {
  const ParsedResultSheet({
    required this.prizes,
    required this.compliments,
    this.date,
  });

  final List<String> prizes;
  final List<String> compliments;
  final DateTime? date;
}

class ResultOcrParser {
  static final _prizeLine = RegExp(
    r'(?<!\d)([1-5])\s*[:.]\s*([0-9OIl|]{3})(?!\d)',
  );
  static final _rankToken = RegExp(r'^[1-5]$');
  static final _dateLine = RegExp(
    r'(?<!\d)(\d{2})[-/.](\d{2})[-/.](\d{4})(?!\d)',
  );

  static ParsedResultSheet parse(List<OcrToken> tokens) {
    if (tokens.isEmpty) {
      throw Exception('No text found in this image.');
    }

    final rows = _groupRows(tokens);
    final prizes = List<String?>.filled(5, null);
    DateTime? date;
    OcrToken? complimentsHeader;
    OcrToken? fifthPrize;

    for (final row in rows) {
      final joined = row.map((item) => item.text).join(' ');
      final dateMatch = _dateLine.firstMatch(joined);
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = int.parse(dateMatch.group(3)!);
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          date = DateTime(year, month, day);
        }
      }

      if (joined.toUpperCase().contains('COMPLIMENT')) {
        complimentsHeader = row.first;
        continue;
      }

      if (complimentsHeader != null) continue;

      final prizeMatch = _prizeLine.firstMatch(joined);
      if (prizeMatch != null) {
        final index = int.parse(prizeMatch.group(1)!) - 1;
        final value = _asThreeDigits(prizeMatch.group(2)!);
        if (value != null) {
          prizes[index] ??= value;
          if (index == 4) fifthPrize = row.last;
        }
        continue;
      }

      final rank = row
          .map((item) => item.text.trim())
          .where(_rankToken.hasMatch)
          .toList();
      final values = row
          .map((item) => _asThreeDigits(item.text))
          .whereType<String>()
          .toList();
      if (rank.length == 1 && values.length == 1) {
        final index = int.parse(rank.first) - 1;
        prizes[index] ??= values.first;
        if (index == 4) fifthPrize = row.last;
      }
    }

    if (prizes.any((item) => item == null)) {
      throw Exception(
        'Could not read 1st to 5th prizes. Use a clear full screenshot.',
      );
    }

    final prizeSet = prizes.whereType<String>().toSet();
    final minY = complimentsHeader != null
        ? complimentsHeader.bottom.toDouble()
        : (fifthPrize?.bottom.toDouble() ?? 0) + 8;

    final complimentsTokens = tokens
        .where((token) {
          final value = _asThreeDigits(token.text);
          if (value == null) return false;
          if (token.cy <= minY) return false;
          if (complimentsHeader == null && prizeSet.contains(value)) {
            return false;
          }
          return true;
        })
        .toList();

    final compliments = _columnMajorGrid(complimentsTokens);
    if (compliments.length < 30) {
      throw Exception(
        'Read ${compliments.length}/30 compliments. Use a full result screenshot.',
      );
    }

    return ParsedResultSheet(
      prizes: prizes.whereType<String>().toList(),
      compliments: compliments.take(30).toList(),
      date: date,
    );
  }

  static List<List<OcrToken>> _groupRows(List<OcrToken> tokens) {
    final sorted = [...tokens]..sort((a, b) => a.cy.compareTo(b.cy));
    final rows = <List<OcrToken>>[];
    for (final token in sorted) {
      if (rows.isEmpty) {
        rows.add([token]);
        continue;
      }
      final row = rows.last;
      final avgY = row.fold<double>(0, (sum, item) => sum + item.cy) / row.length;
      final avgH =
          row.fold<double>(0, (sum, item) => sum + item.height) / row.length;
      final slop = (avgH * 0.7).clamp(14, 70);
      if ((token.cy - avgY).abs() <= slop) {
        row.add(token);
      } else {
        rows.add([token]);
      }
    }
    for (final row in rows) {
      row.sort((a, b) => a.cx.compareTo(b.cx));
    }
    return rows;
  }

  static List<String> _columnMajorGrid(List<OcrToken> tokens) {
    if (tokens.isEmpty) return const [];
    final cols = _splitColumns(tokens, 3);
    for (final col in cols) {
      col.sort((a, b) => a.cy.compareTo(b.cy));
    }
    final out = <String>[];
    for (final col in cols) {
      for (final token in col) {
        final value = _asThreeDigits(token.text);
        if (value != null) out.add(value);
      }
    }
    return out;
  }

  static List<List<OcrToken>> _splitColumns(List<OcrToken> tokens, int count) {
    final xs = tokens.map((item) => item.cx).toList()..sort();
    var centers = <double>[
      xs.first,
      xs[xs.length ~/ 2],
      xs.last,
    ];
    var labels = List<int>.filled(tokens.length, 0);
    for (var step = 0; step < 8; step++) {
      for (var i = 0; i < tokens.length; i++) {
        var best = 0;
        var bestDist = double.infinity;
        for (var c = 0; c < count; c++) {
          final dist = (tokens[i].cx - centers[c]).abs();
          if (dist < bestDist) {
            bestDist = dist;
            best = c;
          }
        }
        labels[i] = best;
      }
      for (var c = 0; c < count; c++) {
        final members = <double>[];
        for (var i = 0; i < tokens.length; i++) {
          if (labels[i] == c) members.add(tokens[i].cx);
        }
        if (members.isNotEmpty) {
          members.sort();
          centers[c] = members[members.length ~/ 2];
        }
      }
    }

    final indexed = [
      for (var c = 0; c < count; c++) (center: centers[c], index: c),
    ]..sort((a, b) => a.center.compareTo(b.center));
    final order = {
      for (var i = 0; i < indexed.length; i++) indexed[i].index: i,
    };

    final cols = List.generate(count, (_) => <OcrToken>[]);
    for (var i = 0; i < tokens.length; i++) {
      cols[order[labels[i]]!].add(tokens[i]);
    }
    return cols;
  }

  static String? _asThreeDigits(String raw) {
    final cleaned = raw
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 3) return null;
    return cleaned;
  }
}
