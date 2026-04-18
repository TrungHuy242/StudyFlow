import '../data/ai_assistant_message.dart';
import '../data/ai_study_context.dart';

abstract class AiAssistantService {
  const AiAssistantService();

  String buildWelcomeMessage(AiStudyContext context);

  Future<String> reply({
    required String message,
    required AiStudyContext context,
    List<AiAssistantMessage> history = const <AiAssistantMessage>[],
  });
}
