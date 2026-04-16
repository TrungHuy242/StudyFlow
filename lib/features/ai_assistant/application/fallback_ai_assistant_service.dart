import 'dart:developer' as developer;

import '../data/ai_assistant_message.dart';
import '../data/ai_study_context.dart';
import 'ai_assistant_service.dart';

class FallbackAiAssistantService extends AiAssistantService {
  const FallbackAiAssistantService({
    required this.primary,
    required this.fallback,
  });

  final AiAssistantService primary;
  final AiAssistantService fallback;

  @override
  String buildWelcomeMessage(AiStudyContext context) {
    try {
      return primary.buildWelcomeMessage(context);
    } catch (error, stackTrace) {
      developer.log(
        'Primary welcome failed, using fallback welcome.',
        name: 'FallbackAiAssistantService',
        error: error,
        stackTrace: stackTrace,
      );
      return fallback.buildWelcomeMessage(context);
    }
  }

  @override
  Future<String> reply({
    required String message,
    required AiStudyContext context,
    List<AiAssistantMessage> history = const <AiAssistantMessage>[],
  }) async {
    try {
      return await primary.reply(
        message: message,
        context: context,
        history: history,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Primary AI provider failed, switching to local fallback.',
        name: 'FallbackAiAssistantService',
        error: error,
        stackTrace: stackTrace,
      );

      final String fallbackReply = await fallback.reply(
        message: message,
        context: context,
        history: history,
      );

      return 'Gemini hiện tại chưa khả dụng, mình đang dùng dữ liệu học tập cục bộ để trả lời:\n\n$fallbackReply';
    }
  }
}
