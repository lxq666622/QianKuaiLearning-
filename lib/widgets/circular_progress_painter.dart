import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ==========================================================================
// 圆形进度环 / 倒计时环 CustomPainter
// 需求#7.2计时器 / 各类进度展示
// ==========================================================================
class CircularProgressPainter extends CustomPainter {
  final double progress;     // 0.0 ~ 1.0
  final double strokeWidth;
  final Color color;
  final Color bgColor;
  final String? centerLabel;
  final TextStyle? labelStyle;

  CircularProgressPainter({
    required this.progress,
    this.strokeWidth = 18,
    this.color = AppColors.neonCyan,
    this.bgColor = Colors.white24,
    this.centerLabel, this.labelStyle,
  });

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset(strokeWidth/2, strokeWidth/2) &
        Size(s.width - strokeWidth, s.height - strokeWidth);
    // 背景
    c.drawArc(rect, 0, 2*3.14159265, false,
        Paint()..color = bgColor..strokeWidth=strokeWidth..style=PaintingStyle.stroke..isAntiAlias=true);
    // 前景（顶部开始，顺时针）
    c.drawArc(rect, -3.14159265/2, 2*3.14159265 * progress.clamp(0.0,1.0), false,
        Paint()..shader = const LinearGradient(colors: [
          AppColors.neonCyan, AppColors.skyBlue,
        ]).createShader(rect)
         ..strokeCap=StrokeCap.round..strokeWidth=strokeWidth..style=PaintingStyle.stroke..isAntiAlias=true);
    // 中心文字
    if (centerLabel != null && labelStyle != null) {
      final tp = TextPainter(
          text: TextSpan(text: centerLabel, style: labelStyle),
          textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(c, Offset((s.width - tp.width)/2, (s.height - tp.height)/2));
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter od) =>
      od.progress != progress || od.centerLabel != centerLabel;
}
