import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/intimacy_provider.dart';
import '../../providers/xinghui_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/intimacy_badge.dart';

// ==========================================================================
// 沈星回 主页面：单页三图层架构（需求#9.1）
// 图层1：常驻小人（全屏居中 / 对话悬浮）
// 图层2：底部控制通栏
// 图层3：打字抽屉 / 语音半屏（无跳转，单页叠加）
// ==========================================================================
class XingHuiInteractionView extends ConsumerStatefulWidget {
  const XingHuiInteractionView({super.key});
  @override ConsumerState<XingHuiInteractionView> createState() => _XHState();
}
class _XHState extends State<XingHuiInteractionView>
    with ConsumerStateMixin<XingHuiInteractionView>, SingleTickerProviderStateMixin {
  // 抽屉上滑展开
  double _drawerOffset = 0;
  double _startDy = 0;
  bool _voiceActive = false;
  late final AnimationController _voiceAnim;
  final double kDrawerMax = 520; // 打字抽屉最大高度
  final double kVoiceMax = 620;

  @override void initState() {
    super.initState();
    _voiceAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }
  @override void dispose() { _voiceAnim.dispose(); super.dispose(); }

  void _onVerticalDragStart(DragStartDetails d) { _startDy = d.globalPosition.dy; }
  void _onVerticalDragUpdate(DragUpdateDetails d) {
    final dy = _startDy - d.globalPosition.dy;
    setState(() {
      if (_voiceActive) {
        _drawerOffset = (kVoiceMax * (_voiceAnim.value) + dy).clamp(0.0, kVoiceMax);
      } else {
        _drawerOffset = (_drawerOffset + dy).clamp(0.0, kDrawerMax);
      }
    });
    _startDy = d.globalPosition.dy;
  }
  void _onVerticalDragEnd(_) {
    if (_voiceActive) return;
    if (_drawerOffset < kDrawerMax * 0.4) {
      setState(() => _drawerOffset = 0);
      ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.interact);
    } else {
      setState(() => _drawerOffset = kDrawerMax);
      ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.typing);
    }
  }

  void _switchMode(XHInteractionMode m) {
    if (m == XHInteractionMode.voice) {
      ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.voice);
      _voiceAnim.forward();
      setState(() { _voiceActive = true; _drawerOffset = kVoiceMax; });
    } else if (m == XHInteractionMode.typing) {
      ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.typing);
      setState(() { _voiceActive = false; _drawerOffset = kDrawerMax; _voiceAnim.value = 0; });
    } else {
      ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.interact);
      setState(() { _voiceActive = false; _drawerOffset = 0; _voiceAnim.value = 0; });
    }
  }

  @override Widget build(BuildContext context) {
    final xh = ref.watch(xinghuiProvider);
    final intimacy = ref.watch(intimacyProvider);
    final drawerActive = _drawerOffset > 40;
    final fullScreenAvatar = !drawerActive;
    return Scaffold(
      body: Stack(children: [
        // ========== 背景 ==========
        AnimatedContainer(duration: const Duration(seconds: 8),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              xh.identity == XingHuiIdentity.prince ? const Color(0xFF1A237E) :
              xh.identity == XingHuiIdentity.hunter ? const Color(0xFF1B1F3B) :
              xh.identity == XingHuiIdentity.police ? const Color(0xFF263238) :
                  const Color(0xFF14A3A7),
              xh.identity == XingHuiIdentity.prince ? const Color(0xFF99CCFF) :
              xh.identity == XingHuiIdentity.hunter ? const Color(0xFF4A5FC1) :
              xh.identity == XingHuiIdentity.police ? const Color(0xFF607D8B) :
                  const Color(0xFFD9EEF7),
            ]))),
        // ========== 图层1：常驻小人 + 顶部徽章 ==========
        SafeArea(child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: drawerActive ? _onVerticalDragStart : null,
          onVerticalDragUpdate: drawerActive ? _onVerticalDragUpdate : null,
          onVerticalDragEnd: drawerActive ? _onVerticalDragEnd : null,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                IntimacyBadge(level: intimacy.level, size: 38,
                  showProgress: true,
                  progress: (intimacy.value - intimacy.needAtLevel(intimacy.level)) /
                      (intimacy.needForNext() - intimacy.needAtLevel(intimacy.level)).clamp(1, 99999)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('沈星回', style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Lv.${intimacy.level} · 已相识 ${intimacy.daysKnown} 天 · 共 ${intimacy.totalChatRounds} 轮',
                    style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11)),
                ]),
                const Spacer(),
                // 亲密度增量飘字
                for (int i = 0; i < intimacy.recentlyAdded.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1100),
                      builder: (c, v, child) {
                        return Transform.translate(offset: Offset(0, -30*v),
                          child: Opacity(opacity: 1-v,
                            child: Text(intimacy.recentlyAdded[i],
                              style: TextStyle(color: AppColors.badgeRoseGold,
                                fontWeight: FontWeight.w800,
                                shadows: [const Shadow(color: Colors.white54, blurRadius: 4)]))));
                      }),
                  ),
              ]),
            ),
            // ========== 交互小人 ==========
            Expanded(child: fullScreenAvatar
              ? _AvatarFullScreen(emotion: xh.avatarEmotion, action: xh.lastActionHint,
                  onTapPart: (p) => ref.read(xinghuiProvider.notifier).tapPart(p),
                  intimacy: intimacy.level, identity: xh.identity)
              : _AvatarMini(emotion: xh.avatarEmotion, action: xh.lastActionHint,
                  onTap: () => _switchMode(XHInteractionMode.interact),
                  identity: xh.identity)),
            const SizedBox(height: drawerActive ? 0 : 88),
          ]),
        )),
        // ========== 图层3：内容浮层（打字抽屉 / 语音半屏） ==========
        _voiceActive
          ? _voiceModeOverlay()
          : _typingDrawerOverlay(),
        // ========== 图层2：底部控制条 ==========
        Positioned(left: 0, right: 0, bottom: 0,
          child: _ControlBar(
            identity: xh.identity, mode: xh.mode,
            onIdentity: (i) => ref.read(xinghuiProvider.notifier).setIdentity(i),
            onMode: _switchMode,
            onSettings: () => _openSettings(context, ref),
          ),
        ),
      ]),
    );
  }

  // ========== 打字抽屉 ==========
  Widget _typingDrawerOverlay() {
    return Positioned(left: 0, right: 0, bottom: 80,
      height: _drawerOffset,
      child: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedContainer(
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24,
                offset: const Offset(0, -8))],
          ),
          child: const _TypingDrawerContent(),
        ),
      ));
  }
  Widget _voiceModeOverlay() {
    return Positioned(left: 0, right: 0, bottom: 80,
      height: _drawerOffset,
      child: AnimatedBuilder(animation: _voiceAnim, builder: (c,_) {
        return Opacity(opacity: _voiceAnim.value,
          child: Transform.scale(scale: 0.9 + 0.1 * _voiceAnim.value,
            alignment: Alignment.bottomCenter,
            child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0A2324), Color(0xFF004F52)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24,
                    offset: const Offset(0, -8))],
                ),
                child: const _VoiceOverlayContent()),
          ));
      }));
  }

  void _openSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius:
        BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => _SettingsSheet());
  }
}

