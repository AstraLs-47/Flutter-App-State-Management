// Flutter imports:
import 'package:flutter/material.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../features/admin/presentation/screens/admin_activities_screen.dart';
import '../../features/admin/presentation/screens/admin_announcements_screen.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/admin/presentation/screens/command_center_screen.dart';
import '../../features/announcement/presentation/screens/announcements_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screens.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/exercises/presentation/screens/exercises_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/profile/presentation/screens/contact_us_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/add_workout_screen.dart';
import '../../features/workout/presentation/screens/edit_workout_screen.dart';
import '../../features/workout/presentation/screens/tracking_screen.dart';
import '../constants/route_constants.dart';
import '../../domain/auth/user.dart';

// ─── RouterNotifier ────────────────────────────────────────────────────────
// Bridges Riverpod state changes to GoRouter refreshes.

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ─── Router ────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteConstants.root,
    refreshListenable: notifier,
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),

    // ── Role-Based Authorization Guard ──────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authStateNotifierProvider);
      final user = authState.valueOrNull;
      final location = state.matchedLocation;

      // While initial auth check is loading → don't redirect
      if (authState.isLoading) return null;

      // Public routes that don't require authentication
      final publicRoutes = {
        RouteConstants.root,
        RouteConstants.signIn,
        RouteConstants.signUp,
      };

      // Not authenticated
      if (user == null) {
        // Onboarding is also public (happens right after signup before session stabilises)
        if (location == RouteConstants.onboarding) return null;
        // Any non-public route → send to landing
        if (!publicRoutes.contains(location)) return RouteConstants.root;
        return null;
      }

      // ── Authenticated below this line ─────────────────────────────────────

      // Redirect away from auth/landing pages
      if (publicRoutes.contains(location)) {
        return user.role == UserRole.admin
            ? RouteConstants.admin
            : RouteConstants.dashboard;
      }

      // ── Authorization: Admin-only routes ──────────────────────────────────
      // Restricts /admin/* to admin role only.
      // Regular users who try to access /admin or any sub-route are sent to /dashboard.
      if (location.startsWith(RouteConstants.admin) &&
          user.role != UserRole.admin) {
        return RouteConstants.dashboard;
      }

      // All other authenticated routes are accessible to both roles
      return null;
    },

    routes: [
      // ── Public / Auth routes ───────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.root,
        name: RouteConstants.rootName,
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: RouteConstants.signIn,
        name: RouteConstants.signInName,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: RouteConstants.signUp,
        name: RouteConstants.signUpName,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        name: RouteConstants.onboardingName,
        builder: (_, __) => const OnboardingFlow(),
      ),

      // ── User routes (role: user) ───────────────────────────────────────────
      GoRoute(
        path: RouteConstants.dashboard,
        name: RouteConstants.dashboardName,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteConstants.announcements,
        name: RouteConstants.announcementsName,
        builder: (_, __) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: RouteConstants.contactUs,
        name: RouteConstants.contactUsName,
        builder: (_, __) => const ContactUsScreen(),
      ),
      GoRoute(
        path: RouteConstants.exerciseDetail,
        name: RouteConstants.exerciseDetailName,
        builder: (_, state) => ExerciseDetailScreen(
          exercise: state.extra as Map<String, String>,
        ),
      ),
      GoRoute(
        path: RouteConstants.profile,
        name: RouteConstants.profileName,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.exercises,
        name: RouteConstants.exercisesName,
        builder: (_, __) => const ExercisesScreen(),
      ),
      GoRoute(
        path: RouteConstants.products,
        name: RouteConstants.productsName,
        builder: (_, __) => const ProductsScreen(),
      ),

      // ── Workout tracking routes ────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.tracking,
        name: RouteConstants.trackingName,
        builder: (_, __) => const TrackingScreen(),
        routes: [
          GoRoute(
            path: RouteConstants.trackingAddRel,
            name: RouteConstants.trackingAddName,
            builder: (_, __) => const AddWorkoutScreen(),
          ),
          GoRoute(
            path: RouteConstants.trackingEditRel,
            name: RouteConstants.trackingEditName,
            builder: (_, __) => const EditWorkoutScreen(),
          ),
        ],
      ),

      // ── Admin routes (role: admin only — enforced by redirect guard above) ─
      GoRoute(
        path: RouteConstants.admin,
        name: RouteConstants.adminName,
        builder: (_, __) => const CommandCenterScreen(),
        routes: [
          GoRoute(
            path: RouteConstants.adminActivitiesRel,
            name: RouteConstants.adminActivitiesName,
            builder: (_, __) => const AdminActivitiesScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminProductsRel,
            name: RouteConstants.adminProductsName,
            builder: (_, __) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: RouteConstants.adminAnnouncementsRel,
            name: RouteConstants.adminAnnouncementsName,
            builder: (_, __) => const AdminAnnouncementsScreen(),
          ),
        ],
      ),
    ],
  );
});
