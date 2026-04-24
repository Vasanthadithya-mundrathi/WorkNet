import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:worknet/features/onboarding/screens/profile_setup_screen.dart';
import 'package:worknet/features/onboarding/screens/spotlight_setup_screen.dart';
import 'package:worknet/features/onboarding/screens/permission_screen.dart';
import 'package:worknet/features/feed/screens/nearby_feed_screen.dart';
import 'package:worknet/features/search/screens/search_screen.dart';
import 'package:worknet/features/profile/screens/my_profile_screen.dart';
import 'package:worknet/features/profile/screens/profile_editor_screen.dart';
import 'package:worknet/features/profile/screens/peer_profile_view_screen.dart';
import 'package:worknet/features/settings/screens/settings_screen.dart';
import 'package:worknet/features/settings/screens/privacy_settings_screen.dart';
import 'package:worknet/data/repositories/profile_repository.dart';
import 'package:worknet/services/permissions/permission_service.dart';

// ════════════════════════════════════════════════════════════════════
// Route path constants
// ════════════════════════════════════════════════════════════════════

abstract final class AppRoutes {
  static const String onboarding      = '/onboarding';
  static const String profileSetup    = '/onboarding/profile';
  static const String spotlightSetup  = '/onboarding/spotlight';
  static const String permissions     = '/onboarding/permissions';
  static const String feed            = '/';
  static const String search          = '/search';
  static const String myProfile       = '/me';
  static const String profileEditor   = '/me/edit';
  static const String settings        = '/settings';
  static const String privacySettings = '/settings/privacy';
  static String peerProfile(String userId) => '/profile/$userId';
}

// ════════════════════════════════════════════════════════════════════
// AppRouter Provider — plain Riverpod provider (no code generation)
// ════════════════════════════════════════════════════════════════════

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) async {
      // Guard: if onboarding complete and user lands on /onboarding, push to feed
      // We only redirect from the top-level onboarding to avoid loops.
      if (state.matchedLocation == AppRoutes.onboarding) {
        try {
          final repo = await ref.read(profileRepositoryProvider.future);
          final complete = await repo.isOnboardingComplete();
          if (complete) {
            // Wait, we must also check permissions before entering the feed
            final permSvc = ref.read(permissionServiceProvider);
            final permStatus = await permSvc.checkAll();
            if (permStatus == WorkNetPermissionStatus.granted) {
              return AppRoutes.feed;
            } else {
              return AppRoutes.permissions;
            }
          }
        } catch (_) {}
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (ctx, state) => const OnboardingSlidesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (ctx, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.spotlightSetup,
        builder: (ctx, state) => const SpotlightSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (ctx, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (ctx, state) => const NearbyFeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (ctx, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        builder: (ctx, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditor,
        builder: (ctx, state) => const ProfileEditorScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (ctx, state) => PeerProfileViewScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (ctx, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySettings,
        builder: (ctx, state) => const PrivacySettingsScreen(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: const Color(0xFF080D1A),
      body: Center(
        child: Text(
          'Page not found',
          style: const TextStyle(color: Color(0xFF8892A4)),
        ),
      ),
    ),
  );
});
