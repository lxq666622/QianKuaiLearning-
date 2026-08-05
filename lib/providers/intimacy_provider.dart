import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_models.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class IntimacyState {
  final int value;
  final int level;
  final int totalChatRounds;
  final int daysKnown;
  final int? levelUpFrom;
  final List<IntimacyUnlockModel> unlocks;
  final List<String> recentlyAdded;
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
  bool _alive = true;
  IntimacyNotifier() : super(const IntimacyState(value: 0)) { _load(); }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  bool _dailyFirstMet = false;
  Future<void> _load() async {
    final s = await _db.getXHSettings();
    final u = await _db.getIntimacyUnlocks();
    super.state = IntimacyState(
      value: s.intimacyValue, level: s.intimacyLevel,
      totalChatRounds: s.totalChatRounds, daysKnown: s.daysKnown,
      unlocks: u,
    );
  }

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
    if (lv > from) {
      for (int i = from + 1; i <= lv; i++) {
        await _db.setIntimacyUnlocked(i);
      }
    }
    final unlocks = await _db.getIntimacyUnlocks();
    super.state = super.state.copyWith(
      value: v, level: lv,
      totalChatRounds: updated.totalChatRounds,
      levelUpFrom: lv > from ? from : null,
      unlocks: unlocks,
      recentlyAdded: [...super.state.recentlyAdded, reason == 'chat_round'
          ? '+2' : reason.isEmpty ? '+$delta' : '+$delta $reason'].cast<String>(),
      clearLevelUp: lv <= from,
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_alive) {
        super.state = super.state.copyWith(recentlyAdded: []);
      }
    });
  }
  static int _needFor(int level) {
    return level * 100;
  }
  int needForNext() => _needFor(super.state.level + 1);
  int needAtLevel(int level) => _needFor(level);

  Future<void> onChatRoundEnd() async {
    int extra = 0;
    if (!_dailyFirstMet) { _dailyFirstMet = true; extra = 10; }
    await add(2 + extra, reason: 'chat_round');
  }
  Future<void> onDungeonShared() async => add(15, reason: '副本完成');
  Future<void> onSongShared() async => add(10, reason: '练唱分享');
  Future<void> onWeekStreak() async => add(50, reason: '七日连击');
  Future<void> onAchievementUnlocked() async => add(10, reason: '解锁成就');
  Future<void> onCareAsked() async => add(15, reason: '关心');
  Future<void> onReplyWithin5Min(int delta) async {
    if (delta > 0) add(delta, reason: '秒回推送');
  }
  void clearLevelUp() => super.state = super.state.copyWith(clearLevelUp: true);
}

final intimacyProvider = StateNotifierProvider<IntimacyNotifier, IntimacyState>(
  (ref) => IntimacyNotifier(),
);
