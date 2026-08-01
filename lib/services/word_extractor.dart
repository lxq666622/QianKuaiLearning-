import '../models/all_models.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

// ==========================================================================
// 智能单词提取（对应原 WordExtractor.swift，需求#3.3）
// 流程：正则[a-zA-Z]+ → 小写 → 停用词过滤 → 长度>2 → 统计词频 → 返回带例句
// ==========================================================================
class WordExtractor {
  static List<ExtractedWordModel> extract(String fullText) {
    final freq = <String, int>{};
    final example = <String, String>{};
    final lines = fullText.split(RegExp(r'[\n.!?。？！]'));
    for (final line in lines) {
      final matches = RegExp(r'[a-zA-Z]+').allMatches(line);
      final wordsInLine = <String>{};
      for (final m in matches) {
        var w = m.group(0)!.toLowerCase();
        if (w.length <= 2) continue;
        if (kStopWords.contains(w)) continue;
        freq[w] = (freq[w] ?? 0) + 1;
        wordsInLine.add(w);
      }
      for (final w in wordsInLine) {
        example.putIfAbsent(w, () => line.trim());
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    return sorted.map((e) => ExtractedWordModel(
      word: e.key, frequency: e.value, exampleSentence: example[e.key] ?? '',
    )).toList();
  }

  // Levenshtein 相似度（0~1）
  static double similarity(String a, String b) => a.similarityTo(b);
  // 分数评级 S/A/B/C/D
  static String grade(int percent) => '$percent'.gradeFromPercent();
}
