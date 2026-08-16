import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/developer/developer_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/expenses/expense_detail_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/opportunities/inbox_screen.dart';
import '../features/people/people_screens.dart';
import '../features/places/places_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/shell_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
    final user = ref.watch(sessionProfileProvider);
    return GoRouter(
    initialLocation: user == null ? '/welcome' : '/home',
    redirect: (context, state) {
      final loggingIn =
          state.matchedLocation == '/welcome' || state.matchedLocation == '/auth';
      if (user == null && !loggingIn) return '/welcome';
      if (user != null && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, nav) => ShellScreen(navigationShell: nav),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/expenses',
              builder: (_, __) => const ExpensesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/places', builder: (_, __) => const PlacesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/people', builder: (_, __) => const PeopleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/add',
        builder: (_, s) => AddExpenseScreen(
          initialAmountMinor: int.tryParse(s.uri.queryParameters['amount'] ?? ''),
          initialWhat: s.uri.queryParameters['what'],
          placeId: s.uri.queryParameters['placeId'],
        ),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (_, s) => ExpenseDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/people/:id',
        builder: (_, s) => PersonDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/places/:id',
        builder: (_, s) => PlaceDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/developer', builder: (_, __) => const DeveloperScreen()),
    ],
  );
});
