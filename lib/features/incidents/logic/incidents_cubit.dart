import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/incident_completion_confirmation_model.dart';
import '../data/incident_image_attachment.dart';
import '../data/incident_model.dart';
import '../data/incidents_repository.dart';
import 'incidents_state.dart';

class IncidentsCubit extends Cubit<IncidentsState> {
  final IncidentsRepository _repository;

  IncidentsCubit(this._repository) : super(const IncidentsState.initial());

  Future<void> loadInitialData() async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        submitStatus: IncidentSubmitStatus.initial,
        clearSubmitMessage: true,
      ),
    );

    try {
      final categories = await _repository.getCategories();
      final incidents = await _repository.getIncidents();

      emit(
        state.copyWith(
          loading: false,
          categories: categories,
          incidents: incidents,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(loading: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'No se pudo cargar la informacion de incidencias.',
        ),
      );
    }
  }

  Future<void> refreshIncidents() async {
    try {
      final incidents = await _repository.getIncidents();
      emit(state.copyWith(incidents: incidents, clearError: true));
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'No se pudo actualizar la lista de incidencias.',
        ),
      );
    }
  }

  Future<void> loadNearbyPreferredIncidents({
    required double latitud,
    required double longitud,
    bool notifyNearby = false,
  }) async {
    emit(
      state.copyWith(
        nearbyLoading: true,
        clearError: true,
        clearNearbyMessage: true,
      ),
    );

    try {
      final incidents = await _repository.getNearbyPreferredIncidents(
        latitud: latitud,
        longitud: longitud,
      );

      String? message;
      if (notifyNearby) {
        final total = await _repository.notifyNearbyIncidents(
          latitud: latitud,
          longitud: longitud,
        );
        message = total > 0
            ? 'Te avisamos sobre $total reportes cercanos.'
            : 'No hay nuevas alertas cercanas por ahora.';
      }

      emit(
        state.copyWith(
          nearbyLoading: false,
          incidents: incidents,
          nearbyMessage: message,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(nearbyLoading: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          nearbyLoading: false,
          errorMessage: 'No se pudieron cargar las incidencias cercanas.',
        ),
      );
    }
  }

  Future<void> loadMyReports() async {
    emit(state.copyWith(myReportsLoading: true, clearMyReportsError: true));

    try {
      final reports = await _repository.getMyIncidents();
      emit(
        state.copyWith(
          myReportsLoading: false,
          myReports: reports,
          clearMyReportsError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          myReportsLoading: false,
          myReportsErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          myReportsLoading: false,
          myReportsErrorMessage: 'No se pudieron cargar tus reportes.',
        ),
      );
    }
  }

  Future<void> createIncident({
    required String idCategoria,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    required String direccionReferencial,
    IncidentImageAttachment? imageAttachment,
  }) async {
    emit(
      state.copyWith(
        submitStatus: IncidentSubmitStatus.loading,
        clearSubmitMessage: true,
      ),
    );

    try {
      final incident = await _repository.createIncident(
        idCategoria: idCategoria,
        titulo: titulo,
        descripcion: descripcion,
        latitud: latitud,
        longitud: longitud,
        direccionReferencial: direccionReferencial,
        imageAttachment: imageAttachment,
      );

      emit(
        state.copyWith(
          incidents: [incident, ...state.incidents],
          myReports: [incident, ...state.myReports],
          submitStatus: IncidentSubmitStatus.success,
          submitMessage: 'Tu incidencia fue reportada correctamente.',
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          submitStatus: IncidentSubmitStatus.failure,
          submitMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submitStatus: IncidentSubmitStatus.failure,
          submitMessage: 'No se pudo reportar la incidencia.',
        ),
      );
    }
  }

  void resetSubmitStatus() {
    emit(
      state.copyWith(
        submitStatus: IncidentSubmitStatus.initial,
        clearSubmitMessage: true,
      ),
    );
  }

  Future<void> loadIncidentDetail(String idIncidencia) async {
    emit(
      state.copyWith(
        detailLoading: true,
        commentsLoading: true,
        voteSummaryLoading: true,
        followStatusLoading: true,
        completionSummaryLoading: true,
        statusHistoryLoading: true,
        statusOptionsLoading: state.statusOptions.isEmpty,
        clearDetailError: true,
        clearCommentsError: true,
        clearCommentSubmitMessage: true,
        clearVoteSummaryError: true,
        clearVoteSubmitMessage: true,
        clearVoteSummary: true,
        clearFollowStatusError: true,
        clearFollowActionMessage: true,
        clearFollowStatus: true,
        clearCompletionSummaryError: true,
        clearCompletionSubmitMessage: true,
        clearCompletionSummary: true,
        clearStatusHistoryError: true,
        clearStatusChangeMessage: true,
        clearContentReportMessage: true,
        clearSelectedIncident: true,
        selectedIncidentMultimedia: const [],
        selectedIncidentComments: const [],
        recentVotes: const [],
        recentConfirmations: const [],
        statusHistory: const [],
      ),
    );

    try {
      final incident = await _repository.getIncidentById(idIncidencia);
      final multimedia = await _repository.getIncidentMultimedia(idIncidencia);
      final statusOptions = state.statusOptions.isEmpty
          ? await _repository.getIncidentStatuses()
          : state.statusOptions;
      final imageUrls = multimedia
          .map((media) => media.downloadUrl)
          .where((url) => url.isNotEmpty)
          .toList();

      emit(
        state.copyWith(
          detailLoading: false,
          selectedIncident: incident.copyWith(imagenes: imageUrls),
          selectedIncidentMultimedia: multimedia,
          statusOptionsLoading: false,
          statusOptions: statusOptions,
          clearDetailError: true,
        ),
      );

      await refreshIncidentFollowStatus(idIncidencia);
      await refreshIncidentCompletionSummary(idIncidencia);
      await refreshIncidentVoteSummary(idIncidencia);
      await refreshIncidentStatusHistory(idIncidencia);
      await refreshIncidentComments(idIncidencia);
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          detailLoading: false,
          commentsLoading: false,
          voteSummaryLoading: false,
          followStatusLoading: false,
          completionSummaryLoading: false,
          statusHistoryLoading: false,
          statusOptionsLoading: false,
          detailErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          detailLoading: false,
          commentsLoading: false,
          voteSummaryLoading: false,
          followStatusLoading: false,
          completionSummaryLoading: false,
          statusHistoryLoading: false,
          statusOptionsLoading: false,
          detailErrorMessage: 'No se pudo cargar el detalle de la incidencia.',
        ),
      );
    }
  }

  Future<void> changeIncidentStatus({
    required String idIncidencia,
    required String codigoEstado,
    String? observacion,
  }) async {
    emit(state.copyWith(statusChanging: true, clearStatusChangeMessage: true));

    try {
      final updated = await _repository.changeIncidentStatus(
        idIncidencia: idIncidencia,
        codigoEstado: codigoEstado,
        observacion: observacion,
      );

      final incidents = state.incidents.map((incident) {
        if (incident.idIncidencia == updated.idIncidencia) {
          return updated.copyWith(imagenes: incident.imagenes);
        }
        return incident;
      }).toList();
      final myReports = state.myReports.map((incident) {
        if (incident.idIncidencia == updated.idIncidencia) {
          return updated.copyWith(imagenes: incident.imagenes);
        }
        return incident;
      }).toList();

      emit(
        state.copyWith(
          statusChanging: false,
          selectedIncident: updated.copyWith(
            imagenes: state.selectedIncident?.imagenes,
          ),
          incidents: incidents,
          myReports: myReports,
          statusChangeMessage: 'Estado actualizado correctamente.',
        ),
      );

      await refreshIncidentStatusHistory(idIncidencia);
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          statusChanging: false,
          statusChangeMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          statusChanging: false,
          statusChangeMessage: 'No se pudo cambiar el estado de la incidencia.',
        ),
      );
    }
  }

  Future<void> refreshIncidentStatusHistory(String idIncidencia) async {
    emit(
      state.copyWith(statusHistoryLoading: true, clearStatusHistoryError: true),
    );

    try {
      final history = await _repository.getIncidentStatusHistory(idIncidencia);
      emit(
        state.copyWith(
          statusHistoryLoading: false,
          statusHistory: history,
          clearStatusHistoryError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          statusHistoryLoading: false,
          statusHistoryErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          statusHistoryLoading: false,
          statusHistoryErrorMessage:
              'No se pudo cargar el historial de estados.',
        ),
      );
    }
  }

  Future<void> refreshIncidentCompletionSummary(String idIncidencia) async {
    emit(
      state.copyWith(
        completionSummaryLoading: true,
        clearCompletionSummaryError: true,
      ),
    );

    try {
      final summary = await _repository.getIncidentCompletionSummary(
        idIncidencia,
      );
      final confirmations = await _repository
          .getIncidentCompletionConfirmations(idIncidencia);
      emit(
        state.copyWith(
          completionSummaryLoading: false,
          completionSummary: summary,
          recentConfirmations: confirmations,
          clearCompletionSummaryError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          completionSummaryLoading: false,
          completionSummaryErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          completionSummaryLoading: false,
          completionSummaryErrorMessage:
              'No se pudo cargar el resumen de completado.',
        ),
      );
    }
  }

  Future<bool> createCompletionConfirmation({
    required String idIncidencia,
    String? observacion,
    double? latitud,
    double? longitud,
    IncidentImageAttachment? imageAttachment,
  }) async {
    emit(
      state.copyWith(
        completionSubmitting: true,
        clearCompletionSubmitMessage: true,
      ),
    );

    try {
      final confirmation = await _repository.createCompletionConfirmation(
        idIncidencia: idIncidencia,
        observacion: observacion,
        latitud: latitud,
        longitud: longitud,
        imageAttachment: imageAttachment,
      );
      final currentSummary =
          state.completionSummary ??
          const IncidentCompletionSummaryModel.empty();
      final alreadyConfirmed = currentSummary.usuarioYaConfirmo;

      emit(
        state.copyWith(
          completionSubmitting: false,
          completionSummary: IncidentCompletionSummaryModel(
            totalConfirmaciones:
                currentSummary.totalConfirmaciones + (alreadyConfirmed ? 0 : 1),
            usuarioYaConfirmo: true,
            confirmacionUsuario: confirmation,
          ),
          selectedIncident: _updateSelectedIncidentConfirmationCount(
            delta: alreadyConfirmed ? 0 : 1,
          ),
          incidents: _updateIncidentConfirmationCount(
            state.incidents,
            idIncidencia,
            alreadyConfirmed ? 0 : 1,
          ),
          myReports: _updateIncidentConfirmationCount(
            state.myReports,
            idIncidencia,
            alreadyConfirmed ? 0 : 1,
          ),
          clearCompletionSubmitMessage: true,
        ),
      );
      await refreshIncidentCompletionSummary(idIncidencia);
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          completionSubmitting: false,
          completionSubmitMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          completionSubmitting: false,
          completionSubmitMessage:
              'No se pudo registrar la confirmación de completado.',
        ),
      );
      return false;
    }
  }

  Future<void> refreshIncidentFollowStatus(String idIncidencia) async {
    emit(
      state.copyWith(followStatusLoading: true, clearFollowStatusError: true),
    );

    try {
      final followStatus = await _repository.getIncidentFollowStatus(
        idIncidencia,
      );
      emit(
        state.copyWith(
          followStatusLoading: false,
          followStatus: followStatus,
          clearFollowStatusError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          followStatusLoading: false,
          followStatusErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          followStatusLoading: false,
          followStatusErrorMessage:
              'No se pudo cargar el estado de seguimiento.',
        ),
      );
    }
  }

  Future<bool> followIncident(String idIncidencia) async {
    emit(
      state.copyWith(followActionLoading: true, clearFollowActionMessage: true),
    );

    try {
      final previousFollowing = state.followStatus?.siguiendo == true;
      final followStatus = await _repository.followIncident(idIncidencia);
      emit(
        state.copyWith(
          followActionLoading: false,
          followStatus: followStatus,
          selectedIncident: _updateSelectedIncidentFollowerCount(
            delta: previousFollowing ? 0 : 1,
          ),
          incidents: _updateIncidentFollowerCount(
            state.incidents,
            idIncidencia,
            previousFollowing ? 0 : 1,
          ),
          myReports: _updateIncidentFollowerCount(
            state.myReports,
            idIncidencia,
            previousFollowing ? 0 : 1,
          ),
          clearFollowActionMessage: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          followActionLoading: false,
          followActionMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          followActionLoading: false,
          followActionMessage: 'No se pudo seguir la incidencia.',
        ),
      );
      return false;
    }
  }

  Future<bool> unfollowIncident(String idIncidencia) async {
    emit(
      state.copyWith(followActionLoading: true, clearFollowActionMessage: true),
    );

    try {
      final previousFollowing = state.followStatus?.siguiendo == true;
      final followStatus = await _repository.unfollowIncident(idIncidencia);
      emit(
        state.copyWith(
          followActionLoading: false,
          followStatus: followStatus,
          selectedIncident: _updateSelectedIncidentFollowerCount(
            delta: previousFollowing ? -1 : 0,
          ),
          incidents: _updateIncidentFollowerCount(
            state.incidents,
            idIncidencia,
            previousFollowing ? -1 : 0,
          ),
          myReports: _updateIncidentFollowerCount(
            state.myReports,
            idIncidencia,
            previousFollowing ? -1 : 0,
          ),
          clearFollowActionMessage: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          followActionLoading: false,
          followActionMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          followActionLoading: false,
          followActionMessage: 'No se pudo dejar de seguir la incidencia.',
        ),
      );
      return false;
    }
  }

  Future<void> refreshIncidentVoteSummary(String idIncidencia) async {
    emit(state.copyWith(voteSummaryLoading: true, clearVoteSummaryError: true));

    try {
      final summary = await _repository.getIncidentVoteSummary(idIncidencia);
      final votes = await _repository.getIncidentVotes(idIncidencia);
      emit(
        state.copyWith(
          voteSummaryLoading: false,
          voteSummary: summary,
          recentVotes: votes,
          clearVoteSummaryError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          voteSummaryLoading: false,
          voteSummaryErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          voteSummaryLoading: false,
          voteSummaryErrorMessage: 'No se pudo cargar el resumen de votos.',
        ),
      );
    }
  }

  Future<bool> createIncidentVote({
    required String idIncidencia,
    required String tipoVoto,
    String? observacion,
  }) async {
    emit(state.copyWith(voteSubmitting: true, clearVoteSubmitMessage: true));

    try {
      await _repository.createIncidentVote(
        idIncidencia: idIncidencia,
        tipoVoto: tipoVoto,
        observacion: observacion,
      );
      emit(state.copyWith(voteSubmitting: false, clearVoteSubmitMessage: true));
      await refreshIncidentVoteSummary(idIncidencia);
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(voteSubmitting: false, voteSubmitMessage: error.message),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          voteSubmitting: false,
          voteSubmitMessage: 'No se pudo registrar tu validación.',
        ),
      );
      return false;
    }
  }

  Future<bool> reportContent({
    required String tipoEntidad,
    required String idEntidad,
    required String motivo,
    String? detalle,
  }) async {
    final cleanMotivo = motivo.trim();
    if (cleanMotivo.isEmpty) {
      emit(
        state.copyWith(
          contentReportMessage: 'Selecciona un motivo para enviar la denuncia.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        contentReportSubmitting: true,
        clearContentReportMessage: true,
      ),
    );

    try {
      await _repository.reportContent(
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
        motivo: cleanMotivo,
        detalle: detalle,
      );
      emit(
        state.copyWith(
          contentReportSubmitting: false,
          contentReportMessage:
              'Denuncia enviada. Revisaremos el contenido reportado.',
        ),
      );
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          contentReportSubmitting: false,
          contentReportMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          contentReportSubmitting: false,
          contentReportMessage: 'No se pudo enviar la denuncia.',
        ),
      );
      return false;
    }
  }

  Future<void> refreshIncidentComments(String idIncidencia) async {
    emit(state.copyWith(commentsLoading: true, clearCommentsError: true));

    try {
      final comments = await _repository.getIncidentComments(idIncidencia);
      emit(
        state.copyWith(
          commentsLoading: false,
          selectedIncidentComments: comments,
          clearCommentsError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          commentsLoading: false,
          commentsErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          commentsLoading: false,
          commentsErrorMessage: 'No se pudieron cargar los comentarios.',
        ),
      );
    }
  }

  Future<bool> createIncidentComment({
    required String idIncidencia,
    required String contenido,
  }) async {
    final cleanContent = contenido.trim();
    if (cleanContent.isEmpty) {
      emit(
        state.copyWith(
          commentSubmitMessage: 'Escribe un comentario antes de enviarlo.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(commentSubmitting: true, clearCommentSubmitMessage: true),
    );

    try {
      final comment = await _repository.createIncidentComment(
        idIncidencia: idIncidencia,
        contenido: cleanContent,
      );
      final selectedIncident = state.selectedIncident;
      final updatedSelectedIncident = selectedIncident?.copyWith(
        cantidadComentarios: selectedIncident.cantidadComentarios + 1,
      );

      emit(
        state.copyWith(
          commentSubmitting: false,
          selectedIncident: updatedSelectedIncident,
          selectedIncidentComments: [
            ...state.selectedIncidentComments,
            comment,
          ],
          incidents: _updateIncidentCommentCount(state.incidents, idIncidencia),
          myReports: _updateIncidentCommentCount(state.myReports, idIncidencia),
          clearCommentSubmitMessage: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          commentSubmitting: false,
          commentSubmitMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          commentSubmitting: false,
          commentSubmitMessage: 'No se pudo publicar el comentario.',
        ),
      );
      return false;
    }
  }

  List<IncidentModel> _updateIncidentCommentCount(
    List<IncidentModel> incidents,
    String idIncidencia,
  ) {
    return incidents
        .map(
          (incident) => incident.idIncidencia == idIncidencia
              ? incident.copyWith(
                  cantidadComentarios: incident.cantidadComentarios + 1,
                )
              : incident,
        )
        .toList();
  }

  IncidentModel? _updateSelectedIncidentFollowerCount({required int delta}) {
    final incident = state.selectedIncident;
    if (incident == null || delta == 0) {
      return incident;
    }

    return incident.copyWith(
      cantidadSeguidores: _nonNegative(incident.cantidadSeguidores + delta),
    );
  }

  List<IncidentModel> _updateIncidentFollowerCount(
    List<IncidentModel> incidents,
    String idIncidencia,
    int delta,
  ) {
    if (delta == 0) {
      return incidents;
    }

    return incidents
        .map(
          (incident) => incident.idIncidencia == idIncidencia
              ? incident.copyWith(
                  cantidadSeguidores: _nonNegative(
                    incident.cantidadSeguidores + delta,
                  ),
                )
              : incident,
        )
        .toList();
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;

  IncidentModel? _updateSelectedIncidentConfirmationCount({
    required int delta,
  }) {
    final incident = state.selectedIncident;
    if (incident == null || delta == 0) {
      return incident;
    }

    return incident.copyWith(
      cantidadConfirmaciones: _nonNegative(
        incident.cantidadConfirmaciones + delta,
      ),
    );
  }

  List<IncidentModel> _updateIncidentConfirmationCount(
    List<IncidentModel> incidents,
    String idIncidencia,
    int delta,
  ) {
    if (delta == 0) {
      return incidents;
    }

    return incidents
        .map(
          (incident) => incident.idIncidencia == idIncidencia
              ? incident.copyWith(
                  cantidadConfirmaciones: _nonNegative(
                    incident.cantidadConfirmaciones + delta,
                  ),
                )
              : incident,
        )
        .toList();
  }
}
