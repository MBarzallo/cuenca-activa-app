import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../incidents/data/incident_model.dart';
import 'home_shared_widgets.dart';

class IncidentBottomSheet extends StatelessWidget {
  final IncidentModel incident;

  const IncidentBottomSheet({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final date = incident.fechaReporte;
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IncidentCategoryIcon(
                  category: incident.nombreCategoria,
                  size: 52,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident.nombreCategoria,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              incident.descripcion.isEmpty
                  ? 'Sin descripcion disponible.'
                  : incident.descripcion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
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
                  icon: Icons.check_circle_outline_rounded,
                  label: '${incident.cantidadConfirmaciones} confirmaciones',
                  color: AppColors.success,
                ),
                StatusChip(
                  icon: Icons.schedule_rounded,
                  label: formattedDate,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if ((incident.direccionReferencial ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      incident.direccionReferencial!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.go('/incidents/${incident.idIncidencia}');
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ver detalle'),
            ),
          ],
        ),
      ),
    );
  }
}
