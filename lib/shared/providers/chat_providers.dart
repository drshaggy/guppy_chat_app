import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/shared/services/chat_service.dart';
import 'package:guppy_chat_app/features/chat/domain/chat_state.dart';
import 'package:guppy_chat_app/shared/models/chat_message.dart';
import 'package:guppy_chat_app/features/canvas/providers/canvas_providers.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final Ref _ref;
  
  ChatNotifier(this._chatService, this._ref) : super(const ChatState()) {
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    final isConnected = await _chatService.testConnection();
    state = state.copyWith(isConnected: isConnected);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    state = state.addMessage(userMessage).copyWith(isLoading: true);

    try {
      final assistantMessage = await _chatService.sendMessage(
        message: content.trim(),
        conversationId: _getCurrentConversationId(),
      );

      state = state.addMessage(assistantMessage).copyWith(
        isLoading: false,
        error: null,
      );

      // Detect and show artifacts in the Canvas
      _ref.read(canvasStateProvider.notifier).detectAndShowArtifacts(assistantMessage.content);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${e.toString()}',
        role: MessageRole.system,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );

      state = state.addMessage(errorMessage).copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> retryMessage(String messageId) async {
    final message = state.messages.firstWhere(
      (msg) => msg.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );

    if (message.role == MessageRole.user) {
      state = state.removeMessage(messageId);
      await sendMessage(message.content);
    }
  }

  void clearError() {
    state = state.clearError();
  }

  void clearMessages() {
    state = const ChatState();
  }

  Future<void> loadConversationHistory(String conversationId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final messages = await _chatService.getConversationHistory(conversationId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  String _getCurrentConversationId() {
    return 'default_conversation_${DateTime.now().day}';
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}