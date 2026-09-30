import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/data/datasources/app_paths.dart';
import 'package:readspark/presentation/app/app.dart';
import 'package:readspark/presentation/app/providers.dart';

/// Application entry point: resolves the database location off the UI
/// thread, then composes providers in a single [ProviderScope].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseFile = await AppPaths.databaseFile();
  runApp(
    ProviderScope(
      overrides: [appDatabaseFileProvider.overrideWithValue(databaseFile)],
      child: const ReadSparkApp(),
    ),
  );
}
