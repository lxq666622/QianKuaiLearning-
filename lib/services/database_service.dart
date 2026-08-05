import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/all_models.dart';
import '../utils/sample_data.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

// ==========================================================================
// sqflite 原生数据库服务（替代CoreData）
// 11张表：需求11.2 + 需求9.10
// ==========================================================================
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'qiankuai_learning.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (d) async { await d.execute('PRAGMA foreign_keys = ON;'); },
    );
  }

  // ========= 11张表建表SQL =========================================================
  Future<void> _onCreate(Database db, int version) async {
    final b = db.batch();
    // 1. player 玩家表
    b.execute('''CREATE TABLE player(
      player_name TEXT PRIMARY KEY,
      level INTEGER NOT NULL DEFAULT 1,
      current_xp INTEGER NOT NULL DEFAULT 0,
      max_xp INTEGER NOT NULL DEFAULT 1000,
      streak_days INTEGER NOT NULL DEFAULT 0,
      last_study_date INTEGER,
      power_vocab INTEGER NOT NULL DEFAULT 0,
      power_listening INTEGER NOT NULL DEFAULT 0,
      power_speaking INTEGER NOT NULL DEFAULT 0,
      power_reading INTEGER NOT NULL DEFAULT 0)''');
    // 2. words 单词表
    b.execute('''CREATE TABLE words(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT UNIQUE NOT NULL,
      phonetic TEXT,
      meaning TEXT NOT NULL,
      example_sentence TEXT NOT NULL DEFAULT '',
      word_type TEXT NOT NULL DEFAULT 'read',
      proficiency INTEGER NOT NULL DEFAULT 0,
      next_review_date INTEGER NOT NULL,
      review_count INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'builtin',
      frequency INTEGER NOT NULL DEFAULT 1,
      is_user_added INTEGER NOT NULL DEFAULT 0)''');
    // 3. imported_files 导入文件表
    b.execute('''CREATE TABLE imported_files(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_name TEXT NOT NULL,
      file_type TEXT NOT NULL,
      import_date INTEGER NOT NULL,
      extracted_word_count INTEGER NOT NULL DEFAULT 0)''');
    // 4. songs 歌曲表
    b.execute('''CREATE TABLE songs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist TEXT NOT NULL DEFAULT '未知歌手',
      audio_path TEXT NOT NULL,
      lyrics_content TEXT NOT NULL DEFAULT '',
      is_lrc INTEGER NOT NULL DEFAULT 0,
      import_date INTEGER NOT NULL)''');
    // 5. achievements 成就表
    b.execute('''CREATE TABLE achievements(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      icon TEXT NOT NULL DEFAULT 'star',
      is_unlocked INTEGER NOT NULL DEFAULT 0,
      unlock_date INTEGER,
      xp_reward INTEGER NOT NULL DEFAULT 100)''');
    // 6. daily_tasks 每日任务表
    b.execute('''CREATE TABLE daily_tasks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date INTEGER NOT NULL UNIQUE,
      vocab_completed INTEGER NOT NULL DEFAULT 0,
      listening_completed INTEGER NOT NULL DEFAULT 0,
      speaking_completed INTEGER NOT NULL DEFAULT 0,
      vocab_minutes INTEGER NOT NULL DEFAULT 0,
      listening_minutes INTEGER NOT NULL DEFAULT 0,
      speaking_minutes INTEGER NOT NULL DEFAULT 0,
      total_xp INTEGER NOT NULL DEFAULT 0)''');
    // 7. speaking_records 口语记录
    b.execute('''CREATE TABLE speaking_records(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      user_sentence TEXT NOT NULL DEFAULT '',
      recorded_audio_path TEXT NOT NULL,
      date INTEGER NOT NULL,
      score INTEGER NOT NULL DEFAULT 0)''');
    // 8. xinghui_messages 星回消息
    b.execute('''CREATE TABLE xinghui_messages(
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      is_from_user INTEGER NOT NULL,
      timestamp INTEGER NOT NULL,
      message_type TEXT NOT NULL DEFAULT 'reply',
      is_read INTEGER NOT NULL DEFAULT 0,
      identity_context TEXT NOT NULL DEFAULT '日常闲居',
      mode_context TEXT NOT NULL DEFAULT '默认恋人',
      intimacy_level_at_send INTEGER NOT NULL DEFAULT 1)''');
    // 9. xinghui_settings 星回设置（1条记录
    b.execute('''CREATE TABLE xinghui_settings(
      id INTEGER PRIMARY KEY,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      daily_push_limit INTEGER NOT NULL DEFAULT 3,
      do_not_disturb_start INTEGER NOT NULL DEFAULT 1380,
      do_not_disturb_end INTEGER NOT NULL DEFAULT 420,
      reminder_items TEXT NOT NULL DEFAULT '[]',
      current_identity TEXT NOT NULL DEFAULT '日常闲居',
      current_mode TEXT NOT NULL DEFAULT '默认恋人',
      user_nickname TEXT NOT NULL DEFAULT '倩',
      intimacy_value INTEGER NOT NULL DEFAULT 0,
      intimacy_level INTEGER NOT NULL DEFAULT 1,
      total_chat_rounds INTEGER NOT NULL DEFAULT 0,
      days_known INTEGER NOT NULL DEFAULT 1)''');
    // 10. xinghui_reply_templates 回复模板
    b.execute('''CREATE TABLE xinghui_reply_templates(
      id TEXT PRIMARY KEY,
      category TEXT NOT NULL,
      trigger_keywords TEXT NOT NULL DEFAULT '[]',
      responses TEXT NOT NULL DEFAULT '[]')''');
    // 11. intimacy_unlocks 亲密度解锁
    b.execute('''CREATE TABLE intimacy_unlocks(
      level INTEGER PRIMARY KEY,
      unlock_name TEXT NOT NULL,
      unlock_description TEXT NOT NULL DEFAULT '',
      is_unlocked INTEGER NOT NULL DEFAULT 0,
      unlock_date INTEGER)''');

    await b.commit(noResult: true);
    await _injectSampleData(db);
  }

 // ========= 预置数据注入（首次启动）===========================================
  Future<void> _injectSampleData(Database db) async {
    final b = db.batch();
    // 玩家默认
    b.insert('player', SampleData.kDefaultPlayer);
    // 星回设置默认
    b.insert('xinghui_settings', SampleData.kDefaultXHSettings);
    // 50单词
    final now = DateTime.now().unixMillis;
    for (final (w,ph,m,ex,type,fq) in SampleData.kWords50) {
      b.insert('words', {
        'word':w,'phonetic':ph,'meaning':m,'example_sentence':ex,
        'word_type':type,'next_review_date':now,
        'frequency':fq,'source':'builtin','is_user_added':0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // 12成就
    for (final (id,title,desc,icon,xp) in SampleData.kAchievements12) {
      b.insert('achievements', {
        'id':id,'title':title,'description':desc,'icon':icon,'xp_reward':xp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // 7亲密度解锁
    for (final (lv,name,desc) in SampleData.kIntimacyUnlocks7) {
      b.insert('intimacy_unlocks', {
        'level':lv,'unlock_name':name,'unlock_description':desc,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b.commit(noResult: true);
  }

  // ====================================================================
  // 通用CRUD：Player
  // ====================================================================
  Future<PlayerModel> getPlayer() async {
    final rows = await (await db).query('player', limit: 1);
    if (rows.isEmpty) return const PlayerModel();
    return PlayerModel.fromMap(rows.first);
  }
  Future<void> savePlayer(PlayerModel p) async {
    await (await db).insert('player', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ====================================================================
  // CRUD：Words
  // ====================================================================
  Future<List<WordModel>> getWordsToReviewToday() async {
    final now = DateTime.now().unixMillis;
    final rows = await (await db).query(
      'words',
      where: 'next_review_date <= ?',
      whereArgs: [now],
      orderBy: 'frequency DESC, proficiency ASC',
      limit: 50,
    );
    return rows.map((e) => WordModel.fromMap(e)).toList();
  }
  Future<void> upsertWord(WordModel w) async {
    await (await db).insert('words', w.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<int> countWords({bool masteredOnly = false}) async {
    if (!masteredOnly) {
      return Sqflite.firstIntValue(
          await (await db).rawQuery('SELECT COUNT(*) FROM words')) ?? 0;
    }
    return Sqflite.firstIntValue(await (await db).rawQuery(
        'SELECT COUNT(*) FROM words WHERE proficiency >= 3 OR review_count >= 3')) ?? 0;
  }
  Future<void> batchInsertWords(List<WordModel> list) async {
    final b = (await db).batch();
    for (final w in list) {
      b.insert('words', w.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b.commit(noResult: true);
  }

  // ====================================================================
  // CRUD：Achievements
  // ====================================================================
  Future<List<AchievementModel>> getAllAchievements() async {
    final rows = await (await db).query('achievements');
    return rows.map((e) => AchievementModel.fromMap(e)).toList();
  }
  Future<void> markAchievementUnlocked(String id) async {
    await (await db).update('achievements',
        {'is_unlocked':1,'unlock_date': DateTime.now().unixMillis},
        where: 'id = ? AND is_unlocked = 0', whereArgs: [id]);
  }

  // ====================================================================
  // CRUD：Daily Tasks
  // ====================================================================
  Future<DailyTaskModel> getTodayTask() async {
    final today = DateTime.now().dayStart;
    final rows = await (await db).query(
      'daily_tasks', where: 'date = ?', whereArgs: [today], limit: 1,
    );
    if (rows.isEmpty) {
      final t = DailyTaskModel(date: DateTime.now());
      await (await db).insert('daily_tasks', t.toMap());
      return t;
    }
    return DailyTaskModel.fromMap(rows.first);
  }
  Future<void> updateTodayTask(DailyTaskModel t) async {
    await (await db).update('daily_tasks', t.toMap(),
        where: 'date = ?', whereArgs: [t.date.dayStart]);
  }

  // ====================================================================
  // CRUD：Songs / Imported Files / Speaking Records
  // ====================================================================
  Future<List<SongModel>> getAllSongs() async =>
      (await (await db).query('songs', orderBy: 'import_date DESC'))
          .map((e) => SongModel.fromMap(e)).toList();
  Future<void> insertSong(SongModel s) async =>
      (await db).insert('songs', s.toMap());

  // ====================================================================
  // CRUD：XingHui 相关
  // ====================================================================
  Future<XHSettingsModel> getXHSettings() async {
    final rows = await (await db).query('xinghui_settings', limit: 1);
    if (rows.isEmpty) {
      await (await db).insert('xinghui_settings', SampleData.kDefaultXHSettings);
      return const XHSettingsModel();
    }
    return XHSettingsModel.fromMap(rows.first);
  }
  Future<void> saveXHSettings(XHSettingsModel s) async =>
      (await db).insert('xinghui_settings', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<XHMessageModel>> getXHMessages({int limit = 50}) async =>
      (await (await db).query('xinghui_messages',
              orderBy: 'timestamp DESC', limit: limit))
          .reversed.map((e) => XHMessageModel.fromMap(e)).toList();

  Future<void> insertXHMessage(XHMessageModel m) async =>
      (await db).insert('xinghui_messages', m.toMap());

  Future<List<IntimacyUnlockModel>> getIntimacyUnlocks() async =>
      (await (await db).query('intimacy_unlocks', orderBy: 'level'))
          .map((e)=>IntimacyUnlockModel.fromMap(e)).toList();

  Future<void> setIntimacyUnlocked(int level) async =>
      (await db).update('intimacy_unlocks',
          {'is_unlocked':1,'unlock_date':DateTime.now().unixMillis},
          where: 'level = ? AND is_unlocked = 0', whereArgs: [level]);
}
