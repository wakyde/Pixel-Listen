import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/subtitle.dart';

class AIService {
  static const _defaultBaseUrl = 'http://localhost:8000';

  final String baseUrl;
  final String Function() getToken;

  AIService({
    this.baseUrl = _defaultBaseUrl,
    required this.getToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${getToken()}',
      };

  Future<String?> translate(String text, {String targetLang = 'zh'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/translate'),
        headers: _headers,
        body: jsonEncode({
          'text': text,
          'source_lang': 'en',
          'target_lang': targetLang,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['translation'] as String?;
      }
    } catch (e, st) {
      debugPrint('[AIService] translate failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<List<CollocationToken>> detectCollocationsAI(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/detect-collocations'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['collocations'] is List) {
          final list = data['collocations'] as List;
          return list.map((item) {
            final m = item as Map<String, dynamic>;
            return CollocationToken(
              text: m['text'] as String? ?? '',
              type: m['type'] as String? ?? 'phrase',
              meaning: m['meaning'] as String?,
              startIndex: m['start_index'] as int? ?? 0,
              endIndex: m['end_index'] as int? ?? 0,
              aiDetected: true,
            );
          }).toList();
        }
      }
    } catch (e, st) {
      debugPrint('[AIService] detectCollocationsAI failed: $e\n$st');
      return [];
    }
    return [];
  }

  Future<Map<String, String>?> generateCloze({
    required String collocation,
    required String originalSentence,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/generate-cloze'),
        headers: _headers,
        body: jsonEncode({
          'collocation': collocation,
          'original_sentence': originalSentence,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'clozeSentence': data['cloze_sentence'] as String? ?? '',
          'hint': data['hint'] as String? ?? '',
        };
      }
    } catch (e, st) {
      debugPrint('[AIService] generateCloze failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<String?> checkAISubtitleCache(String mediaPath) async {
    try {
      final uri = Uri.parse('$baseUrl/api/ai/subtitle-cache')
          .replace(queryParameters: {'media_path': mediaPath});
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['cached'] == true) {
          return data['srt_content'] as String?;
        }
      }
    } catch (e, st) {
      debugPrint('[AIService] checkAISubtitleCache failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<String?> transcribeAudio(String mediaPath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/transcribe'),
        headers: _headers,
        body: jsonEncode({'media_path': mediaPath}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['srt_content'] as String?;
      }
    } catch (e, st) {
      debugPrint('[AIService] transcribeAudio failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<WordLookupResult?> lookupWord(String word) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/lookup-word'),
        headers: _headers,
        body: jsonEncode({'word': word}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WordLookupResult.fromJson(data);
      }
    } catch (e, st) {
      debugPrint('[AIService] lookupWord failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<String?> tutorChat({
    required String question,
    required String currentSubtitle,
    List<String> contextSubtitles = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/tutor-chat'),
        headers: _headers,
        body: jsonEncode({
          'question': question,
          'current_subtitle': currentSubtitle,
          'context_subtitles': contextSubtitles,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['answer'] as String?;
      }
    } catch (e, st) {
      debugPrint('[AIService] tutorChat failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<MistakeAnalysis?> analyzeMistakes(List<MistakeRecord> mistakes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/analyze-mistakes'),
        headers: _headers,
        body: jsonEncode({
          'mistakes': mistakes.map((m) => m.toJson()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MistakeAnalysis.fromJson(data);
      }
    } catch (e, st) {
      debugPrint('[AIService] analyzeMistakes failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<List<DictationSentence>> generateDictation({
    List<String> sourceSentences = const [],
    List<String> weakPatterns = const [],
    int count = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/generate-dictation'),
        headers: _headers,
        body: jsonEncode({
          'source_sentences': sourceSentences,
          'weak_patterns': weakPatterns,
          'count': count,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['sentences'] as List<dynamic>? ?? [];
        return list
            .map((e) => DictationSentence.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      debugPrint('[AIService] generateDictation failed: $e\n$st');
      return [];
    }
    return [];
  }

  Future<List<ExampleSentence>> generateExamples({
    required String word,
    String? meaning,
    int count = 3,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/generate-examples'),
        headers: _headers,
        body: jsonEncode({
          'word': word,
          'meaning': meaning,
          'count': count,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['examples'] as List<dynamic>? ?? [];
        return list
            .map((e) => ExampleSentence.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      debugPrint('[AIService] generateExamples failed: $e\n$st');
      return [];
    }
    return [];
  }

  Future<List<MemorizationMeta>?> evaluateChunk(
    List<Map<String, dynamic>> lines,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/evaluate-chunk'),
        headers: _headers,
        body: jsonEncode({'lines': lines}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['results'] as List<dynamic>? ?? [];
        return list
            .map((e) => MemorizationMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      debugPrint('[AIService] evaluateChunk failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<MemoCardTemplate?> generateMemoTemplate({
    required String text,
    List<String> highlights = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/generate-memo-template'),
        headers: _headers,
        body: jsonEncode({
          'text': text,
          'highlights': highlights,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MemoCardTemplate.fromJson(data);
      }
    } catch (e, st) {
      debugPrint('[AIService] generateMemoTemplate failed: $e\n$st');
      return null;
    }
    return null;
  }

  Future<GrammarAnalysis?> analyzeGrammar(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/analyze-grammar'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GrammarAnalysis.fromJson(data);
      }
    } catch (e, st) {
      debugPrint('[AIService] analyzeGrammar failed: $e\n$st');
      return null;
    }
    return null;
  }
}