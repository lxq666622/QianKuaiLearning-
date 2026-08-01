import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ==========================================================================
// 羁绊等级徽章（需求#9.3羁绊值展示）
// 4级色：1-5银 / 6-10金 / 11-15玫瑰金 / 16-20星辉
// 发光BoxShadow + 等级字
// ==========================================================================
class IntimacyBadge extends StatelessWidget {
  final int level;
  final double size;
  final bool showProgress;
  final double progress; // 0~1
  const IntimacyBadge({super.key, required this.level,
    this.size = 56, this.showProgress = false, this.progress = 0});

  Color get _color => level >= 16 ? AppColors.badgeStarlight
                   : level >= 11 ? AppColors.badgeRoseGold
                   : level >= 6  ? AppColors.badgeGold
                   : AppColors.badgeSilver;

  @override
  Widget build(BuildContext context) {
    final lvl = level.clamp(1, 20);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_color.withOpacity(0.3), _color, _color.withOpacity(0.5)],
            ),
            boxShadow: [
              BoxShadow(color: _color.withOpacity(0.55), blurRadius: 16, spreadRadius: 2),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text('Lv.$lvl', style: TextStyle(
              fontSize: size*0.34, fontWeight: FontWeight.w800,
              color: level>=11 ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            )),
          ),
        ),
        if (showProgress)
          Positioned.fill(child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0), strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(_color.withOpacity(0.9)),
            backgroundColor: Colors.black12,
          )),
      ],
    );
  }
}
