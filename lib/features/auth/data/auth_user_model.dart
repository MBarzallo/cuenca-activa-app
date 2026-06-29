class AuthUserModel {
  final String idUsuario;
  final String email;
  final String nombres;
  final String apellidos;
  final String aliasPublico;
  final String? telefono;
  final String? telefonoPendiente;
  final bool telefonoVerificado;
  final String? telefonoVerificadoEn;
  final String? fotoPerfilUrl;
  final String estadoCuenta;
  final int puntosTotales;
  final String idNivelActual;
  final String codigoNivelActual;
  final String nombreNivelActual;
  final int puntosMinimosNivel;
  final int puntosMaximosNivel;
  final String iconoNivelActual;
  final List<String> roles;
  final bool perfilCompleto;

  AuthUserModel({
    required this.idUsuario,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.aliasPublico,
    required this.telefono,
    required this.telefonoPendiente,
    required this.telefonoVerificado,
    required this.telefonoVerificadoEn,
    required this.fotoPerfilUrl,
    required this.estadoCuenta,
    required this.puntosTotales,
    required this.idNivelActual,
    required this.codigoNivelActual,
    required this.nombreNivelActual,
    required this.puntosMinimosNivel,
    required this.puntosMaximosNivel,
    required this.iconoNivelActual,
    required this.roles,
    required this.perfilCompleto,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      idUsuario: json['idUsuario']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      aliasPublico: json['aliasPublico']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      telefonoPendiente: json['telefonoPendiente']?.toString(),
      telefonoVerificado: json['telefonoVerificado'] as bool? ?? false,
      telefonoVerificadoEn: json['telefonoVerificadoEn']?.toString(),
      fotoPerfilUrl: json['fotoPerfilUrl']?.toString(),
      estadoCuenta: json['estadoCuenta']?.toString() ?? '',
      puntosTotales: json['puntosTotales'] as int? ?? 0,
      idNivelActual: json['idNivelActual']?.toString() ?? '',
      codigoNivelActual: json['codigoNivelActual']?.toString() ?? '',
      nombreNivelActual: json['nombreNivelActual']?.toString() ?? 'Inicial',
      puntosMinimosNivel: _toInt(json['puntosMinimosNivel']),
      puntosMaximosNivel: _toInt(json['puntosMaximosNivel']),
      iconoNivelActual: json['iconoNivelActual']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
    );
  }

  double get nivelProgress {
    final min = puntosMinimosNivel;
    final max = puntosMaximosNivel;

    if (max <= min) {
      return 1;
    }

    return ((puntosTotales - min) / (max - min)).clamp(0, 1).toDouble();
  }

  int get puntosParaSiguienteNivel {
    final remaining = puntosMaximosNivel - puntosTotales;
    return remaining <= 0 ? 0 : remaining;
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
