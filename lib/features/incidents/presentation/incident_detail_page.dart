import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../home/presentation/widgets/home_shared_widgets.dart';
import '../../main/presentation/main_scaffold.dart';
import '../data/incident_model.dart';
import '../logic/incidents_cubit.dart';
import '../logic/incidents_state.dart';

class IncidentDetailPage extends StatefulWidget {
  final String idIncidencia;

  const IncidentDetailPage({super.key, required this.idIncidencia});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsCubit>().loadIncidentDetail(widget.idIncidencia);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      title: 'Detalle',
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            if (state.detailLoading) {
              return const _DetailLoadingView();
            }

            if (state.detailErrorMessage != null) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: HomeInfoState(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar el detalle',
                  message: state.detailErrorMessage!,
                  actionLabel: 'Reintentar',
                  onAction: () => context
                      .read<IncidentsCubit>()
                      .loadIncidentDetail(widget.idIncidencia),
                ),
              );
            }

            final incident = state.selectedIncident;
            if (incident == null) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: HomeInfoState(
                  icon: Icons.report_problem_outlined,
                  title: 'Incidencia no disponible',
                  message: 'No encontramos información para esta incidencia.',
                  actionLabel: 'Volver',
                  onAction: () => context.pop(),
                ),
              );
            }

            return _IncidentDetailContent(incident: incident);
          },
        ),
      ),
    );
  }
}

class _IncidentDetailContent extends StatelessWidget {
  final IncidentModel incident;

  const _IncidentDetailContent({required this.incident});

  @override
  Widget build(BuildContext context) {
    final date = incident.fechaReporte;
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _ImageGallery(images: incident.imagenes),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IncidentCategoryIcon(
                      category: incident.nombreCategoria,
                      size: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.titulo.isEmpty
                                ? 'Incidencia sin titulo'
                                : incident.titulo,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            incident.nombreCategoria,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  incident.descripcion.isEmpty
                      ? 'Sin descripción disponible.'
                      : incident.descripcion,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      icon: Icons.flag_rounded,
                      label: incident.nombreEstado,
                      color: AppColors.teal,
                    ),
                    StatusChip(
                      icon: Icons.person_outline_rounded,
                      label: incident.aliasUsuarioReporta.isEmpty
                          ? 'Ciudadano'
                          : '@${incident.aliasUsuarioReporta}',
                      color: AppColors.textSecondary,
                    ),
                    StatusChip(
                      icon: Icons.schedule_rounded,
                      label: formattedDate,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MetricsSection(incident: incident),
        const SizedBox(height: 14),
        _LocationSection(incident: incident),
      ],
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;

  const _ImageGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sin imágenes adjuntas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == images.length - 1 ? 0 : 10,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.lightGray,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.navy,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  final IncidentModel incident;

  const _MetricsSection({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Confirmaciones',
            value: incident.cantidadConfirmaciones,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.comment_outlined,
            label: 'Comentarios',
            value: incident.cantidadComentarios,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.visibility_outlined,
            label: 'Seguidores',
            value: incident.cantidadSeguidores,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final IncidentModel incident;

  const _LocationSection({required this.incident});

  @override
  Widget build(BuildContext context) {
    final hasCoordinates =
        incident.latitud != null && incident.longitud != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if ((incident.direccionReferencial ?? '').trim().isNotEmpty)
              _DetailRow(
                icon: Icons.place_outlined,
                text: incident.direccionReferencial!,
              ),
            if (hasCoordinates)
              _DetailRow(
                icon: Icons.my_location_rounded,
                text:
                    '${incident.latitud!.toStringAsFixed(6)}, ${incident.longitud!.toStringAsFixed(6)}',
              )
            else
              const _DetailRow(
                icon: Icons.location_off_outlined,
                text: 'Coordenadas no disponibles',
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLoadingView extends StatelessWidget {
  const _DetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        const SizedBox(height: 16),
        const IncidentLoadingList(),
      ],
    );
  }
}
