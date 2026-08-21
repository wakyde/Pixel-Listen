import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:http/http.dart' as http;

class AnkiImportScreen extends ConsumerStatefulWidget {
  const AnkiImportScreen({super.key});

  @override
  ConsumerState<AnkiImportScreen> createState() => _AnkiImportScreenState();
}

class _AnkiImportScreenState extends ConsumerState<AnkiImportScreen> {
  bool _isLoading = false;
  String? _error;
  String? _importMode;
  Map<String, dynamic>? _preview;
  int _importedCount = 0;

  Future<void> _pickAndPreviewAnki() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apkg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _error = '文件为空';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('http://localhost:8000/api/flashcards/import/anki');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _preview = json.decode(body) as Map<String, dynamic>;
          _importMode = 'anki';
          _isLoading = false;
        });
      } else {
        final detail = (json.decode(body) as Map<String, dynamic>)['detail'] ?? '导入失败';
        setState(() {
          _error = detail.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '连接后端失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndPreviewCsv() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      String content;

      if (file.path != null) {
        content = File(file.path!).readAsStringSync();
      } else if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else {
        setState(() {
          _error = '无法读取文件';
          _isLoading = false;
        });
        return;
      }

      final lines = content.trim().split('\n');
      if (lines.length < 2) {
        setState(() {
          _error = 'CSV 文件至少需要表头和一行数据';
          _isLoading = false;
        });
        return;
      }

      final headers = _parseCsvLine(lines[0]);
      final previewRows = <Map<String, String>>[];
      for (int i = 1; i < lines.length && i < 11; i++) {
        final values = _parseCsvLine(lines[i]);
        final row = <String, String>{};
        for (int j = 0; j < headers.length && j < values.length; j++) {
          row[headers[j]] = values[j];
        }
        previewRows.add(row);
      }

      setState(() {
        _preview = {
          'headers': headers,
          'preview': previewRows,
          'total_rows': lines.length - 1,
        };
        _importMode = 'csv';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '解析 CSV 失败: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if ((char == ',' || char == '\t') && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('http://localhost:8000/api/flashcards/import/csv');
      final cards = _buildCardsFromPreview();
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cards': cards}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _importedCount = (body['imported_count'] as int?) ?? 0;
          _preview = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '导入失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '连接后端失败: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _buildCardsFromPreview() {
    if (_preview == null || _importMode != 'csv') return [];

    final headers = (_preview!['headers'] as List<dynamic>?)?.cast<String>() ?? [];
    final previewRows = (_preview!['preview'] as List<dynamic>?) ?? [];

    final frontIdx = headers.indexWhere((h) =>
        h.toLowerCase().contains('front') || h.toLowerCase().contains('word') || h.toLowerCase().contains('question'));
    final backIdx = headers.indexWhere((h) =>
        h.toLowerCase().contains('back') || h.toLowerCase().contains('answer') || h.toLowerCase().contains('meaning'));
    final tagsIdx = headers.indexWhere((h) => h.toLowerCase().contains('tag'));

    if (frontIdx < 0 || backIdx < 0) return [];

    final frontKey = headers[frontIdx];
    final backKey = headers[backIdx];
    final tagsKey = tagsIdx >= 0 ? headers[tagsIdx] : null;

    return previewRows.map((row) {
      final r = row as Map<String, dynamic>;
      return {
        'front_text': (r[frontKey] ?? '').toString(),
        'back_answer': (r[backKey] ?? '').toString(),
        if (tagsKey != null) 'tags': (r[tagsKey] ?? '').toString(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入闪卡')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _importedCount > 0
              ? _buildSuccessView()
              : _preview != null
                  ? _buildPreviewView()
                  : _error != null
                      ? _buildErrorView()
                      : _buildSelectView(),
    );
  }

  Widget _buildSelectView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file, size: 64, color: PlatformColors.primary),
            const SizedBox(height: PlatformSpacing.lg),
            Text('导入闪卡', style: PlatformTextStyles.headline),
            const SizedBox(height: PlatformSpacing.sm),
            Text('支持 Anki .apkg 或 CSV 文件',
              style: PlatformTextStyles.body.copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
            const SizedBox(height: PlatformSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_stories),
                label: const Text('导入 Anki 牌组 (.apkg)'),
                onPressed: _pickAndPreviewAnki,
              ),
            ),
            const SizedBox(height: PlatformSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.table_chart),
                label: const Text('导入 CSV 文件'),
                onPressed: _pickAndPreviewCsv,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewView() {
    final preview = _preview!;
    final previewItems = (preview['preview'] as List<dynamic>?) ?? [];
    final headers = (preview['headers'] as List<dynamic>?)?.cast<String>() ?? [];
    final totalRows = (preview['total_rows'] as int?) ?? 0;
    final deckName = (preview['deck_name'] as String?) ?? '';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PlatformSpacing.md),
          color: PlatformColors.primary.withAlpha(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deckName.isNotEmpty)
                Text('牌组: $deckName', style: PlatformTextStyles.title),
              Text('共 $totalRows 张卡片', style: PlatformTextStyles.body.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              )),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(PlatformSpacing.md),
            children: [
              Text('预览 (前 ${previewItems.length} 张):',
                style: PlatformTextStyles.title.copyWith(fontSize: 14)),
              const SizedBox(height: PlatformSpacing.sm),
              for (final item in previewItems)
                _buildPreviewCard(item as Map<String, dynamic>, headers),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PlatformSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmImport,
                child: Text('确认导入 $totalRows 张卡片'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> item, List<String> headers) {
    String front = '';
    String back = '';

    if (headers.isNotEmpty) {
      final frontIdx = headers.indexWhere((h) =>
          h.toLowerCase().contains('front') || h.toLowerCase().contains('word') || h.toLowerCase().contains('question'));
      final backIdx = headers.indexWhere((h) =>
          h.toLowerCase().contains('back') || h.toLowerCase().contains('answer') || h.toLowerCase().contains('meaning'));
      if (frontIdx >= 0) front = (item[headers[frontIdx]] ?? '').toString();
      if (backIdx >= 0) back = (item[headers[backIdx]] ?? '').toString();
    } else {
      front = (item['front'] ?? item['front_text'] ?? '').toString();
      back = (item['back'] ?? item['back_answer'] ?? '').toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(front, style: PlatformTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            if (back.isNotEmpty) ...[
              const Divider(height: PlatformSpacing.md),
              Text(back, style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: PlatformColors.green),
          const SizedBox(height: PlatformSpacing.lg),
          Text('导入成功', style: PlatformTextStyles.headline),
          const SizedBox(height: PlatformSpacing.sm),
          Text('已导入 $_importedCount 张闪卡',
            style: PlatformTextStyles.body.copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
          const SizedBox(height: PlatformSpacing.xl),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: PlatformColors.error),
            const SizedBox(height: PlatformSpacing.lg),
            Text('导入失败', style: PlatformTextStyles.headline),
            const SizedBox(height: PlatformSpacing.sm),
            Text(_error ?? '未知错误', textAlign: TextAlign.center,
              style: PlatformTextStyles.body.copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
            const SizedBox(height: PlatformSpacing.xl),
            ElevatedButton(
              onPressed: () => setState(() {
                _error = null;
                _preview = null;
                _importMode = null;
              }),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}