import 'package:equatable/equatable.dart';

import '../data/category_model.dart';
import '../data/incident_comment_model.dart';
import '../data/incident_completion_confirmation_model.dart';
import '../data/incident_follow_model.dart';
import '../data/incident_model.dart';
import '../data/incident_vote_model.dart';
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
  final bool commentsLoading;
  final List<IncidentCommentModel> selectedIncidentComments;
  final String? commentsErrorMessage;
  final bool commentSubmitting;
  final String? commentSubmitMessage;
  final bool voteSummaryLoading;
  final IncidentVoteSummaryModel? voteSummary;
  final String? voteSummaryErrorMessage;
  final bool voteSubmitting;
  final String? voteSubmitMessage;
  final bool followStatusLoading;
  final IncidentFollowStatusModel? followStatus;
  final String? followStatusErrorMessage;
  final bool followActionLoading;
  final String? followActionMessage;
  final bool completionSummaryLoading;
  final IncidentCompletionSummaryModel? completionSummary;
  final String? completionSummaryErrorMessage;
  final bool completionSubmitting;
  final String? completionSubmitMessage;
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
    required this.commentsLoading,
    required this.selectedIncidentComments,
    required this.commentsErrorMessage,
    required this.commentSubmitting,
    required this.commentSubmitMessage,
    required this.voteSummaryLoading,
    required this.voteSummary,
    required this.voteSummaryErrorMessage,
    required this.voteSubmitting,
    required this.voteSubmitMessage,
    required this.followStatusLoading,
    required this.followStatus,
    required this.followStatusErrorMessage,
    required this.followActionLoading,
    required this.followActionMessage,
    required this.completionSummaryLoading,
    required this.completionSummary,
    required this.completionSummaryErrorMessage,
    required this.completionSubmitting,
    required this.completionSubmitMessage,
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
      commentsLoading = false,
      selectedIncidentComments = const [],
      commentsErrorMessage = null,
      commentSubmitting = false,
      commentSubmitMessage = null,
      voteSummaryLoading = false,
      voteSummary = null,
      voteSummaryErrorMessage = null,
      voteSubmitting = false,
      voteSubmitMessage = null,
      followStatusLoading = false,
      followStatus = null,
      followStatusErrorMessage = null,
      followActionLoading = false,
      followActionMessage = null,
      completionSummaryLoading = false,
      completionSummary = null,
      completionSummaryErrorMessage = null,
      completionSubmitting = false,
      completionSubmitMessage = null,
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
    bool? commentsLoading,
    List<IncidentCommentModel>? selectedIncidentComments,
    String? commentsErrorMessage,
    bool clearCommentsError = false,
    bool? commentSubmitting,
    String? commentSubmitMessage,
    bool clearCommentSubmitMessage = false,
    bool? voteSummaryLoading,
    IncidentVoteSummaryModel? voteSummary,
    String? voteSummaryErrorMessage,
    bool clearVoteSummaryError = false,
    bool clearVoteSummary = false,
    bool? voteSubmitting,
    String? voteSubmitMessage,
    bool clearVoteSubmitMessage = false,
    bool? followStatusLoading,
    IncidentFollowStatusModel? followStatus,
    String? followStatusErrorMessage,
    bool clearFollowStatusError = false,
    bool clearFollowStatus = false,
    bool? followActionLoading,
    String? followActionMessage,
    bool clearFollowActionMessage = false,
    bool? completionSummaryLoading,
    IncidentCompletionSummaryModel? completionSummary,
    String? completionSummaryErrorMessage,
    bool clearCompletionSummaryError = false,
    bool clearCompletionSummary = false,
    bool? completionSubmitting,
    String? completionSubmitMessage,
    bool clearCompletionSubmitMessage = false,
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
      commentsLoading: commentsLoading ?? this.commentsLoading,
      selectedIncidentComments:
          selectedIncidentComments ?? this.selectedIncidentComments,
      commentsErrorMessage: clearCommentsError
          ? null
          : commentsErrorMessage ?? this.commentsErrorMessage,
      commentSubmitting: commentSubmitting ?? this.commentSubmitting,
      commentSubmitMessage: clearCommentSubmitMessage
          ? null
          : commentSubmitMessage ?? this.commentSubmitMessage,
      voteSummaryLoading: voteSummaryLoading ?? this.voteSummaryLoading,
      voteSummary: clearVoteSummary ? null : voteSummary ?? this.voteSummary,
      voteSummaryErrorMessage: clearVoteSummaryError
          ? null
          : voteSummaryErrorMessage ?? this.voteSummaryErrorMessage,
      voteSubmitting: voteSubmitting ?? this.voteSubmitting,
      voteSubmitMessage: clearVoteSubmitMessage
          ? null
          : voteSubmitMessage ?? this.voteSubmitMessage,
      followStatusLoading: followStatusLoading ?? this.followStatusLoading,
      followStatus: clearFollowStatus
          ? null
          : followStatus ?? this.followStatus,
      followStatusErrorMessage: clearFollowStatusError
          ? null
          : followStatusErrorMessage ?? this.followStatusErrorMessage,
      followActionLoading: followActionLoading ?? this.followActionLoading,
      followActionMessage: clearFollowActionMessage
          ? null
          : followActionMessage ?? this.followActionMessage,
      completionSummaryLoading:
          completionSummaryLoading ?? this.completionSummaryLoading,
      completionSummary: clearCompletionSummary
          ? null
          : completionSummary ?? this.completionSummary,
      completionSummaryErrorMessage: clearCompletionSummaryError
          ? null
          : completionSummaryErrorMessage ?? this.completionSummaryErrorMessage,
      completionSubmitting: completionSubmitting ?? this.completionSubmitting,
      completionSubmitMessage: clearCompletionSubmitMessage
          ? null
          : completionSubmitMessage ?? this.completionSubmitMessage,
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
    commentsLoading,
    selectedIncidentComments,
    commentsErrorMessage,
    commentSubmitting,
    commentSubmitMessage,
    voteSummaryLoading,
    voteSummary,
    voteSummaryErrorMessage,
    voteSubmitting,
    voteSubmitMessage,
    followStatusLoading,
    followStatus,
    followStatusErrorMessage,
    followActionLoading,
    followActionMessage,
    completionSummaryLoading,
    completionSummary,
    completionSummaryErrorMessage,
    completionSubmitting,
    completionSubmitMessage,
    myReportsLoading,
    myReports,
    myReportsErrorMessage,
  ];
}
