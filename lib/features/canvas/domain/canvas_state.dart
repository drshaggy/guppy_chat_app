import 'package:flutter/foundation.dart';

enum CanvasType {
  none,
  code,
  document,
  data,
  memory,
}

@immutable
class CanvasState {
  final bool isVisible;
  final CanvasType currentType;
  final String? content;
  final Map<String, dynamic>? metadata;

  const CanvasState({
    this.isVisible = false,
    this.currentType = CanvasType.none,
    this.content,
    this.metadata,
  });

  CanvasState copyWith({
    bool? isVisible,
    CanvasType? currentType,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return CanvasState(
      isVisible: isVisible ?? this.isVisible,
      currentType: currentType ?? this.currentType,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
    );
  }

  CanvasState show({
    required CanvasType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return copyWith(
      isVisible: true,
      currentType: type,
      content: content,
      metadata: metadata,
    );
  }

  CanvasState hide() {
    return copyWith(
      isVisible: false,
    );
  }

  CanvasState clear() {
    return copyWith(
      isVisible: false,
      currentType: CanvasType.none,
      content: null,
      metadata: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasState &&
        other.isVisible == isVisible &&
        other.currentType == currentType &&
        other.content == content &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      isVisible,
      currentType,
      content,
      metadata,
    );
  }

  @override
  String toString() {
    return 'CanvasState(isVisible: $isVisible, currentType: $currentType, content: ${content?.length} chars)';
  }
}