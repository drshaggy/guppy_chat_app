# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Flutter AI Guppy Chat App

## Project Overview
This is a Flutter cross-platform AI chat application for iPhone and macOS. The app features a sophisticated dynamic side panel system with artifact viewer and Zep memory graph visualization, inspired by Claude and ChatGPT apps.

## Technology Stack
- **Framework**: Flutter with Dart
- **State Management**: Riverpod
- **Networking**: Dio HTTP client
- **UI**: Material Design with Cupertino touches for Apple platforms
- **Storage**: shared_preferences, sqflite, flutter_secure_storage
- **Visualization**: flutter_highlight, flutter_markdown, graphview
- **Code Editor**: flutter_code_editor, highlight

## Architecture Overview

### Core Application Structure
The app follows a feature-driven architecture with clear separation of concerns:

- **Features Layer**: Self-contained modules (`chat/`, `canvas/`, `memory_graph/`)
- **Shared Layer**: Common components, services, and providers used across features  
- **Core Layer**: App-wide configuration, constants, and utilities

### Canvas Subpanel System
The canvas implements a sophisticated subpanel architecture for extensible content rendering:

- **`CanvasSubpanel`**: Abstract base class defining the interface for all canvas features
- **`CanvasSubpanelState`**: Base state management for subpanel lifecycle and theming
- **`SubpanelConfig`**: Factory pattern for creating different subpanel types (code, memory, data)
- **Dynamic Content Switching**: Canvas can switch between different subpanel types seamlessly
- **Tabbed Interface**: Support for multiple artifacts within a single canvas session

### State Management Architecture
Built on Riverpod with reactive patterns:

- **Provider Hierarchy**: Services → State Notifiers → UI Components
- **Artifact Detection**: Smart parsing of chat messages for code blocks, JSON, and file references
- **Canvas State Management**: Centralized state for canvas visibility, content, and metadata
- **Chat State Management**: Message history, connection status, and API interaction state

### API Integrations
- **n8n Backend**: AI Guppy chat endpoint at `https://n8n.percy.network/webhook/e4cfbbff-9901-4331-82db-c2cf466bd7ce/chat`
- **Zep API**: Memory graph data retrieval and visualization (to be implemented)
- **Real-time Chat**: Message persistence and state management

### Cross-Platform Considerations
- **iOS**: Native navigation transitions, haptic feedback, platform-specific UI
- **macOS**: Window management, native macOS components, desktop-optimized layouts

## Development Commands

```bash
# Primary development workflow (from guppy_chat_app/ directory)
flutter run -d macos          # Run app on macOS (primary platform)
flutter run -d ios           # Run app on iOS simulator
flutter pub get               # Install/update dependencies
flutter analyze               # Code analysis and linting
flutter test                  # Run all tests
flutter clean && flutter pub get  # Clean build when dependencies change

# Code generation (when modifying Riverpod providers)
dart run build_runner build --delete-conflicting-outputs

# Platform builds
flutter build macos           # Build for macOS distribution
flutter build ios            # Build for iOS distribution
```

## Important Development Notes

### macOS Development Setup
Code signing has been configured for local development:
- Code signing disabled in `macos/Runner/Configs/Debug.xcconfig` and `Release.xcconfig`
- Network client permissions enabled in `DebugProfile.entitlements` for API access
- App sandboxing disabled for development builds

### Working Directory
All Flutter commands should be run from the `guppy_chat_app/` subdirectory, not the repository root.

## Key Dependencies

### Core Dependencies
- **flutter_riverpod**: State management and dependency injection
- **dio**: HTTP client for API communication with n8n backend
- **flutter_code_editor**: Advanced code editing with syntax highlighting for 100+ languages
- **flutter_highlight**: Syntax highlighting themes (GitHub, Monokai, etc.)

### Development Dependencies
- **flutter_lints**: Standard Flutter linting rules (primary linter)
- **very_good_analysis**: Enhanced linting rules beyond flutter_lints
- **riverpod_generator**: Code generation for Riverpod providers
- **build_runner**: Code generation runner

### Storage & Platform
- **shared_preferences**, **sqflite**, **flutter_secure_storage**: Multi-tier storage strategy
- **cupertino_icons**: iOS-style icons for cross-platform consistency

### Additional Dependencies
- **riverpod_annotation**: Annotations for Riverpod code generation
- **highlight**: Core highlighting engine used by flutter_code_editor

## Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
├── features/
│   ├── chat/
│   │   ├── domain/
│   │   └── presentation/
│   ├── canvas/
│   │   ├── domain/
│   │   │   ├── artifact_detector.dart
│   │   │   └── canvas_state.dart
│   │   ├── providers/
│   │   │   └── canvas_providers.dart
│   │   └── presentation/
│   │       ├── canvas_panel.dart
│   │       └── widgets/
│   │           └── code_canvas.dart
│   └── memory_graph/
├── shared/
│   ├── providers/
│   ├── services/
│   ├── models/
│   └── widgets/
└── core/
    ├── constants/
    ├── utils/
    └── config/
