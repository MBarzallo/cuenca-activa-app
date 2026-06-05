import 'package:equatable/equatable.dart';

import '../data/category_model.dart';
import '../data/incident_model.dart';
import '../data/multimedia_model.dart';

enum IncidentSubmitStatus { initial, loading, success, failure }

class IncidentsState extends Equatable {
  final bool loading;
  final List<CategoryModel> categories;
  final List<IncidentModel> incidents;
  final String? errorMessage;
  final IncidentSubmitStatus submitStatus;
  final String? submitMessage;
  final bool detailLoading;
  final IncidentModel? selectedIncident;
  final List<MultimediaModel> selectedIncidentMultimedia;
  final String? detailErrorMessage;
  final bool myReportsLoading;
  final List<IncidentModel> myReports;
  final String? myReportsErrorMessage;

  const IncidentsState({
    required this.loading,
    required this.categories,
    required this.incidents,
    required this.errorMessage,
    required this.submitStatus,
    required this.submitMessage,
    required this.detailLoading,
    required this.selectedIncident,
    required this.selectedIncidentMultimedia,
    required this.detailErrorMessage,
    required this.myReportsLoading,
    required this.myReports,
    required this.myReportsErrorMessage,
  });

  const IncidentsState.initial()
    : loading = false,
      categories = const [],
      incidents = const [],
      errorMessage = null,
      submitStatus = IncidentSubmitStatus.initial,
      submitMessage = null,
      detailLoading = false,
      selectedIncident = null,
      selectedIncidentMultimedia = const [],
      detailErrorMessage = null,
      myReportsLoading = false,
      myReports = const [],
      myReportsErrorMessage = null;

  IncidentsState copyWith({
    bool? loading,
    List<CategoryModel>? categories,
    List<IncidentModel>? incidents,
    String? errorMessage,
    bool clearError = false,
    IncidentSubmitStatus? submitStatus,
    String? submitMessage,
    bool clearSubmitMessage = false,
    bool? detailLoading,
    IncidentModel? selectedIncident,
    List<MultimediaModel>? selectedIncidentMultimedia,
    String? detailErrorMessage,
    bool clearDetailError = false,
    bool clearSelectedIncident = false,
    bool? myReportsLoading,
    List<IncidentModel>? myReports,
    String? myReportsErrorMessage,
    bool clearMyReportsError = false,
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
      detailLoading: detailLoading ?? this.detailLoading,
      selectedIncident: clearSelectedIncident
          ? null
          : selectedIncident ?? this.selectedIncident,
      selectedIncidentMultimedia:
          selectedIncidentMultimedia ?? this.selectedIncidentMultimedia,
      detailErrorMessage: clearDetailError
          ? null
          : detailErrorMessage ?? this.detailErrorMessage,
      myReportsLoading: myReportsLoading ?? this.myReportsLoading,
      myReports: myReports ?? this.myReports,
      myReportsErrorMessage: clearMyReportsError
          ? null
          : myReportsErrorMessage ?? this.myReportsErrorMessage,
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
    detailLoading,
    selectedIncident,
    selectedIncidentMultimedia,
    detailErrorMessage,
    myReportsLoading,
    myReports,
    myReportsErrorMessage,
  ];
}
