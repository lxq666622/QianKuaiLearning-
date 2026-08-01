import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 状态栏沉浸
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  // 通知初始化（允许失败静默）
  try { await initNotifications(); } catch(_) {}
  // 预留：首次启动后动态请求麦克风/通知权限
  try {
    await [Permission.microphone, Permission.notification].request();
  } catch(_) {}
  runApp(const ProviderScope(child: App()));
}