// ==========================================================================
// 图层1：全屏小人（无对话）
// ==========================================================================
class _AvatarFullScreen extends StatelessWidget {
  final int emotion; final String? action; final int intimacy;
  final XingHuiIdentity identity;
  final void Function(XingHuiTrigger) onTapPart;
  const _AvatarFullScreen({required this.emotion, this.action, required this.onTapPart,
    required this.intimacy, required this.identity});

  @override Widget build(BuildContext context) {
    // 按部位划分点击：上1/3=头顶，脸颊=中1/3两侧，中心=肩膀，底部按钮=手掌/牵手/拥抱
    return LayoutBuilder(builder: (ctx, cons) {
      return Column(children: [
        Expanded(child: Stack(children: [
          Center(child: _XHAvatarImage(emotion: emotion, identity: identity,
            size: Size(cons.maxWidth*0.9, cons.maxHeight*0.9),),),
          // 点击区域
          _tapArea(0, 0, cons.maxWidth, cons.maxHeight*0.33,
            () => onTapPart(XingHuiTrigger.tapHead)),
          _tapArea(0, cons.maxHeight*0.33, cons.maxWidth*0.45, cons.maxHeight*0.33,
            () => onTapPart(XingHuiTrigger.tapCheek)),
          _tapArea(cons.maxWidth*0.55, cons.maxHeight*0.33, cons.maxWidth*0.45, cons.maxHeight*0.33,
            () => onTapPart(XingHuiTrigger.tapCheek)),
          _tapArea(0, cons.maxHeight*0.66, cons.maxWidth, cons.maxHeight*0.34,
            () => onTapPart(XingHuiTrigger.tapShoulder)),
          if (action != null)
            Positioned(left: 0, right: 0, bottom: 16,
              child: Center(child: Container(padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.55)),
                child: Text('$action', style: const TextStyle(color: Colors.white,
                  fontSize: 12)),))),
        ])),
        // 底部互动按钮：手掌/牵手/拥抱
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(children: [
            Expanded(child: _b('🖐️ 碰手', intimacy >= 0,
                () => onTapPart(XingHuiTrigger.tapPalm))),
            const SizedBox(width: 8),
            Expanded(child: _b(intimacy >= 5 ? '🤝 牵手' : '🔒 牵手 Lv.5', intimacy >= 5,
                () => onTapPart(XingHuiTrigger.tapHand))),
            const SizedBox(width: 8),
            Expanded(child: _b(intimacy >= 10 ? '🤗 拥抱' : '🔒 拥抱 Lv.10', intimacy >= 10,
                () => onTapPart(XingHuiTrigger.tapHug))),
          ])),
      ]);
    });
  }
  Widget _tapArea(double l, double t, double w, double h, VoidCallback onTap) {
    return Positioned(left: l, top: t, width: w, height: h,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand()));
  }
  Widget _b(String n, bool enabled, VoidCallback onTap) {
    return SizedBox(height: 44, child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: enabled ? Colors.white.withOpacity(0.2) : Colors.white10,
        foregroundColor: enabled ? Colors.white : Colors.white54,
        side: BorderSide(color: enabled ? Colors.white70 : Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: enabled ? onTap : null, child: Text(n, style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 12))));
  }
}

