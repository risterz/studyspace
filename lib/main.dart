import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/app/app.dart';
import 'package:studyspace/core/services/ambient_audio_service.dart';
import 'package:studyspace/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = LocalNotificationService();
  final ambientAudio = BackgroundAmbientAudioService();
  await notifications.init();
  await ambientAudio.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        ambientAudioServiceProvider.overrideWithValue(ambientAudio),
      ],
      child: const StudySpaceApp(),
    ),
  );
}
