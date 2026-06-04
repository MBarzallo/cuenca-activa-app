import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
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

  Future<void> createIncident({
    required String idCategoria,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    required String direccionReferencial,
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
      );

      emit(
        state.copyWith(
          incidents: [incident, ...state.incidents],
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
}
