import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../incidents/data/incident_model.dart';

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback? onTap;

  const IncidentCard({super.key, required this.incident, this.onTap});

  String _relativeDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) {
      return 'Ahora';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} h';
    }
    if (diff.inDays < 2) {
      return 'Ayer';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} d';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Color _colorForStatus(String code) {
    final normalized = code.toUpperCase();
    if (normalized.contains('CERR') ||
        normalized.contains('FINAL') ||
        normalized.contains('RESUEL') ||
        normalized.contains('SOLUCION')) {
      return AppColors.success;
    }
    if (normalized.contains('PROCESO') ||
        normalized.contains('TRAB') ||
        normalized.contains('ASIG')) {
      return AppColors.gold;
    }
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = incident.imagenes.isNotEmpty;
    final categoryColor = _colorForCategory(incident.nombreCategoria);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.6)),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IncidentCategoryIcon(
                category: incident.nombreCategoria,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          incident.nombreCategoria,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _relativeDate(incident.fechaReporte),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.titulo.isEmpty ? 'Incidencia sin título' : incident.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CompactStatusChip(
                          label: incident.nombreEstado,
                          color: _colorForStatus(incident.codigoEstado),
                        ),
                        if (incident.cantidadConfirmaciones > 0)
                          _CompactMetricChip(
                            icon: Icons.check_circle_outline_rounded,
                            label: '${incident.cantidadConfirmaciones}',
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: incident.imagenes.first,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.lightGray.withValues(alpha: 0.5),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightGray.withValues(alpha: 0.5),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

class _CompactStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CompactStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactMetricChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
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
        4,
        (index) => Container(
          height: 100,
          margin: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.lightGray.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 30,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.lightGray.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.teal, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
