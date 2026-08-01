import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/xp_bars.dart';
import '../widgets/intimacy_badge.dart';
import '../providers/intimacy_provider.dart';

// ==========================================================================
// 玩家信息卡（需求#1首页）
// 头像 + Lv.X + 经验条 + 四维属性 + 连击🔥
// ==========================================================================
class PlayerCard extends ConsumerWidget {
  const PlayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(gameProvider).player;
    final i = ref.watch(intimacyProvider);
    return GlassmorphismCard(padding: const EdgeInsets.all(18),
      child: Row(children: [
        // 头像区
        Stack(alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 68, height: 68, decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: LinearGradient(
                  colors: [Color(0xFFB76E79), Color(0xFF99CCFF)],
                )),
              child: const Center(child: Text('倩',
                style: TextStyle(fontSize: 28, color: Colors.white,
                  fontWeight: FontWeight.w800))),
            ),
            IntimacyBadge(level: i.level, size: 28),
          ]),
        const SizedBox(width: 14),
        // 信息+XP
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text(p.playerName, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFFD700),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6), blurRadius: 8)]),
                child: Text('Lv.${p.level}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5E4B00),
                    fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Row(children: [
                const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF6B35), size: 14),
                const SizedBox(width: 2),
                Text('${p.streakDays}', style: const TextStyle(
                  color: Color(0xFF333), fontWeight: FontWeight.w700)),
              ]),
            ]),
            const SizedBox(height: 12),
            XPBars(player: p, height: 8),
          ],
        )),
      ]),
    );
  }
}
