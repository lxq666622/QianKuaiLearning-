import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dungeon_provider.dart';
import '../../widgets/circular_progress_painter.dart';
import '../../widgets/confetti_painter.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../utils/constants.dart';

// ==========================================================================
// 副本入口 + 计时器 + 通关结算（需求#7）
// 为了简化，把入口、计时器、通关3个视图合并在同一页面（可通过Tab切换）
// ==========================================================================
class DailyDungeonView extends ConsumerStatefulWidget {
  const DailyDungeonView({super.key});
  @override ConsumerState<DailyDungeonView> createState() => _DDVState();
}
class _DDVState extends ConsumerState<DailyDungeonView> {
  Timer? _tick;
  @override void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_){
      ref.read(dungeonProvider.notifier).tick();
    });
  }
  @override void dispose() { _tick?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final d = ref.watch(dungeonProvider);
    if (d.timerSecondsLeft > 0 || d.timerRunning) {
      return _timerView(d);
    }
    if (d.dungeonCleared) return _completeView(d);
    return _entryView(d);
  }

  Widget _entryView(DungeonState d) {
    final s1 = d.today.vocabCompleted == 1;
    final s2 = d.today.listeningCompleted == 1;
    final s3 = d.today.speakingCompleted == 1;
    return Scaffold(appBar: AppBar(title: const Text('每日副本')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _stageCard(DungeonStage.vocab, s1, d.currentStage == DungeonStage.vocab),
          _stageCard(DungeonStage.listening, s2, d.currentStage == DungeonStage.listening, locked: !s1),
          _stageCard(DungeonStage.speaking, s3, d.currentStage == DungeonStage.speaking, locked: !s1 || !s2),
          _stageCard(DungeonStage.bonus, false, false, locked: false, bonus: true),
        ])));
  }
  Widget _stageCard(DungeonStage s, bool done, bool active, {bool locked = false, bool bonus=false}) {
    final icon = bonus ? Icons.music_note : switch(s) {
      DungeonStage.vocab => Icons.menu_book,
      DungeonStage.listening => Icons.headphones,
      DungeonStage.speaking => Icons.mic,
      _ => Icons.star,
    };
    final name = bonus ? 'Bonus·歌房练唱（可选）' : switch(s) {
      DungeonStage.vocab => '第一关 · 词汇关 20min',
      DungeonStage.listening => '第二关 · 听力关 10min',
      DungeonStage.speaking => '第三关 · 口语关 10min',
      _ => '',
    };
    final xp = bonus ? 200 : switch(s) {
      DungeonStage.vocab => 200, DungeonStage.listening => 150,
      DungeonStage.speaking => 150, _ => 0,
    };
    final c = bonus ? const Color(0xFFFF9800) : switch(s) {
      DungeonStage.vocab => AppColors.vocabGreen,
      DungeonStage.listening => AppColors.listeningBlue,
      DungeonStage.speaking => AppColors.speakingOrange,
      _ => Colors.grey,
    };
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c.withOpacity(0.15),),
          child: Icon(icon, color: c, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: locked ? Colors.grey : Colors.black87)),
          const SizedBox(height: 4),
          Row(children: [
            if (locked) const Icon(Icons.lock, color: Colors.grey, size: 14)
            else if (done) const Icon(Icons.check_circle, color: Colors.green, size: 14)
            else Icon(active ? Icons.play_circle : Icons.radio_button_unchecked,
              color: active ? c : Colors.grey, size: 14),
            const SizedBox(width: 4),
            Text(locked ? '请先完成上一关' : (done ? '已完成' : (active ? '进行中' : '待开始')),
              style: TextStyle(color: locked ? Colors.grey : Colors.grey.shade600, fontSize: 12)),
            const SizedBox(width: 14),
            Text('+$xp XP', style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ])),
        if (bonus) IconButton(onPressed: () => context.push('/karaoke'),
          icon: const Icon(Icons.chevron_right, color: Colors.grey))
        else if (!locked && !done) FilledButton(style: FilledButton.styleFrom(
          backgroundColor: c, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
          onPressed: () => ref.read(dungeonProvider.notifier).startStage(s),
          child: const Text('进入'))
        else const SizedBox(width: 16),
      ])));
  }

  Widget _timerView(DungeonState d) {
    final totalSec = d.stageTargetMinutes * 60;
    final p = totalSec == 0 ? 0.0 : 1 - d.timerSecondsLeft / totalSec;
    final mm = (d.timerSecondsLeft ~/ 60).toString().padLeft(2,'0');
    final ss = (d.timerSecondsLeft % 60).toString().padLeft(2,'0');
    final label = switch(d.currentStage) {
      DungeonStage.vocab => '词汇关：专注背单词',
      DungeonStage.listening => '听力关：影子跟读训练',
      DungeonStage.speaking => '口语关：微输出造句',
      _ => '',
    };
    return Scaffold(appBar: AppBar(title: Text(label),
        actions: [
          TextButton(onPressed: () async {
            bool ok = await showDialog(context: context, builder: (ctx)=>AlertDialog(
              title: const Text('放弃副本？'), content: const Text('今日需重新开始本关。'),
              actions: [
                TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('继续')),
                TextButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('放弃', style: TextStyle(color: Colors.red))),
              ],
            )) ?? false;
            if (ok) ref.read(dungeonProvider.notifier).giveUp();
          }, child: const Text('放弃')),
        ]),
      body: SafeArea(child: Column(children: [
        const Spacer(),
        Center(child: SizedBox(width: 280, height: 280,
          child: CustomPaint(painter: CircularProgressPainter(progress: p,
            strokeWidth: 22,
            centerLabel: '$mm:$ss',
            labelStyle: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800,
              color: AppColors.emeraldGreen, letterSpacing: 2),
          )))),
        const SizedBox(height: 28),
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.grey)),
        const SizedBox(height: 18),
        Text('保持专注，完成后立刻获得 XP 奖励',
          style: TextStyle(color: Colors.grey.shade500)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Expanded(child: SizedBox(height: 56,
              child: OutlinedButton.icon(onPressed: (){
                if (d.timerRunning) {
                  ref.read(dungeonProvider.notifier).pause();
                } else { ref.read(dungeonProvider.notifier).resume(); }
              }, icon: Icon(d.timerRunning ? Icons.pause : Icons.play_arrow,
                color: AppColors.emeraldGreen),
                label: Text(d.timerRunning ? '暂停' : '继续',
                  style: const TextStyle(color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.w700)))),
            ),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(height: 56,
              child: FilledButton.icon(style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => ref.read(dungeonProvider.notifier).completeStage(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('提前完成')))),
          ]),
        ),
        const SizedBox(height: 8),
      ])));
  }

  Widget _completeView(DungeonState d) {
    return Scaffold(body: Stack(children: [
      const ConfettiOverlay(active: true, particleCount: 160,
        duration: Duration(seconds: 8)),
      SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 4),
          const Text('今日副本通关！', style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w900, color: AppColors.emeraldGreen)),
          const SizedBox(height: 30),
          GlassmorphismCard(child: Column(children: [
            Row(children: [
              const Text('获得总XP', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text('+${d.today.totalXP}', style: const TextStyle(fontSize: 24,
                  fontWeight: FontWeight.w900, color: AppColors.emeraldGreen)),
            ]),
            const SizedBox(height: 14),
            _row('词汇力💪', '+${200~/20}', AppColors.vocabGreen),
            const SizedBox(height: 8),
            _row('听力👂', '+${150~/20}', AppColors.listeningBlue),
            const SizedBox(height: 8),
            _row('口语🗣️', '+${150~/20}', AppColors.speakingOrange),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 6),
            Row(children: const [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
              SizedBox(width: 6),
              Text('连击天数 +1', style: TextStyle(fontWeight: FontWeight.w700)),
              Spacer(),
              Text('完美副本成就已纳入检测',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ])),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 52,
            child: FilledButton(style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => context.pop(), child: const Text('返回大厅'))),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.badgeRoseGold)),
              onPressed: () => context.push('/xinghui'),
              icon: const Icon(Icons.favorite, color: AppColors.badgeRoseGold),
              label: const Text('告诉星回我完成了副本',
                  style: TextStyle(color: AppColors.badgeRoseGold,
                      fontWeight: FontWeight.w700),))),
        ]),
      ))),
    ]));
  }
  Widget _row(String n, String delta, Color c) => Row(children: [
        Text(n, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(delta, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 14)),
      ]);
}
