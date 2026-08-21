import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VideoImportService {
  final String baseUrl;
  final String Function() getToken;

  VideoImportService({required this.baseUrl, required this.getToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${getToken()}',
      };

  Future<Map<String, dynamic>> parseUrl(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/video/parse'),
      headers: _headers,
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String detail;
    try {
      final error = jsonDecode(response.body);
      detail = error['detail'] as String? ?? 'Failed to parse URL';
    } catch (e, st) {
      debugPrint('Failed to parse error response body: $e\n$st');
      if (response.statusCode == 503 || response.statusCode == 500) {
        detail = '服务器错误，请检查后端是否已启动';
      } else {
        detail = '解析失败 (${response.statusCode})';
      }
    }
    throw Exception(detail);
  }

  Future<Map<String, dynamic>> download(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/video/download'),
      headers: _headers,
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String detail;
    try {
      final error = jsonDecode(response.body);
      detail = error['detail'] as String? ?? 'Failed to start download';
    } catch (e, st) {
      debugPrint('Failed to parse error response body: $e\n$st');
      if (response.statusCode == 503 || response.statusCode == 500) {
        detail = '服务器错误，请检查后端是否已启动';
      } else {
        detail = '下载失败 (${response.statusCode})';
      }
    }
    throw Exception(detail);
  }

  Stream<Map<String, dynamic>> streamProgress(String taskId) {
    final controller = StreamController<Map<String, dynamic>>();
    final client = http.Client();

    Future(() async {
      try {
        final request = http.Request(
          'GET',
          Uri.parse('$baseUrl/api/video/progress/$taskId/stream'),
        );
        request.headers.addAll(_headers);

        final response = await client.send(request);
        final stream = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.startsWith('data: ')) {
            final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            controller.add(data);
            if (data['status'] == 'done' || data['status'] == 'failed') {
              break;
            }
          }
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        await controller.close();
        client.close();
      }
    });

    return controller.stream;
  }

  Future<Map<String, dynamic>> getSubtitleContent(
      String fileId, int index) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/video/files/$fileId/subtitle/$index'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load subtitle');
  }
}