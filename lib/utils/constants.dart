import 'package:flutter/material.dart';

// ==========================================================================
// UI设计规范常量（需求#12）
// ==========================================================================
class AppColors {
  static const emeraldGreen = Color(0xFF0D7377);
  static const neonCyan = Color(0xFF14FFEC);
  static const skyBlue = Color(0xFF87CEEB);
  static const xingHuiBubble = Color(0xFFD9EEF7);
  static const xingHuiSilver = Color(0xFFF2F2F8);
  static const cardWhite = Color(0xD9FFFFFF); // white.withOpacity(0.85)

  // 羁绊徽章四档色
  static const badgeSilver = Color(0xFFBFC0C7);
  static const badgeGold = Color(0xFFFFD700);
  static const badgeRoseGold = Color(0xFFB76E79);
  static const badgeStarlight = Color(0xFF99CCFF);

  // 属性条四色
  static const vocabGreen = Color(0xFF4CAF50);
  static const listeningBlue = Color(0xFF2196F3);
  static const speakingOrange = Color(0xFFFF9800);
  static const readingPurple = Color(0xFF9C27B0);

  static const scaffoldLight = Color(0xFFEAF6F6);
  static const scaffoldDark = Color(0xFF0B2A2E);
}

// ==========================================================================
// 停用词表（WordExtractor）
// ==========================================================================
const Set<String> kStopWords = {
  'the','a','an','and','or','but','if','then','else','of','in','on','at','to','for','with',
  'by','from','as','is','was','are','were','been','be','have','has','had','do','does','did',
  'will','would','could','should','may','might','can','i','you','he','she','it','we','they',
  'me','him','her','us','them','my','your','his','its','our','their','this','that','these',
  'those','there','here','what','which','who','whom','when','where','why','how','not','no',
  'yes','so','than','too','very','just','about','also','only','more','most','some','any',
  'such','all','each','every','both','few','many','much','own','same','am','up','out','over',
  'into','after','before','between','through','during','without','within','along','across',
  'behind','below','above','under','again','further','once','because','until','while',
};

// ==========================================================================
// 身份形象（一级参数，需求#9.6）
// ==========================================================================
enum XingHuiIdentity { daily, hunter, police, prince }
extension XingHuiIdentityX on XingHuiIdentity {
  String get name => switch(this){
    XingHuiIdentity.daily => '日常闲居',
    XingHuiIdentity.hunter => '深空猎人',
    XingHuiIdentity.police => '特警ST1101',
    XingHuiIdentity.prince => '圣剑王储',
  };
  Color get themeColor => switch(this){
    XingHuiIdentity.daily => const Color(0xFFF5F1EB),
    XingHuiIdentity.hunter => const Color(0xFF1A1A2A),
    XingHuiIdentity.police => const Color(0xFF1E3A5F),
    XingHuiIdentity.prince => const Color(0xFFEFE6C4),
  };
  static XingHuiIdentity parse(String s) => XingHuiIdentity.values.firstWhere(
    (e)=>e.name==s, orElse: ()=>XingHuiIdentity.daily,
  );
}

// ==========================================================================
// 恋爱模式（二级参数，需求#9.6）
// ==========================================================================
enum XingHuiLoveMode { distant, defaultLover, protective, jealous, intimate }
extension XingHuiLoveModeX on XingHuiLoveMode {
  String get name => switch(this){
    XingHuiLoveMode.distant => '疏离礼貌',
    XingHuiLoveMode.defaultLover => '默认恋人',
    XingHuiLoveMode.protective => '守护执念',
    XingHuiLoveMode.jealous => '别扭吃醋',
    XingHuiLoveMode.intimate => '软感亲昵',
  };
  static XingHuiLoveMode parse(String s) => XingHuiLoveMode.values.firstWhere(
    (e)=>e.name==s, orElse: ()=>XingHuiLoveMode.defaultLover,
  );
}

// ==========================================================================
// 交互事件触发（三级参数，需求#9.6）
// ==========================================================================
enum XingHuiTrigger {
  tapHead, tapCheek, tapPalm, tapShoulder, tapHand, tapHug,
  morning, noon, goodnight, exclusiveGoodnight,
  userSad, userHappy, userSick, userStudyDone, userUpset,
  defaultTrigger,
}
extension XingHuiTriggerX on XingHuiTrigger {
  String get label => switch(this){
    XingHuiTrigger.tapHead => '点击头顶',
    XingHuiTrigger.tapCheek => '点击脸颊',
    XingHuiTrigger.tapPalm => '点击手掌',
    XingHuiTrigger.tapShoulder => '点击肩膀',
    XingHuiTrigger.tapHand => '点击牵手',
    XingHuiTrigger.tapHug => '点击拥抱',
    XingHuiTrigger.morning => '早安',
    XingHuiTrigger.noon => '午间休息',
    XingHuiTrigger.goodnight => '晚安',
    XingHuiTrigger.exclusiveGoodnight => '专属晚安',
    XingHuiTrigger.userSad => '用户难过',
    XingHuiTrigger.userHappy => '用户开心',
    XingHuiTrigger.userSick => '用户生病',
    XingHuiTrigger.userStudyDone => '用户完成学习',
    XingHuiTrigger.userUpset => '用户倾诉委屈',
    XingHuiTrigger.defaultTrigger => '闲置状态',
  };
}

// ==========================================================================
// 交互模式（星回页面三态）
// ==========================================================================
enum XHInteractionMode { interact, typing, voice }

// ==========================================================================
// 帧率场景（需求#10 帧率分级）
// ==========================================================================
enum FrameRateScene {
  idle24fps,   // 待机 24-30 FPS
  interact60fps, // 交互 固定 60 FPS
  cg60fps    // 成品CG 60 FPS
}
extension FrameRateSceneX on FrameRateScene {
  int get targetFps => switch(this){
    FrameRateScene.idle24fps => 24,
    FrameRateScene.interact60fps => 60,
    FrameRateScene.cg60fps => 60,
  };
  String get assetTag => switch(this){
    FrameRateScene.idle24fps => 'idle_24fps',
    FrameRateScene.interact60fps => 'interact_60fps',
    FrameRateScene.cg60fps => 'cg_60fps',
  };
}

// ==========================================================================
// 亲密度等级要求（1→Lv1：0，Lv2：30，……，Lv20：5280）
// ==========================================================================
const List<int> kIntimacyLevelRequirements = [
  0,30,70,120,180,260, 360,480,620,780,960,
  1180,1440,1740,2080,2480, 2960,3560,4320,5280,
];
