import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/app_notification_model.dart';
import '../data/notification_preference_model.dart';
import '../logic/notifications_cubit.dart';
import '../logic/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationFilter _activeFilter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().loadNotifications();
    });
  }

  String _getDateGroup(DateTime? date) {
    if (date == null) return 'Anteriores';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));

    final localDate = date.toLocal();
    final compareDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (compareDate == today) {
      return 'Hoy';
    } else if (compareDate == yesterday) {
      return 'Ayer';
    } else if (compareDate.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
      return 'Esta semana';
    } else {
      return 'Anteriores';
    }
  }

  void _showPreferencesSheet(BuildContext context, NotificationsState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationsCubit>(),
        child: _NotificationPreferencesSheet(
          preferences: state.preferences,
          loading: state.preferencesLoading,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) => previous.actionMessage != current.actionMessage,
      listener: (context, state) {
        final message = state.actionMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        // Local filtering
        final filteredNotifications = state.notifications.where((n) {
          if (_activeFilter == NotificationFilter.unread) {
            return !n.leida;
          }
          return true;
        }).toList();

        // Chronological grouping
        final groupedItems = <_GroupedNotificationItem>[];
        String? lastGroup;

        for (final notification in filteredNotifications) {
          final group = _getDateGroup(notification.creadaEn);
          if (group != lastGroup) {
            groupedItems.add(_GroupedNotificationItem.header(group));
            lastGroup = group;
          }
          groupedItems.add(_GroupedNotificationItem.notification(notification));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              if (state.unreadCount > 0)
                IconButton(
                  tooltip: 'Marcar todas como leídas',
                  onPressed: state.actionLoading
                      ? null
                      : () => context.read<NotificationsCubit>().markAllAsRead(),
                  icon: const Icon(Icons.done_all_rounded),
                ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: state.loading
                    ? null
                    : () => context.read<NotificationsCubit>().loadNotifications(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Preferencias',
                onPressed: () => _showPreferencesSheet(context, state),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().loadNotifications(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header and Local Filter Chips
                _HeaderSummary(unreadCount: state.unreadCount),
                _FilterChips(
                  activeFilter: _activeFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                  unreadCount: state.unreadCount,
                ),
                const SizedBox(height: 8),

                // Main Feed
                Expanded(
                  child: state.loading
                      ? ListView.builder(
                          itemCount: 6,
                          itemBuilder: (context, index) => const _NotificationTileSkeleton(),
                        )
                      : state.errorMessage != null
                          ? _ErrorState(
                              message: state.errorMessage!,
                              onRetry: context.read<NotificationsCubit>().loadNotifications,
                            )
                          : filteredNotifications.isEmpty
                              ? _EmptyState(
                                  isFilteringUnread: _activeFilter == NotificationFilter.unread,
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: groupedItems.length,
                                  itemBuilder: (context, index) {
                                    final item = groupedItems[index];
                                    if (item.header != null) {
                                      return _GroupHeader(title: item.header!);
                                    } else {
                                      return _NotificationTile(notification: item.notification!);
                                    }
                                  },
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum NotificationFilter { all, unread }

class _GroupedNotificationItem {
  final String? header;
  final AppNotificationModel? notification;

  _GroupedNotificationItem.header(this.header) : notification = null;
  _GroupedNotificationItem.notification(this.notification) : header = null;
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final int unreadCount;

  const _HeaderSummary({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
            size: 16,
            color: unreadCount > 0 ? AppColors.teal : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            unreadCount == 0 ? 'Todo al día' : 'Tienes $unreadCount sin leer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: unreadCount > 0 ? AppColors.navy : AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 4),
          if (unreadCount > 0)
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final NotificationFilter activeFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final int unreadCount;

  const _FilterChips({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            selected: activeFilter == NotificationFilter.all,
            onTap: () => onFilterChanged(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sin leer',
            badgeCount: unreadCount > 0 ? unreadCount : null,
            selected: activeFilter == NotificationFilter.unread,
            onTap: () => onFilterChanged(NotificationFilter.unread),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.badgeCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : AppColors.teal,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      color: selected ? AppColors.teal : AppColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.codigoTipo);
    final isUnread = !notification.leida;

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? AppColors.teal.withValues(alpha: 0.04) : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGray.withValues(alpha: 0.5),
            width: 1,
          ),
          left: BorderSide(
            color: isUnread ? AppColors.teal : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isUnread) {
            context.read<NotificationsCubit>().markAsRead(notification.idNotificacion);
          }
          if (notification.idIncidencia.isNotEmpty) {
            context.push('/incidents/${notification.idIncidencia}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon(notification.codigoTipo),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
                                  color: isUnread ? AppColors.navy : AppColors.textPrimary,
                                ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ChipLabel(
                          label: notification.nombreTipo,
                          color: color,
                        ),
                        const Spacer(),
                        Text(
                          _relativeDate(notification.creadaEn),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
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

class _NotificationPreferencesSheet extends StatelessWidget {
  final List<NotificationPreferenceModel> preferences;
  final bool loading;

  const _NotificationPreferencesSheet({
    required this.preferences,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Preferencias',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Controla qué avisos quieres recibir en este dispositivo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 14),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ...preferences.map((preference) {
                  return _PreferenceSwitch(preference: preference);
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatefulWidget {
  final NotificationPreferenceModel preference;

  const _PreferenceSwitch({required this.preference});

  @override
  State<_PreferenceSwitch> createState() => _PreferenceSwitchState();
}

class _PreferenceSwitchState extends State<_PreferenceSwitch> {
  late double _radio;

  @override
  void initState() {
    super.initState();
    _radio = _normalizeRadio(widget.preference.radioCercaniaKm);
  }

  @override
  void didUpdateWidget(covariant _PreferenceSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preference.radioCercaniaKm != widget.preference.radioCercaniaKm) {
      _radio = _normalizeRadio(widget.preference.radioCercaniaKm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final preference = widget.preference;
    final isNearby = preference.codigoTipo == 'INCIDENCIA_CERCANA';
    final disabled = state.actionLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: preference.habilitada,
          title: Text(
            preference.nombreTipo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: isNearby ? Text('Radio: ${_radio.toStringAsFixed(1)} km') : null,
          onChanged: disabled
              ? null
              : (value) {
                  context.read<NotificationsCubit>().updatePreference(
                        codigoTipo: preference.codigoTipo,
                        habilitada: value,
                        radioCercaniaKm: _radio,
                      );
                },
        ),
        if (isNearby) ...[
          Slider(
            min: 0.5,
            max: 20,
            divisions: 39,
            value: _radio,
            label: '${_radio.toStringAsFixed(1)} km',
            onChanged: preference.habilitada && !disabled
                ? (value) => setState(() => _radio = value)
                : null,
            onChangeEnd: preference.habilitada && !disabled
                ? (value) {
                    context.read<NotificationsCubit>().updatePreference(
                          codigoTipo: preference.codigoTipo,
                          habilitada: preference.habilitada,
                          radioCercaniaKm: value,
                        );
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  '0.5 km',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const Spacer(),
                Text(
                  '20 km',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            child: Text(
              'Este rango se usa para el mapa y las alertas de incidencias cercanas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  double _normalizeRadio(double? value) {
    return (value ?? 2.0).clamp(0.5, 20).toDouble();
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFilteringUnread;

  const _EmptyState({required this.isFilteringUnread});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFilteringUnread ? 'Sin notificaciones pendientes' : 'Aún no tienes notificaciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            isFilteringUnread
                ? '¡Estás al día! No tienes notificaciones sin leer en este momento.'
                : 'Cuando ocurra algo de tu interés, como comentarios o actualizaciones, lo verás aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: AppColors.danger,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTileSkeleton extends StatelessWidget {
  const _NotificationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGray.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
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
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _typeIcon(String code) {
  switch (code) {
    case 'NUEVO_COMENTARIO':
      return Icons.mode_comment_outlined;
    case 'CAMBIO_ESTADO':
      return Icons.sync_alt_rounded;
    case 'INCIDENCIA_CERCANA':
      return Icons.near_me_outlined;
    case 'LOGRO_DESBLOQUEADO':
      return Icons.emoji_events_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _typeColor(String code) {
  switch (code) {
    case 'NUEVO_COMENTARIO':
      return AppColors.teal;
    case 'CAMBIO_ESTADO':
      return AppColors.gold;
    case 'INCIDENCIA_CERCANA':
      return AppColors.danger;
    case 'LOGRO_DESBLOQUEADO':
      return AppColors.success;
    default:
      return AppColors.textSecondary;
  }
}

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
  if (diff.inDays < 7) {
    return '${diff.inDays} d';
  }

  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
