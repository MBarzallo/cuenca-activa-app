import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/notifications/push_notifications_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/logic/auth_cubit.dart';
import '../features/auth/logic/auth_state.dart';
import '../features/incidents/data/incidents_repository.dart';
import '../features/incidents/logic/incidents_cubit.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/logic/notifications_cubit.dart';
import 'router.dart';
import 'theme.dart';

class CuencaActivaApp extends StatelessWidget {
  const CuencaActivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(AuthRepository())..checkSession(),
        ),
        BlocProvider(create: (_) => IncidentsCubit(IncidentsRepository())),
        BlocProvider(
          create: (_) => NotificationsCubit(NotificationsRepository()),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            PushNotificationsService().initializeForAuthenticatedUser();
          }
        },
        child: MaterialApp.router(
          title: 'CuencaActiva',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
