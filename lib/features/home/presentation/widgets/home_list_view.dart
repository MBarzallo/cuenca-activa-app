import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_user_model.dart';
import '../../../incidents/logic/incidents_cubit.dart';
import '../../../incidents/logic/incidents_state.dart';
import 'home_shared_widgets.dart';

class HomeListView extends StatelessWidget {
  final AuthUserModel user;

  const HomeListView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<IncidentsCubit>().loadInitialData,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: WelcomeHeader(
                name: user.nombres,
                alias: user.aliasPublico,
                points: user.puntosTotales,
                levelName: user.nombreNivelActual,
                levelProgress: user.nivelProgress,
                pointsToNextLevel: user.puntosParaSiguienteNivel,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Incidencias recientes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          BlocBuilder<IncidentsCubit, IncidentsState>(
            builder: (context, state) {
              if (state.loading) {
                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(child: IncidentLoadingList()),
                );
              }

              if (state.errorMessage != null) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: HomeInfoState(
                      icon: Icons.cloud_off_rounded,
                      title: 'No pudimos cargar las incidencias',
                      message: state.errorMessage!,
                      actionLabel: 'Reintentar',
                      onAction: context.read<IncidentsCubit>().loadInitialData,
                    ),
                  ),
                );
              }

              if (state.incidents.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: HomeInfoState(
                      icon: Icons.location_searching_rounded,
                      title: 'Aun no hay reportes',
                      message:
                          'Cuando la comunidad reporte incidencias, apareceran aqui.',
                      actionLabel: 'Crear primer reporte',
                      onAction: () => context.go('/report-incident'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final incident = state.incidents[index];

                    return IncidentCard(
                      incident: incident,
                      onTap: () =>
                          context.go('/incidents/${incident.idIncidencia}'),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: state.incidents.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