// 小人占位图（真实项目替换为帧率标签动画资源：idle_24fps / interact_60fps / cg_60fps）
class _XHAvatarImage extends StatefulWidget {
  final int emotion; final Size size; final XingHuiIdentity identity;
  const _XHAvatarImage({required this.emotion, required this.size, required this.identity});
  @override State<_XHAvatarImage> createState() => _XHAvatarImageState();
}
class _XHAvatarImageState extends State<_XHAvatarImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  @override void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }
  @override void dispose() { _breath.dispose(); super.dispose(); }
  Color get _bg {
    return switch(widget.identity) {
      XingHuiIdentity.daily => const Color(0xFFC5D6E8),
      XingHuiIdentity.hunter => const Color(0xFF3A4A8C),
      XingHuiIdentity.police => const Color(0xFF4E5968),
      XingHuiIdentity.prince => const Color(0xFF6E8FD6),
    };
  }
  Color get _hair {
    return widget.emotion == 1 ? const Color(0xFFC9A176)
         : widget.emotion == 2 ? const Color(0xFFE2B57D)
         : const Color(0xFFB38D61);
  }
  Color get _face {
    return widget.emotion == 2 ? const Color(0xFFFBD1C5)
         : const Color(0xFFF6E2D3);
  }

  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _breath, builder: (c,_) {
      final s = 1 + _breath.value * 0.015;
      return Transform.scale(scale: s, child: SizedBox.fromSize(size: widget.size,
        child: CustomPaint(painter: _AvatarPainter(
            bg: _bg, hair: _hair, face: _face, identity: widget.identity,
            emotion: widget.emotion))));
    });
  }
}
// 占位：极简星回人像
class _AvatarPainter extends CustomPainter {
  final Color bg, hair, face; final XingHuiIdentity identity; final int emotion;
  _AvatarPainter({required this.bg, required this.hair, required this.face,
    required this.identity, required this.emotion});
  @override void paint(Canvas c, Size s) {
    // 背景
    c.drawRect(Offset.zero & s, Paint()..color = bg);
    // 肩
    c.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width*0.15, s.height*0.55, s.width*0.7, s.height*0.4),
        Radius.circular(s.width*0.35)),
      Paint()..color = identity == XingHuiIdentity.hunter ? const Color(0xFF213055)
          : identity == XingHuiIdentity.police ? const Color(0xFF15273A)
          : identity == XingHuiIdentity.prince ? const Color(0xFF394E8E)
          : const Color(0xFF14A3A7));
    // 脸
    c.drawOval(Rect.fromCenter(
        center: Offset(s.width/2, s.height*0.42),
        width: s.width*0.32, height: s.height*0.36),
      Paint()..color = face);
    // 头发
    final hp = Path();
    hp.moveTo(s.width*0.33, s.height*0.26);
    hp.quadraticBezierTo(s.width/2, s.height*0.18, s.width*0.67, s.height*0.26);
    hp.cubicTo(s.width*0.73, s.height*0.24, s.width*0.76, s.height*0.42, s.width*0.66, s.height*0.46);
    hp.lineTo(s.width*0.6, s.height*0.3);
    hp.quadraticBezierTo(s.width/2, s.height*0.25, s.width*0.4, s.height*0.3);
    hp.lineTo(s.width*0.34, s.height*0.46);
    hp.cubicTo(s.width*0.24, s.height*0.42, s.width*0.27, s.height*0.24, s.width*0.33, s.height*0.26);
    c.drawPath(hp, Paint()..color = hair);
    // 眼睛
    c.drawOval(Rect.fromCenter(center: Offset(s.width*0.42, s.height*0.44), width: 10, height: 16),
        Paint()..color = Colors.black87);
    c.drawOval(Rect.fromCenter(center: Offset(s.width*0.58, s.height*0.44), width: 10, height: 16),
        Paint()..color = Colors.black87);
    c.drawCircle(Offset(s.width*0.425, s.height*0.455), 3, Paint()..color = Colors.white);
    c.drawCircle(Offset(s.width*0.585, s.height*0.455), 3, Paint()..color = Colors.white);
    // 嘴（微笑 / 正常）
    final p = Path();
    p.moveTo(s.width*0.44, s.height*0.55);
    if (emotion == 1) { p.quadraticBezierTo(s.width/2, s.height*0.58, s.width*0.56, s.height*0.55); }
    else { p.quadraticBezierTo(s.width/2, s.height*0.565, s.width*0.56, s.height*0.55); }
    c.drawPath(p, Paint()..style = PaintingStyle.stroke
      ..color = Colors.black54..strokeWidth = 2..strokeCap = StrokeCap.round);
    if (emotion == 2) {
      // 腮红
      c.drawCircle(Offset(s.width*0.38, s.height*0.51), 12, Paint()..color = const Color(0x88FFB1A4));
      c.drawCircle(Offset(s.width*0.62, s.height*0.51), 12, Paint()..color = const Color(0x88FFB1A4));
    }
    if (emotion == 4) {
      // 说话状态 → 嘴张开
      c.drawOval(Rect.fromCenter(center: Offset(s.width/2, s.height*0.555), width: 14, height: 10),
          Paint()..color = const Color(0xFF9D4E3E));
    }
  }
  @override bool shouldRepaint(covariant _AvatarPainter o) =>
    o.hair != hair || o.face != face || o.identity != identity || o.emotion != emotion;
}

