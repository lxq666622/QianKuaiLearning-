import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/settings_provider.dart';
import 'views/home/game_lobby_view.dart';
import 'views/vocabulary/vocabulary_view.dart';
import 'views/file_import/file_import_view.dart';
import 'views/karaoke/karaoke_studio_view.dart';
import 'views/karaoke/karaoke_player_view.dart';
import 'views/dungeon/daily_dungeon_view.dart';
import 'views/xinghui/xinghui_interaction_view.dart';
import 'views/achievements/achievements_view.dart';
import 'views/profile/profile_view.dart';
import 'models/all_models.dart';
import 'utils/constants.dart';

// ==========================================================================
// App 壳：主题 + 路由（go_router） + Riverpod 初始化
// ==========================================================================
final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/lobby',
  routes: [
    ShellRoute(navigatorKey: _shellNavKey,
      builder: (ctx, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/lobby', pageBuilder: (_, s) => const NoTransitionPage(child: GameLobbyView())),
        GoRoute(path: '/vocabulary', pageBuilder: (_, s) => const NoTransitionPage(child: VocabularyView())),
        GoRoute(path: '/karaoke', pageBuilder: (_, s) => const NoTransitionPage(child: KaraokeStudioView())),
        GoRoute(path: '/dungeon', pageBuilder: (_, s) => const NoTransitionPage(child: DailyDungeonView())),
        GoRoute(path: '/xinghui', pageBuilder: (_, s) => const NoTransitionPage(child: XingHuiInteractionView())),
        GoRoute(path: '/me', pageBuilder: (_, s) => const NoTransitionPage(child: ProfileView())),
      ]),
    GoRoute(path: '/import', parentNavigatorKey: _rootNavKey, builder: (_, s) => const FileImportView()),
    GoRoute(path: '/achievements', parentNavigatorKey: _rootNavKey, builder: (_, s) => const AchievementsView()),
    GoRoute(path: '/karaoke/:id', parentNavigatorKey: _rootNavKey,
        builder: (_, s) {
          final SongModel song = s.extra as SongModel;
          return KaraokePlayerView(song: song);
        }),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(settingsProvider).themeMode;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '倩快学习',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: AppColors.emeraldGreen,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6FBFB),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0,
          backgroundColor: Colors.transparent),
      ),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: AppColors.emeraldGreen,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: t,
      routerConfig: _router,
    );
  }
}

// 底部导航栏 Shell
class _Shell extends StatefulWidget {
  final Widget child;
  const _Shell({required this.child});
  @override State<_Shell> createState() => _ShellState();
}
class _ShellState extends State<_Shell> with SingleTickerProviderStateMixin {
  int _idx = 0;
  final _tabs = const [
    ('大厅', Icons.home_outlined, Icons.home, '/lobby'),
    ('词海', Icons.menu_book_outlined, Icons.menu_book, '/vocabulary'),
    ('歌房', Icons.music_note_outlined, Icons.music_note, '/karaoke'),
    ('副本', Icons.sports_esports_outlined, Icons.sports_esports, '/dungeon'),
    ('星回', Icons.star_border, Icons.star, '/xinghui'),
    ('我的', Icons.person_outline, Icons.person, '/me'),
  ];
  late final AnimationController _tabAnim;
  @override void initState() {
    super.initState();
    _tabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  }
  @override void dispose() { _tabAnim.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final newIdx = _tabs.indexWhere((e) => loc.startsWith(e.$4));
    if (newIdx != -1 && newIdx != _idx) {
      _idx = newIdx;
      _tabAnim.forward(from: 0);
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) {
          if (i != _idx) {
            _idx = i;
            context.go(_tabs[i].$4);
            _tabAnim.forward(from: 0);
          }
        },
        destinations: _tabs.map((t) => NavigationDestination(
          icon: AnimatedBuilder(animation: _tabAnim, builder: (c,_){
            final selected = _tabs[_idx].$4 == t.$4;
            final v = selected ? _tabAnim.value : 0.0;
            return Transform.translate(offset: Offset(0, -4*v),
              child: Transform.scale(scale: 1 + v*0.08,
                child: Icon(selected ? t.$3 : t.$2)));
          }),
          label: t.$1,
        )).toList(),
      ),
    );
  }
}

// 本地通知初始化（顶层）
Future<void> initNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true,
      requestSoundPermission: true);
  await plugin.initialize(const InitializationSettings(android: android, iOS: ios));
}
