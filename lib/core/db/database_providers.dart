import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/services/entitlement_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return const FreeEntitlementService();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(appDatabaseProvider).watchProfile();
});

final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(appDatabaseProvider).watchSubjects();
});

final subjectsByIdProvider = Provider<Map<String, Subject>>((ref) {
  final list = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];
  return {for (final s in list) s.id: s};
});
