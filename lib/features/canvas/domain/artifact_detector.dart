import 'dart:convert';
import 'package:guppy_chat_app/features/canvas/domain/canvas_state.dart';

class ArtifactDetector {
  static const Map<String, String> _languageExtensions = {
    'javascript': 'js',
    'typescript': 'ts',
    'python': 'py',
    'dart': 'dart',
    'java': 'java',
    'cpp': 'cpp',
    'c': 'c',
    'csharp': 'cs',
    'php': 'php',
    'ruby': 'rb',
    'go': 'go',
    'rust': 'rs',
    'swift': 'swift',
    'kotlin': 'kt',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'sql': 'sql',
    'json': 'json',
    'yaml': 'yml',
    'xml': 'xml',
    'markdown': 'md',
    'bash': 'sh',
    'shell': 'sh',
    'powershell': 'ps1',
  };

  /// Detects artifacts in a message and returns the most significant one
  static ArtifactResult? detectArtifacts(String messageContent) {
    // Priority: Code blocks > JSON data > Inline code > File references
    
    // 1. Check for code blocks (highest priority)
    final codeBlocks = _detectCodeBlocks(messageContent);
    if (codeBlocks.isNotEmpty) {
      return ArtifactResult(
        type: CanvasType.code,
        artifacts: codeBlocks,
        primaryArtifact: codeBlocks.first,
      );
    }

    // 2. Check for JSON/structured data
    final jsonData = _detectJsonData(messageContent);
    if (jsonData != null) {
      return ArtifactResult(
        type: CanvasType.data,
        artifacts: [jsonData],
        primaryArtifact: jsonData,
      );
    }

    // 3. Check for multiple inline code snippets
    final inlineCode = _detectInlineCode(messageContent);
    if (inlineCode.length >= 3) { // Only show Canvas for multiple code snippets
      return ArtifactResult(
        type: CanvasType.code,
        artifacts: inlineCode,
        primaryArtifact: inlineCode.first,
      );
    }

    // 4. Check for file references/paths
    final fileRefs = _detectFileReferences(messageContent);
    if (fileRefs.isNotEmpty) {
      return ArtifactResult(
        type: CanvasType.document,
        artifacts: fileRefs,
        primaryArtifact: fileRefs.first,
      );
    }

    return null; // No significant artifacts found
  }

  /// Detects code blocks with ```language syntax
  static List<Artifact> _detectCodeBlocks(String content) {
    final codeBlocks = <Artifact>[];
    final codeBlockRegex = RegExp(
      r'```(\w+)?\n([\s\S]*?)\n```',
      multiLine: true,
    );

    final matches = codeBlockRegex.allMatches(content);
    for (final match in matches) {
      final language = match.group(1)?.toLowerCase() ?? 'text';
      final code = match.group(2)?.trim() ?? '';
      
      if (code.isNotEmpty) {
        codeBlocks.add(Artifact(
          id: 'code_${codeBlocks.length}',
          type: ArtifactType.code,
          content: code,
          metadata: {
            'language': language,
            'extension': _languageExtensions[language] ?? 'txt',
            'lineCount': code.split('\n').length,
            'charCount': code.length,
            'filename': _generateFilename(language, codeBlocks.length),
          },
        ));
      }
    }

    return codeBlocks;
  }

  /// Detects JSON data blocks
  static Artifact? _detectJsonData(String content) {
    // Look for JSON patterns (basic detection)
    final jsonPatterns = [
      RegExp(r'\{[\s\S]*?"[\w]+"[\s\S]*?:[\s\S]*?\}', multiLine: true),
      RegExp(r'\[[\s\S]*?\{[\s\S]*?\}[\s\S]*?\]', multiLine: true),
    ];

    for (final pattern in jsonPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        final potentialJson = match.group(0)!;
        try {
          // Validate it's actually valid JSON
          final decoded = jsonDecode(potentialJson);
          return Artifact(
            id: 'json_data',
            type: ArtifactType.data,
            content: _formatJson(potentialJson),
            metadata: {
              'dataType': 'json',
              'objectCount': decoded is List ? decoded.length : 1,
              'filename': 'data.json',
            },
          );
        } catch (e) {
          // Not valid JSON, continue
        }
      }
    }

