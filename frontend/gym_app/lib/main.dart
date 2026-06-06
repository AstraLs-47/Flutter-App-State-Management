// Flutter imports:
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Project imports:
import 'core/data/database_helper.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> initSQLite() async {
  if (kIsWeb) {
    // Web: handled by sqflite_common_ffi_web (configured separately)
    return;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    // Mobile: sqflite uses the native platform plugin — no FFI init needed
    return;
  }
  // Windows / Linux / macOS: needs FFI initialization
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSQLite();

  // Pre-initialize the database so it is open and ready before any repository
  // tries to query or insert.
  // On web: sqflite_common_ffi_web uses a Shared Worker (or Dedicated Worker as
  // a fallback) to run SQLite in the background. We pre-initialize it here
  // to ensure it is open and ready before any UI components load.
  await DatabaseHelper().ensureInitialized();

  // On web: override the global sqflite factory so all openDatabase() calls
  // (including the sqflite top-level helper) use the FFI-web implementation.
  if (kIsWeb) {
    sqflite.databaseFactory = databaseFactoryFfiWeb;
    debugPrint('main: sqflite databaseFactory set to databaseFactoryFfiWeb');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fitness Activity Tracking App',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
