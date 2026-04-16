import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../core/config/app_env.dart';
import '../data/ai_assistant_message.dart';
import '../data/ai_study_context.dart';
import 'ai_assistant_prompt_builder.dart';
import 'ai_assistant_service.dart';
import 'local_ai_assistant_service.dart';

class GeminiAiAssistantService extends AiAssistantService {
  const GeminiAiAssistantService();

  static const String _logName = 'GeminiAiAssistantService';
  static const String defaultModel = 'gemini-2.5-flash';
  static const int _historyLimit = 12;

  // Keep this field so hot reload does not reject the previous const-class layout.
  // ignore: unused_field
  final LocalAiAssistantService _welcomeHelper =
      const LocalAiAssistantService();

  static const List<String> _systemInstructionParts = <String>[
    'Bạn là trợ lý học tập thông minh của ứng dụng StudyFlow, đặc biệt giỏi hiểu bối cảnh học tập thực của từng người dùng.',
    'Trả lời bằng tiếng Việt TỰ NHIÊN, CỤ THỂ, THIẾT THỰC và KHÔNG LẶP LẠI. Âm thanh như một người bạn, không như một bot.',
    'LUÔN để dữ liệu học tập thực (lịch, deadline, kế hoạch, Pomodoro) làm nền tảng. KHÔNG ĐƯỢC bịa ra dữ liệu không có.',
    'Nếu một câu hỏi là follow-up hoặc nhắc lại chủ đề cũ, hãy nhớ ngữ cảnh trước và liên kết câu trả lời, không hỏi lại từ đầu.',
    'Trả lời NGẮN TỪ 1-3 câu nếu có thể, chi tiết hơn nếu cần. Không dàn trải hoặc lặp lại thông tin.',
    'Nếu dữ liệu chưa đủ để trả lời, nói rõ cần gì thêm và đưa ra lời khuyên tạm thời dựa trên những gì có.',
  ];

  @override
  String buildWelcomeMessage(AiStudyContext context) {
    final int todayFocus = context.focusMinutesForDate(context.generatedAt);
    final int openDeadlines = context.openDeadlines.length;
    final int overdueDeadlines = context.overdueDeadlines.length;

    if (!context.hasAnyData) {
      return 'Mình đã sẵn sàng hỗ trợ, nhưng hiện chưa có nhiều dữ liệu học tập trong tài khoản này. '
          'Bạn vẫn có thể hỏi tự do hoặc thêm deadline, lịch học, kế hoạch, Pomodoro và ghi chú để nhận gợi ý chính xác hơn.';
    }

    return 'Mình đã đọc dữ liệu học tập hiện tại của ${context.displayName}. '
        'Hiện có $openDeadlines deadline đang mở, $overdueDeadlines deadline quá hạn '
        'và ${_formatMinutes(todayFocus)} thời gian tập trung hôm nay. '
        'Bạn có thể chọn một gợi ý nhanh bên trên hoặc đặt câu hỏi tự do.';
  }

  @override
  Future<String> reply({
    required String message,
    required AiStudyContext context,
    List<AiAssistantMessage> history = const <AiAssistantMessage>[],
  }) async {
    final String trimmedMessage = message.trim();
    developer.log(
      'Preparing Gemini request: messageLength=${trimmedMessage.length}, '
      'history=${history.length}, deadlines=${context.deadlines.length}, '
      'schedules=${context.schedules.length}, plans=${context.plans.length}, '
      'sessions=${context.sessions.length}, notes=${context.notes.length}.',
      name: _logName,
    );

    final String apiKey;
    final String model;
    try {
      apiKey = AppEnv.geminiApiKey;
      model = AppEnv.geminiModel;
      developer.log(
        'Gemini config loaded successfully: model=$model.',
        name: _logName,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load Gemini configuration for request.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      throw GeminiAiAssistantException(
          'Gemini chưa được cấu hình trong file .env.');
    }

    try {
      final Uri uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
        <String, String>{'key': apiKey},
      );

      final AiAssistantIntent intent =
          AiAssistantPromptBuilder.detectIntent(trimmedMessage);
      final http.Response response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          <String, Object?>{
            'system_instruction': <String, Object?>{
              'parts': <Map<String, String>>[
                <String, String>{
                  'text': _systemInstructionParts.join(' '),
                },
              ],
            },
            'generationConfig': <String, Object?>{
              'temperature': 0.4,
              'maxOutputTokens': 768,
            },
            'contents': _buildGeminiContents(
              history: _trimmedHistory(history),
              studyContext: AiAssistantPromptBuilder.buildStudyContext(
                context,
                intent: intent,
              ),
              message: trimmedMessage,
              intent: intent,
            ),
          },
        ),
      );

      developer.log(
        'Gemini response received with status=${response.statusCode}.',
        name: _logName,
      );

