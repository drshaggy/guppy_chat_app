// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/app/app.dart';
import 'package:guppy_chat_app/shared/providers/chat_providers.dart';
import 'package:guppy_chat_app/shared/services/chat_service.dart';
import 'package:guppy_chat_app/features/chat/domain/chat_state.dart';

class MockChatService extends ChatService {
  @override
  Future<bool> testConnection({String? baseUrl}) async {
    return Future.value(true);
  }
}

void main() {
  testWidgets('Guppy Chat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatServiceProvider.overrideWithValue(MockChatService()),
        ],
        child: const GuppyChatApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Guppy Chat'), findsOneWidget);
    expect(find.text('Welcome to Guppy Chat!'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });
}
