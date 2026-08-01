import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../services/database_service.dart';
import '../../models/all_models.dart';
import '../../services/word_extractor.dart';
import '../../providers/vocabulary_provider.dart';
import '../../widgets/glassmorphism_card.dart';

// ==========================================================================
// 歌房列表（练唱室，需求#4.1）
// 导入音频+歌词 / 一键提取生词
// ==========================================================================
class KaraokeStudioView extends ConsumerStatefulWidget {
  const KaraokeStudioView({super.key});
  @override ConsumerState<KaraokeStudioView> createState() => _KSVState();
}
class _KSVState extends ConsumerState<KaraokeStudioView> {
  List<SongModel> _songs = [];
  @override void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    _songs = await DatabaseService.instance.getAllSongs();
    if (mounted) setState(() {});
  }

  Future<void> _importSong() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.audio, allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final audio = res.files.single;
    final lycRes = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: const ['lrc','txt']);
    String lyrics = '';
    bool isLRC = false;
    if (lycRes != null && lycRes.files.isNotEmpty) {
      final f = lycRes.files.single;
      isLRC = (f.extension ?? '').toLowerCase() == 'lrc';
      if (f.path != null) {
        lyrics = await File(f.path!).readAsString();
      } else if (f.bytes != null) {
        lyrics = String.fromCharCodes(f.bytes!);
      }
    }
    final song = SongModel(
      title: audio.name.replaceAll('.mp3', '').replaceAll('.m4a', '').replaceAll('.wav', ''),
      artist: '未知歌手',
      audioPath: audio.path ?? '',
      lyricsContent: lyrics,
      isLRC: isLRC ? 1 : 0,
      importDate: DateTime.now(),
    );
    await DatabaseService.instance.insertSong(song);
    await _load();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 练唱室')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importSong, icon: const Icon(Icons.add), label: const Text('导入歌曲')),
      body: SafeArea(child: _songs.isEmpty ? _empty() : ListView.builder(
        itemCount: _songs.length, padding: const EdgeInsets.all(12),
        itemBuilder: (c, i) {
          final s = _songs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassmorphismCard(child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0D7377).withOpacity(0.2)),
                child: const Center(child: Icon(Icons.music_note, color: Color(0xFF0D7377)))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${s.artist} · ${s.isLRC == 1 ? 'LRC歌词' : 'TXT歌词'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ])),
              Column(children: [
                IconButton(
                    onPressed: () => context.push('/karaoke/${s.id}', extra: s),
                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFF0D7377), size: 32)),
                IconButton(onPressed: () async {
                  final words = WordExtractor.extract(s.lyricsContent);
                  await ref.read(vocabularyProvider.notifier).addImported(
                    words, source: '歌曲：${s.title}', topN: 80);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已提取${words.length}个生词加入词库')));
                }, icon: const Icon(Icons.auto_awesome, color: Color(0xFFFF9800), size: 22)),
              ]),
            ])),
          );
        })),
    );
  }
  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.library_music, size: 80, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('还没有歌曲，点右下角导入吧～', style: TextStyle(color: Colors.grey)),
    ],
  ));
}
