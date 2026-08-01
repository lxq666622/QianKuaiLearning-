import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vocabulary_provider.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/word_card_view.dart';

// ==========================================================================
// 词海主界面（需求#2）
// 顶部筛选，中间卡片翻转，底部三按钮
// ==========================================================================
class VocabularyView extends ConsumerWidget {
  const VocabularyView({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(vocabularyProvider);
    final notifier = ref.read(vocabularyProvider.notifier);
    return AnimatedGradientBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('词海攻坚', style: TextStyle(color: Colors.white,
          fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _filters(),
          const SizedBox(height: 32),
          Expanded(child: v.queue.isEmpty ? _empty()
              : Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: const WordCardView())))),
          const SizedBox(height: 24),
          if (v.current != null) Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn('忘记', 2, Colors.redAccent),
            _btn('模糊', 3, Colors.orangeAccent),
            _btn('认识', 5, Colors.greenAccent.shade400),
          ]),
        ]),
      )),
    ));
  }
  Widget _filters() {
    return Row(children: [
      _chip('全部', true, null),
      const SizedBox(width: 8),
      _chip('内置', false, null),
      const SizedBox(width: 8),
      _chip('导入', false, null),
      const SizedBox(width: 8),
      _chip('歌词', false, null),
    ]);
  }
  Widget _chip(String t, bool selected, Color? c) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
        color: selected ? Colors.white.withOpacity(0.95) : Colors.white12,
        border: Border.all(color: Colors.white24),
      ),
      child: Text(t, style: TextStyle(color: selected ? const Color(0xFF0A3D3F) : Colors.white,
        fontWeight: FontWeight.w700)),
    );
  }
  Widget _empty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min,
      children: const [
        Text('🎉 今天的复习任务完成了！',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 12),
        Text('可以去歌房练唱或查看成就墙～', style: TextStyle(color: Colors.white70)),
      ],
    ));
  }
  Widget _btn(String name, int q, Color c) {
    return Consumer(builder: (ctx, ref, _) {
      return SizedBox(width: 96, height: 48, child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: c, foregroundColor: Colors.black87,
        ),
        onPressed: () => ref.read(vocabularyProvider.notifier).answer(q),
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ));
    });
  }
}
