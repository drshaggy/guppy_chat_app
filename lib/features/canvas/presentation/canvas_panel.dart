import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_state.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_subpanel.dart';
import 'package:guppy_chat_app/features/canvas/providers/canvas_providers.dart';
import 'package:guppy_chat_app/features/canvas/presentation/widgets/code_canvas.dart';

class CanvasPanel extends ConsumerStatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const CanvasPanel({
    super.key,
    this.isVisible = false,
    this.onClose,
  });

  @override
  ConsumerState<CanvasPanel> createState() => _CanvasPanelState();
}

class _CanvasPanelState extends ConsumerState<CanvasPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0, // Start off-screen to the right
      end: 0.0,   // End in position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic, // Smooth reverse animation
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0, // Start transparent
      end: 1.0,   // End fully visible
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.8, curve: Curves.easeIn), // Fade out early on close
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CanvasPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // If not visible and animation is complete, return empty container
        if (!widget.isVisible && _animationController.isDismissed) {
          return const SizedBox.shrink();
        }
        
        return ClipRect(
          child: Transform.translate(
            offset: Offset(_slideAnimation.value * 400, 0), // Increased distance for smoother motion
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCanvasHeader(theme),
                    Expanded(
                      child: _buildCanvasContent(theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanvasHeader(ThemeData theme) {
    final canvasState = ref.watch(canvasStateProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Canvas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (canvasState.currentType == CanvasType.code) ..._buildSubpanelActions(),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          if (_shouldShowSubpanelTabs()) _buildSubpanelTabs(theme),
        ],
      ),
    );
  }

  List<Widget> _buildSubpanelActions() {
    final canvasState = ref.watch(canvasStateProvider);
    
    if (canvasState.currentType == CanvasType.code && canvasState.content != null) {
      // For now, return empty list - actions will be handled by subpanel
      // In future, we could show canvas-level actions here
      return [];
    }
    
    return [];
  }

  bool _shouldShowSubpanelTabs() {
    final canvasState = ref.watch(canvasStateProvider);
    
    // Show tabs if we have multiple artifacts or plan to support multiple subpanels
    if (canvasState.currentType == CanvasType.code) {
      final artifacts = canvasState.metadata?['artifacts'] as List?;
      return artifacts != null && artifacts.length > 1;
    }
    
    return false;
  }

  Widget _buildSubpanelTabs(ThemeData theme) {
    final canvasState = ref.watch(canvasStateProvider);
    
    if (canvasState.currentType == CanvasType.code) {
      final artifacts = canvasState.metadata?['artifacts'] as List?;
      if (artifacts == null || artifacts.length <= 1) {
        return const SizedBox.shrink();
      }
      
      return Container(
        height: 48,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: artifacts.length,
          itemBuilder: (context, index) {
            final artifact = artifacts[index];
            final currentArtifactId = canvasState.metadata?['currentArtifactId'];
            final isSelected = artifact.id == currentArtifactId;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: isSelected 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _switchToArtifact(artifact),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getLanguageIcon(artifact.language),
                          size: 16,
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          artifact.filename,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _switchToArtifact(dynamic artifact) {
    ref.read(canvasStateProvider.notifier).showArtifact(artifact);
  }

  IconData _getLanguageIcon(String language) {
    switch (language.toLowerCase()) {
      case 'javascript':
      case 'js':
        return Icons.code;
      case 'python':
      case 'py':
        return Icons.smart_toy;
      case 'dart':
        return Icons.flutter_dash;
      case 'html':
        return Icons.web;
      case 'css':
        return Icons.palette;
      case 'json':
        return Icons.data_object;
      case 'sql':
        return Icons.storage;
      default:
        return Icons.code;
    }
  }

  Widget _buildCanvasContent(ThemeData theme) {
    final canvasState = ref.watch(canvasStateProvider);
    
    if (!canvasState.isVisible || canvasState.content == null) {
      return _buildEmptyState(theme);
    }

    switch (canvasState.currentType) {
      case CanvasType.code:
        final config = SubpanelConfig.code(
          content: canvasState.content!,
          filename: canvasState.metadata?['filename'],
          language: canvasState.metadata?['language'],
          metadata: canvasState.metadata,
        );
        // Use currentArtifactId as key to force widget rebuild when switching artifacts
        final currentArtifactId = canvasState.metadata?['currentArtifactId'];
        return CodeCanvasSubpanel.fromConfig(
          config,
          key: ValueKey(currentArtifactId),
        );
      case CanvasType.data:
        return _buildDataCanvas(theme, canvasState.content!, canvasState.metadata ?? {});
      case CanvasType.document:
        return _buildDocumentCanvas(theme, canvasState.content!, canvasState.metadata ?? {});
      case CanvasType.memory:
        return _buildMemoryCanvas(theme);
      case CanvasType.none:
        return _buildEmptyState(theme);
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Canvas Ready',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message with code or structured content\nto see it displayed here beautifully.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCanvas(ThemeData theme, String content, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Data Canvas',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'Monaco',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCanvas(ThemeData theme, String content, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Document Canvas',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCanvas(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.memory,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Memory Canvas',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Zep memory visualization coming soon...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}