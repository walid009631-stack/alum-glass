import 'dart:math';

class Bar {
  final List<double> pieces = [];
  double used = 0; // يشمل سماكة المنشار
  double waste(double barLen) => barLen - used;
}

class CutResult {
  final List<Bar> bars;
  final List<double> tooLong;
  CutResult(this.bars, this.tooLong);
}

List<Bar> _pack(List<double> order, double barLen, double kerf) {
  final bars = <Bar>[];
  for (final len in order) {
    int best = -1;
    double bestRem = double.infinity;
    for (var i = 0; i < bars.length; i++) {
      final need = len + (bars[i].pieces.isEmpty ? 0 : kerf);
      final rem = barLen - bars[i].used - need;
      if (rem >= -1e-9 && rem < bestRem) {
        bestRem = rem;
        best = i;
      }
    }
    if (best == -1) {
      final b = Bar()
        ..pieces.add(len)
        ..used = len;
      bars.add(b);
    } else {
      final b = bars[best];
      b.used += len + (b.pieces.isEmpty ? 0 : kerf);
      b.pieces.add(len);
    }
  }
  return bars;
}

double _score(List<Bar> bars, double barLen) {
  // أقل عدد أعواد أولاً، ثم تجميع الهدر في قطعة واحدة كبيرة
  var sq = 0.0;
  for (final b in bars) {
    final w = b.waste(barLen);
    sq += w * w;
  }
  return bars.length * 1e12 - sq;
}

CutResult optimize(List<double> lengths, double barLen, double kerf) {
  final tooLong = lengths.where((l) => l > barLen + 1e-9).toList();
  final ok = lengths.where((l) => l <= barLen + 1e-9 && l > 0).toList()
    ..sort((a, b) => b.compareTo(a));
  if (ok.isEmpty) return CutResult([], tooLong);

  var best = _pack(ok, barLen, kerf);
  var bestScore = _score(best, barLen);
  final rnd = Random(7);
  final iters = ok.length > 300 ? 40 : 400;
  for (var i = 0; i < iters; i++) {
    final keyed = ok.map((l) => MapEntry(l * (1 + (rnd.nextDouble() - 0.5) * 0.4), l)).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final cand = _pack(keyed.map((e) => e.value).toList(), barLen, kerf);
    final s = _score(cand, barLen);
    if (s < bestScore) {
      best = cand;
      bestScore = s;
    }
  }
  for (final b in best) {
    b.pieces.sort((a, c) => c.compareTo(a));
  }
  return CutResult(best, tooLong);
}
