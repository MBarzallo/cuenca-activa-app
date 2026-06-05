import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../home/presentation/widgets/home_shared_widgets.dart';
import '../../main/presentation/main_scaffold.dart';
import '../logic/incidents_cubit.dart';
import '../logic/incidents_state.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsCubit>().loadMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/');
        }
      },
      child: MainScaffold(
        currentIndex: 2,
        title: 'Mis reportes',
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<IncidentsCubit, IncidentsState>(
            builder: (context, state) {
              final reports = state.myReports;

              if (state.myReportsLoading) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: IncidentLoadingList(),
                );
              }

              if (state.myReportsErrorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: HomeInfoState(
                    icon: Icons.cloud_off_rounded,
                    title: 'No pudimos cargar tus reportes',
                    message: state.myReportsErrorMessage!,
                    actionLabel: 'Reintentar',
                    onAction: context.read<IncidentsCubit>().loadMyReports,
                  ),
                );
              }

              if (reports.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: HomeInfoState(
                    icon: Icons.assignment_outlined,
                    title: 'Aun no tienes reportes',
                    message:
                        'Tus incidencias apareceran aqui para que puedas revisarlas rapidamente.',
                    actionLabel: 'Crear reporte',
                    onAction: () => context.go('/report-incident'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: context.read<IncidentsCubit>().loadMyReports,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  itemBuilder: (context, index) {
                    final incident = reports[index];

                    return IncidentCard(
                      incident: incident,
                      onTap: () =>
                          context.go('/incidents/${incident.idIncidencia}'),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: reports.length,
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/report-incident'),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Reportar'),
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
        ),
      ),
    );
  }
}
