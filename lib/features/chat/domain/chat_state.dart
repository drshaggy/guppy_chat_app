import 'package:flutter/foundation.dart';
import 'package:guppy_chat_app/shared/models/chat_message.dart';

@immutable
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  ChatState clearError() {
    return copyWith(error: null);
  }

  ChatState addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      error: null,
    );
  }

  ChatState updateMessage(String messageId, ChatMessage updatedMessage) {
    final updatedMessages = messages.map((msg) {
      return msg.id == messageId ? updatedMessage : msg;
    }).toList();
    
    return copyWith(messages: updatedMessages);
  }

  ChatState removeMessage(String messageId) {
    final filteredMessages = messages.where((msg) => msg.id != messageId).toList();
    return copyWith(messages: filteredMessages);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        listEquals(other.messages, messages) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isConnected == isConnected;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(messages),
      isLoading,
      error,
      isConnected,
    );
  }

  @override
  String toString() {
    return 'ChatState(messages: ${messages.length}, isLoading: $isLoading, error: $error, isConnected: $isConnected)';
  }
}