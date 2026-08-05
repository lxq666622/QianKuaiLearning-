import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/all_models.dart';
import '../services/database_service.dart';
import '../services/xinghui_ai_engine.dart';
import '../utils/constants.dart';
import 'intimacy_provider.dart';

class XingHuiState {
  final XHInteractionMode mode;
  final List<XHMessageModel> messages;
  final bool isTyping;
  final XingHuiIdentity identity;
  final XingHuiLoveMode loveMode;
  final String userNickname;
  final int intimacyLevel;
  final String? lastActionHint;
  final int? avatarEmotion;
  const XingHuiState({
    this.mode = XHInteractionMode.interact,
    this.messages = const [],
    this.isTyping = false,
    this.identity = XingHuiIdentity.daily,
    this.loveMode = XingHuiLoveMode.defaultLover,
    this.userNickname = '倩',
    this.intimacyLevel = 1,
    this.lastActionHint,
    this.avatarEmotion = 0,
  });
  XingHuiState copyWith({
    XHInteractionMode? mode, List<XHMessageModel>? messages,
    bool? isTyping, XingHuiIdentity? identity, XingHuiLoveMode? loveMode,
    String? userNickname, int? intimacyLevel, String? lastActionHint,
    int? avatarEmotion, bool clearActionHint=false,
  }) => XingHuiState(
    mode: mode ?? this.mode, messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping, identity: identity ?? this.identity,
    loveMode: loveMode ?? this.loveMode,
    userNickname: userNickname ?? this.userNickname,
    intimacyLevel: intimacyLevel ?? this.intimacyLevel,
    lastActionHint: clearActionHint ? null : (lastActionHint ?? this.lastActionHint),
    avatarEmotion: avatarEmotion ?? this.avatarEmotion,
  );
}

