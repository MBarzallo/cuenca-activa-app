import 'package:equatable/equatable.dart';

import '../data/category_model.dart';
import '../data/incident_model.dart';

enum IncidentSubmitStatus { initial, loading, success, failure }

class IncidentsState extends Equatable {
  final bool loading;
  final List<CategoryModel> categories;
  final List<IncidentModel> incidents;
  final String? errorMessage;
  final IncidentSubmitStatus submitStatus;
  final String? submitMessage;

  const IncidentsState({
    required this.loading,
    required this.categories,
    required this.incidents,
    required this.errorMessage,
    required this.submitStatus,
    required this.submitMessage,
  });

  const IncidentsState.initial()
    : loading = false,
      categories = const [],
      incidents = const [],
      errorMessage = null,
      submitStatus = IncidentSubmitStatus.initial,
      submitMessage = null;

  IncidentsState copyWith({
    bool? loading,
    List<CategoryModel>? categories,
    List<IncidentModel>? incidents,
    String? errorMessage,
    bool clearError = false,
    IncidentSubmitStatus? submitStatus,
    String? submitMessage,
    bool clearSubmitMessage = false,
  }) {
    return IncidentsState(
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      incidents: incidents ?? this.incidents,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      submitMessage: clearSubmitMessage
          ? null
          : submitMessage ?? this.submitMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    categories,
    incidents,
    errorMessage,
    submitStatus,
    submitMessage,
  ];
}
