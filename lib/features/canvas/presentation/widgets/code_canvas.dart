import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_subpanel.dart';
import 'package:highlight/languages/all.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class CodeCanvasSubpanel extends CanvasSubpanel {
  const CodeCanvasSubpanel({
    super.key,
    required super.id,
    required super.title,
    required super.icon,
    required super.content,
    super.metadata = const {},
    super.canClose = true,
  });

  factory CodeCanvasSubpanel.fromConfig(SubpanelConfig config, {Key? key}) {
    return CodeCanvasSubpanel(
      key: key,
      id: config.id,
      title: config.title,
      icon: config.icon,
      content: config.content,
      metadata: config.metadata,
      canClose: config.canClose,
    );
  }

  @override
  State<CodeCanvasSubpanel> createState() => _CodeCanvasSubpanelState();
}

class _CodeCanvasSubpanelState extends CanvasSubpanelState<CodeCanvasSubpanel> {
  late CodeController _codeController;
  bool _isReadOnly = true;
  bool _showLineNumbers = true;
  bool _wordWrap = false;
  bool _isCopied = false;

  String get language => widget.metadata['language'] ?? 'text';
  String get filename => widget.metadata['filename'] ?? 'code.txt';
  int get lineCount => _codeController.text.split('\n').length;
  int get charCount => _codeController.text.length;
  
  double get gutterWidth {
    if (!_showLineNumbers) return 0;
    
    // Calculate width based on number of digits in line count
    final digits = lineCount.toString().length;
    // Base width: 20px, then add 12px per digit, plus 16px padding
    return 20 + (digits * 12) + 16;
  }

  @override
  void initState() {
    super.initState();
    _initializeCodeController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CodeCanvasSubpanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _codeController.text = widget.content;
    }
  }

  void _initializeCodeController() {
    final highlightLanguage = _getHighlightLanguage(language);
    final languageDefinition = allLanguages[highlightLanguage];
    
    _codeController = CodeController(
      text: widget.content,
      language: languageDefinition,
      analyzer: DefaultLocalAnalyzer(),
    );
  }

  String _getHighlightLanguage(String lang) {
    final languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'yml': 'yaml',
      'cpp': 'cpp',
      'c++': 'cpp',
    };
    return languageMap[lang.toLowerCase()] ?? lang.toLowerCase();
  }

  @override
  Widget buildContent() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _buildCodeEditor(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Language badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              language.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // File info - flexible but with minimum width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$lineCount lines • $charCount chars',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Buttons - right aligned and scrollable if needed
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                
                // Toggle controls
                _buildToggleButton(
                  Icons.edit,
                  'Edit mode',
                  !_isReadOnly,
                  () => setState(() => _isReadOnly = !_isReadOnly),
                ),
                const SizedBox(width: 8),
                _buildToggleButton(
                  Icons.format_list_numbered,
                  'Line numbers',
                  _showLineNumbers,
                  () => setState(() => _showLineNumbers = !_showLineNumbers),
                ),
                const SizedBox(width: 8),
                _buildToggleButton(
                  Icons.wrap_text,
                  'Word wrap',
                  _wordWrap,
                  () => setState(() => _wordWrap = !_wordWrap),
                ),
                const SizedBox(width: 16),
                
                // Actions
                _buildActionButton(
                  _isCopied ? Icons.check : Icons.copy,
                  _isCopied ? 'Copied!' : 'Copy code',
                  _copyToClipboard,
                  color: _isCopied ? Colors.green : null,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.download,
                  'Download',
                  _downloadCode,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.share,
                  'Share',
                  _shareCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    IconData icon,
    String tooltip,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive 
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: isActive 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: CodeTheme(
        data: CodeThemeData(
          styles: isDark ? monokaiSublimeTheme : githubTheme,
        ),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            readOnly: _isReadOnly,
            wrap: _wordWrap,
            gutterStyle: GutterStyle(
              showLineNumbers: _showLineNumbers,
              width: gutterWidth,
              textStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 12,
                fontFamily: 'Monaco',
              ),
              background: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
              margin: 8,
            ),
            textStyle: const TextStyle(
              fontFamily: 'Monaco',
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    setState(() => _isCopied = true);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  void _downloadCode() {
    // TODO: Implement file download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}