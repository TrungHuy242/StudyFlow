enum AiAssistantRole {
  user,
  assistant,
}

class AiAssistantMessage {
  const AiAssistantMessage({
    this.id,
    this.threadId,
    required this.role,
    required this.text,
    required this.createdAt,
    this.metadataJson,
  });

  factory AiAssistantMessage.user(String text) {
    return AiAssistantMessage(
      role: AiAssistantRole.user,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory AiAssistantMessage.assistant(String text) {
    return AiAssistantMessage(
      role: AiAssistantRole.assistant,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory AiAssistantMessage.fromMap(Map<String, Object?> map) {
    return AiAssistantMessage(
      id: map['id']?.toString(),
      threadId: map['thread_id']?.toString(),
      role: _parseRole(map['role']?.toString()),
      text: (map['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      metadataJson: map['metadata_json'] is Map
          ? Map<String, dynamic>.from(map['metadata_json'] as Map)
          : null,
    );
  }

  final String? id;
  final String? threadId;
  final AiAssistantRole role;
  final String text;
  final DateTime createdAt;
  final Map<String, dynamic>? metadataJson;

  bool get isUser => role == AiAssistantRole.user;

  String get roleValue => role == AiAssistantRole.user ? 'user' : 'assistant';

  Map<String, Object?> toInsertMap({
    required String threadId,
    required String userId,
  }) {
    return <String, Object?>{
      'thread_id': threadId,
      'user_id': userId,
      'role': roleValue,
      'content': text.trim(),
      'metadata_json': metadataJson,
    };
  }

  static AiAssistantRole _parseRole(String? value) {
    return value == 'assistant'
        ? AiAssistantRole.assistant
        : AiAssistantRole.user;
  }
}
