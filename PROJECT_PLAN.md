# Flutter AI Guppy Chat App - Project Plan

## Project Overview
Cross-platform AI chat application for iPhone and macOS, featuring a dynamic side panel system with artifact viewer and Zep memory graph visualization. Inspired by Claude and ChatGPT apps.

## Technology Stack

### Core Framework
- **Flutter**: Cross-platform development for iOS and macOS
- **Dart**: Programming language

### State Management & Architecture
- **Riverpod**: Modern reactive state management
- **Material Design**: Primary UI framework with Cupertino touches for Apple platforms

### Networking & APIs
- **Dio**: HTTP client for API communication
- **n8n Backend**: Current AI Guppy hosting platform (subject to change)
- **Zep API**: Memory graph data retrieval

### UI & Visualization
- **flutter_highlight**: Syntax highlighting for code artifacts
- **flutter_markdown**: Markdown rendering for document artifacts
- **graphview**: Interactive network graphs for memory visualization
- **Material + Cupertino**: Hybrid UI approach for Apple ecosystem optimization

### Storage & Persistence
- **shared_preferences**: Settings and user preferences
- **sqflite**: SQLite database for chat history and artifact metadata
- **flutter_secure_storage**: Encrypted storage for API keys and sensitive data

## Architecture Overview

### Dynamic Side Panel System
- **Single versatile side panel** that switches between different content types
- **Panel Modes**:
  - Artifacts (code, documents, structured data)
  - Memory Graph (Zep memory visualization)
  - Chat History
  - Settings
- **Context-aware behavior**: Auto-show artifacts, manual memory graph access
- **Responsive design**: Desktop split-view, mobile overlay/modal

### Core Features

#### Chat Interface
- Real-time chat with AI Guppy
- Message bubbles with Material Design
- Input field with send functionality
- Message persistence with timestamps

#### Artifact System
- Automatic artifact detection from AI responses
- Type-specific rendering (code, markdown, JSON, images)
- Interactive features (copy, syntax highlighting, full-screen)
- Artifact history and metadata storage

#### Memory Graph Integration
- Zep API integration for memory data
- Interactive node exploration
- Relationship visualization between memories
- Contextual highlighting for current conversation
- On-demand loading (accessible via menu/button)

### Platform-Specific Considerations

#### iOS
- Info.plist configuration
- App icons and launch screens
- iOS-style navigation transitions
- Haptic feedback integration

#### macOS
- macOS support enablement
- App entitlements configuration
- Window management
- Native macOS UI components where appropriate

## Implementation Phases

### Phase 1: Project Setup ✅ COMPLETED
- ✅ Initialize Flutter project with iOS/macOS support
- ✅ Configure dependencies in pubspec.yaml
- ✅ Set up folder structure and architecture
- ✅ Resolve macOS code signing issues for development

### Phase 2: Core Chat Interface ✅ COMPLETED
- ✅ Implement beautiful chat UI with Material Design + Apple touches
- ✅ Set up Riverpod state management with reactive providers
- ✅ Integrate Dio for n8n API communication with real endpoint
- ✅ Implement message persistence and error handling
- ✅ Add connection status monitoring and retry mechanisms
- ✅ Create comprehensive test suite

### Phase 3: Dynamic Side Panel System 🔄 IN PROGRESS
- Build panel switching architecture
- Implement artifact detection and parsing
- Create type-specific artifact renderers
- Add panel state management

### Phase 4: Memory Graph Integration
- Integrate Zep API for memory data
- Implement graph visualization with graphview
- Add interactive node exploration
- Create memory-chat relationship highlighting

### Phase 5: Platform Optimization
- Add Cupertino touches for iOS/macOS
- Implement platform-specific UI behaviors
- Optimize responsive design
- Configure platform-specific settings

### Phase 6: Testing & Polish
- Unit tests for core logic and state management
- Widget tests for UI components
- Integration testing on both platforms
- Performance optimization
- Final UI polish and refinement

## Key Design Decisions

### State Management Choice
- **Riverpod selected** for modern reactive programming, compile-time safety, and industry relevance
- Provides clean separation of concerns and excellent testing capabilities

### UI Strategy
- **Material + Apple polish** approach for faster development with native feel
- Conditional platform-specific touches where user experience matters most

### Side Panel Architecture
- **Single dynamic panel** rather than multiple fixed panels for cleaner UI
- **Context-aware switching** to reduce cognitive load on users

### Memory Graph Access
- **Discoverable but not prominent** - power user feature accessible via menu
- **On-demand loading** to optimize performance and data usage

## Technical Achievements

### Resolved Challenges
- **macOS Code Signing**: Successfully disabled code signing for development while maintaining security
- **Network Permissions**: Configured proper entitlements for API communication
- **Cross-Platform UI**: Implemented responsive design that works on both iOS and macOS
- **State Management**: Built reactive state system with proper error handling and loading states
- **Real-time Updates**: Implemented live connection status and message state management

### Current API Configuration
- **n8n Endpoint**: `https://n8n.percy.network/webhook/e4cfbbff-9901-4331-82db-c2cf466bd7ce/chat`
- **Connection Status**: Live monitoring with visual indicators
- **Error Handling**: Comprehensive error states with retry mechanisms
- **Message Flow**: User input → n8n processing → AI response display

## Future Considerations
- Potential migration from n8n to other backend platforms
- Additional artifact types (images, interactive components)
- Advanced memory graph filtering and search
- Multi-chat session management
- Export/sharing functionality for conversations and artifacts

## Development Environment Requirements
- Flutter SDK (latest stable)
- Xcode (for iOS/macOS development)
- iOS Simulator and/or physical iOS device
- macOS development machine

---
*This plan serves as a living document and may be updated as the project evolves.*