// 悬浮小人
class _AvatarMini extends StatelessWidget {
  final int emotion; final String? action;
  final VoidCallback onTap; final XingHuiIdentity identity;
  const _AvatarMini({required this.emotion, this.action, required this.onTap,
    required this.identity});
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(onTap: onTap,
        child: Container(width: 120, height: 120, decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20)],
        ), clipBehavior: Clip.antiAlias,
          child: _XHAvatarImage(emotion: emotion, identity: identity,
            size: const Size(120,120)))));
  }
}

// ==========================================================================
// 图层3a：打字抽屉内容
// ==========================================================================
class _TypingDrawerContent extends ConsumerStatefulWidget {
  const _TypingDrawerContent();
  @override ConsumerState<_TypingDrawerContent> createState() => _TDCState();
}
class _TDCState extends State<_TypingDrawerContent> with ConsumerStateMixin<_TypingDrawerContent> {
  final _tc = TextEditingController();
  final _sc = ScrollController();
  @override void dispose() { _tc.dispose(); _sc.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final xh = ref.watch(xinghuiProvider);
    final list = xh.messages;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients && list.isNotEmpty) {
        _sc.animateTo(_sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    return Column(children: [
      // Drag Handle
      Padding(padding: const EdgeInsets.only(top: 8),
        child: Container(width: 44, height: 4,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
            color: Colors.grey.shade300))),
      const Text('打字聊天',
        style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      // 快捷按钮
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(spacing: 6, runSpacing: 4, children: [
          _q('早安'), _q('晚安'), _q('我好累'), _q('想你了'),
          _q('我完成了副本'), _q('今天学了XX词'), _q('我难受'), _q('吃醋了'),
        ])),
      const SizedBox(height: 8),
      // 消息列表
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: list.isEmpty
          ? Center(child: Text('输入内容开始聊天，无轮次限制。',
            style: TextStyle(color: Colors.grey.shade400)))
          : ListView.builder(controller: _sc, itemCount: list.length + (xh.isTyping ? 1 : 0),
              itemBuilder: (c, i) {
                if (i == list.length) {
                  return const _TypingIndicator();
                }
                final m = list[i];
                return _Bubble(msg: m);
              }))),
      const Divider(height: 1),
      // 输入区
      Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(children: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.mic_none, color: AppColors.emeraldGreen)),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
                color: Colors.grey.shade100),
            child: TextField(controller: _tc,
              decoration: const InputDecoration(border: InputBorder.none,
                  hintText: '跟他说点什么…'),
              onSubmitted: (s) => _send(s)))),
          IconButton(onPressed: () => _send(_tc.text),
              icon: const Icon(Icons.send, color: AppColors.emeraldGreen))
        ])),
    ]);
  }
  Widget _q(String n) {
    return InkWell(onTap: () => _send(n),
      borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            color: AppColors.xingHuiBubble),
        child: Text(n, style: const TextStyle(fontSize: 12, color: Color(0xFF0A3D3F),
          fontWeight: FontWeight.w600))));
  }
  Future<void> _send(String s) async {
    final txt = s.trim();
    if (txt.isEmpty) return;
    _tc.clear();
    await ref.read(xinghuiProvider.notifier).sendText(txt);
    // 检测5分钟内回复推送（+20羁绊）
    final delta = 0; // 预留 XingHuiPushManager 回调
    if (delta > 0) {
      await ref.read(intimacyProvider.notifier).onReplyWithin5Min(delta);
    }
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(10),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.xingHuiBubble,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20),
                bottomRight: Radius.circular(20))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 3; i++)
              Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: _BounceDot(delay: i * 150)),
          ])),
      ]));
  }
}
class _BounceDot extends StatefulWidget {
  final int delay;
  const _BounceDot({this.delay = 0});
  @override State<_BounceDot> createState() => _BounceDotState();
}
class _BounceDotState extends State<_BounceDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (c,_) {
      return Transform.translate(offset: Offset(0, -6 * (_c.value - 0.5).abs() * 2),
        child: Container(width: 8, height: 8, decoration: BoxDecoration(
          shape: BoxShape.circle, color: const Color(0xFF779CB5))));
    });
  }
}

