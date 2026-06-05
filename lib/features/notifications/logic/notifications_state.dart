import '../data/app_notification_model.dart';
import '../data/notification_preference_model.dart';

class NotificationsState {
  final bool loading;
  final bool preferencesLoading;
  final bool actionLoading;
  final List<AppNotificationModel> notifications;
  final List<NotificationPreferenceModel> preferences;
  final int unreadCount;
  final String? errorMessage;
  final String? actionMessage;

  const NotificationsState({
    required this.loading,
    required this.preferencesLoading,
    required this.actionLoading,
    required this.notifications,
    required this.preferences,
    required this.unreadCount,
    this.errorMessage,
    this.actionMessage,
  });

  const NotificationsState.initial()
    : loading = false,
      preferencesLoading = false,
      actionLoading = false,
      notifications = const [],
      preferences = const [],
      unreadCount = 0,
      errorMessage = null,
      actionMessage = null;

  NotificationsState copyWith({
    bool? loading,
    bool? preferencesLoading,
    bool? actionLoading,
    List<AppNotificationModel>? notifications,
    List<NotificationPreferenceModel>? preferences,
    int? unreadCount,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearActionMessage = false,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      preferencesLoading: preferencesLoading ?? this.preferencesLoading,
      actionLoading: actionLoading ?? this.actionLoading,
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }
}
