import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_state.dart';
import 'package:guppy_chat_app/features/canvas/domain/canvas_subpanel.dart';
import 'package:guppy_chat_app/features/canvas/domain/artifact_detector.dart';

final canvasStateProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  void showCanvas({
    required CanvasType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    state = state.show(
      type: type,
      content: content,
      metadata: metadata,
    );
  }

  void hideCanvas() {
    state = state.hide();
  }

  void toggleCanvas() {
    if (state.isVisible) {
      hideCanvas();
    } else {
      // Show existing content if available, otherwise show empty state
      if (state.content != null && state.content!.isNotEmpty) {
        state = state.copyWith(isVisible: true);
      } else {
        showCanvas(
          type: CanvasType.none,
          content: '',
        );
      }
    }
  }

  void detectAndShowArtifacts(String messageContent) {
    final result = ArtifactDetector.detectArtifacts(messageContent);
    
    if (result != null) {
      showCanvas(
        type: result.type,
        content: result.primaryArtifact.content,
        metadata: {
          'artifacts': result.artifacts,
          'primaryArtifact': result.primaryArtifact,
          'currentArtifactId': result.primaryArtifact.id, // Track current artifact by ID
          'language': result.primaryArtifact.language,
          'filename': result.primaryArtifact.filename,
          'artifactCount': result.artifacts.length,
          'originalMessage': messageContent,
          'lineCount': result.primaryArtifact.content.split('\n').length,
          'charCount': result.primaryArtifact.content.length,
        },
      );
    }
  }

  void showArtifact(Artifact artifact) {
    final canvasType = switch (artifact.type) {
      ArtifactType.code => CanvasType.code,
      ArtifactType.data => CanvasType.data,
      ArtifactType.file => CanvasType.document,
      ArtifactType.document => CanvasType.document,
      ArtifactType.image => CanvasType.document,
    };

    // Preserve existing artifacts list and other metadata when switching tabs
    final existingArtifacts = state.metadata?['artifacts'];
    final existingArtifactCount = state.metadata?['artifactCount'];
    final existingOriginalMessage = state.metadata?['originalMessage'];

    showCanvas(
      type: canvasType,
      content: artifact.content,
      metadata: {
        // Preserve original artifacts list for tab system
        if (existingArtifacts != null) 'artifacts': existingArtifacts,
        if (existingArtifactCount != null) 'artifactCount': existingArtifactCount,
        if (existingOriginalMessage != null) 'originalMessage': existingOriginalMessage,
        // Current artifact metadata
        'currentArtifactId': artifact.id, // Track which artifact is currently selected
        'language': artifact.language,
        'filename': artifact.filename,
        'lineCount': artifact.content.split('\n').length,
        'charCount': artifact.content.length,
        ...artifact.metadata,
      },
    );
  }

  void showSubpanel(SubpanelConfig config) {
    final canvasType = switch (config.type) {
      SubpanelType.code => CanvasType.code,
      SubpanelType.data => CanvasType.data,
      SubpanelType.document => CanvasType.document,
      SubpanelType.memory => CanvasType.memory,
      SubpanelType.image => CanvasType.document,
    };

    showCanvas(
      type: canvasType,
      content: config.content,
      metadata: config.metadata,
    );
  }
}