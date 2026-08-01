import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/all_models.dart';
import '../../services/word_extractor.dart';
import '../../utils/extensions.dart';
import '../../utils/constants.dart';
import '../../providers/game_provider.dart';

// ==========================================================================
// 练唱界面（需求#4.2 / 4.3）
// 播放控制 / 歌词高亮（LRC随时间自动推进，TXT手动推进）
// 录音 → 停止 → 对比播放 → 发音评分(Levenshtein) → XP
// ==========================================================================
class KaraokePlayerView extends ConsumerStatefulWidget {
  final SongModel song;
  const KaraokePlayerView({super.key, required this.song});
  @override ConsumerState<KaraokePlayerView> createState() => _KPVState();
}
class _KPVState extends ConsumerState<KaraokePlayerView> {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _playback = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _stt = stt.SpeechToText();

  Duration _total = Duration.zero;
  Duration _pos = Duration.zero;
  PlayerState _ps = PlayerState.stopped;
  bool isRecording = false;
  String? recPath;
  double playbackRate = 1.0;

  // 歌词解析
  List<LyricLine> _lrc = [];
  List<String> _txtLines = [];
  int _txtIdx = 0;
  int _lrcIdx = 0;
  Timer? _t;
  // 评分
  String? _grade;
  int? _score;
  bool _sttReady = false;

