import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/app/router.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';

ThemeMode parseThemeMode(String? raw) {
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class StudySpaceApp extends ConsumerStatefulWidget {
  const StudySpaceApp({super.key});

  @override
  ConsumerState<StudySpaceApp> createState() => _StudySpaceAppState();
}

class _StudySpaceAppState extends ConsumerState<StudySpaceApp> {
  bool _syncedOnLaunch = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (!_syncedOnLaunch && profile != null && profile.onboardingDone) {
      _syncedOnLaunch = true;
      Future.microtask(
        () => syncAllRemindersFromDb(
          ref.read(appDatabaseProvider),
          ref.read(notificationServiceProvider),
        ),
      );
    }

    final themeMode = parseThemeMode(profile?.themeMode);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StudySpace',
      debugShowCheckedModeBanner: false,
      theme: buildStudySpaceTheme(Brightness.light),
      darkTheme: buildStudySpaceTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
