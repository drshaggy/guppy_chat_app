import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/app/theme/app_theme.dart';
import 'package:guppy_chat_app/features/chat/presentation/chat_layout.dart';

class GuppyChatApp extends ConsumerWidget {
  const GuppyChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Guppy Chat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ChatLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}