      final dynamic payload = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String readableError = _mapGeminiError(
          response.statusCode,
          payload,
        );
        developer.log(
          'Gemini returned a non-success status.',
          name: _logName,
          error: readableError,
        );
        throw GeminiAiAssistantException(readableError);
      }

      if (payload is! Map) {
        developer.log(
          'Gemini payload was not a JSON object.',
          name: _logName,
          error: payload,
        );
        throw GeminiAiAssistantException('Phản hồi Gemini không hợp lệ.');
      }

      String replyText = _extractText(Map<String, dynamic>.from(payload));
      if (replyText.trim().isEmpty) {
        developer.log(
          'Gemini payload did not contain a usable text reply.',
          name: _logName,
        );
        throw GeminiAiAssistantException('Gemini chưa trả về nội dung hợp lệ.');
      }

      // Clean up the response for naturalness
      replyText = _cleanupResponse(replyText);

      developer.log(
        'Gemini reply parsed successfully (${replyText.length} chars).',
        name: _logName,
      );
      return replyText.trim();
    } catch (error, stackTrace) {
      developer.log(
        'Gemini request failed unexpectedly.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (error is GeminiAiAssistantException) {
        throw error;
      }
      throw GeminiAiAssistantException(
          'Không kết nối được với Gemini lúc này.');
    }
  }

  List<AiAssistantMessage> _trimmedHistory(List<AiAssistantMessage> history) {
    if (history.length <= _historyLimit) {
      return history;
    }
    return history.sublist(history.length - _historyLimit);
  }

  List<Map<String, Object?>> _buildGeminiContents({
    required List<AiAssistantMessage> history,
    required String studyContext,
    required String message,
    required AiAssistantIntent intent,
  }) {
    final List<Map<String, Object?>> contents = <Map<String, Object?>>[];

    if (studyContext.trim().isNotEmpty) {
      contents.add(
        <String, Object?>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{
              'text': [
                'Dưới đây là dữ liệu học tập thật hiện tại của người dùng.',
                'Hãy dùng dữ liệu này làm ngữ cảnh chính khi trả lời.',
                '',
                studyContext,
              ].join('\n'),
            },
          ],
        },
      );
    }

    for (final AiAssistantMessage item in history) {
      final String content = item.text.trim();
      if (content.isEmpty) {
        continue;
      }

      contents.add(
        <String, Object?>{
          'role': item.role == AiAssistantRole.assistant ? 'model' : 'user',
          'parts': <Map<String, String>>[
            <String, String>{'text': content},
          ],
        },
      );
    }

    // Include intent and conversation context
    if (history.isNotEmpty) {
      contents.add(
        <String, Object?>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{
              'text':
                  'Đây là cuộc trò chuyện đang diễn ra. Hãy duy trì ngữ cảnh và trả lời dựa trên yêu cầu cụ thể này.',
            },
          ],
        },
      );
    }

    if (intent != AiAssistantIntent.general) {
      contents.add(
        <String, Object?>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{
              'text':
                  'Ưu tiên: ${AiAssistantPromptBuilder.intentLabel(intent)}.',
            },
          ],
        },
      );
    }

    contents.add(
      <String, Object?>{
        'role': 'user',
        'parts': <Map<String, String>>[
          <String, String>{
            'text': 'Câu hỏi: $message',
          },
        ],
      },
    );

    return contents;
  }

  String _extractText(Map<String, dynamic> payload) {
    final dynamic candidatesValue = payload['candidates'];
    if (candidatesValue is! List) {
      return '';
    }

    for (final dynamic candidate in candidatesValue) {
      if (candidate is! Map) {
        continue;
      }
      final dynamic contentValue = candidate['content'];
      if (contentValue is! Map) {
        continue;
      }
      final dynamic partsValue = contentValue['parts'];
      if (partsValue is! List) {
        continue;
      }

      final String text = partsValue
          .whereType<Map>()
          .map((Map part) => (part['text'] ?? '').toString().trim())
          .where((String value) => value.isNotEmpty)
          .join('\n');

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  String _formatMinutes(int value) {
    if (value <= 0) {
      return '0 phút';
    }
    final int hours = value ~/ 60;
    final int minutes = value % 60;
    if (hours == 0) {
      return '$minutes phút';
    }
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }

  String _cleanupResponse(String text) {
    // Remove excessive newlines but preserve intentional paragraph breaks
    String cleaned = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Fix common Vietnamese text formatting issues
    cleaned = cleaned.replaceAll('( +)', ' '); // Multiple spaces to one
    cleaned = cleaned.replaceAll(' ([,.])', r'$1'); // Space before punctuation
    cleaned = cleaned.replaceAll(':\n+', ': '); // Fix colons

    return cleaned.trim();
  }

  String _mapGeminiError(int statusCode, dynamic payload) {
    if (payload is Map) {
      final dynamic errorValue = payload['error'];
      if (errorValue is Map) {
        final String message = (errorValue['message'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    }

    if (statusCode == 400) {
      return 'Yêu cầu gửi tới Gemini chưa hợp lệ.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'GEMINI_API_KEY không hợp lệ hoặc chưa được cấp quyền.';
    }
    if (statusCode == 429) {
      return 'Gemini đang bận hoặc đã chạm giới hạn tạm thời. Hãy thử lại sau ít phút.';
    }
    if (statusCode >= 500) {
      return 'Gemini đang gặp lỗi phía máy chủ. Hãy thử lại sau.';
    }
    return 'Không thể lấy phản hồi từ Gemini lúc này.';
  }
}

class GeminiAiAssistantException implements Exception {
  GeminiAiAssistantException(this.message);

  final String message;

  @override
  String toString() => 'GeminiAiAssistantException: $message';
}
