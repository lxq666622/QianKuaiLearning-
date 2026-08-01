import 'dart:ui';
import 'package:flutter/material.dart';

// ==========================================================================
// 玻璃拟态卡片（需求#1玩家信息卡 / 各模块通用）
// BackdropFilter + ClipRRect + BoxDecoration(白色半透明+shadow)
// ==========================================================================
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;
  final double blurX, blurY;
  const GlassmorphismCard({
    super.key, required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.opacity = 0.85,
    this.blurX = 18, this.blurY = 18,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24, offset: const Offset(0, 8),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
