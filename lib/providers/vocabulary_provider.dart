import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_models.dart';
import '../services/database_service.dart';
import '../services/word_extractor.dart';
import 'game_provider.dart';

// ==========================================================================
// 词海模块（需求#2）
// - 单词卡片翻转 / SM-2简化间隔重复 / 三按钮(认识/模糊/忘记)
// ==========================================================================
class VocabularyState {
  final List<WordModel> queue;
  final int currentIndex;
  final bool isFront;
  final String sourceFilter;
  const VocabularyState({
    this.queue = const [], this.currentIndex = 0,
    this.isFront = true, this.sourceFilter = '全部',
  });
  VocabularyState copyWith({
    List<WordModel>? queue, int? currentIndex, bool? isFront, String? sourceFilter,
  }) => VocabularyState(
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    isFront: isFront ?? this.isFront,
    sourceFilter: sourceFilter ?? this.sourceFilter,
  );
}

class VocabularyNotifier extends StateNotifier<VocabularyState> {
  final DatabaseService _db = DatabaseService.instance;
  final Ref _ref;
  VocabularyNotifier(this._ref) : super(const VocabularyState()) { load(); }

  Future<void> load() async {
    final q = await _db.getWordsToReviewToday();
    state = state.copyWith(queue: q, currentIndex: 0, isFront: true);
  }

  WordModel? get current {
    if (state.queue.isEmpty || state.currentIndex >= state.queue.length) return null;
    return state.queue[state.currentIndex];
  }

  void flip() => state = state.copyWith(isFront: !state.isFront);

  // ====== SM-2 简化 ======
  Future<void> answer(int quality) async {
    // quality: 2=忘记，3=模糊，5=认识
    final w = current;
    if (w == null) return;
    int p = w.proficiency + (quality >= 4 ? 1 : quality <= 2 ? -1 : 0);
    p = p.clamp(0, 5);
    final now = DateTime.now();
    int days;
    if (quality >= 5) days = 1 << p; // 1,2,4,8,16,32
    else if (quality >= 3) days = 1;
    else days = 0;
    final next = now.add(Duration(days: days));
    final updated = w.copyWith(
      proficiency: p, nextReviewDate: next,
      reviewCount: w.reviewCount + 1,
    );
    await _db.upsertWord(updated);
    // XP：认识+10 / 模糊+5 / 忘记+2
    final xp = quality >= 5 ? 10 : quality >= 3 ? 5 : 2;
    await _ref.read(gameProvider.notifier).addXP(xp,
        attribute: PowerAttribute.vocab, attrValue: xp ~/ 5);
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      // 刷新队列（取下一批）
      await load();
    } else {
      state = state.copyWith(currentIndex: nextIndex, isFront: true);
    }
  }

  // ====== 从导入结果 / 歌词生词加入词库 ======
  Future<void> addImported(
    List<ExtractedWordModel> list, { String source = '文件导入', int topN = 0,
  }) async {
    final data = (topN > 0 && topN < list.length ? list.take(topN) : list).map((e){
      return WordModel(
        word: e.word, meaning: '',
        exampleSentence: e.exampleSentence,
        source: source, frequency: e.frequency,
        nextReviewDate: DateTime.now(), isUserAdded: 1,
      );
    }).toList();
    await _db.batchInsertWords(data);
    await load();
  }
}

final vocabularyProvider = StateNotifierProvider<VocabularyNotifier, VocabularyState>(
  (ref) => VocabularyNotifier(ref),
);
