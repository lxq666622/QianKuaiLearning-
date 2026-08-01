import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_models.dart';
import '../services/database_service.dart';
import 'game_provider.dart';
import 'intimacy_provider.dart';

// ==========================================================================
// 每日副本系统（需求#7）
// 3关：词汇(20min) → 听力(10min) → 口语(10min)；Bonus 歌房
// 计时器：暂停/放弃/完成；Confetti庆祝；连击天数+1
// ==========================================================================
class DungeonState {
  final DailyTaskModel today;
  final DungeonStage currentStage;
  final bool dungeonCleared;
  final int timerSecondsLeft;
  final bool timerRunning;
  final int? sessionStartXP; // 用于结算XP增量
  const DungeonState({
    required this.today, this.currentStage = DungeonStage.vocab,
    this.dungeonCleared = false,
    this.timerSecondsLeft = 0, this.timerRunning = false,
    this.sessionStartXP,
  });
  DungeonState copyWith({
    DailyTaskModel? today, DungeonStage? currentStage, bool? dungeonCleared,
    int? timerSecondsLeft, bool? timerRunning, int? sessionStartXP,
  }) => DungeonState(
    today: today ?? this.today,
    currentStage: currentStage ?? this.currentStage,
    dungeonCleared: dungeonCleared ?? this.dungeonCleared,
    timerSecondsLeft: timerSecondsLeft ?? this.timerSecondsLeft,
    timerRunning: timerRunning ?? this.timerRunning,
    sessionStartXP: sessionStartXP ?? this.sessionStartXP,
  );
  int get stageTargetMinutes => switch(currentStage) {
    DungeonStage.vocab => 20, DungeonStage.listening => 10,
    DungeonStage.speaking => 10, DungeonStage.bonus => 0,
  };
  bool get stageCompleted => switch(currentStage) {
    DungeonStage.vocab => today.vocabCompleted == 1,
    DungeonStage.listening => today.listeningCompleted == 1,
    DungeonStage.speaking => today.speakingCompleted == 1,
    DungeonStage.bonus => false,
  };
}

enum DungeonStage { vocab, listening, speaking, bonus }

class DungeonNotifier extends StateNotifier<DungeonState> {
  final DatabaseService _db = DatabaseService.instance;
  final Ref _ref;
  DungeonNotifier(this._ref) : super(DungeonState(
      today: DailyTaskModel(date: DateTime.now())
  )) { _load(); }

  Future<void> _load() async {
    final t = await _db.getTodayTask();
    final cleared = t.vocabCompleted == 1 &&
                    t.listeningCompleted == 1 &&
                    t.speakingCompleted == 1;
    final stage = t.vocabCompleted != 1
        ? DungeonStage.vocab
        : t.listeningCompleted != 1
            ? DungeonStage.listening
            : t.speakingCompleted != 1
                ? DungeonStage.speaking
                : DungeonStage.bonus;
    state = state.copyWith(today: t, dungeonCleared: cleared, currentStage: stage);
  }

  void tick() {
    if (!state.timerRunning) return;
    if (state.timerSecondsLeft <= 0) return;
    state = state.copyWith(timerSecondsLeft: state.timerSecondsLeft - 1);
    if (state.timerSecondsLeft <= 0) {
      completeStage(); // 倒计时0 → 自动完成
    }
  }

  // ========= 开始闯关 =========
  Future<void> startStage(DungeonStage s) async {
    final mins = switch(s){
      DungeonStage.vocab => 20, DungeonStage.listening => 10,
      DungeonStage.speaking => 10, _ => 0,
    };
    state = state.copyWith(
      currentStage: s,
      timerSecondsLeft: mins * 60,
      timerRunning: true,
      sessionStartXP: _ref.read(gameProvider).player.currentXP,
    );
  }
  void pause() => state = state.copyWith(timerRunning: false);
  void resume() => state = state.copyWith(timerRunning: true);
  Future<void> giveUp() async {
    state = state.copyWith(timerRunning: false, timerSecondsLeft: 0);
  }

  // ========= 完成一关 → 累计XP → 属性 → 进入下一关 =========
  Future<void> completeStage() async {
    final stage = state.currentStage;
    final mins = state.stageTargetMinutes;
    int xp = 0;
    PowerAttribute? attr;
    final t = state.today;
    DailyTaskModel updated = t;
    switch(stage) {
      case DungeonStage.vocab:
        updated = t.copyWith(vocabCompleted: 1, vocabMinutes: mins);
        xp = 200; attr = PowerAttribute.vocab;
        break;
      case DungeonStage.listening:
        updated = t.copyWith(listeningCompleted: 1, listeningMinutes: mins);
        xp = 150; attr = PowerAttribute.listening;
        break;
      case DungeonStage.speaking:
        updated = t.copyWith(speakingCompleted: 1, speakingMinutes: mins);
        xp = 150; attr = PowerAttribute.speaking;
        break;
      case DungeonStage.bonus: break;
    }
    updated = updated.copyWith(totalXP: updated.totalXP + xp);
    await _db.updateTodayTask(updated);
    if (xp > 0) {
      await _ref.read(gameProvider.notifier).addXP(xp, attribute: attr, attrValue: xp ~/ 20);
    }
    final perfect = updated.vocabCompleted == 1 && updated.listeningCompleted == 1 && updated.speakingCompleted == 1;
    final next = perfect ? DungeonStage.bonus : (stage == DungeonStage.vocab
        ? DungeonStage.listening
        : stage == DungeonStage.listening
            ? DungeonStage.speaking
            : DungeonStage.bonus);
    state = state.copyWith(
      today: updated, currentStage: next,
      timerRunning: false, timerSecondsLeft: 0,
      dungeonCleared: perfect,
    );
    if (perfect) {
      // 连击 +1
      await _ref.read(gameProvider.notifier).markStudyDone(true);
      await _ref.read(intimacyProvider.notifier).add(15, reason: '通关副本');
    }
  }
}

final dungeonProvider = StateNotifierProvider<DungeonNotifier, DungeonState>(
  (ref) => DungeonNotifier(ref),
);
