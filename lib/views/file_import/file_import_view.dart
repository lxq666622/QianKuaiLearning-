import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glassmorphism_card.dart';
import '../../services/document_parser.dart';
import '../../services/word_extractor.dart';
import '../../models/all_models.dart';
import '../../providers/vocabulary_provider.dart';

// ==========================================================================
// 文件导入中心（需求#3）：选择→解析→展示结果→批量加入词库
// ==========================================================================
class FileImportView extends ConsumerStatefulWidget {
  const FileImportView({super.key});
  @override ConsumerState<FileImportView> createState() => _FIVState();
}
class _FIVState extends ConsumerState<FileImportView> {
  bool parsing = false;
  double progress = 0;
  String? error;
  List<ExtractedWordModel>? extracted;
  String? fileName;
  int? totalCount, uniqueCount;

  Future<void> pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any, allowMultiple: true, withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    setState(() { parsing = true; progress = 0; error = null; extracted = null; });
    final buf = StringBuffer();
    int i = 0;
    for (final f in res.files) {
      fileName = res.files.length == 1 ? f.name : '${res.files.length}个文件';
      final txt = await DocumentParser.parseFile(f);
      buf.writeln(txt);
      i++;
      if (mounted) setState(() => progress = i / res.files.length);
    }
    final list = WordExtractor.extract(buf.toString());
    if (mounted) setState(() {
      parsing = false;
      extracted = list;
      totalCount = list.fold<int>(0, (p,e)=>p+e.frequency);
      uniqueCount = list.length;
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文件解析中心'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: extracted == null ? _selector() : _result(),
      )),
    );
  }
  Widget _selector() {
    return Column(children: [
      const SizedBox(height: 40),
      GestureDetector(onTap: parsing ? null : pick,
        child: GlassmorphismCard(child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.cloud_upload, size: 80, color: parsing
                ? Colors.grey : Theme.of(context).primaryColor),
            const SizedBox(height: 14),
            Text(parsing ? '解析中…请稍候' : '点击选择文件',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('支持 PDF / DOCX / TXT / MD / 图片 / LRC',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            if (parsing) ...[
              const SizedBox(height: 20),
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
              const SizedBox(height: 10),
              AnimatedOpacity(opacity: (DateTime.now().millisecondsSinceEpoch~/500).isEven ? 1 : 0.4,
                duration: const Duration(milliseconds: 500),
                child: Text('正在解析：${fileName ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey))),
            ],
          ]),
        )),
      ),
      if (error != null) Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error!, style: const TextStyle(color: Colors.red))),
    ]);
  }
  Widget _result() {
    final list = extracted!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassmorphismCard(child: Row(children: [
        const Icon(Icons.description, color: Color(0xFF0D7377)),
        const SizedBox(width: 10),
        Expanded(child: Text('$fileName', style: const TextStyle(fontWeight: FontWeight.w700))),
      ])),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: GlassmorphismCard(child: Column(children: [
          Text('$totalCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
            color: Color(0xFF0D7377))),
          const SizedBox(height: 4),
          const Text('总词数', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ]))),
        const SizedBox(width: 10),
        Expanded(child: GlassmorphismCard(child: Column(children: [
          Text('$uniqueCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
            color: Color(0xFF14A3A7))),
          const SizedBox(height: 4),
          const Text('去重词数', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ]))),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () {
          ref.read(vocabularyProvider.notifier).addImported(list, source: fileName!);
          context.pop();
        }, child: const Text('全选加入'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () {
          ref.read(vocabularyProvider.notifier).addImported(list, source: fileName!, topN: 50);
          context.pop();
        }, child: const Text('只加前50高频词'))),
      ]),
      const SizedBox(height: 14),
      Expanded(child: ListView.builder(itemCount: list.length,
        itemBuilder: (c, i) {
        final e = list[i];
        return ListTile(
          title: Row(children: [
            Text(e.word, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF14FFEC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8)),
              child: Text('×${e.frequency}', style: const TextStyle(
                color: Color(0xFF0A3D3F), fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          subtitle: e.exampleSentence.isEmpty ? null : Text(e.exampleSentence,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: IconButton(onPressed: () {
            ref.read(vocabularyProvider.notifier).addImported([e], source: fileName!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${e.word} 已加入词库'), duration: const Duration(seconds: 1)));
          }, icon: const Icon(Icons.add_circle, color: Color(0xFF0D7377))),
        );
      })),
    ]);
  }
}
