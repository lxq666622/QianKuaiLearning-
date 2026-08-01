import '../utils/extensions.dart';

// ==========================================================================
// 玩家数据
// ==========================================================================
class PlayerModel {
  final String playerName;
  final int level;
  final int currentXP;
  final int maxXP;
  final int streakDays;
  final DateTime? lastStudyDate;
  final int powerVocab;
  final int powerListening;
  final int powerSpeaking;
  final int powerReading;

  const PlayerModel({
    this.playerName = '倩',
    this.level = 1,
    this.currentXP = 0,
    this.maxXP = 1000,
    this.streakDays = 0,
    this.lastStudyDate,
    this.powerVocab = 0,
    this.powerListening = 0,
    this.powerSpeaking = 0,
    this.powerReading = 0,
  });

  factory PlayerModel.fromMap(Map<String,dynamic> m) => PlayerModel(
    playerName: m['player_name'] as String? ?? '倩',
    level: m['level'] as int? ?? 1,
    currentXP: m['current_xp'] as int? ?? 0,
    maxXP: m['max_xp'] as int? ?? 1000,
    streakDays: m['streak_days'] as int? ?? 0,
    lastStudyDate: m['last_study_date'] == null ? null : DateTimeX.fromUnix(m['last_study_date'] as int?),
    powerVocab: m['power_vocab'] as int? ?? 0,
    powerListening: m['power_listening'] as int? ?? 0,
    powerSpeaking: m['power_speaking'] as int? ?? 0,
    powerReading: m['power_reading'] as int? ?? 0,
  );

  Map<String,dynamic> toMap() => {
    'player_name': playerName,
    'level': level,
    'current_xp': currentXP,
    'max_xp': maxXP,
    'streak_days': streakDays,
    'last_study_date': lastStudyDate?.unixMillis,
    'power_vocab': powerVocab,
    'power_listening': powerListening,
    'power_speaking': powerSpeaking,
    'power_reading': powerReading,
  };

  PlayerModel copyWith({
    String? playerName, int? level, int? currentXP, int? maxXP, int? streakDays,
    DateTime? lastStudyDate, int? powerVocab, int? powerListening,
    int? powerSpeaking, int? powerReading,
  }) => PlayerModel(
    playerName: playerName ?? this.playerName,
    level: level ?? this.level,
    currentXP: currentXP ?? this.currentXP,
    maxXP: maxXP ?? this.maxXP,
    streakDays: streakDays ?? this.streakDays,
    lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    powerVocab: powerVocab ?? this.powerVocab,
    powerListening: powerListening ?? this.powerListening,
    powerSpeaking: powerSpeaking ?? this.powerSpeaking,
    powerReading: powerReading ?? this.powerReading,
  );
}

// ==========================================================================
// 单词
// ==========================================================================
class WordModel {
  final int? id;
  final String word;
  final String? phonetic;
  final String meaning;
  final String exampleSentence;
  final String wordType; // read/write
  final int proficiency; // 0-5
  final DateTime nextReviewDate;
  final int reviewCount;
  final String source;
  final int frequency;
  final bool isUserAdded;

  const WordModel({
    this.id,
    required this.word,
    this.phonetic,
    required this.meaning,
    required this.exampleSentence,
    this.wordType = 'read',
    this.proficiency = 0,
    required this.nextReviewDate,
    this.reviewCount = 0,
    this.source = 'builtin',
    this.frequency = 1,
    this.isUserAdded = false,
  });

  factory WordModel.fromMap(Map<String,dynamic> m) => WordModel(
    id: m['id'] as int?,
    word: m['word'] as String,
    phonetic: m['phonetic'] as String?,
    meaning: m['meaning'] as String,
    exampleSentence: m['example_sentence'] as String? ?? '',
    wordType: m['word_type'] as String? ?? 'read',
    proficiency: m['proficiency'] as int? ?? 0,
    nextReviewDate: DateTimeX.fromUnix(m['next_review_date'] as int?),
    reviewCount: m['review_count'] as int? ?? 0,
    source: m['source'] as String? ?? 'builtin',
    frequency: m['frequency'] as int? ?? 1,
    isUserAdded: (m['is_user_added'] as int? ?? 0) == 1,
  );

