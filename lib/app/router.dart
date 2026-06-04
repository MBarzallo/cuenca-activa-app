import 'package:cuenca_activa_app/features/auth/presentation/login_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/register_page.dart';
import 'package:cuenca_activa_app/features/auth/presentation/welcome_page.dart';
import 'package:cuenca_activa_app/features/home/presentation/home_page.dart';
import 'package:cuenca_activa_app/features/incidents/presentation/report_incident_page.dart';
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
        path: '/report-incident',
        builder: (context, state) => const ReportIncidentPage(),
      ),
    ],
  );
}
