import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

// ==========================================================================
// 沈星回AI返回结构（需求#9.6强制输出格式）
// ==========================================================================
class XHAIResponse {
  final String action;
  final String dialogue;
  final String pauseMark;
  const XHAIResponse({
    required this.action, required this.dialogue, this.pauseMark='短停',
  });
}

// ==========================================================================
// 沈星回结构化AI引擎（需求#9.6）
// 四级参数：身份(4) + 模式(5) + 触发(15) + 亲密度(1-20)
// 人设铁则：短句、克制、不OOC、不油腻、不告白我爱你、不说网络梗
// ==========================================================================
class XingHuiAIEngine {
  XingHuiIdentity identity = XingHuiIdentity.daily;
  XingHuiLoveMode mode = XingHuiLoveMode.defaultLover;

  // ========= 触发 + 四级参数 → 结构化返回 =========
  XHAIResponse generate({
    required XingHuiTrigger trigger,
    required int intimacyLevel, // 1-20
    required String userNickname,
  }) {
    // 亲密度决定：称呼、句子长度、回复温度
    final call = intimacyLevel >= 11 ? userNickname : '你';
    final lineCount = intimacyLevel >= 16
        ? 2
        : intimacyLevel >= 10
            ? (DateTime.now().millisecond % 2 == 0 ? 2 : 1)
            : 1;

    // 【动作】库（严格控制≤30字）
    final action = switch(trigger) {
      XingHuiTrigger.tapHead => '微微偏头抬眸，耳尖泛红。',
      XingHuiTrigger.tapCheek => '愣半秒，垂眸别开脸，唇角极轻勾。',
      XingHuiTrigger.tapPalm => '指尖下意识蜷一下，轻轻回握。',
      XingHuiTrigger.tapShoulder => '身体微僵一瞬，随即放松，侧头。',
      XingHuiTrigger.tapHand => '指尖一顿，缓缓收拢，力道很轻。',
      XingHuiTrigger.tapHug => '身体微僵后放松，手臂环过来，动作很轻。',
      XingHuiTrigger.morning => '抬手揉额发，眼神带刚醒慵懒。',
      XingHuiTrigger.noon => '递出一杯温水。',
      XingHuiTrigger.goodnight => '帮掖被角，动作很轻。',
      XingHuiTrigger.exclusiveGoodnight => '等你呼吸平稳才低声开口。',
      XingHuiTrigger.userSad => '沉默坐下，轻轻拍后背。',
      XingHuiTrigger.userHappy => '唇角勾起极淡弧度，目光柔软。',
      XingHuiTrigger.userSick => '眉头微蹙，伸手探额头。',
      XingHuiTrigger.userStudyDone => '目光微动，极轻点头。',
      XingHuiTrigger.userUpset => '下颌微紧，眼神沉下来。',
      XingHuiTrigger.defaultTrigger => '垂眸看着你，呼吸平稳。',
    };

    // 【台词】库（严格符合语言铁则：短句、清淡、无语气词、温柔藏于陈述句）
    final lines = switch(trigger) {
      XingHuiTrigger.tapHead => ['怎么了？','有事？'],
      XingHuiTrigger.tapCheek => ['别闹。','……调皮。'],
      XingHuiTrigger.tapPalm => [
          '嗯。',
          intimacyLevel >= 5 ? '手怎么这么凉。' : '手别乱动。',
        ],
      XingHuiTrigger.tapShoulder => ['想说什么？','（无声等待）'],
      XingHuiTrigger.tapHand => ['...手怎么这么凉。','别松开。'],
      XingHuiTrigger.tapHug => ['...累了？','（轻轻拍背）'],
      XingHuiTrigger.morning => [
          '醒了？早餐在桌上。',
          if (intimacyLevel >= 11) '$call，起了？',
        ],
      XingHuiTrigger.noon => ['歇会儿，别太累。','起来走两分钟。'],
      XingHuiTrigger.goodnight => ['睡吧，我在。','晚安。'],
      XingHuiTrigger.exclusiveGoodnight => ['晚安。我等你睡了再走。'],
      XingHuiTrigger.userSad => [
          '想哭就哭会儿，我陪着。',
          if (intimacyLevel >= 11) '我在，$call。',
        ],
      XingHuiTrigger.userHappy => ['这么高兴？','不错。'],
      XingHuiTrigger.userSick => ['怎么这么不注意。','药在桌上。'],
      XingHuiTrigger.userStudyDone => ['做得不错。休息吧。','辛苦了。'],
      XingHuiTrigger.userUpset => ['...谁让你受委屈了。','说。'],
      XingHuiTrigger.defaultTrigger => _defaultIdle(mode, intimacyLevel, call),
    };

    // 模式叠加修饰（二级参数，需求#9.6二级恋爱模式）
    var dialogue = lineCount == 1
        ? lines.first
        : lines.take(2).join(' ');
    dialogue = _applyLoveMode(dialogue, mode);

    // 语音停顿标记
    final pause = (trigger == XingHuiTrigger.goodnight ||
            trigger == XingHuiTrigger.exclusiveGoodnight ||
            trigger == XingHuiTrigger.userSad)
        ? '长停'
        : '短停';

    return XHAIResponse(action: action, dialogue: dialogue, pauseMark: pause);
  }

  // 用户文本→Trigger识别（快捷触发）
  XingHuiTrigger detectTriggerFromText(String userText) {
    final s = userText.toLowerCase();
    if (s.contains('早')) return XingHuiTrigger.morning;
    if (s.contains('晚安') || s.contains('睡')) return XingHuiTrigger.goodnight;
    if (s.contains('午') || s.contains('休息')) return XingHuiTrigger.noon;
    if (s.contains('累') || s.contains('难过') || s.contains('哭')) return XingHuiTrigger.userSad;
    if (s.contains('开心') || s.contains('高兴') || s.contains('哈哈')) return XingHuiTrigger.userHappy;
    if (s.contains('病') || s.contains('不舒服') || s.contains('疼')) return XingHuiTrigger.userSick;
    if (s.contains('完成') || s.contains('学完') || s.contains('做完')) return XingHuiTrigger.userStudyDone;
    if (s.contains('委屈') || s.contains('欺负') || s.contains('气')) return XingHuiTrigger.userUpset;
    return XingHuiTrigger.defaultTrigger;
  }

  // ========== 模式叠加（需求#9.6二级参数）==========
  String _applyLoveMode(String line, XingHuiLoveMode mode) {
    return switch(mode) {
      XingHuiLoveMode.distant => line.length > 8 ? '有事？请说。' : line,
      XingHuiLoveMode.jealous => line.contains('？') ? '是吗。' : '（话量骤减）$line',
      XingHuiLoveMode.protective => '$line。别怕，我在。',
      XingHuiLoveMode.intimate => line, // 已经是亲昵级
      XingHuiLoveMode.defaultLover => line,
    };
  }

  // ========== 默认待机语录 ==========
  List<String> _defaultIdle(XingHuiLoveMode mode, int lv, String call) {
    return switch(mode) {
      XingHuiLoveMode.distant => ['有事？', '请说。'],
      XingHuiLoveMode.jealous => ['是吗。', '（话量骤减）'],
      XingHuiLoveMode.protective => ['别怕。', '我在。'],
      XingHuiLoveMode.intimate => [
          lv >= 11 ? '在呢，$call。' : '在。',
          '今天学得怎么样？',
        ],
      XingHuiLoveMode.defaultLover => [
          lv >= 11 ? '嗯？$call。' : '嗯？',
          '有话就说。',
        ],
    };
  }
}
