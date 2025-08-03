import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/features/chat/presentation/chat_screen.dart';
import 'package:guppy_chat_app/features/canvas/presentation/canvas_panel.dart';
import 'package:guppy_chat_app/features/canvas/providers/canvas_providers.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_state.dart';

class ChatLayout extends ConsumerStatefulWidget {
  const ChatLayout({super.key});

  @override
  ConsumerState<ChatLayout> createState() => _ChatLayoutState();
}

class _ChatLayoutState extends ConsumerState<ChatLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _layoutAnimationController;

  @override
  void initState() {
    super.initState();
    _layoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _layoutAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasStateProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);

    // Animate layout when Canvas visibility changes
    ref.listen(canvasStateProvider, (previous, next) {
      if (previous?.isVisible != next.isVisible) {
        if (next.isVisible) {
          // Start layout animation immediately with Canvas
          _layoutAnimationController.forward();
        } else {
          // Start layout animation immediately when closing
          _layoutAnimationController.reverse();
        }
      }
    });

    return Scaffold(
      body: AnimatedBuilder(
        animation: _layoutAnimationController,
        builder: (context, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          final canvasWidth = screenWidth * 0.6 * _layoutAnimationController.value;
          
          return Row(
            children: [
              // Chat Section (fills remaining space)
              Expanded(
                child: const ChatScreen(),
              ),
              
              // Canvas Section (animated width)
              SizedBox(
                width: canvasWidth,
                child: canvasWidth > 1 
                    ? CanvasPanel(
                        isVisible: canvasState.isVisible,
                        onClose: canvasNotifier.hideCanvas,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildCanvasToggle(canvasState, canvasNotifier),
    );
  }

  Widget _buildCanvasToggle(CanvasState canvasState, CanvasNotifier canvasNotifier) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.extended(
        onPressed: canvasNotifier.toggleCanvas,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            canvasState.isVisible ? Icons.close : Icons.palette_outlined,
            key: ValueKey(canvasState.isVisible),
          ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            canvasState.isVisible ? 'Close Canvas' : 'Open Canvas',
            key: ValueKey(canvasState.isVisible),
          ),
        ),
        backgroundColor: canvasState.isVisible 
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primary,
        foregroundColor: canvasState.isVisible
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}