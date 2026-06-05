import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/incident_image_attachment.dart';
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
        clearDetailError: true,
        clearSelectedIncident: true,
        selectedIncidentMultimedia: const [],
      ),
    );

    try {
      final incident = await _repository.getIncidentById(idIncidencia);
      final multimedia = await _repository.getIncidentMultimedia(idIncidencia);
      final imageUrls = multimedia
          .map((media) => media.downloadUrl)
          .where((url) => url.isNotEmpty)
          .toList();

      emit(
        state.copyWith(
          detailLoading: false,
          selectedIncident: incident.copyWith(imagenes: imageUrls),
          selectedIncidentMultimedia: multimedia,
          clearDetailError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(detailLoading: false, detailErrorMessage: error.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          detailLoading: false,
          detailErrorMessage: 'No se pudo cargar el detalle de la incidencia.',
        ),
      );
    }
  }
}
