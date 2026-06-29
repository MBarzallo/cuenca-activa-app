import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_user_model.dart';
import '../../../incidents/logic/incidents_cubit.dart';
import '../../../incidents/logic/incidents_state.dart';
import '../../../incidents/data/incident_model.dart';
import 'home_shared_widgets.dart';

class HomeListView extends StatefulWidget {
  final AuthUserModel user;
  final double topPadding;

  const HomeListView({
    super.key,
    required this.user,
    this.topPadding = 0,
  });

  @override
  State<HomeListView> createState() => _HomeListViewState();
}

class _HomeListViewState extends State<HomeListView> {
  String _selectedFilter = 'Todas';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        // Filter logic
        final incidents = state.incidents;
        List<IncidentModel> filteredList = incidents;

        if (_selectedFilter == 'Recientes') {
          final limitDate = DateTime.now().subtract(const Duration(days: 7));
          final recent = incidents
              .where((i) => i.fechaReporte != null && i.fechaReporte!.isAfter(limitDate))
              .toList();
          filteredList = recent.isNotEmpty ? recent : incidents.take(5).toList();
        } else if (_selectedFilter == 'Pendientes') {
          filteredList = incidents.where((i) {
            final code = i.codigoEstado.toUpperCase();
            final name = i.nombreEstado.toUpperCase();
            final isClosed = code.contains('CERR') ||
                code.contains('FINAL') ||
                code.contains('RESUEL') ||
                code.contains('SOLUCION') ||
                name.contains('CERR') ||
                name.contains('FINAL') ||
                name.contains('RESUEL') ||
                name.contains('SOLUCION');
            return !isClosed;
          }).toList();
        } else if (_selectedFilter == 'Con confirmaciones') {
          filteredList = incidents.where((i) => i.cantidadConfirmaciones > 0).toList();
        }

        return RefreshIndicator(
          onRefresh: context.read<IncidentsCubit>().loadInitialData,
          child: CustomScrollView(
            slivers: [
              if (widget.topPadding > 0)
                SliverToBoxAdapter(
                  child: SizedBox(height: widget.topPadding),
                ),
              
              // New Compact Feed Header
              SliverToBoxAdapter(
                child: _IncidentFeedHeader(
                  totalCount: filteredList.length,
                ),
              ),

              // Horizontal scroll filter chips
              SliverToBoxAdapter(
                child: _FilterChipsScroll(
                  selectedFilter: _selectedFilter,
                  onChanged: (newFilter) {
                    setState(() {
                      _selectedFilter = newFilter;
                    });
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Main Feed Body
              if (state.loading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverToBoxAdapter(child: IncidentLoadingList()),
                )
              else if (state.errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverToBoxAdapter(
                    child: HomeInfoState(
                      icon: Icons.cloud_off_rounded,
                      title: 'No pudimos cargar los reportes',
                      message: state.errorMessage!,
                      actionLabel: 'Reintentar',
                      onAction: context.read<IncidentsCubit>().loadInitialData,
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverToBoxAdapter(
                    child: HomeInfoState(
                      icon: Icons.location_searching_rounded,
                      title: _selectedFilter == 'Todas' ? 'Aún no hay reportes' : 'Sin coincidencias',
                      message: _selectedFilter == 'Todas'
                          ? 'Cuando la comunidad reporte incidencias, aparecerán aquí.'
                          : 'No encontramos reportes que coincidan con este filtro.',
                      actionLabel: 'Crear reporte',
                      onAction: () => context.go('/report-incident'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final incident = filteredList[index];
                      return IncidentCard(
                        incident: incident,
                        onTap: () => context.push('/incidents/${incident.idIncidencia}'),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemCount: filteredList.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IncidentFeedHeader extends StatelessWidget {
  final int totalCount;

  const _IncidentFeedHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidencias recientes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reportes compartidos por la comunidad',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCount reportes',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipsScroll extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _FilterChipsScroll({required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = ['Todas', 'Recientes', 'Pendientes', 'Con confirmaciones'];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(
                filter,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              onSelected: (_) => onChanged(filter),
              backgroundColor: AppColors.white,
              selectedColor: AppColors.teal,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected ? AppColors.teal : AppColors.lightGray.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        },
      ),
    );
  }
}
