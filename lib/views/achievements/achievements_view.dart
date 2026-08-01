import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../providers/intimacy_provider.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/confetti_painter.dart';

// ==========================================================================
// 成就墙（需求#8）+ 解锁弹窗 + 升级弹窗
// 三合一页面：默认成就墙；若有 pendingUnlocks/levelUp 自动弹
// ==========================================================================
class AchievementsView extends ConsumerStatefulWidget {
  const AchievementsView({super.key});
  @override ConsumerState<AchievementsView> createState() => _AViewState();
}
class _AViewState extends ConsumerState<AchievementsView> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }
  void _check() {
    final g = ref.read(gameProvider);
    if (g.pendingUnlocks.isNotEmpty || g.levelUpFrom != null) {
      showDialog(context: context, barrierDismissible: false,
          builder: (_) => _CelebrateDialog(levelFrom: g.levelUpFrom,
            unlocks: g.pendingUnlocks, onClose: () {
            ref.read(gameProvider.notifier).clearUnlocks();
            Navigator.pop(context);
          }));
    }
  }
  @override Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(gameProvider).achievements;
    final player = ref.watch(gameProvider).player;
    final unlocks = ref.watch(intimacyProvider).unlocks;
    return Scaffold(appBar: AppBar(title: const Text('🏅 成就墙')),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(children: [
          GlassmorphismCard(child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor:
              const Color(0xFF0D7377).withOpacity(0.15),
              child: const Icon(Icons.trophy, color: Color(0xFF0D7377), size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('玩家等级 Lv.${player.level} · 连击${player.streakDays}天',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _microStat('词', player.powerVocab, AppColors.vocabGreen),
                _microStat('听', player.powerListening, AppColors.listeningBlue),
                _microStat('说', player.powerSpeaking, AppColors.speakingOrange),
                _microStat('读', player.powerReading, AppColors.readingPurple),
              ]),
            ])),
          ])),
          const SizedBox(height: 18),
          const Align(alignment: Alignment.centerLeft,
            child: Text('学习成就 (${all.where((e)=>e.isUnlocked).length}/${all.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey))),
          const SizedBox(height: 10),
          GridView.count(crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
              children: all.map((a) => _AchievementTile(a: a)).toList()),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
            child: Text('羁绊解锁 (${unlocks.where((e)=>e.isUnlocked).length}/${unlocks.length})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey))),
          const SizedBox(height: 10),
          ...unlocks.map((u) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: GlassmorphismCard(opacity: u.isUnlocked ? 0.9 : 0.55,
              child: Row(children: [
                CircleAvatar(backgroundColor: u.isUnlocked ? AppColors.badgeRoseGold
                    : Colors.grey.shade300,
                  radius: 22, child: Text('Lv.${u.level}', style: TextStyle(
                    color: u.isUnlocked ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w800, fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.unlockName, style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: u.isUnlocked ? Colors.black87 : Colors.grey)),
                  const SizedBox(height: 2),
                  Text(u.unlockDescription,
                    style: TextStyle(color: u.isUnlocked ? Colors.grey.shade700
                        : Colors.grey.shade400, fontSize: 12)),
                ])),
                Icon(u.isUnlocked ? Icons.verified : Icons.lock,
                  color: u.isUnlocked ? AppColors.badgeRoseGold : Colors.grey.shade400),
              ])))),
          const SizedBox(height: 20),
        ]))));
  }
  Widget _microStat(String n, int v, Color c) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
        child: Text('$n·$v', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11)));
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel a;
  const _AchievementTile({required this.a});
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: a.isUnlocked ? Colors.white : Colors.grey.shade50,
          boxShadow: a.isUnlocked ? [BoxShadow(
            color: AppColors.badgeGold.withOpacity(0.35), blurRadius: 12, spreadRadius: 2)]
            : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          const SizedBox(height: 4),
          Text(a.icon.substring(0,2), style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              color: a.isUnlocked ? const Color(0xFF0A3D3F) : Colors.grey.shade500)),
          const SizedBox(height: 2),
          Expanded(child: Text(a.description, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
          if (a.isUnlocked) Container(padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 1), margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: AppColors.badgeGold.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8)),
            child: Text('+${a.xpReward} XP', style: const TextStyle(
                color: Color(0xFF7A5B00), fontSize: 10, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }
}

// 解锁/升级庆祝弹窗
class _CelebrateDialog extends StatelessWidget {
  final int? levelFrom;
  final List<AchievementModel> unlocks;
  final VoidCallback onClose;
  const _CelebrateDialog({this.levelFrom, required this.unlocks, required this.onClose});
  @override Widget build(BuildContext context) {
    return Stack(children: [
      const ConfettiOverlay(active: true, particleCount: 140,
        duration: Duration(seconds: 6)),
      Dialog(insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (levelFrom != null)
              Column(children: [
                const Text('🎇', style: TextStyle(fontSize: 52)),
                Text('升级！Lv.$levelFrom → Lv.${levelFrom!+1}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: AppColors.emeraldGreen)),
                const SizedBox(height: 8),
                const Text('学习到新的知识，解锁了下一阶段的属性成长！',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ]),
            if (unlocks.isNotEmpty) ...[
              if (levelFrom != null) const SizedBox(height: 18),
              const Text('🏅 成就解锁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                color: AppColors.badgeGold)),
              const SizedBox(height: 10),
              for (final a in unlocks) Padding(padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(tileColor: AppColors.badgeGold.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Text(a.icon.substring(0,2), style: const TextStyle(fontSize: 28)),
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(a.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: Text('+${a.xpReward} XP',
                    style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.w800))),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 48,
              child: FilledButton(style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: onClose, child: const Text('太好啦！'))),
          ]))),
    ]);
  }
}
