import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/core/constants/app_constants.dart';
import 'package:readspark/presentation/app/providers.dart';
import 'package:readspark/presentation/library/library_screen.dart';

/// Root widget of ReadSpark. All providers are composed in `providers.dart`
/// (see `lib/main.dart`), keeping business logic out of the UI layer.
class ReadSparkApp extends ConsumerWidget {
  const ReadSparkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeModeOf(settings?.theme),
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
      home: const LibraryScreen(),
    );
  }
}

/// Maps the persisted `'system' | 'light' | 'dark'` value (§19) to a
/// [ThemeMode]; unknown values fall back to the system theme.
ThemeMode themeModeOf(String? raw) => switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
