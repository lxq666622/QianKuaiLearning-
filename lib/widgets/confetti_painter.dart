import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ==========================================================================
// Confetti 粒子系统（需求#13 / 副本通关 / 升级 / 成就解锁）
// CustomPainter + gravity + 纸片旋转 + 随机色
// ==========================================================================
class ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  ConfettiPainter(this.pieces);

  static const _colors = [
    AppColors.neonCyan, AppColors.skyBlue, AppColors.emeraldGreen,
    Color(0xFFFFD700), Color(0xFFFF6B6B), Color(0xFFB76E79),
    Color(0xFF99CCFF), Colors.white,
  ];
  static List<_ConfettiPiece> spawn(int n, Size size, {int seed = 0}) {
    final r = Random(seed);
    return List.generate(n, (_) => _ConfettiPiece(
      x: r.nextDouble() * size.width,
      y: -r.nextDouble() * size.height * 0.5,
      vx: (r.nextDouble() - 0.5) * 60,
      vy: 120 + r.nextDouble() * 180,
      size: 6 + r.nextDouble() * 10,
      rot: r.nextDouble() * 2 * pi,
      vrot: (r.nextDouble() - 0.5) * 10,
      color: _colors[r.nextInt(_colors.length)],
    ));
  }

  @override
  void paint(Canvas c, Size s) {
    for (final p in pieces) {
      final rect = Offset(p.x - p.size/2, p.y - p.size/2) & Size(p.size, p.size*0.6);
      c.save();
      c.translate(p.x, p.y);
      c.rotate(p.rot);
      c.drawRect(rect.translate(-p.x, -p.y), Paint()..color = p.color);
      c.restore();
    }
  }

  @override bool shouldRepaint(covariant ConfettiPainter o) => true;
}

class _ConfettiPiece {
  double x, y, vx, vy, size, rot, vrot; Color color;
  _ConfettiPiece({
    required this.x, required this.y, required this.vx, required this.vy,
    required this.size, required this.rot, required this.vrot, required this.color,
  });
}

// 带动画的全屏 Confetti widget
class ConfettiOverlay extends StatefulWidget {
  final bool active;
  final int particleCount;
  final Duration duration;
  const ConfettiOverlay({super.key, this.active = false,
    this.particleCount = 120, this.duration = const Duration(seconds: 5)});

  @override State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}
class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  List<_ConfettiPiece> _ps = [];
  Size _last = Size.zero;

  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override void didUpdateWidget(covariant ConfettiOverlay o) {
    super.didUpdateWidget(o);
    if (o.active && !widget.active && !_c.isAnimating) {
      _start();
    }
  }
  void _start() {
    if (_last.isEmpty) return;
    _ps = ConfettiPainter.spawn(widget.particleCount, _last,
        seed: DateTime.now().millisecondsSinceEpoch % 10000);
    _c.forward(from: 0).orCancel.then((_) { if (mounted) setState((){}); });
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      _last = Size(cons.maxWidth, cons.maxHeight);
      if (_ps.isEmpty && widget.active) Future.microtask(_start);
      return AnimatedBuilder(animation: _c, builder: (ctx,_) {
        if (_c.isAnimating) _step(_c.lastElapsedDuration ?? Duration.zero);
        return IgnorePointer(child: CustomPaint(
          size: _last, painter: ConfettiPainter(_ps)));
      });
    });
  }
  void _step(Duration dt) {
    final sec = dt.inMilliseconds / 1000;
    for (final p in _ps) {
      p.vy += 180 * sec;
      p.x += p.vx * sec;
      p.y += p.vy * sec;
      p.rot += p.vrot * sec;
    }
  }
}
