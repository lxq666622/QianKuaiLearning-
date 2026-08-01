import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_models.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

// ==========================================================================
// 亲密度 / 羁绊状态（需求#9.3）
// - 羁绊等级：1-20，每升一级 = level*100 羁绊值
// - 触发累积：对话+2 / 每日首找+10 / 副本完成分享+15 / 5分钟内回复推送+20 /
//             连击7天+50 / 新成就告知+10 / 歌房分享+10 / 关心生病+15
// ==========================================================================
class IntimacyState {
  final int value;
  final int level;
  final int totalChatRounds;
  final int daysKnown;
  final int? levelUpFrom; // 升级弹窗
  final List<IntimacyUnlockModel> unlocks;
  final List<String> recentlyAdded; // +2 +10 ...飘字
  const IntimacyState({
    required this.value, this.level=1,
    this.totalChatRounds=0, this.daysKnown=1,
    this.levelUpFrom, this.unlocks = const [],
    this.recentlyAdded = const [],
  });
  IntimacyState copyWith({
    int? value, int? level, int? totalChatRounds, int? daysKnown,
    int? levelUpFrom, List<IntimacyUnlockModel>? unlocks,
    List<String>? recentlyAdded, bool clearLevelUp=false,
  }) => IntimacyState(
    value: value ?? this.value,
    level: level ?? this.level,
    totalChatRounds: totalChatRounds ?? this.totalChatRounds,
    daysKnown: daysKnown ?? this.daysKnown,
    levelUpFrom: clearLevelUp ? null : (levelUpFrom ?? this.levelUpFrom),
    unlocks: unlocks ?? this.unlocks,
    recentlyAdded: recentlyAdded ?? this.recentlyAdded,
  );
}

class IntimacyNotifier extends StateNotifier<IntimacyState> {
  final DatabaseService _db = DatabaseService.instance;
  IntimacyNotifier() : super(const IntimacyState()) { _load(); }
  bool _dailyFirstMet = false; // 每日首次找他（内存，重启清）

  Future<void> _load() async {
    final s = await _db.getXHSettings();
    final u = await _db.getIntimacyUnlocks();
    state = IntimacyState(
      value: s.intimacyValue, level: s.intimacyLevel,
      totalChatRounds: s.totalChatRounds, daysKnown: s.daysKnown,
      unlocks: u,
    );
  }

  // ========== 加羁绊值（核心入口） ==========
  Future<void> add(int delta, {String reason=''}) async {
    if (delta <= 0) return;
    final settings = await _db.getXHSettings();
    var v = settings.intimacyValue + delta;
    var lv = settings.intimacyLevel;
    final from = lv;
    while (v >= _needFor(lv + 1)) { lv++; }
    while (v < _needFor(lv)) { lv--; if (lv < 1) { lv = 1; break; } }
    final updated = settings.copyWith(
      intimacyValue: v, intimacyLevel: lv,
      totalChatRounds: settings.totalChatRounds +
          (reason == 'chat_round' ? 1 : 0),
    );
    await _db.saveXHSettings(updated);
    // 解锁
    if (lv > from) {
      for (int i = from + 1; i <= lv; i++) {
        await _db.setIntimacyUnlocked(i);
      }
    }
    final unlocks = await _db.getIntimacyUnlocks();
    state = state.copyWith(
      value: v, level: lv,
      totalChatRounds: updated.totalChatRounds,
      levelUpFrom: lv > from ? from : null,
      unlocks: unlocks,
      recentlyAdded: [...state.recentlyAdded, reason == 'chat_round'
          ? '+2' : reason.isEmpty ? '+$delta' : '+$delta $reason'].cast<String>(),
      clearLevelUp: lv <= from,
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        state = state.copyWith(recentlyAdded: []);
      }
    });
  }

  static int _needFor(int level) {
    // Lv.2 需要 200，Lv.3 300，… Lv.N = N*100
    return level * 100;
  }
  int needForNext() => _needFor(state.level + 1);
  int needAtLevel(int level) => _needFor(level);

  // 1轮对话结束（双方各1句）
  Future<void> onChatRoundEnd() async {
    int extra = 0;
    if (!_dailyFirstMet) { _dailyFirstMet = true; extra = 10; }
    await add(2 + extra, reason: 'chat_round');
  }
  // 分享副本完成
  Future<void> onDungeonShared() async => add(15, reason: '副本完成');
  // 歌房分享
  Future<void> onSongShared() async => add(10, reason: '练唱分享');
  // 连续打卡7天加成
  Future<void> onWeekStreak() async => add(50, reason: '七日连击');
  // 新成就
  Future<void> onAchievementUnlocked() async => add(10, reason: '解锁成就');
  // 关心他
  Future<void> onCareAsked() async => add(15, reason: '关心');
  // 5分钟内回复推送
  Future<void> onReplyWithin5Min(int delta) async {
    if (delta > 0) add(delta, reason: '秒回推送');
  }
  void clearLevelUp() => state = state.copyWith(clearLevelUp: true);
}

final intimacyProvider = StateNotifierProvider<IntimacyNotifier, IntimacyState>(
  (ref) => IntimacyNotifier(),
);
