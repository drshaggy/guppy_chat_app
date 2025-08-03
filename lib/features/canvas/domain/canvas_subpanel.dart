import 'package:flutter/material.dart';

/// Abstract base class for all canvas subpanels
/// Provides a common interface for canvas features like code viewing, memory graphs, etc.
abstract class CanvasSubpanel extends StatefulWidget {
  /// Unique identifier for this subpanel type
  final String id;
  
  /// Display title for this subpanel (used in tabs)
  final String title;
  
  /// Icon to display in tabs
  final IconData icon;
  
  /// Content to display in this subpanel
  final String content;
  
  /// Additional metadata for the subpanel
  final Map<String, dynamic> metadata;
  
  /// Whether this subpanel can be closed
  final bool canClose;

  const CanvasSubpanel({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
    this.metadata = const {},
    this.canClose = true,
  });

  /// Called when the subpanel should be closed
  void onClose() {}
  
  /// Called when the subpanel becomes active
  void onActivate() {}
  
  /// Called when the subpanel becomes inactive
  void onDeactivate() {}
}

/// Base state class for canvas subpanels
abstract class CanvasSubpanelState<T extends CanvasSubpanel> extends State<T> {
  /// Whether this subpanel is currently active/visible
  bool get isActive => true; // Will be managed by canvas
  
  /// Theme data from parent context
  ThemeData get theme => Theme.of(context);
  
  /// Build the subpanel header (optional - canvas can provide default)
  Widget? buildHeader() => null;
  
  /// Build the main content area (required)
  Widget buildContent();
  
  /// Build any action buttons for the header (optional)
  List<Widget> buildActions() => [];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (buildHeader() != null) buildHeader()!,
        Expanded(child: buildContent()),
      ],
    );
  }
}

/// Enum for different subpanel types
enum SubpanelType {
  code,
  memory,
  data,
  document,
  image,
}

/// Configuration for creating subpanels
class SubpanelConfig {
  final SubpanelType type;
  final String id;
  final String title;
  final IconData icon;
  final String content;
  final Map<String, dynamic> metadata;
  final bool canClose;

  const SubpanelConfig({
    required this.type,
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
    this.metadata = const {},
    this.canClose = true,
  });

  factory SubpanelConfig.code({
    required String content,
    String? filename,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    final resolvedFilename = filename ?? 'code.${language ?? 'txt'}';
    final resolvedLanguage = language ?? 'text';
    
    return SubpanelConfig(
      type: SubpanelType.code,
      id: 'code_${DateTime.now().millisecondsSinceEpoch}',
      title: resolvedFilename,
      icon: _getLanguageIcon(resolvedLanguage),
      content: content,
      metadata: {
        'filename': resolvedFilename,
        'language': resolvedLanguage,
        'lineCount': content.split('\n').length,
        'charCount': content.length,
        ...?metadata,
      },
    );
  }

  factory SubpanelConfig.memory({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return SubpanelConfig(
      type: SubpanelType.memory,
      id: 'memory_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Memory Graph',
      icon: Icons.memory,
      content: content,
      metadata: metadata ?? {},
    );
  }

  factory SubpanelConfig.data({
    required String content,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    return SubpanelConfig(
      type: SubpanelType.data,
      id: 'data_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Data Viewer',
      icon: Icons.data_object,
      content: content,
      metadata: metadata ?? {},
    );
  }

  static IconData _getLanguageIcon(String language) {
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
}