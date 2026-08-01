import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/constants.dart';

// ==========================================================================
// FrameRateManager：帧率分级设计（需求#10）
// 模式:
//  - idle24fps    ：待机24-30FPS（AnimationController驱动的重绘节流）
//  - interact60fps：用户点击触发的交互（默认60FPS，Ticker全速率）
//  - cg60fps      ：剧情短片 / 展示向60FPS
// 使用：对需要控帧的 AnimationController 调用 throttleIdle() 降频；
//       在交互场景用 enableFullFrame() 还原60FPS。
// ==========================================================================
class FrameRateManager {
  static const int idleTargetFPS = 24;
  static const int fullTargetFPS = 60;
  FrameRateScene _scene = FrameRateScene.idle24fps;
  FrameRateScene get scene => _scene;

  // 切换场景：供Views在路由/模式切换时调用
  void setScene(FrameRateScene s) {
    _scene = s;
    _frameInterval = switch(s) {
      FrameRateScene.idle24fps => const Duration(microseconds: 1000000 ~/ idleTargetFPS),
      FrameRateScene.interact60fps => Duration.zero,
      FrameRateScene.cg60fps => Duration.zero,
    };
  }

  Duration _frameInterval = const Duration(microseconds: 1000000 ~/ idleTargetFPS);

  // 对 AnimationController.lastElapsedDuration 做「帧丢弃」包装
  // 返回 true 表示这一帧允许绘制，false 表示跳过
  int _lastDrawMicro = 0;
  bool allowDraw() {
    if (_frameInterval == Duration.zero) return true;
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now - _lastDrawMicro < _frameInterval.inMicroseconds) return false;
    _lastDrawMicro = now;
    return true;
  }

  // 构建一个 Ticker 节流包装：通过 CustomPainter 每帧判定 allowDraw
  Widget frameThrottled({
    required FrameRateScene scene,
    required Widget child,
  }) {
    return _FrameThrottle(manager: this, scene: scene, child: child);
  }
}

// Widget：在 build 时切换场景
class _FrameThrottle extends StatefulWidget {
  final FrameRateManager manager;
  final FrameRateScene scene;
  final Widget child;
  const _FrameThrottle({required this.manager, required this.scene, required this.child});
  @override State<_FrameThrottle> createState() => _FrameThrottleState();
}
class _FrameThrottleState extends State<_FrameThrottle> {
  @override void initState() {
    super.initState();
    widget.manager.setScene(widget.scene);
  }
  @override void didUpdateWidget(covariant _FrameThrottle old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) {
      widget.manager.setScene(widget.scene);
    }
  }
  @override Widget build(BuildContext context) => widget.child;
}

// 给 CustomPainter 用的基类：自动节流
abstract class FrameThrottledPainter extends CustomPainter {
  final FrameRateManager? manager;
  final bool _skip;
  FrameThrottledPainter({this.manager})
      : _skip = !(manager?.allowDraw() ?? true);
  @override void paint(Canvas c, Size s) {
    if (_skip) return;
    paintThrottled(c, s);
  }
  void paintThrottled(Canvas c, Size s);
}
