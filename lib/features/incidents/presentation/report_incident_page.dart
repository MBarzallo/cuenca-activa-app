import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../data/category_model.dart';
import '../data/incident_image_attachment.dart';
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
  final _imagePicker = ImagePicker();

  CategoryModel? _selectedCategory;
  XFile? _selectedImage;
  Position? _currentPosition;
  bool _locating = false;
  String? _locationMessage;
  bool _locationBlocked = false;
  bool _locationServiceDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<IncidentsCubit>();
      if (cubit.state.categories.isEmpty && !cubit.state.loading) {
        cubit.loadInitialData();
      }
      _useCurrentLocation(silent: true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() {
      _locating = true;
      _locationMessage = null;
      _locationBlocked = false;
      _locationServiceDisabled = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationFailure(
          'Activa la ubicación del dispositivo para continuar.',
          serviceDisabled: true,
          silent: silent,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationFailure(
          permission == LocationPermission.deniedForever
              ? 'La ubicación está bloqueada. Habilítala desde ajustes para reportar.'
              : 'Necesitamos permiso de ubicación para registrar el reporte.',
          blocked: permission == LocationPermission.deniedForever,
          silent: silent,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = position;
        _locationMessage = 'Ubicación lista para enviar el reporte.';
        _locationBlocked = false;
        _locationServiceDisabled = false;
      });
    } catch (_) {
      _setLocationFailure(
        'No se pudo obtener tu ubicación. Intenta nuevamente.',
        silent: silent,
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _setLocationFailure(
    String message, {
    bool blocked = false,
    bool serviceDisabled = false,
    bool silent = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = null;
      _locationMessage = message;
      _locationBlocked = blocked;
      _locationServiceDisabled = serviceDisabled;
    });

    if (!silent) {
      _showMessage(message);
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final position = _currentPosition;
    if (position == null) {
      _showMessage('Obtén tu ubicación actual antes de enviar el reporte.');
      _useCurrentLocation();
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
      latitud: position.latitude,
      longitud: position.longitude,
      direccionReferencial: _addressController.text,
      imageAttachment: _selectedImage == null
          ? null
          : IncidentImageAttachment(_selectedImage!),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (image == null) {
        return;
      }

      setState(() => _selectedImage = image);
    } catch (_) {
      _showMessage('No se pudo seleccionar la imagen.');
    }
  }

  void _clearImage() {
    setState(() => _selectedImage = null);
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
                        hint: const Text('Selecciona una categoría'),
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: state.categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.nombre),
                          );
                        }).toList(),
                        onChanged: submitting
                            ? null
                            : (value) =>
                                  setState(() => _selectedCategory = value),
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una categoría';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Bache peligroso en la calzada',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 80,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !submitting,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del problema',
                          hintText:
                              'Describe detalladamente la situación y los peligros asociados...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 56),
                            child: Icon(Icons.description_rounded),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 500,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 12),
                      _LocationCaptureCard(
                        position: _currentPosition,
                        locating: _locating,
                        message: _locationMessage,
                        blocked: _locationBlocked,
                        serviceDisabled: _locationServiceDisabled,
                        disabled: submitting,
                        onRetry: () => _useCurrentLocation(),
                        onOpenSettings: _locationBlocked
                            ? Geolocator.openAppSettings
                            : Geolocator.openLocationSettings,
                      ),
                      const SizedBox(height: 22),
                      _ImagePickerCard(
                        selectedImage: _selectedImage,
                        disabled: submitting,
                        onCamera: () => _pickImage(ImageSource.camera),
                        onGallery: () => _pickImage(ImageSource.gallery),
                        onClear: _clearImage,
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: submitting || _locating ? null : _submit,
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

class _LocationCaptureCard extends StatelessWidget {
  final Position? position;
  final bool locating;
  final String? message;
  final bool blocked;
  final bool serviceDisabled;
  final bool disabled;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenSettings;

  const _LocationCaptureCard({
    required this.position,
    required this.locating,
    required this.message,
    required this.blocked,
    required this.serviceDisabled,
    required this.disabled,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final currentPosition = position;
    final hasLocation = currentPosition != null;
    final hasProblem = !hasLocation && (blocked || serviceDisabled);
    final color = hasLocation
        ? AppColors.success
        : hasProblem
        ? AppColors.danger
        : AppColors.teal;
    final title = hasLocation
        ? 'Ubicación capturada'
        : locating
        ? 'Obteniendo ubicación'
        : hasProblem
        ? 'Ubicación requerida'
        : 'Ubicación del reporte';
    final description = hasLocation
        ? '${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}'
        : message ??
              'La app tomará tu ubicación actual para ubicar el reporte en el mapa.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    hasLocation
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled || locating ? null : onRetry,
                    icon: locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            hasLocation
                                ? Icons.refresh_rounded
                                : Icons.gps_fixed_rounded,
                          ),
                    label: Text(
                      locating
                          ? 'Ubicando...'
                          : hasLocation
                          ? 'Actualizar'
                          : 'Obtener ubicación',
                    ),
                  ),
                ),
                if (blocked || serviceDisabled) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: disabled || locating
                          ? null
                          : () async {
                              await onOpenSettings();
                            },
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Ajustes'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? selectedImage;
  final bool disabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _ImagePickerCard({
    required this.selectedImage,
    required this.disabled,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final image = selectedImage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen del reporte',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'JPG, PNG o WEBP. Máximo 5 MB.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (image == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: disabled ? null : onCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: disabled ? null : onGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        image.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar imagen',
                      onPressed: disabled ? null : onClear,
                      icon: const Icon(Icons.close_rounded),
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
