import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guppy_chat_app/app/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GuppyChatApp(),
    ),
  );
}
