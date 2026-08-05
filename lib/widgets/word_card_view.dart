import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vocabulary_provider.dart';

// ==========================================================================
// 单词卡片 3D翻转动画（需求#13）
// GestureDetector + AnimatedBuilder + Matrix4.rotationY
// ==========================================================================
class WordCardView extends ConsumerStatefulWidget {
  const WordCardView({super.key});
  @override ConsumerState<WordCardView> createState() => _WordCardViewState();
}
class _WordCardViewState extends State<WordCardView>
    with ConsumerStateMixin<WordCardView>, SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  void flip() {
    final n = ref.read(vocabularyProvider.notifier);
    n.flip();
    if (!ref.read(vocabularyProvider).isFront) _c.forward(); else _c.reverse();
  }

  @override Widget build(BuildContext context) {
    final v = ref.watch(vocabularyProvider);
    final w = v.current;
    if (w == null) return const SizedBox.shrink();
    return GestureDetector(onTap: flip,
      child: AnimatedBuilder(animation: _c, builder: (ctx, _) {
        final angle = _c.value * 3.14159265;
        final showFront = angle < 3.14159265/2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3,2, 0.001)
            ..rotateY(angle),
          child: showFront ? _front(w) : Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.14159265),
            child: _back(w),
          ),
        );
      }),
    );
  }
  Widget _front(w) => Card(elevation: 10, shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24)),
    color: const Color(0xFFFFFFFF),
    child: SizedBox(width: double.infinity, height: 420,
      child: Padding(padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF0D7377).withOpacity(0.1)),
            child: Text(w.source, style: const TextStyle(color: Color(0xFF0D7377),
                fontSize: 11, fontWeight: FontWeight.w700))),
          const SizedBox(height: 24),
          Text(w.word, style: const TextStyle(fontSize: 38,
              fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          Text(w.phonetic ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey,
              letterSpacing: 1)),
          const SizedBox(height: 20),
          Chip(label: Text('${w.wordType == 'read' ? '阅读词' : '写作词'} · 熟练度 ${w.proficiency}/5',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFF14FFEC).withOpacity(0.2)),
          const SizedBox(height: 40),
          const Text('👆 点击卡片查看释义',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]))),
  );
  Widget _back(w) => Card(elevation: 10, shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24)),
    color: const Color(0xFF0D7377),
    child: SizedBox(width: double.infinity, height: 420,
      child: Padding(padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
            color: Color(0xFF14FFEC))),
          const SizedBox(height: 18),
          const Text('释义', style: TextStyle(color: Color(0xFFB4F3F0), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(w.meaning, style: const TextStyle(fontSize: 20, color: Colors.white,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          const Text('例句', style: TextStyle(color: Color(0xFFB4F3F0), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1)),
            child: Text(w.exampleSentence,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))),
          const Spacer(),
          const Center(child: Text('👆 再次点击翻回',
              style: TextStyle(color: Color(0xFFB4F3F0), fontSize: 12))),
        ]))),
  );
}
