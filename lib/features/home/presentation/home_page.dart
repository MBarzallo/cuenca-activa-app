import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../incidents/data/incident_model.dart';
import '../../incidents/logic/incidents_cubit.dart';
import '../../incidents/logic/incidents_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsCubit>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cuenca Activa'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesion',
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        floatingActionButton: authState is AuthAuthenticated
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/report-incident'),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Reportar'),
              )
            : null,
        body: SafeArea(
          child: switch (authState) {
            AuthAuthenticated(:final user) => RefreshIndicator(
              onRefresh: context.read<IncidentsCubit>().loadInitialData,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _WelcomeHeader(
                        name: user.nombres,
                        alias: user.aliasPublico,
                        points: user.puntosTotales,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Incidencias recientes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  BlocBuilder<IncidentsCubit, IncidentsState>(
                    builder: (context, state) {
                      if (state.loading) {
                        return const SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverToBoxAdapter(
                            child: _IncidentLoadingList(),
                          ),
                        );
                      }

                      if (state.errorMessage != null) {
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverToBoxAdapter(
                            child: _InfoState(
                              icon: Icons.cloud_off_rounded,
                              title: 'No pudimos cargar las incidencias',
                              message: state.errorMessage!,
                              actionLabel: 'Reintentar',
                              onAction: context
                                  .read<IncidentsCubit>()
                                  .loadInitialData,
                            ),
                          ),
                        );
                      }

                      if (state.incidents.isEmpty) {
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverToBoxAdapter(
                            child: _InfoState(
                              icon: Icons.location_searching_rounded,
                              title: 'Aun no hay reportes',
                              message:
                                  'Cuando la comunidad reporte incidencias, apareceran aqui.',
                              actionLabel: 'Crear primer reporte',
                              onAction: () => context.push('/report-incident'),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) {
                            return _IncidentCard(
                              incident: state.incidents[index],
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
            ),
            _ => const Center(child: Text('No hay usuario autenticado')),
          },
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String name;
  final String alias;
  final int points;

  const _WelcomeHeader({
    required this.name,
    required this.alias,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${name.isEmpty ? 'ciudadano' : name}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alias.isEmpty ? 'Perfil ciudadano' : '@$alias',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$points puntos comunitarios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final date = incident.fechaReporte;
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.titulo.isEmpty
                            ? 'Incidencia sin titulo'
                            : incident.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        incident.nombreCategoria,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: Icons.flag_rounded,
                  label: incident.nombreEstado,
                  color: AppColors.teal,
                ),
                _StatusChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: '${incident.cantidadConfirmaciones} confirmaciones',
                  color: AppColors.success,
                ),
                _StatusChip(
                  icon: Icons.schedule_rounded,
                  label: formattedDate,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentLoadingList extends StatelessWidget {
  const _IncidentLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 132,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.teal),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
