import 'package:equatable/equatable.dart';

import '../data/category_model.dart';
import '../data/incident_comment_model.dart';
import '../data/incident_completion_confirmation_model.dart';
import '../data/incident_follow_model.dart';
import '../data/incident_model.dart';
import '../data/incident_status_history_model.dart';
import '../data/incident_status_option_model.dart';
import '../data/incident_vote_model.dart';
import '../data/multimedia_model.dart';
import '../data/incident_related_model.dart';

enum IncidentSubmitStatus { initial, loading, success, failure }

class IncidentsState extends Equatable {
  final bool loading;
  final bool nearbyLoading;
  final List<CategoryModel> categories;
  final List<IncidentModel> incidents;
  final String? errorMessage;
  final String? nearbyMessage;
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
  final List<IncidentVoteModel> recentVotes;
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
  final List<IncidentCompletionConfirmationDetailModel> recentConfirmations;
  final String? completionSummaryErrorMessage;
  final bool completionSubmitting;
  final String? completionSubmitMessage;
  final bool statusHistoryLoading;
  final List<IncidentStatusHistoryModel> statusHistory;
  final String? statusHistoryErrorMessage;
  final bool statusOptionsLoading;
  final List<IncidentStatusOptionModel> statusOptions;
  final bool statusChanging;
  final String? statusChangeMessage;
  final bool contentReportSubmitting;
  final String? contentReportMessage;
  final bool myReportsLoading;
  final List<IncidentModel> myReports;
  final String? myReportsErrorMessage;
  final bool relatedLoading;
  final List<IncidentRelatedModel> relatedIncidents;
  final String? relatedErrorMessage;

  const IncidentsState({
    required this.loading,
    required this.nearbyLoading,
    required this.categories,
    required this.incidents,
    required this.errorMessage,
    required this.nearbyMessage,
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
    required this.recentVotes,
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
    required this.recentConfirmations,
    required this.completionSummaryErrorMessage,
    required this.completionSubmitting,
    required this.completionSubmitMessage,
    required this.statusHistoryLoading,
    required this.statusHistory,
    required this.statusHistoryErrorMessage,
    required this.statusOptionsLoading,
    required this.statusOptions,
    required this.statusChanging,
    required this.statusChangeMessage,
    required this.contentReportSubmitting,
    required this.contentReportMessage,
    required this.myReportsLoading,
    required this.myReports,
    required this.myReportsErrorMessage,
    required this.relatedLoading,
    required this.relatedIncidents,
    required this.relatedErrorMessage,
  });

  const IncidentsState.initial()
    : loading = false,
      nearbyLoading = false,
      categories = const [],
      incidents = const [],
      errorMessage = null,
      nearbyMessage = null,
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
      recentVotes = const [],
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
      recentConfirmations = const [],
      completionSummaryErrorMessage = null,
      completionSubmitting = false,
      completionSubmitMessage = null,
      statusHistoryLoading = false,
      statusHistory = const [],
      statusHistoryErrorMessage = null,
      statusOptionsLoading = false,
      statusOptions = const [],
      statusChanging = false,
      statusChangeMessage = null,
      contentReportSubmitting = false,
      contentReportMessage = null,
      myReportsLoading = false,
      myReports = const [],
      myReportsErrorMessage = null,
      relatedLoading = false,
      relatedIncidents = const [],
      relatedErrorMessage = null;

