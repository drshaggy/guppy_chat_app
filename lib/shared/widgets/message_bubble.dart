import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:guppy_chat_app/shared/models/chat_message.dart';
import 'package:guppy_chat_app/app/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isError = message.status == MessageStatus.error;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.platformPadding.horizontal / 2,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: _getBubbleColor(theme, isUser, isError),
                borderRadius: _getBorderRadius(isUser),
                border: isError 
                    ? Border.all(color: theme.colorScheme.error.withOpacity(0.3))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.role == MessageRole.system)
                    _buildSystemHeader(theme),
                  _buildMessageContent(context, theme),
                  const SizedBox(height: 4),
                  _buildMessageFooter(context, theme),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, true),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSystemHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'System',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ThemeData theme) {
    final textColor = _getTextColor(theme, message.role == MessageRole.user, message.status == MessageStatus.error);
    final isUser = message.role == MessageRole.user;
    
    // User messages: simple text, AI messages: markdown
    if (isUser) {
      return GestureDetector(
        onLongPress: () => _copyToClipboard(context),
        child: SelectableText(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            height: 1.4,
          ),
        ),
      );
    }
    
    // AI messages with markdown rendering
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context),
      child: MarkdownBody(
        data: message.content,
        selectable: true,
        styleSheet: _getMarkdownStyleSheet(theme, textColor),
        builders: {
          'code': CodeElementBuilder(theme: theme, context: context),
        },
        onTapLink: (text, href, title) {
          // Handle link taps if needed
        },
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: _getTextColor(theme, message.role == MessageRole.user, false).withValues(alpha: 0.6),
                ),
              ),
              if (message.status == MessageStatus.sending) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(
                      _getTextColor(theme, message.role == MessageRole.user, false).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
              if (message.status == MessageStatus.error && onRetry != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRetry,
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (message.content.isNotEmpty)
          _CopyButton(
            onPressed: () => _copyMessageToClipboard(context),
            theme: theme,
            size: 12,
          ),
      ],
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isUser, bool isError) {
    if (isError) {
      return theme.colorScheme.errorContainer;
    }
    if (isUser) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _getTextColor(ThemeData theme, bool isUser, bool isError) {
    if (isError) {
      return theme.colorScheme.onErrorContainer;
    }
    if (isUser) {
      return theme.colorScheme.onPrimary;
    }
    return theme.colorScheme.onSurface;
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  MarkdownStyleSheet _getMarkdownStyleSheet(ThemeData theme, Color textColor) {
    final isDark = theme.brightness == Brightness.dark;
    
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        color: textColor,
        height: 1.4,
      ),
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.2,
      ),
      code: TextStyle(
        fontFamily: 'Monaco',
        fontSize: 14,
        backgroundColor: isDark 
            ? Colors.grey[800]!.withValues(alpha: 0.3)
            : Colors.grey[200]!.withValues(alpha: 0.3),
        color: textColor,
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.transparent, // Let our custom builder handle styling
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: TextStyle(
        color: textColor.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyMessageToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  final BuildContext context;
  
  CodeElementBuilder({required this.theme, required this.context});
  
  @override
  Widget visitElementAfter(markdown.Element element, preferredStyle) {
    final String language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final String code = element.textContent;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[900]!.withValues(alpha: 0.4)
            : Colors.grey[100]!.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _CopyButton(
                    onPressed: () => _copyCodeToClipboard(code, context),
                    theme: theme,
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: _getLanguageForHighlight(language),
              theme: isDark ? vs2015Theme : githubTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'Monaco',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getLanguageForHighlight(String language) {
    // Map common language names to highlight.js language IDs
    final Map<String, String> languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'yml': 'yaml',
      'json': 'json',
      'xml': 'xml',
      'html': 'xml',
      'css': 'css',
      'dart': 'dart',
      'java': 'java',
      'cpp': 'cpp',
      'c': 'c',
      'go': 'go',
      'rust': 'rust',
      'php': 'php',
      'swift': 'swift',
      'kotlin': 'kotlin',
      'sql': 'sql',
    };
    
    return languageMap[language.toLowerCase()] ?? language;
  }
  
  void _copyCodeToClipboard(String code, BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
  }
}

class _CopyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;
  final double? size;
  
  const _CopyButton({
    required this.onPressed,
    required this.theme,
    this.size,
  });
  
  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isCopied = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(widget.size != null ? 4 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _getButtonColor(),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isCopied ? Icons.check : Icons.copy,
              key: ValueKey(_isCopied),
              size: widget.size ?? 14,
              color: _getIconColor(),
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleTap() {
    widget.onPressed();
    setState(() => _isCopied = true);
    
    // Reset to copy icon after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }
  
  Color _getButtonColor() {
    if (_isCopied) {
      return Colors.green.withValues(alpha: 0.2);
    } else if (_isPressed) {
      return widget.theme.colorScheme.primary.withValues(alpha: 0.3);
    } else if (_isHovered) {
      return widget.theme.colorScheme.primary.withValues(alpha: 0.15);
    }
    return Colors.transparent;
  }
  
  Color _getIconColor() {
    if (_isCopied) {
      return Colors.green;
    } else if (_isPressed) {
      return widget.theme.colorScheme.primary;
    } else if (_isHovered) {
      return widget.theme.colorScheme.primary;
    }
    return widget.theme.colorScheme.primary.withValues(alpha: 0.7);
  }
}