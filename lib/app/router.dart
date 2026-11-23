import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/widgets/study_scaffold.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/onboarding/onboarding_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  bool? onboardingDone;

  void update(bool? value) {
    if (onboardingDone != value) {
      onboardingDone = value;
      notifyListeners();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      body: const SizedBox.shrink(),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  final initial = ref.read(userProfileProvider);
  if (initial.hasValue) {
    refresh.onboardingDone = initial.value?.onboardingDone ?? false;
  }

  ref.listen(userProfileProvider, (_, next) {
    if (next.hasValue) {
      refresh.update(next.value?.onboardingDone ?? false);
    }
  });

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = refresh.onboardingDone;
      final loc = state.matchedLocation;
      if (done == null) return loc == '/splash' ? null : '/splash';
      if (!done) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/splash' || loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudyScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const _PlaceholderTab('Home'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timetable',
                builder: (context, state) => const _PlaceholderTab('Timetable'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assignments',
                builder: (context, state) => const _PlaceholderTab('Assignments'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                builder: (context, state) => const _PlaceholderTab('Focus'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const _PlaceholderTab('Notes'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});
