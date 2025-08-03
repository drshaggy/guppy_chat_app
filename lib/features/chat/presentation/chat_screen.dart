import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/shared/providers/chat_providers.dart';
import 'package:guppy_chat_app/shared/widgets/message_bubble.dart';
import 'package:guppy_chat_app/shared/widgets/chat_input.dart' show ChatInput, chatInputKey;
import 'package:guppy_chat_app/shared/models/chat_message.dart';
import 'package:guppy_chat_app/app/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);
    final chatNotifier = ref.read(chatStateProvider.notifier);

    ref.listen(chatStateProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Guppy Chat'),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  chatState.isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: chatState.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  chatState.isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: chatState.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(chatState, chatNotifier),
          ),
          ChatInput(
            key: chatInputKey,
            onSendMessage: chatNotifier.sendMessage,
            isLoading: chatState.isLoading,
            isEnabled: chatState.isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppTheme.platformPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Guppy Chat!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation to begin',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('Tell me a joke'),
                _buildSuggestionChip('What can you help me with?'),
                _buildSuggestionChip('How are you today?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        ref.read(chatStateProvider.notifier).sendMessage(text);
      },
    );
  }

  Widget _buildMessagesList(chatState, chatNotifier) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return MessageBubble(
          message: message,
          onRetry: message.status == MessageStatus.error
              ? () => chatNotifier.retryMessage(message.id)
              : null,
        );
      },
    );
  }
}