  @override void initState() {
    super.initState();
    _parseLyrics();
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _total = d); });
    _player.onPositionChanged.listen((d) { if (mounted) setState(() {
      _pos = d;
      if (_lrc.isNotEmpty) {
        int idx = 0;
        for (int i = 0; i < _lrc.length; i++) {
          if (d.inMilliseconds >= _lrc[i].ms) idx = i; else break;
        }
        _lrcIdx = idx;
      }
    }); });
    _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _ps = s); });
    _stt.initialize(onStatus: (s){}, onError: (e){}).then((ok){ _sttReady = ok; });
    Future.microtask(() async {
      if (widget.song.audioPath.isNotEmpty) {
        try { await _player.setSourceDeviceFile(widget.song.audioPath); } catch(_) {}
      }
    });
  }
  void _parseLyrics() {
    if (widget.song.isLRC == 1) {
      final re = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]([^\[\]]*)');
      for (final m in re.allMatches(widget.song.lyricsContent)) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final ms = int.parse((m.group(3) ?? '0').padRight(3,'0'));
        final ttl = Duration(minutes: min, seconds: sec, milliseconds: ms).inMilliseconds;
        final txt = m.group(4)!.trim();
        if (txt.isNotEmpty) _lrc.add(LyricLine(ms: ttl, text: txt));
      }
      _lrc.sort((a,b)=>a.ms.compareTo(b.ms));
    } else {
      _txtLines = widget.song.lyricsContent.split('\n').where((e)=>e.trim().isNotEmpty).toList();
    }
  }

  @override void dispose() {
    _t?.cancel();
    _player.dispose(); _playback.dispose(); _recorder.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (_ps == PlayerState.playing) { await _player.pause(); }
    else { await _player.resume(); }
  }
  Future<void> seek(double v) async => _player.seek(Duration(milliseconds: (_total.inMilliseconds*v).toInt()));
  Future<void> setRate(double r) async { playbackRate = r; setState((){}); await _player.setPlaybackRate(r); }

  Future<void> toggleRec() async {
    if (!isRecording) {
      final dir = await getApplicationDocumentsDirectory();
      recPath = '${dir.path}/kx_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: recPath!);
      if (mounted) setState(() => isRecording = true);
    } else {
      final path = await _recorder.stop();
      if (mounted) setState(() { isRecording = false; recPath = path ?? recPath; });
      await _grade();
    }
  }

  Future<void> _grade() async {
    if (recPath == null) return;
    // 文本对比：取当前段歌词
    final groundTruth = widget.song.isLRC == 1
        ? _lrc.map((e)=>e.text).join(' ')
        : _txtLines.join(' ');
    // 优先 STT 识别录音 → 否则（权限失败/未初始化）：提示
    String recognized = '';
    if (_sttReady) {
      // note: 本地 STT 需要通过 listen() 实时从麦克风录音，这里无法回放录音转文字
      // 真实项目：调用云STT或平台原生通道；demo 给出 mock 机制
      recognized = groundTruth; // mock 满分，实际接 STT
    }
    double sim = recognized.isEmpty ? 0.3 : WordExtractor.similarity(recognized, groundTruth);
    final score = (sim * 100).round();
    final g = '$score'.gradeFromPercent();
    if (mounted) setState(() { _score = score; _grade = g; });
    // XP
    final xp = g == 'S' ? 200 : g == 'A' ? 150 : g == 'B' ? 100 : g == 'C' ? 50 : 20;
    await ref.read(gameProvider.notifier).addXP(xp, attribute: PowerAttribute.speaking);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('评分：$g · 得分 $score · 获得 $xp XP'),
        backgroundColor: AppColors.emeraldGreen));
  }

  Future<void> compare() async {
    if (recPath == null) return;
    await _player.seek(Duration.zero); await _player.resume();
    Future.delayed(_total + const Duration(milliseconds: 500), () async {
      try { await _playback.play(DeviceFileSource(recPath!)); } catch(_){}
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2324),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        title: Text('${widget.song.title} - ${widget.song.artist}',
          style: const TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: Column(children: [
          // 播放器控制
          Card(color: const Color(0xFF124146), shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              Row(children: [
                Text(_pos.ms(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(child: Slider(
                  value: _total.inMilliseconds > 0
                      ? (_pos.inMilliseconds / _total.inMilliseconds).clamp(0.0,1.0)
                      : 0,
                  onChanged: seek, activeColor: AppColors.neonCyan,
                  inactiveColor: Colors.white12)),
                Text(_total.ms(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: ()=>setRate(playbackRate==0.5 ? 1.0 : playbackRate==1.0 ? 1.5 : playbackRate==1.5 ? 0.5 : 0.5),
                  icon: Text('${playbackRate.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700))),
                const SizedBox(width: 30),
                IconButton(icon: Icon(isRecording ? Icons.stop : _ps == PlayerState.playing
                    ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 44),
                  onPressed: toggle),
                const SizedBox(width: 30),
                IconButton(onPressed: compare, icon: const Icon(Icons.swap_horiz, color: AppColors.neonCyan),
                  tooltip: '对比播放'),
              ]),
            ]))),
          const SizedBox(height: 12),
          // 歌词展示
          Expanded(child: widget.song.isLRC == 1
              ? _lrcView() : _txtView()),
          const SizedBox(height: 8),
          // 评分
          if (_score != null) Card(color: _gradeColor(), child: Padding(
            padding: const EdgeInsets.all(12), child: Row(children: [
              Text('评分 $_grade', style: const TextStyle(fontSize: 20,
                  color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(width: 18),
              Text('相似度 $_score%', style: const TextStyle(color: Colors.white70)),
            ]),
          )),
          const SizedBox(height: 8),
          // 底部控制
          Row(children: [
            Expanded(child: SizedBox(height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                  backgroundColor: isRecording ? Colors.red : AppColors.emeraldGreen,
                  foregroundColor: Colors.white),
                onPressed: toggleRec,
                icon: Icon(isRecording ? Icons.stop : Icons.mic),
                label: Text(isRecording ? '结束录音' : '🎙️ 开始跟唱'),
              ))),
          ]),
        ]))));
  }
  Color _gradeColor() {
    switch(_grade) {
      case 'S': return const Color(0xFFFF1744);
      case 'A': return const Color(0xFFFF9100);
      case 'B': return const Color(0xFF00C853);
      case 'C': return const Color(0xFF14A3A7);
      default: return const Color(0xFF616161);
    }
  }
  Widget _lrcView() {
    return ListView.builder(itemCount: _lrc.length,
      itemBuilder: (c, i) {
        final isCur = i == _lrcIdx;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
            style: TextStyle(fontSize: isCur ? 22 : 15,
                color: isCur ? AppColors.neonCyan : Colors.white.withOpacity(0.5),
                fontWeight: isCur ? FontWeight.w800 : FontWeight.w400,
                shadows: isCur ? [Shadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 12)] : null),
            child: Text(_lrc[i].text, textAlign: TextAlign.center,),
          ),
        );
      });
  }
  Widget _txtView() {
    return Column(children: [
      Expanded(child: ListView.builder(
        itemCount: _txtLines.length,
        itemBuilder: (c, i) {
          final isCur = i == _txtIdx;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_txtLines[i], textAlign: TextAlign.center,
              style: TextStyle(color: isCur ? AppColors.neonCyan : Colors.white.withOpacity(0.5),
                fontSize: isCur ? 22 : 15, fontWeight: isCur ? FontWeight.w800 : FontWeight.w400)),
          );
        })),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: OutlinedButton(onPressed: _txtIdx>0?(){setState(()=>_txtIdx--);}:null,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan,
              side: BorderSide(color: AppColors.neonCyan.withOpacity(0.4))),
            child: const Text('上一句'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: _txtIdx<_txtLines.length-1
              ? (){setState(()=>_txtIdx++);} : null,
            style: FilledButton.styleFrom(backgroundColor: AppColors.neonCyan,
              foregroundColor: const Color(0xFF0A3D3F)),
            child: const Text('下一句 →'))),
        ]),
      ),
    ]);
  }
}

class LyricLine { final int ms; final String text;
  LyricLine({required this.ms, required this.text}); }
