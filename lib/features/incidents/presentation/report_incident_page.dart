import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/category_model.dart';
import '../logic/incidents_cubit.dart';
import '../logic/incidents_state.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  CategoryModel? _selectedCategory;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<IncidentsCubit>();
      if (cubit.state.categories.isEmpty && !cubit.state.loading) {
        cubit.loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Activa la ubicacion del dispositivo para continuar.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('No tenemos permiso para leer tu ubicacion.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    } catch (_) {
      _showMessage('No se pudo obtener tu ubicacion.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final category = _selectedCategory;
    if (category == null) {
      _showMessage('Selecciona una categoria.');
      return;
    }

    context.read<IncidentsCubit>().createIncident(
      idCategoria: category.idCategoria,
      titulo: _titleController.text,
      descripcion: _descriptionController.text,
      latitud: double.parse(_latitudeController.text.trim()),
      longitud: double.parse(_longitudeController.text.trim()),
      direccionReferencial: _addressController.text,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentsCubit, IncidentsState>(
      listener: (context, state) {
        if (state.submitStatus == IncidentSubmitStatus.success) {
          _showMessage(state.submitMessage ?? 'Incidencia reportada.');
          context.read<IncidentsCubit>().resetSubmitStatus();
          context.pop();
        }

        if (state.submitStatus == IncidentSubmitStatus.failure) {
          _showMessage(state.submitMessage ?? 'No se pudo reportar.');
          context.read<IncidentsCubit>().resetSubmitStatus();
        }
      },
      builder: (context, state) {
        final submitting = state.submitStatus == IncidentSubmitStatus.loading;

        return Scaffold(
          appBar: AppBar(title: const Text('Reportar incidencia')),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IntroCard(onUseLocation: _useCurrentLocation),
                    const SizedBox(height: 18),
                    if (state.loading && state.categories.isEmpty)
                      const _LoadingCategoriesCard()
                    else if (state.categories.isEmpty)
                      _MissingCategoriesCard(
                        onRetry: context.read<IncidentsCubit>().loadInitialData,
                      )
                    else ...[
                      DropdownButtonFormField<CategoryModel>(
                        initialValue: _selectedCategory,
                        items: state.categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) {
                                setState(() => _selectedCategory = value);
                              },
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (value) =>
                            value == null ? 'Selecciona una categoria' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          labelText: 'Titulo',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          labelText: 'Direccion referencial',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                                prefixIcon: Icon(Icons.my_location_rounded),
                              ),
                              validator: (value) => _coordinateValidator(
                                value,
                                min: -90,
                                max: 90,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!submitting) _submit();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                                prefixIcon: Icon(Icons.explore_outlined),
                              ),
                              validator: (value) => _coordinateValidator(
                                value,
                                min: -180,
                                max: 180,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _locating || submitting
                            ? null
                            : _useCurrentLocation,
                        icon: _locating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gps_fixed_rounded),
                        label: Text(
                          _locating
                              ? 'Obteniendo ubicacion'
                              : 'Usar mi ubicacion actual',
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: submitting ? null : _submit,
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          submitting ? 'Reportando' : 'Enviar reporte',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    return null;
  }

  String? _coordinateValidator(
    String? value, {
    required double min,
    required double max,
  }) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null) {
      return 'Valor invalido';
    }

    if (number < min || number > max) {
      return 'Fuera de rango';
    }

    return null;
  }
}

class _IntroCard extends StatelessWidget {
  final VoidCallback onUseLocation;

  const _IntroCard({required this.onUseLocation});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_location_alt_rounded,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo reporte ciudadano',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Describe el problema y registra su ubicacion para que pueda ser atendido.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCategoriesCard extends StatelessWidget {
  const _LoadingCategoriesCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 14),
            Text('Cargando categorias...'),
          ],
        ),
      ),
    );
  }
}

class _MissingCategoriesCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _MissingCategoriesCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.category_outlined,
              color: AppColors.teal,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay categorias disponibles',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Necesitamos cargar las categorias antes de crear un reporte.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
