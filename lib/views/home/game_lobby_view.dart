import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/animated_gradient_background.dart';
import '../../widgets/player_card.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../providers/game_provider.dart';
import '../../providers/dungeon_provider.dart';
import '../../utils/constants.dart';

// ==========================================================================
// 首页 / 游戏大厅（需求#1）
// 顶部动态渐变背景 / 玩家信息卡 / 今日副本入口（脉冲） / 底部快捷入口
// ==========================================================================
class GameLobbyView extends ConsumerStatefulWidget {
  const GameLobbyView({super.key});
  @override ConsumerState<GameLobbyView> createState() => _GameLobbyViewState();
}
class _GameLobbyViewState extends State<GameLobbyView>
    with ConsumerStateMixin<GameLobbyView>, SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final today = ref.watch(dungeonProvider);
    return AnimatedGradientBackground(child: SafeArea(
      child: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          const PlayerCard(),
          const SizedBox(height: 18),
          // 今日副本入口（脉冲动画）
          GestureDetector(
            onTap: () => context.push('/dungeon'),
            child: AnimatedBuilder(animation: _pulse, builder: (ctx, c){
              final s = 1.0 + _pulse.value * 0.05;
              return Transform.scale(scale: s,
                child: GlassmorphismCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.sports_esports, color: AppColors.emeraldGreen, size: 26),
                    SizedBox(width: 8),
                    Text('今日副本', style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800, color: Color(0xFF0A3D3F))),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('词汇关', today.today.vocabMinutes, 20,
                      AppColors.vocabGreen, today.today.vocabCompleted==1),
                    _chip('听力关', today.today.listeningMinutes, 10,
                      AppColors.listeningBlue, today.today.listeningCompleted==1),
                    _chip('口语关', today.today.speakingMinutes, 10,
                      AppColors.speakingOrange, today.today.speakingCompleted==1),
                  ]),
                  const SizedBox(height: 14),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.emeraldGreen,
                          foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
                      onPressed: () => context.push('/dungeon'),
                      child: Text(today.dungeonCleared ? '查看通关奖励' : '开始闯关 →')),
                ])));
            }),
          ),
          const SizedBox(height: 18),
          // 快捷入口
          GridView.count(crossAxisCount: 4, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, children: [
            _shortcut('🎵','歌房', () => context.push('/karaoke')),
            _shortcut('📁','导入', () => context.push('/import')),
            _shortcut('🏅','成就', () => context.push('/achievements')),
            _shortcut('⭐','星回', () => context.push('/xinghui')),
          ]),
          const SizedBox(height: 18),
        ]),
      ),
    ));
  }

  Widget _chip(String name, int cur, int max, Color color, bool done) {
    final ratio = (cur/max).clamp(0.0, 1.0);
    return Container(padding: const EdgeInsets.symmetric(
      horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.14),
        border: Border.all(color: done ? color : Colors.transparent, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check_circle : Icons.access_time_filled,
          color: color, size: 16),
        const SizedBox(width: 6),
        Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 6),
        Text('${cur}${done ? '' : '/$max'}min',
            style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 11)),
        const SizedBox(width: 8),
        SizedBox(width: 42, height: 6, child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: ratio, backgroundColor: Colors.white54,
            valueColor: AlwaysStoppedAnimation(color)),
        )),
      ]),
    );
  }

  Widget _shortcut(String icon, String name, VoidCallback onTap) {
    return GestureDetector(onTap: onTap,
      child: GlassmorphismCard(opacity: 0.8, padding: const EdgeInsets.all(6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ])),
    );
  }
}