```

## Implementation Guidelines

### Canvas Subpanel Development
When creating new canvas subpanels:

1. **Extend `CanvasSubpanel`**: All canvas content must inherit from this base class
2. **Use `CanvasSubpanelState`**: Provides theme access and lifecycle management
3. **Create via `SubpanelConfig`**: Use factory methods (`SubpanelConfig.code()`, etc.) for consistent creation
4. **Implement `buildContent()`**: Required method for rendering subpanel content

### Code Editor Integration
The `flutter_code_editor` integration requires careful setup:

- **Language Detection**: Map user languages to highlight.js supported languages via `_getHighlightLanguage()`
- **Theme Application**: Use `CodeTheme` wrapper with proper theme maps (`githubTheme`, `monokaiSublimeTheme`)
- **Error Analysis**: `DefaultLocalAnalyzer` provides syntax error detection but can conflict with highlighting on malformed code
- **Controller Management**: Always dispose `CodeController` properly in widget lifecycle

### API Integration Pattern
Chat service follows this structure:

- **Payload Format**: `{"chatInput": "message", "sessionId": "conversation_id"}`
- **Response Format**: `{"output": "AI response content"}`
- **Error Handling**: Dio interceptors handle network failures with user feedback
- **State Updates**: Use Riverpod providers to broadcast API state changes

### Artifact Detection System
Messages are automatically parsed for displayable content:

- **Code Blocks**: Detects fenced code blocks with language specifications
- **JSON Data**: Identifies and formats JSON structures
- **File References**: Recognizes file paths and names for context
- **Multi-artifact**: Single messages can contain multiple artifacts with tab switching

## Current Configuration

### API Endpoints
- **n8n Chat**: `https://n8n.percy.network/webhook/e4cfbbff-9901-4331-82db-c2cf466bd7ce/chat`
- **Zep Memory**: Not yet configured (planned for memory graph feature)

### Development Status
- **Primary Platform**: macOS (code signing configured for local development)
- **Canvas System**: Subpanel architecture implemented with code editing capabilities
- **Syntax Highlighting**: Currently debugging theme application issues with malformed code
- **Chat Integration**: Fully functional with n8n backend

### Known Issues
- DefaultLocalAnalyzer disabled for malformed code to prevent theme conflicts with syntax highlighting
- Download and share functionality in code canvas marked as TODO (not yet implemented)
- SIGABRT crashes may occur due to threading issues in Dio HTTP client or state management race conditions

## Recent Architectural Improvements

### Tab Switching & State Preservation
The canvas now properly maintains artifact lists during tab switching through:
- **Artifact ID tracking**: Uses unique IDs instead of content comparison for tab selection
- **State preservation**: `showArtifact()` maintains original artifacts list and metadata
- **Widget rebuilding**: `ValueKey(currentArtifactId)` forces proper CodeCanvasSubpanel recreation

### Responsive UI & Overflow Handling
Recent fixes for toolbar and canvas layout:
- **Dynamic gutter width**: Calculates based on line count digits (`20px + digits * 12px + 16px padding`)
- **Toolbar overflow protection**: Action buttons in scrollable container with right-alignment
- **Responsive file info**: `Expanded` section with ellipsis overflow for long filenames

### Code Editor Enhancements
- **Theme switching**: Automatic dark/light theme detection with GitHub/Monokai themes
- **Language detection**: Enhanced mapping for 30+ languages with proper highlight.js integration
- **Professional styling**: Monaco font, proper line heights, and theme-aware gutter styling

## Development Patterns

### Artifact Detection Priority System
```
1. Code blocks (```language) → Multiple CodeCanvas artifacts with tabs
2. JSON data → Single DataCanvas with formatted JSON
3. Inline code (3+ snippets) → Multiple CodeCanvas artifacts  
4. File references → DocumentCanvas for file paths
```

### Canvas State Flow
```
Chat Message → ArtifactDetector → ArtifactResult → CanvasNotifier.showCanvas() →
Canvas UI Update → Tab System (if multiple artifacts) → User Interaction
```

### Widget Key Strategy
Critical for proper state management:
- Use `ValueKey(currentArtifactId)` for canvas subpanels to force rebuilds
- Maintain artifact list in canvas metadata for tab persistence
- Preserve original message content for context reconstruction

## Troubleshooting

### Common Development Issues

#### SIGABRT Crashes
If encountering SIGABRT crashes during development:
1. Run `flutter clean && flutter pub get` to clean build artifacts
2. Check Xcode console for detailed error information
3. Test on device vs simulator - crashes may be simulator-specific
4. Verify Dio HTTP client timeout configurations in `chat_service.dart`

#### Canvas/Artifact Display Issues
If artifacts are not displaying correctly:
1. Verify artifact detection patterns in `artifact_detector.dart`
2. Check canvas state management in `canvas_providers.dart`
3. Ensure proper widget keys are used for state rebuilding

#### Build Issues
If experiencing build failures:
1. Verify working directory is `guppy_chat_app/` not repository root
2. Run code generation if modifying providers: `dart run build_runner build --delete-conflicting-outputs`
3. Check platform-specific configurations in `ios/` and `macos/` directories