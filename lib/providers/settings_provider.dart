import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==========================================================================
// 全局设置：暗黑模式、TTS音量、免打扰开关、用户昵称等
// ==========================================================================
class SettingsState {
  final ThemeMode themeMode;
  final double ttsVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool xhEnabled;
  final int xhDNDStartMin;  // 分
  final int xhDNDEndMin;
  final int dailyPushLimit;
  final bool autoReplyEnabled;
  final String userNickname;
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.ttsVolume = 1.0, this.musicVolume = 0.7, this.sfxVolume = 1.0,
    this.xhEnabled = true,
    this.xhDNDStartMin = 1380, // 23:00
    this.xhDNDEndMin = 420,    // 7:00
    this.dailyPushLimit = 3,
    this.autoReplyEnabled = true,
    this.userNickname = '倩',
  });
  SettingsState copyWith({
    ThemeMode? themeMode, double? ttsVolume, double? musicVolume, double? sfxVolume,
    bool? xhEnabled, int? xhDNDStartMin, int? xhDNDEndMin,
    int? dailyPushLimit, bool? autoReplyEnabled, String? userNickname,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    ttsVolume: ttsVolume ?? this.ttsVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    xhEnabled: xhEnabled ?? this.xhEnabled,
    xhDNDStartMin: xhDNDStartMin ?? this.xhDNDStartMin,
    xhDNDEndMin: xhDNDEndMin ?? this.xhDNDEndMin,
    dailyPushLimit: dailyPushLimit ?? this.dailyPushLimit,
    autoReplyEnabled: autoReplyEnabled ?? this.autoReplyEnabled,
    userNickname: userNickname ?? this.userNickname,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setTheme(ThemeMode m) => state = state.copyWith(themeMode: m);
  void toggleTheme() => state = state.copyWith(
    themeMode: state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
  void setVolume({double? t, double? m, double? s}) =>
      state = state.copyWith(ttsVolume: t, musicVolume: m, sfxVolume: s);
  void setXingHui(bool on) => state = state.copyWith(xhEnabled: on);
  void setDND({int? start, int? end}) =>
      state = state.copyWith(xhDNDStartMin: start, xhDNDEndMin: end);
  void setNickname(String n) => state = state.copyWith(userNickname: n);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