  Map<String,dynamic> toMap() => {
    if (id != null) 'id': id,
    'word': word,
    'phonetic': phonetic,
    'meaning': meaning,
    'example_sentence': exampleSentence,
    'word_type': wordType,
    'proficiency': proficiency,
    'next_review_date': nextReviewDate.unixMillis,
    'review_count': reviewCount,
    'source': source,
    'frequency': frequency,
    'is_user_added': isUserAdded ? 1 : 0,
  };
  WordModel copyWith({
    int? id, String? word, String? phonetic, String? meaning,
    String? exampleSentence, String? wordType, int? proficiency,
    DateTime? nextReviewDate, int? reviewCount, String? source,
    int? frequency, bool? isUserAdded,
  }) => WordModel(
    id: id ?? this.id,
    word: word ?? this.word,
    phonetic: phonetic ?? this.phonetic,
    meaning: meaning ?? this.meaning,
    exampleSentence: exampleSentence ?? this.exampleSentence,
    wordType: wordType ?? this.wordType,
    proficiency: proficiency ?? this.proficiency,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    reviewCount: reviewCount ?? this.reviewCount,
    source: source ?? this.source,
    frequency: frequency ?? this.frequency,
    isUserAdded: isUserAdded ?? this.isUserAdded,
  );
}

// ==========================================================================
// 歌曲
// ==========================================================================
class SongModel {
  final int? id;
  final String title;
  final String artist;
  final String audioPath;
  final String lyricsContent;
  final bool isLRC;
  final DateTime importDate;

  const SongModel({
    this.id,
    required this.title,
    this.artist = '未知歌手',
    required this.audioPath,
    required this.lyricsContent,
    this.isLRC = false,
    required this.importDate,
  });

  factory SongModel.fromMap(Map<String,dynamic> m) => SongModel(
    id: m['id'] as int?,
    title: m['title'] as String,
    artist: m['artist'] as String? ?? '未知歌手',
    audioPath: m['audio_path'] as String,
    lyricsContent: m['lyrics_content'] as String? ?? '',
    isLRC: (m['is_lrc'] as int? ?? 0) == 1,
    importDate: DateTimeX.fromUnix(m['import_date'] as int?),
  );

  Map<String,dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'artist': artist,
    'audio_path': audioPath,
    'lyrics_content': lyricsContent,
    'is_lrc': isLRC ? 1 : 0,
    'import_date': importDate.unixMillis,
  };
}

// ==========================================================================
// 成就
// ==========================================================================
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockDate;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockDate,
    this.xpReward = 100,
  });

  factory AchievementModel.fromMap(Map<String,dynamic> m) => AchievementModel(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String? ?? '',
    icon: m['icon'] as String? ?? 'star',
    isUnlocked: (m['is_unlocked'] as int? ?? 0) == 1,
    unlockDate: m['unlock_date'] == null ? null : DateTimeX.fromUnix(m['unlock_date'] as int?),
    xpReward: m['xp_reward'] as int? ?? 100,
  );

  Map<String,dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'is_unlocked': isUnlocked ? 1 : 0,
    'unlock_date': unlockDate?.unixMillis,
    'xp_reward': xpReward,
  };
  AchievementModel copyWith({
    String? id, String? title, String? description, String? icon,
    bool? isUnlocked, DateTime? unlockDate, int? xpReward,
  }) => AchievementModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockDate: unlockDate ?? this.unlockDate,
    xpReward: xpReward ?? this.xpReward,
  );
}

// ==========================================================================
// 沈星回消息
// ==========================================================================
class XHMessageModel {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final String messageType;
  final bool isRead;
  final String identityContext;
  final String modeContext;
  final int intimacyLevelAtSend;

  const XHMessageModel({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.messageType = 'reply',
    this.isRead = false,
    this.identityContext = '日常闲居',
    this.modeContext = '默认恋人',
    this.intimacyLevelAtSend = 1,
  });

  factory XHMessageModel.fromMap(Map<String,dynamic> m) => XHMessageModel(
    id: m['id'] as String,
    content: m['content'] as String,
    isFromUser: (m['is_from_user'] as int? ?? 0) == 1,
    timestamp: DateTimeX.fromUnix(m['timestamp'] as int?),
    messageType: m['message_type'] as String? ?? 'reply',
    isRead: (m['is_read'] as int? ?? 0) == 1,
    identityContext: m['identity_context'] as String? ?? '日常闲居',
    modeContext: m['mode_context'] as String? ?? '默认恋人',
    intimacyLevelAtSend: m['intimacy_level_at_send'] as int? ?? 1,
  );

  Map<String,dynamic> toMap() => {
    'id': id,
    'content': content,
    'is_from_user': isFromUser ? 1 : 0,
    'timestamp': timestamp.unixMillis,
    'message_type': messageType,
    'is_read': isRead ? 1 : 0,
    'identity_context': identityContext,
    'mode_context': modeContext,
    'intimacy_level_at_send': intimacyLevelAtSend,
  };
}

