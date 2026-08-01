import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../providers/intimacy_provider.dart';
import '../../providers/xinghui_provider.dart';

// ==========================================================================
// 我的页面（个人中心 / 设置入口）
// ==========================================================================
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(gameProvider).player;
    final s = ref.watch(settingsProvider);
    final i = ref.watch(intimacyProvider);
    return Scaffold(appBar: AppBar(title: const Text('我的')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        GlassmorphismCard(child: Row(children: [
          CircleAvatar(radius: 36,
              backgroundColor: const Color(0xFFB76E79).withOpacity(0.2),
              child: Text(p.playerName, style: const TextStyle(fontSize: 24,
                  color: Color(0xFFB76E79), fontWeight: FontWeight.w800))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('倩', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Lv.${p.level} · 连击 ${p.streakDays} 天',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('羁绊 Lv.${i.level} · 累计 ${i.totalChatRounds} 轮对话 · 相识 ${i.daysKnown} 天',
              style: const TextStyle(color: Color(0xFFB76E79), fontSize: 12)),
          ])),
        ])),
        const SizedBox(height: 16),
        _section('外观'),
        _tile(Icons.dark_mode, s.themeMode == ThemeMode.dark ? '暗黑模式（当前）'
            : s.themeMode == ThemeMode.light ? '浅色模式（当前）' : '跟随系统（当前）', onTap: () {
          final next = s.themeMode == ThemeMode.system ? ThemeMode.light
              : s.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.system;
          ref.read(settingsProvider.notifier).setTheme(next);
        }, trailing: DropdownButton<ThemeMode>(value: s.themeMode, items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('暗黑')),
        ], onChanged: (v){ if (v != null) ref.read(settingsProvider.notifier).setTheme(v); })),
        _section('声音'),
        _tile(Icons.volume_up, 'TTS音量 ${(s.ttsVolume*100).toStringAsFixed(0)}%',
          trailing: Expanded(child: Slider(value: s.ttsVolume,
              onChanged: (v)=>ref.read(settingsProvider.notifier).setVolume(t:v)))),
        _tile(Icons.music_note, '背景音乐 ${(s.musicVolume*100).toStringAsFixed(0)}%',
          trailing: Expanded(child: Slider(value: s.musicVolume,
              onChanged: (v)=>ref.read(settingsProvider.notifier).setVolume(m:v)))),
        _section('数据'),
        _tile(Icons.delete_sweep, '清空本地聊天记录（仅星回）', onTap: () async {
          bool ok = await showDialog(context: context, builder: (ctx)=> AlertDialog(
            title: const Text('确认清空？'), content: const Text('将删除全部沈星回对话记录（不影响设置与羁绊值）'),
            actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('取消')),
              TextButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('清空', style: TextStyle(color: Colors.red)))]));
          if (ok == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能已预留，实际会调用DB')));
          }
        }),
        _tile(Icons.help, '关于 APP', trailing: const Text('倩快学习 v1.0.0 · Flutter 跨平台版',
            style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 24),
      ])));
  }
  Widget _section(String n) => Padding(padding: const EdgeInsets.fromLTRB(4,14,4,6),
    child: Text(n, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 12)));
  Widget _tile(IconData ic, String n, {VoidCallback? onTap, Widget? trailing}) {
    return Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Row(children: [
            Icon(ic, color: const Color(0xFF0D7377)),
            const SizedBox(width: 10),
            Text(n, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (trailing != null) trailing,
          ])))));
  }
}
