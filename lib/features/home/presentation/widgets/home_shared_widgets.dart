import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../incidents/data/incident_model.dart';

class WelcomeHeader extends StatelessWidget {
  final String name;
  final String alias;
  final int points;

  const WelcomeHeader({
    super.key,
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

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback? onTap;

  const IncidentCard({super.key, required this.incident, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = incident.fechaReporte;
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IncidentCategoryIcon(category: incident.nombreCategoria),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}

class IncidentCategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const IncidentCategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(category);
    final color = _colorForCategory(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.54),
    );
  }

  IconData _iconForCategory(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('agua') || normalized.contains('alcantar')) {
      return Icons.water_drop_outlined;
    }

    if (normalized.contains('luz') || normalized.contains('eléctr')) {
      return Icons.bolt_outlined;
    }

    if (normalized.contains('via') || normalized.contains('calle')) {
      return Icons.add_road_outlined;
    }

    if (normalized.contains('basura') || normalized.contains('residuo')) {
      return Icons.delete_outline_rounded;
    }

    if (normalized.contains('seguridad')) {
      return Icons.shield_outlined;
    }

    return Icons.report_problem_outlined;
  }

  Color _colorForCategory(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('agua') || normalized.contains('alcantar')) {
      return const Color(0xFF0284C7);
    }

    if (normalized.contains('luz') || normalized.contains('eléctr')) {
      return AppColors.gold;
    }

    if (normalized.contains('basura') || normalized.contains('residuo')) {
      return const Color(0xFF16A34A);
    }

    if (normalized.contains('seguridad')) {
      return const Color(0xFF7C3AED);
    }

    return AppColors.teal;
  }
}

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusChip({
    super.key,
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

class IncidentLoadingList extends StatelessWidget {
  const IncidentLoadingList({super.key});

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

class HomeInfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const HomeInfoState({
    super.key,
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