// ==========================================================================
// 亲密度解锁
// ==========================================================================
class IntimacyUnlockModel {
  final int level;
  final String unlockName;
  final String unlockDescription;
  final bool isUnlocked;
  final DateTime? unlockDate;

  const IntimacyUnlockModel({
    required this.level,
    required this.unlockName,
    required this.unlockDescription,
    this.isUnlocked = false,
    this.unlockDate,
  });

  factory IntimacyUnlockModel.fromMap(Map<String,dynamic> m) => IntimacyUnlockModel(
    level: m['level'] as int,
    unlockName: m['unlock_name'] as String,
    unlockDescription: m['unlock_description'] as String? ?? '',
    isUnlocked: (m['is_unlocked'] as int? ?? 0) == 1,
    unlockDate: m['unlock_date'] == null ? null : DateTimeX.fromUnix(m['unlock_date'] as int?),
  );

  Map<String,dynamic> toMap() => {
    'level': level,
    'unlock_name': unlockName,
    'unlock_description': unlockDescription,
    'is_unlocked': isUnlocked ? 1 : 0,
    'unlock_date': unlockDate?.unixMillis,
  };
}

// ==========================================================================
// 解析出来的单词
// ==========================================================================
class ExtractedWordModel {
  final String word;
  final int frequency;
  final String exampleSentence;
  bool selected;

  ExtractedWordModel({
    required this.word,
    required this.frequency,
    required this.exampleSentence,
    this.selected = false,
  });
}

// ==========================================================================
// 每日副本任务
// ==========================================================================
class DailyTaskModel {
  final int? id;
  final DateTime date;
  final bool vocabCompleted;
  final bool listeningCompleted;
  final bool speakingCompleted;
  final int vocabMinutes;
  final int listeningMinutes;
  final int speakingMinutes;
  final int totalXP;

  const DailyTaskModel({
    this.id,
    required this.date,
    this.vocabCompleted = false,
    this.listeningCompleted = false,
    this.speakingCompleted = false,
    this.vocabMinutes = 0,
    this.listeningMinutes = 0,
    this.speakingMinutes = 0,
    this.totalXP = 0,
  });

  factory DailyTaskModel.fromMap(Map<String,dynamic> m) => DailyTaskModel(
    id: m['id'] as int?,
    date: DateTimeX.fromUnix(m['date'] as int?),
    vocabCompleted: (m['vocab_completed'] as int? ?? 0) == 1,
    listeningCompleted: (m['listening_completed'] as int? ?? 0) == 1,
    speakingCompleted: (m['speaking_completed'] as int? ?? 0) == 1,
    vocabMinutes: m['vocab_minutes'] as int? ?? 0,
    listeningMinutes: m['listening_minutes'] as int? ?? 0,
    speakingMinutes: m['speaking_minutes'] as int? ?? 0,
    totalXP: m['total_xp'] as int? ?? 0,
  );

  Map<String,dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date.dayStart,
    'vocab_completed': vocabCompleted ? 1 : 0,
    'listening_completed': listeningCompleted ? 1 : 0,
    'speaking_completed': speakingCompleted ? 1 : 0,
    'vocab_minutes': vocabMinutes,
    'listening_minutes': listeningMinutes,
    'speaking_minutes': speakingMinutes,
    'total_xp': totalXP,
  };
  DailyTaskModel copyWith({
    int? id, DateTime? date, bool? vocabCompleted, bool? listeningCompleted,
    bool? speakingCompleted, int? vocabMinutes, int? listeningMinutes,
    int? speakingMinutes, int? totalXP,
  }) => DailyTaskModel(
    id: id ?? this.id,
    date: date ?? this.date,
    vocabCompleted: vocabCompleted ?? this.vocabCompleted,
    listeningCompleted: listeningCompleted ?? this.listeningCompleted,
    speakingCompleted: speakingCompleted ?? this.speakingCompleted,
    vocabMinutes: vocabMinutes ?? this.vocabMinutes,
    listeningMinutes: listeningMinutes ?? this.listeningMinutes,
    speakingMinutes: speakingMinutes ?? this.speakingMinutes,
    totalXP: totalXP ?? this.totalXP,
  );
}

// ==========================================================================
// 口语记录
// ==========================================================================
class SpeakingRecordModel {
  final int? id;
  final String word;
  final String userSentence;
  final String recordedAudioPath;
  final DateTime date;
  final int score;

