import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/core/constants/app_constants.dart';

/// Root widget of ReadSpark. All providers are composed in [ProviderScope]
/// (see `lib/main.dart`), keeping business logic out of the UI layer.
class ReadSparkApp extends ConsumerWidget {
  const ReadSparkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _LibraryPlaceholder(),
    );
  }
}

/// Temporary placeholder for the library screen (real implementation in Phase 3).
class _LibraryPlaceholder extends StatelessWidget {
  const _LibraryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(child: Text('Biblioteca')),
    );
  }
}
