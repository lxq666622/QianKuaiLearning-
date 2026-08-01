import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/all_models.dart';
import '../services/database_service.dart';
import '../utils/sample_data.dart';

// ==========================================================================
// 游戏化状态（需求#8玩家数据模型 / 成就 / XP / 升级 / 连击）
// ==========================================================================
class GameState {
  final PlayerModel player;
  final List<AchievementModel> achievements;
  final List<AchievementModel> pendingUnlocks;
  final int? levelUpFrom; // 若有升级，显示弹窗
  const GameState({
    required this.player,
    required this.achievements,
    this.pendingUnlocks = const [],
    this.levelUpFrom,
  });
  GameState copyWith({
    PlayerModel? player,
    List<AchievementModel>? achievements,
    List<AchievementModel>? pendingUnlocks,
    int? levelUpFrom,
    bool clearLevelUp = false,
  }) => GameState(
    player: player ?? this.player,
    achievements: achievements ?? this.achievements,
    pendingUnlocks: pendingUnlocks ?? this.pendingUnlocks,
    levelUpFrom: clearLevelUp ? null : (levelUpFrom ?? this.levelUpFrom),
  );
}

class GameNotifier extends StateNotifier<GameState> {
  final DatabaseService _db = DatabaseService.instance;
  GameNotifier() : super(const GameState(
    player: PlayerModel(), achievements: [],
  )) { _load(); }

  Future<void> _load() async {
    final p = await _db.getPlayer();
    final a = await _db.getAllAchievements();
    state = GameState(player: p, achievements: a);
  }

  // ============ 核心：加XP → 升级检测 → 成就检测（需求#8.1 #8.2）============
  Future<void> addXP(int xp, {PowerAttribute? attribute, int attrValue=1}) async {
    if (xp <= 0) return;
    var p = state.player;
    int fromLv = p.level;
    int cur = p.currentXP + xp;
    int lv = p.level;
    int max = lv * 1000;
    while (cur >= max) {
      cur -= max;
      lv += 1;
      max = lv * 1000;
    }
    p = p.copyWith(level: lv, currentXP: cur, maxXP: max);
    // 四维属性
    if (attribute != null) {
      p = switch(attribute) {
        PowerAttribute.vocab => p.copyWith(powerVocab: p.powerVocab + attrValue),
        PowerAttribute.listening => p.copyWith(powerListening: p.powerListening + attrValue),
        PowerAttribute.speaking => p.copyWith(powerSpeaking: p.powerSpeaking + attrValue),
        PowerAttribute.reading => p.copyWith(powerReading: p.powerReading + attrValue),
      };
    }
    await _db.savePlayer(p);
    final unlockedFromLevel = lv > fromLv ? fromLv : null;
    final ach = await _checkAchievements(newPlayer: p, attribute: attribute);
    state = state.copyWith(
      player: p,
      levelUpFrom: unlockedFromLevel,
      pendingUnlocks: ach,
      clearLevelUp: unlockedFromLevel == null,
    );
  }

  // ========== 学习完成后：连击天数+1 ==========
  Future<void> markStudyDone(bool perfectDungeon) async {
    var p = state.player;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? last = p.lastStudyDate;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      if (lastDay == today.subtract(const Duration(days: 1))) {
        p = p.copyWith(streakDays: p.streakDays + 1);
      } else if (lastDay != today) {
        p = p.copyWith(streakDays: 1);
      }
    } else {
      p = p.copyWith(streakDays: 1);
    }
    p = p.copyWith(lastStudyDate: now);
    await _db.savePlayer(p);
    // 连击7天成就判定
    final a = await _checkAchievements(newPlayer: p, isPerfectDungeon: perfectDungeon);
    state = state.copyWith(player: p, pendingUnlocks: a);
  }

  // ========== 成就检测（12个，需求#8.2） ==========
  Future<List<AchievementModel>> _checkAchievements({
    required PlayerModel newPlayer,
    PowerAttribute? attribute,
    bool isPerfectDungeon = false,
    int? newWordsLearned,
    bool? xhApproved,
    bool? unlockedIntimacy,
    int? chatRounds,
  }) async {
    final pending = <AchievementModel>[];
    final cur = state.achievements;
    Future<void> chk(String id, bool ok) async {
      if (!ok) return;
      final idx = cur.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      final a = cur[idx];
      if (a.isUnlocked) return;
      await _db.markAchievementUnlocked(id);
      final unlocked = a.copyWith(isUnlocked: true, unlockDate: DateTime.now());
      pending.add(unlocked);
      // 成就解锁同时加XP
      await addXP(a.xpReward);
    }
    // 初出茅庐
    await chk(SampleData.kAchievements12.first.$1, newPlayer.lastStudyDate != null);
    // 首杀百词
    final wc = await _db.countWords(masteredOnly: true);
    await chk('word_100', wc >= 100);
    // 七日连击
    await chk('streak_7', newPlayer.streakDays >= 7);
    // 完美副本
    await chk('perfect_dungeon', isPerfectDungeon);
    // 无尽对话
    await chk('endless_chat', (chatRounds ?? 0) >= 500);
    // 羁绊初生
    await chk('bond_start', newPlayer.level >= 2 || (unlockedIntimacy ?? false));
    // 词汇王者
    await chk('vocab_king', wc >= 500);
    return pending;
  }

  // 清除弹窗
  void clearUnlocks() => state = state.copyWith(pendingUnlocks: [], clearLevelUp: true);
}

enum PowerAttribute { vocab, listening, speaking, reading }

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
