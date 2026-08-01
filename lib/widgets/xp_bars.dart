import 'package:flutter/material.dart';
import '../models/all_models.dart';
import '../utils/constants.dart';

// ==========================================================================
// XP条 + 四维属性条（需求#1玩家信息卡 / 首页展示）
// 彩色条+线性渐变+动画
// ==========================================================================
class XPBars extends StatelessWidget {
  final PlayerModel player;
  final double height;
  const XPBars({super.key, required this.player, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final ratio = player.maxXP > 0
        ? (player.currentXP / player.maxXP).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Text('XP', style: _t1(context, 11, Colors.white70)),
          const Spacer(),
          Text('${player.currentXP} / ${player.maxXP}', style: _t1(context, 11, Colors.white70)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(children: [
            Container(height: height, color: Colors.white12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500), curve: Curves.easeOut,
              width: double.infinity * ratio, height: height,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [
                AppColors.neonCyan, AppColors.skyBlue,
              ])),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _attr('词汇力💪', player.powerVocab, AppColors.vocabGreen),
        const SizedBox(height: 6),
        _attr('听力👂', player.powerListening, AppColors.listeningBlue),
        const SizedBox(height: 6),
        _attr('口语🗣️', player.powerSpeaking, AppColors.speakingOrange),
        const SizedBox(height: 6),
        _attr('阅读📖', player.powerReading, AppColors.readingPurple),
      ],
    );
  }
  Widget _attr(String name, int value, Color c) {
    final max = 100;
    final ratio = (value / max).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 64, child: Text(name, style: _t1(null, 11, Colors.white70))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 6, color: Colors.white12),
          AnimatedContainer(duration: const Duration(milliseconds: 400),
              width: double.infinity * ratio, height: 6, color: c),
        ]),
      )),
      const SizedBox(width: 8),
      SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.right,
        style: _t1(null, 10, Colors.white70))),
    ]);
  }
  TextStyle _t1(BuildContext? ctx, double s, Color c) =>
      TextStyle(fontSize: s, color: c, fontWeight: FontWeight.w600);
}
