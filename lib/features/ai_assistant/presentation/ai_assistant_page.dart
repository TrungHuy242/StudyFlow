import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../notes/data/note_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../application/ai_assistant_context_loader.dart';
import '../application/ai_assistant_service.dart';
import '../application/fallback_ai_assistant_service.dart';
import '../application/gemini_ai_assistant_service.dart';
import '../application/local_ai_assistant_service.dart';
import '../data/ai_assistant_message.dart';
import '../data/ai_chat_repository.dart';
import '../data/ai_chat_thread.dart';
import '../data/ai_study_context.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  static const String _logName = 'AiAssistantPage';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _threadDateFormat = DateFormat('dd/MM • HH:mm');

  AiAssistantContextLoader? _contextLoader;
  late AiChatRepository _chatRepository;
  late AiAssistantService _assistantService;
  late Future<void> _bootstrapFuture;

  AiStudyContext? _context;
  List<AiChatThread> _threads = <AiChatThread>[];
  AiChatThread? _activeThread;
  List<AiAssistantMessage> _messages = <AiAssistantMessage>[];
  List<String> _loadWarnings = <String>[];
  String? _chatStorageWarning;
  bool _chatStorageAvailable = true;
  bool _initialized = false;
  bool _isSending = false;
  bool _isThreadLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final DatabaseService databaseService = context.read<DatabaseService>();
    _contextLoader = AiAssistantContextLoader(
      deadlineRepository: DeadlineRepository(databaseService),
      scheduleRepository: ScheduleRepository(databaseService),
      studyPlanRepository: StudyPlanRepository(databaseService),
      pomodoroRepository: PomodoroRepository(databaseService),
      noteRepository: NoteRepository(databaseService),
      sessionController: context.read<AppSessionController>(),
    );
    _chatRepository = AiChatRepository(databaseService);
    _assistantService = const FallbackAiAssistantService(
      primary: GeminiAiAssistantService(),
      fallback: LocalAiAssistantService(),
    );
    _bootstrapFuture = _reloadAll();
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadAll({String? preferredThreadId}) async {
    developer.log('Reloading AI assistant page state.', name: _logName);

    try {
      final AiAssistantContextLoadResult contextResult =
          await _contextLoader!.load();
      final List<String> warnings = <String>[...contextResult.warnings];
      final List<AiChatThread> threads = await _loadThreadsSafely(
        warnings: warnings,
      );

      final AiChatThread? activeThread =
          _pickThread(threads, preferredThreadId ?? _activeThread?.id);

      final List<AiAssistantMessage> messages = activeThread == null
          ? (_chatStorageAvailable
              ? <AiAssistantMessage>[]
              : List<AiAssistantMessage>.from(_messages))
          : await _loadMessagesSafely(
              activeThread.id,
              warnings: warnings,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _context = contextResult.context;
        _threads = threads;
        _activeThread = activeThread;
        _messages = messages;
        _loadWarnings = _dedupeWarnings(warnings);
        _isThreadLoading = false;
      });
      _showLoadWarningsIfNeeded();
      _scrollToBottom();
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected AI assistant bootstrap failure.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );

      final AiStudyContext fallbackContext =
          _contextLoader!.buildFallbackContext();
      final List<String> warnings = _dedupeWarnings(<String>[
        ..._loadWarnings,
        'Trợ lý học tập đang mở ở chế độ giới hạn vì dữ liệu ban đầu chưa tải hết.',
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _context = fallbackContext;
        _threads = <AiChatThread>[];
        _activeThread = null;
        _messages = <AiAssistantMessage>[];
        _loadWarnings = warnings;
        _chatStorageAvailable = false;
        _chatStorageWarning =
            'Không tải được lịch sử trò chuyện AI. Bạn vẫn có thể chat trong phiên hiện tại.';
        _isThreadLoading = false;
      });
      _showLoadWarningsIfNeeded();
    }
  }

  AiChatThread? _pickThread(List<AiChatThread> threads, String? preferredId) {
    if (threads.isEmpty) {
      return null;
    }
    if (preferredId == null || preferredId.isEmpty) {
      return threads.first;
    }
    for (final AiChatThread thread in threads) {
      if (thread.id == preferredId) {
        return thread;
      }
    }
    return threads.first;
  }

  Future<List<AiChatThread>> _loadThreadsSafely({
    required List<String> warnings,
  }) async {
    try {
      final List<AiChatThread> threads = await _chatRepository.getThreads();
      _chatStorageAvailable = true;
      _chatStorageWarning = null;
      return threads;
    } catch (error, stackTrace) {
      developer.log(
        'AI thread history could not be loaded. Falling back to in-memory mode.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      _chatStorageAvailable = false;
      if (error is AiChatStorageException) {
        _chatStorageWarning =
            'Lịch sử trò chuyện AI chưa được thiết lập. Vui lòng áp dụng migration cơ sở dữ liệu.';
      } else {
        _chatStorageWarning =
            'Không tải được lịch sử trò chuyện AI. Bạn vẫn có thể chat nhưng tin nhắn sẽ không được lưu.';
      }
      warnings.add(_chatStorageWarning!);
      return <AiChatThread>[];
    }
  }

  Future<List<AiAssistantMessage>> _loadMessagesSafely(
    String threadId, {
    required List<String> warnings,
  }) async {
    try {
      return await _chatRepository.getMessages(threadId);
    } catch (error, stackTrace) {
      developer.log(
        'AI thread messages could not be loaded for thread=$threadId.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      _chatStorageAvailable = false;
      if (error is AiChatStorageException) {
        _chatStorageWarning =
            'Lịch sử trò chuyện AI chưa được thiết lập. Vui lòng áp dụng migration cơ sở dữ liệu.';
      } else {
        _chatStorageWarning =
            'Không tải được chi tiết lịch sử AI. Bạn vẫn có thể tiếp tục chat trong phiên hiện tại.';
      }
      warnings.add(_chatStorageWarning!);
      return List<AiAssistantMessage>.from(_messages);
    }
  }

  Future<void> _refreshThreads({String? preferredThreadId}) async {
    final List<String> warnings = <String>[];
    final List<AiChatThread> threads = await _loadThreadsSafely(
      warnings: warnings,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _threads = threads;
      _activeThread = threads.isEmpty && !_chatStorageAvailable
          ? _activeThread
          : _pickThread(threads, preferredThreadId ?? _activeThread?.id);
      _loadWarnings = _dedupeWarnings(<String>[
        ..._loadWarnings,
        ...warnings,
      ]);
    });

    if (warnings.isNotEmpty) {
      _showLoadWarningsIfNeeded();
    }
  }

  Future<void> _openThread(AiChatThread thread) async {
    if (_activeThread?.id == thread.id) {
      return;
    }
    if (!_chatStorageAvailable) {
      _showWarning(
        _chatStorageWarning ??
            'Lịch sử AI đang tạm thời không sẵn sàng trong lúc này.',
      );
      return;
    }

    setState(() {
      _isThreadLoading = true;
    });

    final List<String> warnings = <String>[];
    final List<AiAssistantMessage> messages = await _loadMessagesSafely(
      thread.id,
      warnings: warnings,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _activeThread = thread;
      _messages = messages;
      _isThreadLoading = false;
      _loadWarnings = _dedupeWarnings(<String>[
        ..._loadWarnings,
        ...warnings,
      ]);
    });

    if (warnings.isNotEmpty) {
      _showLoadWarningsIfNeeded();
    }
    _scrollToBottom();
  }

  void _startNewChat() {
    setState(() {
      _activeThread = null;
      _messages = <AiAssistantMessage>[];
      _controller.clear();
    });
  }

  Future<void> _showThreadSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            decoration: const BoxDecoration(
              color: StudyFlowPalette.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: StudyFlowPalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Cuộc trò chuyện AI',
                          style: TextStyle(
                            color: StudyFlowPalette.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_comment_rounded,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _startNewChat();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !_chatStorageAvailable
                        ? AppErrorState(
                            title: 'Lịch sử AI tạm thời chưa sẵn sàng',
                            message: _chatStorageWarning ??
                                'Bạn vẫn có thể chat nhưng lịch sử hiện tại chưa tải được.',
                          )
                        : _threads.isEmpty
                            ? const AppErrorState(
                                title: 'Chưa có hội thoại nào',
                                message:
                                    'Gửi câu hỏi đầu tiên để tạo một cuộc trò chuyện mới.',
                              )
                            : ListView.separated(
                                itemCount: _threads.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (
                                  BuildContext context,
                                  int index,
                                ) {
                                  final AiChatThread thread = _threads[index];
                                  final bool isActive =
                                      thread.id == _activeThread?.id;
                                  return _ThreadTile(
                                    thread: thread,
                                    isActive: isActive,
                                    dateText: _threadDateFormat.format(
                                      thread.updatedAt,
                                    ),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      _openThread(thread);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage([String? preset]) async {
    final String text = (preset ?? _controller.text).trim();
    final AiStudyContext? contextData = _context;
    if (text.isEmpty || _isSending || contextData == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    AiChatThread? thread = _activeThread;
    AiAssistantMessage userMessage = AiAssistantMessage.user(text);
    bool shouldRefreshThreads = false;

    if (_chatStorageAvailable) {
      try {
        thread ??= await _chatRepository.createThread(
          title: _buildThreadTitle(text),
        );
        userMessage = await _chatRepository.saveMessage(
          threadId: thread.id,
          role: AiAssistantRole.user,
          content: text,
        );
        shouldRefreshThreads = true;
      } catch (error, stackTrace) {
        developer.log(
          'Unable to persist user AI message. Switching to in-memory chat mode.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
        _markChatStorageUnavailable(
          showMessage: error is! AiChatStorageException,
          isSchemaError: error is AiChatStorageException,
        );
        thread = null;
      }
    }

    if (!mounted) {
      return;
    }

    final List<AiAssistantMessage> historyForReply = <AiAssistantMessage>[
      ..._messages,
      userMessage,
    ];

    setState(() {
      _activeThread = thread;
      _messages = historyForReply;
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    if (shouldRefreshThreads && thread != null) {
      await _refreshThreads(preferredThreadId: thread.id);
    }

    try {
      final String replyText = await _assistantService.reply(
        message: text,
        context: contextData,
        history: historyForReply,
      );

      AiAssistantMessage assistantMessage =
          AiAssistantMessage.assistant(replyText);
      bool shouldRefreshAfterAssistant = false;

      if (_chatStorageAvailable && thread != null) {
        try {
          assistantMessage = await _chatRepository.saveMessage(
            threadId: thread.id,
            role: AiAssistantRole.assistant,
            content: replyText,
          );
          shouldRefreshAfterAssistant = true;
        } catch (error, stackTrace) {
          developer.log(
            'Unable to persist assistant AI message. Keeping message in memory only.',
            name: _logName,
            error: error,
            stackTrace: stackTrace,
          );
          _markChatStorageUnavailable(
            showMessage: error is! AiChatStorageException,
            isSchemaError: error is AiChatStorageException,
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = <AiAssistantMessage>[..._messages, assistantMessage];
        _isSending = false;
      });

      if (shouldRefreshAfterAssistant && thread != null) {
        await _refreshThreads(preferredThreadId: thread.id);
      }
      _scrollToBottom();
    } catch (error, stackTrace) {
      developer.log(
        'AI message flow failed unexpectedly.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      _showError(_readableError(error));
    }
  }

  void _markChatStorageUnavailable(
      {bool showMessage = false, bool isSchemaError = false}) {
    const String generalWarning =
        'Không tải được lịch sử trò chuyện AI. Bạn vẫn có thể chat nhưng tin nhắn sẽ không được lưu.';
    const String schemaWarning =
        'Lịch sử trò chuyện AI chưa được thiết lập. Vui lòng áp dụng migration cơ sở dữ liệu.';

    final String warning = isSchemaError ? schemaWarning : generalWarning;

    if (mounted) {
      setState(() {
        _chatStorageAvailable = false;
        _chatStorageWarning = warning;
        _loadWarnings = _dedupeWarnings(<String>[..._loadWarnings, warning]);
      });
    } else {
      _chatStorageAvailable = false;
      _chatStorageWarning = warning;
      _loadWarnings = _dedupeWarnings(<String>[..._loadWarnings, warning]);
    }

    if (showMessage) {
      _showWarning(warning);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLoadWarningsIfNeeded() {
    if (_loadWarnings.isEmpty || !mounted) {
      return;
    }
    final String message = _loadWarnings.join('\n');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  String _readableError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    if (error is StateError) {
      return error.message;
    }
    final String text = error.toString().trim();
    if (text.isNotEmpty && !text.startsWith('Exception')) {
      return text;
    }
    return 'Không thể xử lý yêu cầu AI lúc này.';
  }

  String _buildThreadTitle(String input) {
    final String normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return 'Cuộc trò chuyện mới';
    }
    if (normalized.length <= 60) {
      return normalized;
    }
    return '${normalized.substring(0, 59)}…';
  }

  List<String> _dedupeWarnings(List<String> warnings) {
    final List<String> unique = <String>[];
    for (final String warning in warnings) {
      if (!unique.contains(warning)) {
        unique.add(warning);
      }
    }
    return unique;
  }

  List<AiAssistantMessage> get _visibleMessages {
    final AiStudyContext? contextData = _context;
    if (_messages.isNotEmpty || contextData == null) {
      return _messages;
    }
    return <AiAssistantMessage>[
      AiAssistantMessage.assistant(
        _assistantService.buildWelcomeMessage(contextData),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowPalette.background,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _bootstrapFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                _context == null) {
              return const AppLoadingState(
                message: 'Đang tải trợ lý học tập...',
              );
            }

            if (snapshot.hasError && _context == null) {
              return AppErrorState(
                title: 'Không thể mở trợ lý học tập',
                message:
                    'Dữ liệu hiện tại chưa tải được. Hãy thử lại hoặc mở lại trang.',
                actionLabel: 'Tải lại',
                onAction: () {
                  setState(() {
                    _bootstrapFuture = _reloadAll();
                  });
                },
              );
            }

            final List<AiAssistantMessage> visibleMessages = _visibleMessages;
            final String subtitle = _activeThread?.title ??
                'Phân tích deadline, lịch học, kế hoạch và Pomodoro';

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: _handleBack,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Trợ lý học tập AI',
                              style: TextStyle(
                                color: StudyFlowPalette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: StudyFlowPalette.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.history_rounded,
                        onTap: _showThreadSheet,
                      ),
                      const SizedBox(width: 8),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_comment_rounded,
                        onTap: _startNewChat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isThreadLoading
                        ? const AppLoadingState(
                            message: 'Đang tải hội thoại...',
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            itemCount:
                                visibleMessages.length + (_isSending ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (BuildContext context, int index) {
                              if (_isSending &&
                                  index == visibleMessages.length) {
                                return const _TypingBubble();
                              }
                              final AiAssistantMessage message =
                                  visibleMessages[index];
                              return _MessageBubble(message: message);
                            },
                          ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: StudyFlowPalette.border),
                      boxShadow: StudyFlowPalette.cardShadow,
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration(
                              hintText: 'Hỏi về tình hình học tập của bạn...',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: StudyFlowPalette.primaryButtonGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiAssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor =
        message.isUser ? StudyFlowPalette.blue : Colors.white;
    final Color textColor =
        message.isUser ? Colors.white : StudyFlowPalette.textPrimary;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
            border: message.isUser
                ? null
                : Border.all(color: StudyFlowPalette.border),
            boxShadow: StudyFlowPalette.cardShadow,
          ),
          padding: const EdgeInsets.all(14),
          child: Text(
            message.text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StudyFlowPalette.border),
          boxShadow: StudyFlowPalette.cardShadow,
        ),
        child: const SizedBox(
          width: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _TypingDot(),
              _TypingDot(),
              _TypingDot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: StudyFlowPalette.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.isActive,
    required this.dateText,
    required this.onTap,
  });

  final AiChatThread thread;
  final bool isActive;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF4FF) : StudyFlowPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? StudyFlowPalette.blue : StudyFlowPalette.border,
          ),
          boxShadow: StudyFlowPalette.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudyFlowPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: StudyFlowPalette.blue,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              thread.lastMessagePreview?.trim().isNotEmpty == true
                  ? thread.lastMessagePreview!.trim()
                  : 'Chưa có tin nhắn nào.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudyFlowPalette.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dateText,
              style: const TextStyle(
                color: StudyFlowPalette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