    return null;
  }

  /// Detects inline code snippets
  static List<Artifact> _detectInlineCode(String content) {
    final inlineCode = <Artifact>[];
    final inlineCodeRegex = RegExp(r'`([^`\n]+)`');
    
    final matches = inlineCodeRegex.allMatches(content);
    for (final match in matches) {
      final code = match.group(1)?.trim() ?? '';
      if (code.length > 5) { // Only meaningful code snippets
        inlineCode.add(Artifact(
          id: 'inline_${inlineCode.length}',
          type: ArtifactType.code,
          content: code,
          metadata: {
            'language': _guessLanguage(code),
            'isInline': true,
            'charCount': code.length,
          },
        ));
      }
    }

    return inlineCode;
  }

  /// Detects file references and paths
  static List<Artifact> _detectFileReferences(String content) {
    final fileRefs = <Artifact>[];
    final filePathRegex = RegExp(
      r'(?:^|\s)([a-zA-Z]:)?[/\\]?(?:[^/\\:\*\?"<>\|]+[/\\])*[^/\\:\*\?"<>\|\s]+\.[a-zA-Z0-9]{1,6}(?:\s|$)',
      multiLine: true,
    );

    final matches = filePathRegex.allMatches(content);
    for (final match in matches) {
      final filePath = match.group(0)?.trim() ?? '';
      final extension = filePath.split('.').last.toLowerCase();
      
      fileRefs.add(Artifact(
        id: 'file_${fileRefs.length}',
        type: ArtifactType.file,
        content: filePath,
        metadata: {
          'filename': filePath.split('/').last.split('\\').last,
          'extension': extension,
          'fullPath': filePath,
        },
      ));
    }

    return fileRefs;
  }

  /// Generates appropriate filename for code blocks
  static String _generateFilename(String language, int index) {
    final extension = _languageExtensions[language] ?? 'txt';
    final baseName = language == 'text' ? 'code' : language;
    return index == 0 ? '$baseName.$extension' : '${baseName}_${index + 1}.$extension';
  }

  /// Attempts to guess programming language from code content
  static String _guessLanguage(String code) {
    // Simple heuristics for language detection
    if (code.contains('function') || code.contains('=>') || code.contains('const ')) {
      return 'javascript';
    }
    if (code.contains('def ') || code.contains('import ') || code.contains('print(')) {
      return 'python';
    }
    if (code.contains('class ') && code.contains('{')) {
      return 'java';
    }
    if (code.contains('<?php') || code.contains(r'$')) {
      return 'php';
    }
    if (code.contains('SELECT') || code.contains('FROM') || code.contains('WHERE')) {
      return 'sql';
    }
    return 'text';
  }

  /// Formats JSON with proper indentation
  static String _formatJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (e) {
      return jsonString; // Return original if formatting fails
    }
  }
}

/// Result of artifact detection
class ArtifactResult {
  final CanvasType type;
  final List<Artifact> artifacts;
  final Artifact primaryArtifact;

  const ArtifactResult({
    required this.type,
    required this.artifacts,
    required this.primaryArtifact,
  });

  @override
  String toString() {
    return 'ArtifactResult(type: $type, artifactCount: ${artifacts.length})';
  }
}

/// Represents a detected artifact
class Artifact {
  final String id;
  final ArtifactType type;
  final String content;
  final Map<String, dynamic> metadata;

  const Artifact({
    required this.id,
    required this.type,
    required this.content,
    required this.metadata,
  });

  String get filename => metadata['filename'] ?? 'artifact.txt';
  String get language => metadata['language'] ?? 'text';
  String get extension => metadata['extension'] ?? 'txt';
  int get charCount => metadata['charCount'] ?? content.length;
  int get lineCount => metadata['lineCount'] ?? content.split('\n').length;

  @override
  String toString() {
    return 'Artifact(id: $id, type: $type, ${content.length} chars)';
  }
}

/// Types of artifacts that can be detected
enum ArtifactType {
  code,
  data,
  file,
  image,
  document,
}