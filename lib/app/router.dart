import 'package:cuenca_activa_app/features/auth/presentation/login_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/register_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/welcome_page.dart';
import 'package:cuenca_activa_app/features/home/presentation/home_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/incident_detail_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/my_reports_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/report_incident_page.dart';
import 'package:cuenca_activa_app/features/profile/presentation/profile_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: "/", builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/incidents/:id',
        builder: (context, state) {
          return IncidentDetailPage(
            idIncidencia: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/report-incident',
        builder: (context, state) => const ReportIncidentPage(),
      ),
      GoRoute(
        path: '/my-reports',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}
