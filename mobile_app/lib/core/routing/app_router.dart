import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/diagnose/presentation/screens/diagnose_screen.dart';
import '../../features/farms/presentation/screens/add_farm_screen.dart';
import '../../features/farms/presentation/screens/farms_screen.dart';
import '../../features/farms/presentation/screens/location_hierarchy_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dashboard/data/dashboard_data.dart';
import '../../features/fertilizer/presentation/screens/fertilizer_screen.dart';
import '../../features/irrigation/presentation/screens/irrigation_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/water/presentation/screens/water_resource_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';

const _authRoutes = {'/splash', '/onboarding', '/login', '/otp', '/profile-setup'};

/// Bridges Riverpod auth state into go_router's `refreshListenable`, so a
/// login/logout/OTP-verify immediately re-evaluates the redirect logic
/// below instead of waiting for the next manual navigation.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(loc);

      switch (status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return (loc == '/login' || loc == '/onboarding') ? null : '/onboarding';
        case AuthStatus.otpSent:
          return null;
        case AuthStatus.authenticatedIncompleteProfile:
          return loc == '/profile-setup' ? null : '/profile-setup';
        case AuthStatus.authenticated:
          return isAuthRoute ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/weather', builder: (context, state) => const WeatherScreen()),
      GoRoute(path: '/diagnose', builder: (context, state) => const DiagnoseScreen()),
      GoRoute(
        path: '/water',
        builder: (context, state) => WaterResourceScreen(section: state.extra as WaterResourceSection),
      ),
      GoRoute(
        path: '/fertilizer',
        builder: (context, state) => FertilizerScreen(section: state.extra as FertilizerRecommendationSection),
      ),
      GoRoute(
        path: '/irrigation',
        builder: (context, state) => IrrigationScreen(section: state.extra as IrrigationPlanSection),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farms',
              builder: (context, state) => const FarmsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddFarmScreen(),
                  routes: [
                    GoRoute(path: 'location', builder: (context, state) => const LocationHierarchyScreen()),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/market', builder: (context, state) => const MarketScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
