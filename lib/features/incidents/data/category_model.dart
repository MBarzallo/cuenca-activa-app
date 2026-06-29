import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CategoryModel {
  final String idCategoria;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String icono;
  final String colorHex;
  final bool requiereFoto;

  const CategoryModel({
    required this.idCategoria,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.colorHex,
    required this.requiereFoto,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      idCategoria: json['idCategoria']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin categoria',
      descripcion: json['descripcion']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? '',
      requiereFoto: json['requiereFoto'] as bool? ?? false,
    );
  }

  Color get color {
    final normalized = colorHex.replaceAll('#', '').trim();

    if (normalized.length == 6) {
      final value = int.tryParse('FF$normalized', radix: 16);
      if (value != null) {
        return Color(value);
      }
    }

    return AppColors.teal;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          idCategoria == other.idCategoria;

  @override
  int get hashCode => idCategoria.hashCode;
}
