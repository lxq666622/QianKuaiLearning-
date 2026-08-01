import 'package:flutter/material.dart';

extension DateTimeX on DateTime {
  /// Unix 时间戳（毫秒）
  int get unixMillis => millisecondsSinceEpoch;
  /// 当天0点时间戳
  int get dayStart {
    final d = DateTime(year, month, day);
    return d.millisecondsSinceEpoch;
  }
  static DateTime fromUnix(int? millis) {
    if (millis == null) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}

extension IntX on int {
  /// 秒数 → 08:05 显示
  String get mmss {
    final m = (this ~/ 60).toString().padLeft(2,'0');
    final s = (this % 60).toString().padLeft(2,'0');
    return '$m:$s';
  }
}

extension DurationX on Duration {
  /// 03:14 显示
  String ms() {
    final m = (inMinutes).toString().padLeft(2,'0');
    final s = (inSeconds.remainder(60)).toString().padLeft(2,'0');
    return '$m:$s';
  }
}

extension StringX on String {
  /// Levenshtein 相似度
  double similarityTo(String other) {
    if (this == other) return 1.0;
    if (isEmpty || other.isEmpty) return 0.0;
    final a = toLowerCase(), b = other.toLowerCase();
    final m = a.length, n = b.length;
    final dp = List.generate(m+1, (_) => List.filled(n+1, 0));
    for (int i=0;i<=m;i++) dp[i][0] = i;
    for (int j=0;j<=n;j++) dp[0][j] = j;
    for (int i=1;i<=m;i++) {
      for (int j=1;j<=n;j++) {
        if (a.codeUnitAt(i-1) == b.codeUnitAt(j-1)) {
          dp[i][j] = dp[i-1][j-1];
        } else {
          dp[i][j] = 1 + [dp[i-1][j],dp[i][j-1],dp[i-1][j-1]].reduce((x,y)=>x<y?x:y);
        }
      }
    }
    final max = m > n ? m : n;
    return (1.0 - dp[m][n] / max).clamp(0.0, 1.0);
  }
  /// 评分：S/A/B/C/D
  String gradeFromPercent() {
    final p = int.tryParse(this) ?? 0;
    return switch(p){
      >= 95 => 'S',
      >= 85 => 'A',
      >= 70 => 'B',
      >= 60 => 'C',
      _ => 'D'
    };
  }
}
