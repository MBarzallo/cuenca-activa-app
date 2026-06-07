import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../home/presentation/widgets/home_shared_widgets.dart';
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
      child: Scaffold(
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
                    onAction: () =>
                        context.read<IncidentsCubit>().loadMyReports(),
                  ),
                );
              }

              if (reports.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: HomeInfoState(
                    icon: Icons.assignment_outlined,
                    title: 'Aún no tienes reportes',
                    message:
                        'Cuando crees una incidencia, aparecerá en esta sección para que puedas seguir su estado.',
                    actionLabel: 'Reportar incidencia',
                    onAction: () => context.go('/report-incident'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<IncidentsCubit>().loadMyReports(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemBuilder: (context, index) {
                    final item = reports[index];
                    return IncidentCard(
                      incident: item,
                      onTap: () => context.push('/incidents/${item.idIncidencia}'),
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