class _Bubble extends StatelessWidget {
  final XHMessageModel msg;
  const _Bubble({required this.msg});
  @override Widget build(BuildContext context) {
    final mine = msg.isFromUser;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine) const SizedBox(width: 24),
          Flexible(
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                  color: mine ? Colors.white : AppColors.xingHuiBubble,
                  border: Border.all(color: mine
                      ? const Color(0xFFE0E0E0) : Colors.transparent),
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: mine ? const Radius.circular(20) : Radius.zero,
                      bottomRight: mine ? Radius.zero : const Radius.circular(20)),
              ),
              child: Text(msg.content, style: const TextStyle(
                fontSize: 14, height: 1.5, color: Colors.black87))),
          ),
          if (mine) const SizedBox(width: 24),
        ]));
  }
}

// ==========================================================================
// 图层3b：语音通话半屏
// ==========================================================================
class _VoiceOverlayContent extends ConsumerStatefulWidget {
  const _VoiceOverlayContent();
  @override ConsumerState<_VoiceOverlayContent> createState() => _VOCState();
}
class _VOCState extends State<_VoiceOverlayContent> with ConsumerStateMixin<_VoiceOverlayContent>, SingleTickerProviderStateMixin {  bool _callActive = false;
  late final AnimationController _emotionBlink;
  int _seconds = 0;
  Timer? _timer;
  bool _companion = false;
  @override void initState() {
    super.initState();
    _emotionBlink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    // 模拟2秒后接通
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _callActive = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_){
        if (mounted) setState(()=>_seconds++);
      });
    });
  }
  @override void dispose() { _timer?.cancel(); _emotionBlink.dispose(); super.dispose(); }

  String fmt(int s) {
    final m = (s~/60).toString().padLeft(2,'0');
    final ss = (s%60).toString().padLeft(2,'0');
    return '$m:$ss';
  }

  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        Text(_companion ? '陪伴挂机模式' : '实时通话', style: const TextStyle(
            color: Colors.white70, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 18),
        Text(fmt(_seconds), style: const TextStyle(
            color: AppColors.neonCyan, fontSize: 32,
            fontWeight: FontWeight.w800, letterSpacing: 4)),
        const SizedBox(height: 18),
        // 声纹波形
        AnimatedBuilder(animation: _emotionBlink, builder: (c,_) {
          return SizedBox(height: 56,
            child: CustomPaint(painter: _WavePainter(_emotionBlink.value, _seconds % 2 == 0)));
        }),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: Icon(_companion ? Icons.volume_off : Icons.volume_up,
              color: Colors.white, size: 32), onPressed: (){setState(()=>_companion = !_companion);},
              tooltip: '切换挂机模式'),
          FloatingActionButton.large(backgroundColor: Colors.red,
            onPressed: (){
              ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.interact);
            }, child: const Icon(Icons.call_end, color: Colors.white, size: 36)),
          IconButton(onPressed: (){
            ref.read(xinghuiProvider.notifier).setMode(XHInteractionMode.typing);
          }, icon: const Icon(Icons.textsms, color: Colors.white, size: 30),
              tooltip: '转文字聊天'),
        ]),
        const SizedBox(height: 10),
      ]));
  }
}
class _WavePainter extends CustomPainter {
  final double t; final bool speaking;
  _WavePainter(this.t, this.speaking);
  @override void paint(Canvas c, Size s) {
    final bars = 48;
    final gap = s.width / bars;
    for (int i = 0; i < bars; i++) {
      double v = (i / bars * 6.28 + t * 6.28).sin().abs() * s.height * 0.9;
      if (!speaking) v *= 0.25;
      final h = v + 2;
      final x = i * gap;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (s.height - h)/2, gap-2, h),
          Radius.circular(4));
      c.drawRRect(r, Paint()
        ..shader = const LinearGradient(colors: [
          AppColors.neonCyan, AppColors.skyBlue]).createShader(Offset.zero & s));
    }
  }
  @override bool shouldRepaint(covariant _WavePainter o) => true;
}

