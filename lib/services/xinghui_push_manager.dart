import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/constants.dart';
import '../models/all_models.dart';
import 'database_service.dart';

// ==========================================================================
// 沈星回3大主动推送体系（需求#9.7）
// 体系A：用户自定义定时提醒
// 体系B：场景化主动关怀（熬夜/久坐/身体不适）
// 体系C：主动日常分享（午后/傍晚）
// 铁则：单日推送数量 ≤ dailyPushLimit（默认3），免打扰时段仅保留健康提醒
// ==========================================================================
class XingHuiPushManager {
  final DatabaseService _db = DatabaseService.instance;
  final _plugin = FlutterLocalNotificationsPlugin();

  DateTime _lastDayReset = DateTime.fromMillisecondsSinceEpoch(0);
  int _todayPushCount = 0;
  DateTime? _lastPushAt;

  final List<String> _sharePool = const [
    '今天胖球又来蹭窗沿了，比昨天胖了一圈。',
    '下午去湖边坐了会儿，钓了条小鱼，放回去了。',
    '试做了新的三明治，这次没翻车。',
    '任务结束，在天台吹会儿风。',
    '今夜的星轨，和菲罗斯星很像。',
  ];

  // 推送限流铁则：单日≤limit，默认3条
  bool _withinLimit(int limit) {
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    if (_lastDayReset.year != today0.year || _lastDayReset.month != today0.month || _lastDayReset.day != today0.day) {
      _todayPushCount = 0;
      _lastDayReset = today0;
    }
    return _todayPushCount < limit;
  }

  // 是否在免打扰时段（健康类除外）
  Future<bool> _isDND(bool healthRelated) async {
    final s = await _db.getXHSettings();
    if (healthRelated) return false;
    final now = DateTime.now();
    final cur = now.hour * 60 + now.minute;
    final start = s.doNotDisturbStart;
    final end = s.doNotDisturbEnd;
    if (start > end) { // 跨天 23:00~07:00
      return cur >= start || cur < end;
    } else {
      return cur >= start && cur < end;
    }
  }

  // ========= 体系A：用户自定义定时提醒 =========
  Future<void> scheduleReminder({
    required int id, required String type, required DateTime time,
  }) async {
    const android = AndroidNotificationDetails('qh_xh','星回提醒', importance: Importance.high);
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    final body = _bodyForReminderType(type);
    await _plugin.zonedSchedule(
      id, '沈星回', body, tz.TZDateTime.from(time, tz.local),
      details, uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String _bodyForReminderType(String t) => switch(t) {
    'morning' => '该起了。早餐温了两次。',
    'water' => '喝水。别等口干才想起来。',
    'exercise' => '起来走两分钟。别久坐。',
    'study' => '该背单词了。别让我等。',
    'sleep' => '还不睡？明天会头疼。',
    'sing' => '嗓子开了吗？该练歌了。',
    _ => '记得做事。'
  };

  // ========= 体系B：场景化主动关怀 =========
  Future<bool?> pushContextualCare(String scene, {bool healthRelated = true}) async {
    final settings = await _db.getXHSettings();
    if (!settings.isEnabled) return null;
    if (await _isDND(healthRelated)) return false;
    if (!_withinLimit(settings.dailyPushLimit)) return false;
    final lv = settings.intimacyLevel;
    final copy = switch(scene) {
      'stay_up' => lv >= 15
          ? '还不睡？你上次说头疼，今天别熬夜。'
          : '还不睡？明天起来会头疼。',
      'sit_long' => '起来走两分钟，别一直坐着。',
      'unwell' => '药放在桌上了，记得涂。',
      'miss_study' => '累了就歇一天，别攒到一起赶。',
      'dungeon_giveup' => '明天再继续，不急。',
      'sing_long' => '嗓子累了就歇会儿。',
      _ => '记得照顾好自己。',
    };
    return _sendLocal(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '沈星回', body: copy, payload: scene,
    );
  }

  // ========= 体系C：主动日常分享（每日0-2次，午后/傍晚）=========
  Future<bool?> pushDailyShare() async {
    final s = await _db.getXHSettings();
    if (!s.isEnabled) return null;
    if (await _isDND(false)) return false;
    if (!_withinLimit(s.dailyPushLimit)) return false;
    final lv = s.intimacyLevel;
    var copy = _sharePool[DateTime.now().millisecond % _sharePool.length];
    if (lv >= 16) copy = '$copy。今天有点累，但听到你的声音就好了。';
    else if (lv >= 10) copy = '$copy。想起你上次说喜欢星星。';
    return _sendLocal(
      id: 10000 + DateTime.now().minute,
      title: '沈星回的日常', body: copy,
    );
  }

  // ========= 底层发推送 =========
  Future<bool> _sendLocal({
    required int id, required String title, required String body, String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'qh_xh_channel','沈星回推送',
      importance: Importance.high, priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    try {
      await _plugin.show(id, title, body, details, payload: payload ?? 'xh_type');
      _todayPushCount += 1;
      _lastPushAt = DateTime.now();
      return true;
    } catch(_) { return false; }
  }

  // ========= 回调：用户5分钟内回复→+20羁绊值（需求#9.3）=========
  Future<int> userRepliedWithin5Min() async {
    if (_lastPushAt == null) return 0;
    final within = DateTime.now().difference(_lastPushAt!).inMinutes <= 5;
    return within ? 20 : 0;
  }
}