class XingHuiNotifier extends StateNotifier<XingHuiState> {
  final DatabaseService _db = DatabaseService.instance;
  final XingHuiAIEngine _ai = XingHuiAIEngine();
  final Ref _ref;
  bool _alive = true;
  XingHuiNotifier(this._ref) : super(const XingHuiState()) { _load(); }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _db.getXHSettings();
    final msgs = await _db.getXHMessages();
    final id = _idFromName(s.currentIdentity);
    final md = _modeFromName(s.currentMode);
    _ai.identity = id;
    _ai.mode = md;
    super.state = XingHuiState(
      messages: msgs, identity: id, loveMode: md,
      userNickname: s.userNickname, intimacyLevel: s.intimacyLevel,
    );
  }
  static XingHuiIdentity _idFromName(String n) =>
      switch(n){
        '深空猎人' => XingHuiIdentity.hunter,
        '特警ST1101' => XingHuiIdentity.police,
        '圣剑王储' => XingHuiIdentity.prince,
        _ => XingHuiIdentity.daily,
      };
  static XingHuiLoveMode _modeFromName(String n) =>
      switch(n){
        '疏离礼貌' => XingHuiLoveMode.distant,
        '守护执念' => XingHuiLoveMode.protective,
        '别扭吃醋' => XingHuiLoveMode.jealous,
        '软感亲昵' => XingHuiLoveMode.intimate,
        _ => XingHuiLoveMode.defaultLover,
      };

  void setMode(XHInteractionMode m) => super.state = super.state.copyWith(mode: m);

  Future<void> setIdentity(XingHuiIdentity i) async {
    _ai.identity = i;
    final s = await _db.getXHSettings();
    await _db.saveXHSettings(s.copyWith(currentIdentity: i.name));
    super.state = super.state.copyWith(identity: i, lastActionHint: '（身份切换：${i.name}）',
        avatarEmotion: 0);
  }
  Future<void> setLoveMode(XingHuiLoveMode m) async {
    _ai.mode = m;
    final s = await _db.getXHSettings();
    final names = {
      XingHuiLoveMode.distant:'疏离礼貌',
      XingHuiLoveMode.defaultLover:'默认恋人',
      XingHuiLoveMode.protective:'守护执念',
      XingHuiLoveMode.jealous:'别扭吃醋',
      XingHuiLoveMode.intimate:'软感亲昵',
    };
    await _db.saveXHSettings(s.copyWith(currentMode: names[m]!));
    super.state = super.state.copyWith(loveMode: m);
  }

  Future<void> sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final userMsg = XHMessageModel(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      content: t, isFromUser: true, timestamp: DateTime.now(),
      identityContext: super.state.identity.name,
      modeContext: _modeNames[super.state.loveMode]!,
      intimacyLevelAtSend: super.state.intimacyLevel,
    );
    final all = [...super.state.messages, userMsg];
    super.state = super.state.copyWith(messages: all, isTyping: true, avatarEmotion: 3);
    await _db.insertXHMessage(userMsg);
    await Future.delayed(const Duration(milliseconds: 550));
    final trig = _ai.detectTriggerFromText(t);
    final resp = _ai.generate(
      trigger: trig, intimacyLevel: super.state.intimacyLevel,
      userNickname: super.state.userNickname,
    );
    final content = '【动作】${resp.action}\n【台词】${resp.dialogue}';
    final aiMsg = XHMessageModel(
      id: 'x${DateTime.now().microsecondsSinceEpoch}',
      content: content, isFromUser: false, timestamp: DateTime.now(),
      messageType: resp.pauseMark,
      identityContext: super.state.identity.name,
      modeContext: _modeNames[super.state.loveMode]!,
      intimacyLevelAtSend: super.state.intimacyLevel,
    );
    await _db.insertXHMessage(aiMsg);
    final after = [...all, aiMsg];
    await _ref.read(intimacyProvider.notifier).onChatRoundEnd();
    super.state = super.state.copyWith(
      messages: after,
      isTyping: false,
      lastActionHint: resp.action,
      avatarEmotion: 1,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (_alive) super.state = super.state.copyWith(clearActionHint: true, avatarEmotion: 0);
    });
  }

  Future<void> tapPart(XingHuiTrigger part) async {
    if (part == XingHuiTrigger.tapHand && super.state.intimacyLevel < 5) {
      final r = _ai.generate(trigger: XingHuiTrigger.tapPalm,
          intimacyLevel: super.state.intimacyLevel, userNickname: super.state.userNickname);
      super.state = super.state.copyWith(lastActionHint: r.action, avatarEmotion: 2);
      return;
    }
    if (part == XingHuiTrigger.tapHug && super.state.intimacyLevel < 10) {
      final r = _ai.generate(trigger: XingHuiTrigger.tapShoulder,
          intimacyLevel: super.state.intimacyLevel, userNickname: super.state.userNickname);
      super.state = super.state.copyWith(lastActionHint: r.action, avatarEmotion: 2);
      return;
    }
    final resp = _ai.generate(
      trigger: part, intimacyLevel: super.state.intimacyLevel,
      userNickname: super.state.userNickname,
    );
    super.state = super.state.copyWith(
      lastActionHint: resp.action,
      avatarEmotion: part == XingHuiTrigger.tapHead || part == XingHuiTrigger.tapCheek
          ? 2 : 1,
    );
    await _ref.read(intimacyProvider.notifier).add(1, reason: '触碰');
    Future.delayed(const Duration(seconds: 3), () {
      if (_alive) super.state = super.state.copyWith(clearActionHint: true, avatarEmotion: 0);
    });
  }
  static const Map<XingHuiLoveMode, String> _modeNames = {
    XingHuiLoveMode.distant: '疏离礼貌',
    XingHuiLoveMode.defaultLover: '默认恋人',
    XingHuiLoveMode.protective: '守护执念',
    XingHuiLoveMode.jealous: '别扭吃醋',
    XingHuiLoveMode.intimate: '软感亲昵',
  };
}

final xinghuiProvider = StateNotifierProvider<XingHuiNotifier, XingHuiState>(
  (ref) => XingHuiNotifier(ref),
);
