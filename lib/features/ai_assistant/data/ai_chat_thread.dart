class AiChatThread {
  const AiChatThread({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessagePreview,
  });

  factory AiChatThread.fromMap(Map<String, Object?> map) {
    final String rawTitle = (map['title'] ?? '').toString().trim();
    return AiChatThread(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: rawTitle.isEmpty ? 'Cuộc trò chuyện mới' : rawTitle,
      lastMessagePreview: map['last_message_preview']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String title;
  final String? lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;
}
