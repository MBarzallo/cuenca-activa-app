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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.actionMessage != current.actionMessage,
      listener: (context, state) {
        final message = state.actionMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                onPressed: state.loading
                    ? null
                    : () =>
                          context.read<NotificationsCubit>().loadNotifications(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _HeaderCard(state: state)),
                if (state.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(message: state.errorMessage!),
                  )
                else if (state.notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return _NotificationTile(notification: notification);
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: state.notifications.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _PreferencesSection(
                    loading: state.preferencesLoading,
                    preferences: state.preferences,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final NotificationsState state;

  const _HeaderCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.unreadCount} sin leer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alertas de reportes, comentarios y avances comunitarios.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Marcar todas como leidas',
                onPressed: state.unreadCount == 0 || state.actionLoading
                    ? null
                    : () => context.read<NotificationsCubit>().markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded),
              ),
            ],
          ),
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (!notification.leida) {
            context.read<NotificationsCubit>().markAsRead(
              notification.idNotificacion,
            );
          }
          if (notification.idIncidencia.isNotEmpty) {
            context.push('/incidents/${notification.idIncidencia}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_typeIcon(notification.codigoTipo), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!notification.leida)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ChipLabel(
                          label: notification.nombreTipo,
                          color: color,
                        ),
                        const Spacer(),
                        Text(
                          _relativeDate(notification.creadaEn),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
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

class _PreferencesSection extends StatelessWidget {
  final bool loading;
  final List<NotificationPreferenceModel> preferences;

  const _PreferencesSection({required this.loading, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferencias',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Controla que avisos quieres recibir en este dispositivo.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
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
    if (oldWidget.preference.radioCercaniaKm !=
        widget.preference.radioCercaniaKm) {
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: isNearby
              ? Text('Radio: ${_radio.toStringAsFixed(1)} km')
              : null,
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            'Aun no tienes notificaciones',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando alguien comente, siga un cambio o haya una alerta relevante, aparecera aqui.',
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

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 54,
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
            onPressed: () =>
                context.read<NotificationsCubit>().loadNotifications(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
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
