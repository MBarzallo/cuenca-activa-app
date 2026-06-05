import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository)
    : super(const NotificationsState.initial());

  Future<void> loadNotifications() async {
    emit(
      state.copyWith(
        loading: true,
        preferencesLoading: state.preferences.isEmpty,
        clearError: true,
        clearActionMessage: true,
      ),
    );

    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();
      final preferences = await _repository.getPreferences();

      emit(
        state.copyWith(
          loading: false,
          preferencesLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
          preferences: preferences,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          loading: false,
          preferencesLoading: false,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          preferencesLoading: false,
          errorMessage: 'No se pudieron cargar tus notificaciones.',
        ),
      );
    }
  }

  Future<void> markAsRead(String idNotificacion) async {
    emit(state.copyWith(actionLoading: true, clearActionMessage: true));

    try {
      final updated = await _repository.markAsRead(idNotificacion);
      final notifications = state.notifications.map((notification) {
        if (notification.idNotificacion == updated.idNotificacion) {
          return updated;
        }
        return notification;
      }).toList();

      emit(
        state.copyWith(
          actionLoading: false,
          notifications: notifications,
          unreadCount: notifications.where((item) => !item.leida).length,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(actionLoading: false, actionMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionMessage: 'No se pudo marcar la notificacion como leida.',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    emit(state.copyWith(actionLoading: true, clearActionMessage: true));

    try {
      await _repository.markAllAsRead();
      await loadNotifications();
      emit(
        state.copyWith(
          actionLoading: false,
          actionMessage: 'Notificaciones marcadas como leidas.',
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(actionLoading: false, actionMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionMessage: 'No se pudieron actualizar las notificaciones.',
        ),
      );
    }
  }

  Future<void> updatePreference({
    required String codigoTipo,
    required bool habilitada,
    double? radioCercaniaKm,
  }) async {
    emit(state.copyWith(actionLoading: true, clearActionMessage: true));

    try {
      final updated = await _repository.updatePreference(
        codigoTipo: codigoTipo,
        habilitada: habilitada,
        radioCercaniaKm: radioCercaniaKm,
      );
      final preferences = state.preferences.map((preference) {
        if (preference.codigoTipo == updated.codigoTipo) {
          return updated;
        }
        return preference;
      }).toList();

      emit(
        state.copyWith(
          actionLoading: false,
          preferences: preferences,
          actionMessage: 'Preferencia actualizada.',
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(actionLoading: false, actionMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionMessage: 'No se pudo actualizar la preferencia.',
        ),
      );
    }
  }
}