// ==========================================================================
// 图层2：底部控制条（身份 / 模式 / 设置）
// ==========================================================================
class _ControlBar extends StatelessWidget {
  final XingHuiIdentity identity; final XHInteractionMode mode;
  final void Function(XingHuiIdentity) onIdentity;
  final void Function(XHInteractionMode) onMode;
  final VoidCallback onSettings;
  const _ControlBar({required this.identity, required this.mode,
    required this.onIdentity, required this.onMode, required this.onSettings});

  static const ids = XingHuiIdentity.values;
  @override Widget build(BuildContext context) {
    return Container(height: 80, padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(children: [
        _identityPicker(),
        const SizedBox(width: 8),
        Expanded(child: _modeSwitcher()),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: onSettings,
          icon: const Icon(Icons.settings), tooltip: '星回设置'),
      ]));
  }
  Widget _identityPicker() {
    return PopupMenuButton<XingHuiIdentity>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onIdentity,
      itemBuilder: (_) => ids.map((i) => PopupMenuItem(value: i,
          child: Row(children: [
            if (i == identity) const Icon(Icons.check, color: AppColors.emeraldGreen, size: 18),
            if (i != identity) const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(i.name, style: TextStyle(
                fontWeight: identity == i ? FontWeight.w800 : FontWeight.w400)),
          ]))).toList(),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: AppColors.emeraldGreen.withOpacity(0.1),
          border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.4))),
        child: Row(children: [
          const Icon(Icons.palette, color: AppColors.emeraldGreen, size: 18),
          const SizedBox(width: 6),
          Text(identity.name, style: const TextStyle(
              color: AppColors.emeraldGreen, fontWeight: FontWeight.w700, fontSize: 12)),
        ])),
    );
  }
  Widget _modeSwitcher() {
    return Container(padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100),
      child: Row(children: [
        _seg('互动', XHInteractionMode.interact, Icons.pan_tool_alt),
        _seg('打字', XHInteractionMode.typing, Icons.keyboard),
        _seg('通话', XHInteractionMode.voice, Icons.phone_in_talk),
      ]));
  }
  Widget _seg(String n, XHInteractionMode m, IconData ic) {
    final selected = mode == m;
    return Expanded(child: GestureDetector(onTap: ()=>onMode(m),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.emeraldGreen : Colors.transparent),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic, size: 16, color: selected ? Colors.white : Colors.black54),
          const SizedBox(width: 4),
          Text(n, style: TextStyle(color: selected ? Colors.white : Colors.black54,
              fontSize: 12, fontWeight: FontWeight.w700))
        ]))));
  }
}

