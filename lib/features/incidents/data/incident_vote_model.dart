class IncidentVoteModel {
  final String idVoto;
  final String idIncidencia;
  final String idUsuario;
  final String tipoVoto;
  final String? observacion;
  final DateTime? creadoEn;

  const IncidentVoteModel({
    required this.idVoto,
    required this.idIncidencia,
    required this.idUsuario,
    required this.tipoVoto,
    required this.observacion,
    required this.creadoEn,
  });

  factory IncidentVoteModel.fromJson(Map<String, dynamic> json) {
    return IncidentVoteModel(
      idVoto: json['idVoto']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      tipoVoto: json['tipoVoto']?.toString() ?? '',
      observacion: json['observacion']?.toString(),
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
    );
  }
}

class IncidentVoteSummaryModel {
  final Map<String, int> conteosPorTipo;
  final bool usuarioYaVoto;
  final IncidentVoteModel? votoUsuario;

  const IncidentVoteSummaryModel({
    required this.conteosPorTipo,
    required this.usuarioYaVoto,
    required this.votoUsuario,
  });

  const IncidentVoteSummaryModel.empty()
    : conteosPorTipo = const {
        'CONFIRMA_EXISTENCIA': 0,
        'NO_EXISTE': 0,
        'IMPORTANTE': 0,
      },
      usuarioYaVoto = false,
      votoUsuario = null;

  factory IncidentVoteSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['conteosPorTipo'];
    final counts = <String, int>{
      'CONFIRMA_EXISTENCIA': 0,
      'NO_EXISTE': 0,
      'IMPORTANTE': 0,
    };

    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        counts[entry.key.toString()] = _toInt(entry.value);
      }
    }

    final rawUserVote = json['votoUsuario'];

    return IncidentVoteSummaryModel(
      conteosPorTipo: counts,
      usuarioYaVoto: json['usuarioYaVoto'] == true,
      votoUsuario: rawUserVote is Map<String, dynamic>
          ? IncidentVoteModel.fromJson(rawUserVote)
          : null,
    );
  }

  int countFor(String type) => conteosPorTipo[type] ?? 0;

  int get total => conteosPorTipo.values.fold(0, (sum, count) => sum + count);

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
