class AuthUserModel {
  final String idUsuario;
  final String email;
  final String nombres;
  final String apellidos;
  final String aliasPublico;
  final String? telefono;
  final String estadoCuenta;
  final int puntosTotales;
  final List<String> roles;
  final bool perfilCompleto;

  AuthUserModel({
    required this.idUsuario,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.aliasPublico,
    required this.telefono,
    required this.estadoCuenta,
    required this.puntosTotales,
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
      estadoCuenta: json['estadoCuenta']?.toString() ?? '',
      puntosTotales: json['puntosTotales'] as int? ?? 0,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),
      perfilCompleto: json['perfilCompleto'] as bool? ?? false,
    );
  }
}
