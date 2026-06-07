import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cuenca_activa_app/features/auth/presentation/login_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/register_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/welcome_page.dart';
import 'package:cuenca_activa_app/features/home/presentation/home_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/incident_detail_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/my_reports_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/report_incident_page.dart';
import 'package:cuenca_activa_app/features/notifications/presentation/notifications_page.dart';
import 'package:cuenca_activa_app/features/profile/presentation/profile_page.dart';
import 'package:cuenca_activa_app/features/main/presentation/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _reportNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'report');
final GlobalKey<NavigatorState> _myReportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'myReports');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Stateful shell route for bottom navigation tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _reportNavigatorKey,
            routes: [
              GoRoute(
                path: '/report-incident',
                builder: (context, state) => const ReportIncidentPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _myReportsNavigatorKey,
            routes: [
              GoRoute(
                path: '/my-reports',
                builder: (context, state) => const MyReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      
      // Sub-routes pushed on top of the root navigator (full screen pages)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/incidents/:id',
        builder: (context, state) {
          return IncidentDetailPage(
            idIncidencia: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