// ==========================================================================
// 设置弹层
// ==========================================================================
class _SettingsSheet extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return SafeArea(child: Padding(padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Center(child: Container(width: 44, height: 4,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
            color: Colors.grey.shade300))),
        const SizedBox(height: 18),
        const Text('星回设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        _row('启用星回', Switch(value: s.xhEnabled,
          onChanged: (v)=>ref.read(settingsProvider.notifier).setXingHui(v))),
        _row('自动回复', Switch(value: s.autoReplyEnabled,
          onChanged: (v){})),
        ListTile(leading: const Icon(Icons.notifications),
          title: const Text('每日推送上限'), trailing: DropdownButton<int>(
              value: s.dailyPushLimit,
              items: const [1,2,3,5].map((e) => DropdownMenuItem(value:e,child: Text('$e 条/日'))).toList(),
              onChanged: (v)=>{}), dense: true),
        ListTile(leading: const Icon(Icons.volume_up),
          title: const Text('TTS音量'), subtitle: Slider(value: s.ttsVolume,
              onChanged: (v)=>ref.read(settingsProvider.notifier).setVolume(t:v))),
        ListTile(leading: const Icon(Icons.person),
          title: const Text('对我的昵称'),
          subtitle: Text(s.userNickname),
          trailing: TextButton(onPressed: (){}, child: const Text('修改'))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))),
            child: const Text('完成'))),
      ])));
  }
  Widget _row(String n, Widget w) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Text(n, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const Spacer(), w]));
}