  IncidentsState copyWith({
    bool? loading,
    bool? nearbyLoading,
    List<CategoryModel>? categories,
    List<IncidentModel>? incidents,
    String? errorMessage,
    String? nearbyMessage,
    bool clearError = false,
    bool clearNearbyMessage = false,
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
    List<IncidentVoteModel>? recentVotes,
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
    List<IncidentCompletionConfirmationDetailModel>? recentConfirmations,
    String? completionSummaryErrorMessage,
    bool clearCompletionSummaryError = false,
    bool clearCompletionSummary = false,
    bool? completionSubmitting,
    String? completionSubmitMessage,
    bool clearCompletionSubmitMessage = false,
    bool? statusHistoryLoading,
    List<IncidentStatusHistoryModel>? statusHistory,
    String? statusHistoryErrorMessage,
    bool clearStatusHistoryError = false,
    bool? statusOptionsLoading,
    List<IncidentStatusOptionModel>? statusOptions,
    bool? statusChanging,
    String? statusChangeMessage,
    bool clearStatusChangeMessage = false,
    bool? contentReportSubmitting,
    String? contentReportMessage,
    bool clearContentReportMessage = false,
    bool? myReportsLoading,
    List<IncidentModel>? myReports,
    String? myReportsErrorMessage,
    bool clearMyReportsError = false,
    bool? relatedLoading,
    List<IncidentRelatedModel>? relatedIncidents,
    String? relatedErrorMessage,
    bool clearRelatedError = false,
  }) {
    return IncidentsState(
      loading: loading ?? this.loading,
      nearbyLoading: nearbyLoading ?? this.nearbyLoading,
      categories: categories ?? this.categories,
      incidents: incidents ?? this.incidents,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      nearbyMessage: clearNearbyMessage
          ? null
          : nearbyMessage ?? this.nearbyMessage,
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
      recentVotes: recentVotes ?? this.recentVotes,
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
      recentConfirmations: recentConfirmations ?? this.recentConfirmations,
      completionSummaryErrorMessage: clearCompletionSummaryError
          ? null
          : completionSummaryErrorMessage ?? this.completionSummaryErrorMessage,
      completionSubmitting: completionSubmitting ?? this.completionSubmitting,
      completionSubmitMessage: clearCompletionSubmitMessage
          ? null
          : completionSubmitMessage ?? this.completionSubmitMessage,
      statusHistoryLoading: statusHistoryLoading ?? this.statusHistoryLoading,
      statusHistory: statusHistory ?? this.statusHistory,
      statusHistoryErrorMessage: clearStatusHistoryError
          ? null
          : statusHistoryErrorMessage ?? this.statusHistoryErrorMessage,
      statusOptionsLoading: statusOptionsLoading ?? this.statusOptionsLoading,
      statusOptions: statusOptions ?? this.statusOptions,
      statusChanging: statusChanging ?? this.statusChanging,
      statusChangeMessage: clearStatusChangeMessage
          ? null
          : statusChangeMessage ?? this.statusChangeMessage,
      contentReportSubmitting:
          contentReportSubmitting ?? this.contentReportSubmitting,
      contentReportMessage: clearContentReportMessage
          ? null
          : contentReportMessage ?? this.contentReportMessage,
      myReportsLoading: myReportsLoading ?? this.myReportsLoading,
      myReports: myReports ?? this.myReports,
      myReportsErrorMessage: clearMyReportsError
          ? null
          : myReportsErrorMessage ?? this.myReportsErrorMessage,
      relatedLoading: relatedLoading ?? this.relatedLoading,
      relatedIncidents: relatedIncidents ?? this.relatedIncidents,
      relatedErrorMessage: clearRelatedError ? null : relatedErrorMessage ?? this.relatedErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    nearbyLoading,
    categories,
    incidents,
    errorMessage,
    nearbyMessage,
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
    recentVotes,
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
    recentConfirmations,
    completionSummaryErrorMessage,
    completionSubmitting,
    completionSubmitMessage,
    statusHistoryLoading,
    statusHistory,
    statusHistoryErrorMessage,
    statusOptionsLoading,
    statusOptions,
    statusChanging,
    statusChangeMessage,
    contentReportSubmitting,
    contentReportMessage,
    myReportsLoading,
    myReports,
    myReportsErrorMessage,
    relatedLoading,
    relatedIncidents,
    relatedErrorMessage,
  ];
}
