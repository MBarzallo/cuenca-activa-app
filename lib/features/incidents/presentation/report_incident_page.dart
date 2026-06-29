import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_showcase_step.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
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
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _detailsKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _submitKey = GlobalKey();

  CategoryModel? _selectedCategory;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  Position? _currentPosition;
  bool _locating = false;
  String? _locationMessage;
  bool _locationBlocked = false;
  bool _locationServiceDisabled = false;
  bool _tourScheduled = false;
  bool _submitSuccess = false;

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

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      _showMessage('No se pudo seleccionar la imagen.');
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _addressController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedImage = null;
      _selectedImageBytes = null;
      _currentPosition = null;
      _locationMessage = null;
    });
    _formKey.currentState?.reset();
    _useCurrentLocation(silent: true);
  }

  bool _hasUnsavedChanges() {
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _addressController.text.isNotEmpty ||
        _selectedCategory != null ||
        _selectedImage != null;
  }

  Future<bool> _showDiscardConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Descartar reporte'),
          content: const Text(
            'Tienes información sin enviar. ¿Deseas salir y descartar el reporte?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _handleBack() async {
    if (_hasUnsavedChanges()) {
      final confirm = await _showDiscardConfirmation(context);
      if (!confirm) return;
    }
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _handleClear(bool submitting) async {
    if (submitting) return;
    if (_hasUnsavedChanges()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Limpiar formulario'),
            content: const Text(
              '¿Estás seguro de que deseas borrar toda la información escrita?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Limpiar'),
              ),
            ],
          );
        },
      );
      if (confirm == true) {
        _clearForm();
      }
    } else {
      _clearForm();
    }
  }

  Future<void> _startShowcaseIfNeeded(
    BuildContext showcaseContext,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'has_shown_report_incident_showcase_v1_$userId';
    final hasShownShowcase = prefs.getBool(key) ?? false;
    if (!hasShownShowcase && showcaseContext.mounted) {
      _startReportTour(showcaseContext);
      await prefs.setBool(key, true);
    }
  }

  void _startReportTour(BuildContext showcaseContext) {
    final keys = [
      _categoryKey,
      _detailsKey,
      _locationKey,
      _imageKey,
      _submitKey,
    ];
    // ignore: deprecated_member_use
    ShowCaseWidget.of(showcaseContext).startShowCase(keys);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is AuthAuthenticated && !authState.user.telefonoVerificado) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verificación requerida'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_locked_rounded,
                  size: 80,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verificación de celular requerida',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para registrar reportes ciudadanos en Cuenca Activa, debes contar con un número celular verificado mediante SMS. Esto garantiza la seriedad y veracidad de cada reporte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.verified_user_rounded),
                    label: const Text('Verificar celular ahora'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ignore: deprecated_member_use
    return ShowCaseWidget(
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 460),
      builder: (showcaseContext) {
        return BlocConsumer<IncidentsCubit, IncidentsState>(
          listener: (context, state) {
            if (state.submitStatus == IncidentSubmitStatus.success) {
              setState(() {
                _submitSuccess = true;
              });

              final cubit = context.read<IncidentsCubit>();
              final router = GoRouter.of(context);

              Future<void>.delayed(const Duration(milliseconds: 1000)).then((_) {
                if (!mounted) return;
                _showMessage(state.submitMessage ?? 'Incidencia reportada.');
                _clearForm();
                cubit.resetSubmitStatus();
                setState(() {
                  _submitSuccess = false;
                });
                router.go('/my-reports');
              });
            }

            if (state.submitStatus == IncidentSubmitStatus.failure) {
              setState(() {
                _submitSuccess = false;
              });
              _showMessage(state.submitMessage ?? 'No se pudo reportar.');
              context.read<IncidentsCubit>().resetSubmitStatus();
            }
          },
          builder: (context, state) {
            final submitting =
                state.submitStatus == IncidentSubmitStatus.loading;
            final userId = authState is AuthAuthenticated
                ? authState.user.idUsuario
                : 'guest';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_tourScheduled && state.categories.isNotEmpty) {
                _tourScheduled = true;
                _startShowcaseIfNeeded(showcaseContext, userId);
              }
            });

            return PopScope(
              canPop: !_hasUnsavedChanges(),
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                final shouldPop = await _showDiscardConfirmation(context);
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar',
                    onPressed: _handleBack,
                  ),
                  title: const Text('Nuevo reporte'),
                  actions: [
                    TextButton(
                      onPressed: submitting ? null : () => _handleClear(submitting),
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ayuda',
                      onPressed: () => _startReportTour(showcaseContext),
                      icon: const Icon(Icons.help_outline_rounded),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.loading && state.categories.isEmpty)
                          const _LoadingCategoriesCard()
                        else if (state.categories.isEmpty)
                          _MissingCategoriesCard(
                            onRetry: context
                                .read<IncidentsCubit>()
                                .loadInitialData,
                          )
                        else ...[
                          AppShowcaseStep(
                            showcaseKey: _categoryKey,
                            title: 'Clasifica el problema',
                            description:
                                'Elige la categoría que mejor describe la incidencia. Esto ayuda a filtrar reportes y asignar prioridad.',
                            child: DropdownButtonFormField<CategoryModel>(
                              key: ValueKey(_selectedCategory),
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
                                  : (value) => setState(
                                      () => _selectedCategory = value,
                                    ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Selecciona una categoría';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppShowcaseStep(
                            showcaseKey: _detailsKey,
                            title: 'Cuenta lo esencial',
                            description:
                                'Usa un título corto y una descripción concreta: qué viste, qué riesgo existe y desde cuándo ocurre si lo sabes.',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  enabled: !submitting,
                                  decoration: const InputDecoration(
                                    labelText: 'Título',
                                    hintText:
                                        'Ej. Bache peligroso en la calzada',
                                    prefixIcon: Icon(Icons.title_rounded),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLength: 80,
                                  validator: _requiredValidator,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _descriptionController,
                                  enabled: !submitting,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción del problema',
                                    hintText:
                                        'Describe detalladamente la situación y los peligros asociados...',
                                    alignLabelWithHint: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(bottom: 36),
                                      child: Icon(Icons.description_rounded),
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLength: 500,
                                  validator: _requiredValidator,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppShowcaseStep(
                            showcaseKey: _locationKey,
                            title: 'Ubicación precisa',
                            description:
                                'La ubicación coloca el reporte en el mapa. Si el permiso falla, puedes abrir ajustes y volver a intentarlo.',
                            child: _LocationCaptureCard(
                              position: _currentPosition,
                              locating: _locating,
                              message: _locationMessage,
                              blocked: _locationBlocked,
                              serviceDisabled: _locationServiceDisabled,
                              disabled: submitting,
                              addressController: _addressController,
                              onRetry: () => _useCurrentLocation(),
                              onOpenSettings: _locationBlocked
                                  ? Geolocator.openAppSettings
                                  : Geolocator.openLocationSettings,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppShowcaseStep(
                            showcaseKey: _imageKey,
                            title: 'Evidencia visual',
                            description:
                                'Una foto no es obligatoria, pero ayuda a validar la incidencia y evita reportes ambiguos.',
                            child: _ImagePickerCard(
                              selectedImage: _selectedImage,
                              selectedImageBytes: _selectedImageBytes,
                              disabled: submitting,
                              onCamera: () => _pickImage(ImageSource.camera),
                              onGallery: () => _pickImage(ImageSource.gallery),
                              onClear: _clearImage,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: AppShowcaseStep(
                      showcaseKey: _submitKey,
                      title: 'Enviar y seguir',
                      description:
                          'Cuando todo esté listo, envía el reporte. Luego aparecerá en Mis reportes para consultar su estado.',
                      child: _AnimatedSubmitButton(
                        submitting: submitting,
                        success: _submitSuccess,
                        locating: _locating,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
  final TextEditingController addressController;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenSettings;

  const _LocationCaptureCard({
    required this.position,
    required this.locating,
    required this.message,
    required this.blocked,
    required this.serviceDisabled,
    required this.disabled,
    required this.addressController,
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
        ? 'Obteniendo ubicación...'
        : hasProblem
        ? 'Ubicación requerida'
        : 'Ubicación del reporte';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasLocation
                        ? Icons.location_on_rounded
                        : Icons.location_searching_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (hasLocation) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${currentPosition.latitude.toStringAsFixed(5)}, ${currentPosition.longitude.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          message ?? 'Ubicaremos el reporte automáticamente con tu GPS.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(currentPosition.latitude, currentPosition.longitude),
                          initialZoom: 15,
                          minZoom: 10,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.cuenca_activa_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(currentPosition.latitude, currentPosition.longitude),
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.danger,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Actualizar ubicación',
                              onPressed: disabled || locating ? null : onRetry,
                              icon: locating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                      color: AppColors.teal,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              enabled: !disabled,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Dirección referencial',
                hintText: 'Ej. Frente al parque, casa color verde...',
                prefixIcon: Icon(Icons.info_outline_rounded),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (!hasLocation) ...[
              const SizedBox(height: 12),
              if (blocked || serviceDisabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: disabled || locating ? null : onRetry,
                      icon: locating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed_rounded, size: 16),
                      label: Text(
                        locating ? 'Ubicando...' : 'Reintentar',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: disabled || locating
                          ? null
                          : () async {
                              await onOpenSettings();
                            },
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Ajustes', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
              else
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: disabled || locating ? null : onRetry,
                    icon: locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.gps_fixed_rounded, size: 16),
                    label: Text(
                      locating ? 'Obteniendo...' : 'Obtener ubicación',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
  final bool disabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _ImagePickerCard({
    required this.selectedImage,
    required this.selectedImageBytes,
    required this.disabled,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final image = selectedImage;
    final bytes = selectedImageBytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen del reporte',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Foto opcional como evidencia.',
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
            const SizedBox(height: 12),
            if (image == null || bytes == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: disabled ? null : onCamera,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Cámara', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: disabled ? null : onGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galería', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              InteractiveViewer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(bytes),
                                ),
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          image.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: disabled ? null : onCamera,
                        icon: const Icon(Icons.cached_rounded, size: 16),
                        label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: disabled ? null : onClear,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Quitar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
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

class _AnimatedSubmitButton extends StatefulWidget {
  final bool submitting;
  final bool success;
  final bool locating;
  final VoidCallback onPressed;

  const _AnimatedSubmitButton({
    required this.submitting,
    required this.success,
    required this.locating,
    required this.onPressed,
  });

  @override
  State<_AnimatedSubmitButton> createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<_AnimatedSubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _flightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.submitting) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.submitting && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!widget.submitting && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.submitting || widget.success || widget.locating;

    final Color buttonColor;
    if (widget.success) {
      buttonColor = AppColors.success;
    } else if (isDisabled) {
      buttonColor = AppColors.navy.withValues(alpha: 0.5);
    } else {
      buttonColor = AppColors.navy;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 48,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isDisabled ? null : widget.onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: widget.success
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('success-icon'),
                            color: AppColors.white,
                            size: 20,
                          )
                        : widget.submitting
                            ? AnimatedBuilder(
                                animation: _flightAnimation,
                                builder: (context, child) {
                                  final double progress = _flightAnimation.value;
                                  final double opacity = progress < 0.1
                                      ? progress / 0.1
                                      : progress > 0.8
                                          ? (1.0 - progress) / 0.2
                                          : 1.0;

                                  return Transform.translate(
                                    offset: Offset(
                                      30.0 * progress - 10.0,
                                      -15.0 * progress + 5.0,
                                    ),
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Opacity(
                                        opacity: opacity.clamp(0.0, 1.0),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: AppColors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.send_rounded,
                                key: ValueKey('normal-icon'),
                                color: AppColors.white,
                                size: 18,
                              ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    widget.success
                        ? 'Reporte enviado'
                        : widget.submitting
                            ? 'Enviando reporte...'
                            : widget.locating
                                ? 'Obteniendo ubicación...'
                                : 'Enviar reporte',
                    key: ValueKey(
                      widget.success
                          ? 'success-text'
                          : widget.submitting
                              ? 'submitting-text'
                              : widget.locating
                                  ? 'locating-text'
                                  : 'normal-text',
                    ),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

