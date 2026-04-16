import 'dart:developer' as developer;

import '../../../core/database/database_service.dart';
import 'ai_assistant_message.dart';
import 'ai_chat_thread.dart';

class AiChatStorageException implements Exception {
  const AiChatStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AiChatRepository {
  AiChatRepository(this._databaseService);

  static const String _logName = 'AiChatRepository';

  final DatabaseService _databaseService;

  Future<List<AiChatThread>> getThreads() async {
    developer.log('Loading AI chat threads.', name: _logName);
    try {
      final String userId = _databaseService.requireUserId();
      final List<dynamic> rows = await _databaseService.client
          .from('ai_chat_threads')
          .select(
            'id, user_id, title, last_message_preview, created_at, updated_at',
          )
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final List<AiChatThread> threads = rows
          .map(
            (dynamic row) =>
                AiChatThread.fromMap(Map<String, Object?>.from(row as Map)),
          )
          .toList(growable: false);

      developer.log(
        'Loaded ${threads.length} AI chat threads successfully.',
        name: _logName,
      );
      return threads;
    } catch (error, stackTrace) {
      // Check if this is a table not found error
      if (error.toString().contains('Could not find the table') ||
          error.toString().contains('relation') &&
              error.toString().contains('does not exist')) {
        developer.log(
          'AI chat tables do not exist. Chat history will not be available.',
          name: _logName,
          error: error,
        );
        throw AiChatStorageException(
            'AI chat tables not found. Please apply database migrations.');
      }
      developer.log(
        'Failed to load AI chat threads.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<AiAssistantMessage>> getMessages(String threadId) async {
    developer.log(
      'Loading AI chat messages for thread=$threadId.',
      name: _logName,
    );
    try {
      final String userId = _databaseService.requireUserId();
      final List<dynamic> rows = await _databaseService.client
          .from('ai_chat_messages')
          .select(
            'id, thread_id, user_id, role, content, created_at, metadata_json',
          )
          .eq('user_id', userId)
          .eq('thread_id', threadId)
          .order('created_at');

      final List<AiAssistantMessage> messages = rows
          .map(
            (dynamic row) => AiAssistantMessage.fromMap(
              Map<String, Object?>.from(row as Map),
            ),
          )
          .toList(growable: false);

      developer.log(
        'Loaded ${messages.length} AI chat messages successfully.',
        name: _logName,
      );
      return messages;
    } catch (error, stackTrace) {
      // Check if this is a table not found error
      if (error.toString().contains('Could not find the table') ||
          error.toString().contains('relation') &&
              error.toString().contains('does not exist')) {
        developer.log(
          'AI chat tables do not exist. Chat history will not be available.',
          name: _logName,
          error: error,
        );
        throw AiChatStorageException(
            'AI chat tables not found. Please apply database migrations.');
      }
      developer.log(
        'Failed to load AI chat messages for thread=$threadId.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AiChatThread> createThread({required String title}) async {
    developer.log('Creating AI chat thread.', name: _logName);
    try {
      final String userId = _databaseService.requireUserId();
      final dynamic row = await _databaseService.client
          .from('ai_chat_threads')
          .insert(
            <String, Object?>{
              'user_id': userId,
              'title':
                  title.trim().isEmpty ? 'Cuộc trò chuyện mới' : title.trim(),
            },
          )
          .select(
            'id, user_id, title, last_message_preview, created_at, updated_at',
          )
          .single();

      developer.log('AI chat thread created successfully.', name: _logName);
      return AiChatThread.fromMap(Map<String, Object?>.from(row as Map));
    } catch (error, stackTrace) {
      // Check if this is a table not found error
      if (error.toString().contains('Could not find the table') ||
          error.toString().contains('relation') &&
              error.toString().contains('does not exist')) {
        developer.log(
          'AI chat tables do not exist. Cannot create thread.',
          name: _logName,
          error: error,
        );
        throw AiChatStorageException(
            'AI chat tables not found. Please apply database migrations.');
      }
      developer.log(
        'Failed to create AI chat thread.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AiAssistantMessage> saveMessage({
    required String threadId,
    required AiAssistantRole role,
    required String content,
    Map<String, dynamic>? metadataJson,
  }) async {
    developer.log(
      'Saving AI chat message for thread=$threadId, role=${role.name}.',
      name: _logName,
    );
    try {
      final String userId = _databaseService.requireUserId();
      final dynamic row = await _databaseService.client
          .from('ai_chat_messages')
          .insert(
            AiAssistantMessage(
              threadId: threadId,
              role: role,
              text: content,
              createdAt: DateTime.now(),
              metadataJson: metadataJson,
            ).toInsertMap(
              threadId: threadId,
              userId: userId,
            ),
          )
          .select(
            'id, thread_id, user_id, role, content, created_at, metadata_json',
          )
          .single();

      developer.log('AI chat message saved successfully.', name: _logName);
      return AiAssistantMessage.fromMap(Map<String, Object?>.from(row as Map));
    } catch (error, stackTrace) {
      // Check if this is a table not found error
      if (error.toString().contains('Could not find the table') ||
          error.toString().contains('relation') &&
              error.toString().contains('does not exist')) {
        developer.log(
          'AI chat tables do not exist. Cannot save message.',
          name: _logName,
          error: error,
        );
        throw AiChatStorageException(
            'AI chat tables not found. Please apply database migrations.');
      }
      developer.log(
        'Failed to save AI chat message for thread=$threadId.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
