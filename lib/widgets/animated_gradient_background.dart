import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ==========================================================================
// 动态渐变背景（需求#13动画要求）
// AnimatedBuilder + AnimationController 无限循环，深翡翠绿→天空蓝缓慢流动
// ==========================================================================
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final t = _c.value * 2 * 3.14159265;
        final dx = 0.5 + 0.3 * (t * 0.3).sin();
        final dy = 0.5 + 0.2 * (t * 0.5).cos();
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(dx, dy),
              radius: 1.3,
              colors: const [
                AppColors.skyBlue,
                AppColors.emeraldGreen,
                Color(0xFF0A3D3F),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
