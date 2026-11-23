import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/app/router.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/database_providers.dart';

ThemeMode parseThemeMode(String? raw) {
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class StudySpaceApp extends ConsumerWidget {
  const StudySpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final themeMode = parseThemeMode(profileAsync.valueOrNull?.themeMode);
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