  const SpeakingRecordModel({
    this.id,
    required this.word,
    required this.userSentence,
    required this.recordedAudioPath,
    required this.date,
    this.score = 0,
  });

  factory SpeakingRecordModel.fromMap(Map<String,dynamic> m) => SpeakingRecordModel(
    id: m['id'] as int?,
    word: m['word'] as String,
    userSentence: m['user_sentence'] as String? ?? '',
    recordedAudioPath: m['recorded_audio_path'] as String,
    date: DateTimeX.fromUnix(m['date'] as int?),
    score: m['score'] as int? ?? 0,
  );

  Map<String,dynamic> toMap() => {
    if (id != null) 'id': id,
    'word': word,
    'user_sentence': userSentence,
    'recorded_audio_path': recordedAudioPath,
    'date': date.unixMillis,
    'score': score,
  };
}

// ==========================================================================
// 星回全局设置（11.2需求）
// ==========================================================================
class XHSettingsModel {
  final int id;
  final bool isEnabled;
  final int dailyPushLimit;
  final int doNotDisturbStart; // 分钟数：1380=23:00
  final int doNotDisturbEnd;
  final String reminderItems; // JSON字符串
  final String currentIdentity;
  final String currentMode;
  final String userNickname;
  final int intimacyValue;
  final int intimacyLevel;
  final int totalChatRounds;
  final int daysKnown;

  const XHSettingsModel({
    this.id = 1,
    this.isEnabled = true,
    this.dailyPushLimit = 3,
    this.doNotDisturbStart = 1380,
    this.doNotDisturbEnd = 420,
    this.reminderItems = '[]',
    this.currentIdentity = '日常闲居',
    this.currentMode = '默认恋人',
    this.userNickname = '倩',
    this.intimacyValue = 0,
    this.intimacyLevel = 1,
    this.totalChatRounds = 0,
    this.daysKnown = 1,
  });

  factory XHSettingsModel.fromMap(Map<String,dynamic> m) => XHSettingsModel(
    id: m['id'] as int? ?? 1,
    isEnabled: (m['is_enabled'] as int? ?? 1) == 1,
    dailyPushLimit: m['daily_push_limit'] as int? ?? 3,
    doNotDisturbStart: m['do_not_disturb_start'] as int? ?? 1380,
    doNotDisturbEnd: m['do_not_disturb_end'] as int? ?? 420,
    reminderItems: m['reminder_items'] as String? ?? '[]',
    currentIdentity: m['current_identity'] as String? ?? '日常闲居',
    currentMode: m['current_mode'] as String? ?? '默认恋人',
    userNickname: m['user_nickname'] as String? ?? '倩',
    intimacyValue: m['intimacy_value'] as int? ?? 0,
    intimacyLevel: m['intimacy_level'] as int? ?? 1,
    totalChatRounds: m['total_chat_rounds'] as int? ?? 0,
    daysKnown: m['days_known'] as int? ?? 1,
  );

  Map<String,dynamic> toMap() => {
    'id': id,
    'is_enabled': isEnabled ? 1 : 0,
    'daily_push_limit': dailyPushLimit,
    'do_not_disturb_start': doNotDisturbStart,
    'do_not_disturb_end': doNotDisturbEnd,
    'reminder_items': reminderItems,
    'current_identity': currentIdentity,
    'current_mode': currentMode,
    'user_nickname': userNickname,
    'intimacy_value': intimacyValue,
    'intimacy_level': intimacyLevel,
    'total_chat_rounds': totalChatRounds,
    'days_known': daysKnown,
  };
  XHSettingsModel copyWith({
    int? id, bool? isEnabled, int? dailyPushLimit, int? doNotDisturbStart,
    int? doNotDisturbEnd, String? reminderItems, String? currentIdentity,
    String? currentMode, String? userNickname, int? intimacyValue,
    int? intimacyLevel, int? totalChatRounds, int? daysKnown,
  }) => XHSettingsModel(
    id: id ?? this.id,
    isEnabled: isEnabled ?? this.isEnabled,
    dailyPushLimit: dailyPushLimit ?? this.dailyPushLimit,
    doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
    doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
    reminderItems: reminderItems ?? this.reminderItems,
    currentIdentity: currentIdentity ?? this.currentIdentity,
    currentMode: currentMode ?? this.currentMode,
    userNickname: userNickname ?? this.userNickname,
    intimacyValue: intimacyValue ?? this.intimacyValue,
    intimacyLevel: intimacyLevel ?? this.intimacyLevel,
    totalChatRounds: totalChatRounds ?? this.totalChatRounds,
    daysKnown: daysKnown ?? this.daysKnown,
  );
}
