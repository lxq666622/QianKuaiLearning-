import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:pdfx/pdfx.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// ==========================================================================
// 文档解析引擎（对应原DocumentParser.swift，需求#3.2）
// 自动路由：PDF / TXT / DOCX(Dart原生ZIP+XML) / 图片OCR / LRC / （音频预留）
// ==========================================================================
class DocumentParser {
  static Future<String> parseFile(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    try {
      return await compute(_parseIsolate, {
        'ext': ext,
        'path': file.path,
        'bytes': file.bytes,
      });
    } catch (e) {
      return '';
    }
  }

  // 解析放 Isolate 避免卡UI
  static Future<String> _parseIsolate(Map<String,dynamic> params) async {
    final ext = params['ext'] as String;
    final path = params['path'] as String?;
    final bytes = params['bytes'] as List<int>?;
    switch (ext) {
      case 'txt': case 'md': case 'rtf':
        if (bytes != null) return _autoDecode(bytes);
        if (path != null) return _autoDecode(await File(path).readAsBytes());
        return '';
      case 'docx':
        return _parseDOCX(bytes ?? (path!=null ? File(path).readAsBytesSync() : []));
      case 'pdf':
        return await _parsePDF(path);
      case 'jpg': case 'jpeg': case 'png': case 'webp': case 'bmp':
        return path != null ? _runOCR(path) : '';
      case 'lrc':
        if (bytes != null) return _parseLRC(String.fromCharCodes(bytes));
        if (path != null) return _parseLRC(await File(path).readAsString());
        return '';
      default:
        return '';
    }
  }

  // =============== 编码自动识别（UTF-8/Latin1）===============
  static String _autoDecode(List<int> bytes) {
    try { return utf8.decode(bytes, allowMalformed: true); } catch(_) {}
    try { return latin1.decode(bytes); } catch(_) { return ''; }
  }

  // =============== DOCX = ZIP → word/document.xml → 提取<w:t> ===============
  static String _parseDOCX(List<int> zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final docFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'word/document.xml',
        orElse: () => throw 'no doc',
      );
      final xmlStr = _autoDecode(docFile.content as List<int>);
      final doc = XmlDocument.parse(xmlStr);
      return doc.findAllElements('w:t').map((e) => e.innerText).join(' ');
    } catch(_) { return ''; }
  }

  // =============== PDF：pdfx 插件 ===============
  static Future<String> _parsePDF(String? path) async {
    if (path == null) return '';
    try {
      final doc = await PdfDocument.openFile(path);
      final buf = StringBuffer();
      for (int i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        final txt = await page.text;
        buf.writeln(txt);
      }
      await doc.close();
      return buf.toString();
    } catch(_) { return ''; }
  }

  // =============== 图片OCR：Google ML Kit 离线识别 ===============
  static Future<String> _runOCR(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(input);
      await recognizer.close();
      return result.text;
    } catch(_) { return ''; }
  }

  // =============== LRC歌词：去除时间戳，保留纯文本 ===============
  static String _parseLRC(String raw) {
    final re = RegExp(r'\[\d{2}:\d{2}(\.\d{1,3})?\]');
    return raw.split('\n').map((l) => l.replaceAll(re, '').trim())
                       .where((l) => l.isNotEmpty)
                       .join('\n');
  }
}
