import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/logic/auth_cubit.dart';
import '../features/incidents/data/incidents_repository.dart';
import '../features/incidents/logic/incidents_cubit.dart';
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
      ],
      child: MaterialApp.router(
        title: 'CuencaActiva',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
