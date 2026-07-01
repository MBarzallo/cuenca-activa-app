import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_user_model.dart';
import '../../auth/data/points_movement_model.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _imagePicker = ImagePicker();
  late Future<List<PointsMovementModel>> _movementsFuture;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _movementsFuture = Future.value(const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshCurrentUser();
      _reloadMovements();
    });
  }

  void _reloadMovements() {
    setState(() {
      _movementsFuture = context.read<AuthCubit>().getPointsMovements();
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('¿Seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (authState) {
            AuthAuthenticated(:final user) => RefreshIndicator(
                onRefresh: context.read<AuthCubit>().refreshCurrentUser,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Compact Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: _savingProfile ? null : () => _showEditProfileSheet(user),
                              icon: const Icon(Icons.edit_outlined, color: AppColors.gold, size: 22),
                              tooltip: 'Editar datos',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 38,
                                      backgroundColor: AppColors.gold,
                                      foregroundImage: (user.fotoPerfilUrl ?? '').trim().isEmpty
                                          ? null
                                          : CachedNetworkImageProvider(
                                              user.fotoPerfilUrl!.trim(),
                                            ),
                                      child: (user.fotoPerfilUrl ?? '').trim().isEmpty
                                          ? Text(
                                              _initials(user.nombres, user.apellidos),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    color: AppColors.navy,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            )
                                          : null,
                                    ),
                                    if (_savingProfile)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.gold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!_savingProfile)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => _changeProfilePhoto(user),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppColors.gold,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 14,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${user.nombres} ${user.apellidos}'.trim().isEmpty
                                      ? 'Ciudadano'
                                      : '${user.nombres} ${user.apellidos}'.trim(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.aliasPublico.isEmpty ? user.email : '@${user.aliasPublico}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.white.withValues(alpha: 0.72),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unified Citizen Progress Card (includes Level, points, progress, and metric chips)
                    _CitizenProgressCard(
                      levelName: user.nombreNivelActual,
                      points: user.puntosTotales,
                      minPoints: user.puntosMinimosNivel,
                      maxPoints: user.puntosMaximosNivel,
                      progress: user.nivelProgress,
                      pointsToNextLevel: user.puntosParaSiguienteNivel,
                    ),
                    const SizedBox(height: 16),

                    // Compact Personal Info Card
                    _ProfilePersonalInfoCard(
                      email: user.email,
                      telefono: user.telefono ?? '',
                      telefonoPendiente: user.telefonoPendiente,
                      telefonoVerificado: user.telefonoVerificado,
                      estadoCuenta: user.estadoCuenta,
                      onVerifyPressed: () => _showVerifyPhoneSheet(user),
                    ),
                    const SizedBox(height: 16),

                    // Compact Points History Card
                    _PointsHistorySection(
                      movementsFuture: _movementsFuture,
                      onRetry: _reloadMovements,
                    ),
                    const SizedBox(height: 20),

                    // Secondary/Destructive Logout Button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _ => const Center(child: Text('No hay usuario autenticado')),
          },
        ),
      ),
    );
  }

  static String _initials(String nombres, String apellidos) {
    final first = nombres.trim().isEmpty ? 'C' : nombres.trim()[0];
    final second = apellidos.trim().isEmpty ? 'A' : apellidos.trim()[0];

    return '$first$second'.toUpperCase();
  }

  Future<void> _showEditProfileSheet(AuthUserModel user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: _EditProfileSheet(user: user),
      ),
    );

    if (result == true && mounted) {
      _showMessage('Perfil actualizado correctamente.');
    }
  }

  Future<void> _showVerifyPhoneSheet(AuthUserModel user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: _VerifyPhoneSheet(user: user),
      ),
    );

    if (result == true && mounted) {
      _showMessage('Celular verificado exitosamente.');
    }
  }

  Future<void> _changeProfilePhoto(AuthUserModel user) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final photoUrl = await context.read<AuthCubit>().uploadProfilePhoto(image);
      if (photoUrl == null || !mounted) {
        return;
      }

      final error = await context.read<AuthCubit>().updateProfile(
            nombres: user.nombres,
            apellidos: user.apellidos,
            aliasPublico: user.aliasPublico,
            telefono: user.telefono,
            fotoPerfilUrl: photoUrl,
          );

      if (!mounted) {
        return;
      }

      if (error == null) {
        _showMessage('Foto de perfil actualizada.');
      } else {
        _showMessage(error);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EditProfileSheet extends StatefulWidget {
  final AuthUserModel user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _aliasController;
  late final TextEditingController _telefonoController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.user.nombres);
    _apellidosController = TextEditingController(text: widget.user.apellidos);
    _aliasController = TextEditingController(text: widget.user.aliasPublico);
    _telefonoController = TextEditingController(text: widget.user.telefono ?? '');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _aliasController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Editar perfil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombresController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombres',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa tus nombres.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apellidosController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa tus apellidos.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aliasController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Alias público',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final alias = (value ?? '').trim();
                      if (alias.length < 3) {
                        return 'El alias debe tener al menos 3 caracteres.';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(alias)) {
                        return 'Usa letras, números, puntos, guiones o guiones bajos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (widget.user.telefonoVerificado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Celular verificado (no se puede cambiar aquí)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.telefono ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (pendiente de verificación)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText: 'Usa formato E.164 (ej: +5939XXXXXXXX)',
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_submitting ? 'Guardando...' : 'Guardar cambios'),
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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    final error = await context.read<AuthCubit>().updateProfile(
          nombres: _nombresController.text,
          apellidos: _apellidosController.text,
          aliasPublico: _aliasController.text,
          telefono: _telefonoController.text,
          fotoPerfilUrl: widget.user.fotoPerfilUrl,
        );

    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

class _CitizenProgressCard extends StatelessWidget {
  final String levelName;
  final int points;
  final int minPoints;
  final int maxPoints;
  final double progress;
  final int pointsToNextLevel;

  const _CitizenProgressCard({
    required this.levelName,
    required this.points,
    required this.minPoints,
    required this.maxPoints,
    required this.progress,
    required this.pointsToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel de Ciudadano',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelName.isEmpty ? 'Inicial' : levelName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        '$points pts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.lightGray.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minPoints pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      pointsToNextLevel == 0
                          ? 'Nivel máximo alcanzado 🎉'
                          : 'Faltan $pointsToNextLevel pts para subir',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Text(
                  '$maxPoints pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetricChip(
                    label: 'Puntos',
                    value: '$points',
                    icon: Icons.star_border_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetricChip(
                    label: 'Nivel',
                    value: levelName.isEmpty ? 'Inicial' : levelName,
                    icon: Icons.workspace_premium_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetricChip(
                    label: 'Para subir',
                    value: pointsToNextLevel == 0 ? 'Límite' : '$pointsToNextLevel',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniMetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePersonalInfoCard extends StatelessWidget {
  final String email;
  final String telefono;
  final String? telefonoPendiente;
  final bool telefonoVerificado;
  final String estadoCuenta;
  final VoidCallback onVerifyPressed;

  const _ProfilePersonalInfoCard({
    required this.email,
    required this.telefono,
    required this.telefonoPendiente,
    required this.telefonoVerificado,
    required this.estadoCuenta,
    required this.onVerifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final displayPhone = telefonoVerificado 
        ? telefono 
        : ((telefonoPendiente ?? '').isEmpty ? 'No registrado' : '$telefonoPendiente\n(pendiente)');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información personal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: 14),
            _PersonalInfoRow(
              icon: Icons.email_outlined,
              label: 'Correo electrónico',
              value: email,
            ),
            const Divider(height: 16, thickness: 1, color: AppColors.lightGray),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _PersonalInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: displayPhone,
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayPhone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                        ),
                        const SizedBox(width: 6),
                        if (telefonoVerificado)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.success,
                          )
                        else
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                      ],
                    ),
                  ),
                ),
                if (!telefonoVerificado)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onVerifyPressed,
                    icon: const Icon(Icons.security_rounded, size: 14),
                    label: const Text(
                      'Verificar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16, thickness: 1, color: AppColors.lightGray),
            _PersonalInfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Estado de cuenta',
              value: estadoCuenta.isEmpty ? 'Activo' : estadoCuenta,
              valueColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueWidget;

  const _PersonalInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              valueWidget ?? Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? AppColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsHistorySection extends StatelessWidget {
  final Future<List<PointsMovementModel>> movementsFuture;
  final VoidCallback onRetry;

  const _PointsHistorySection({
    required this.movementsFuture,
    required this.onRetry,
  });

  void _showAllMovementsSheet(BuildContext context, List<PointsMovementModel> movements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Historial de Puntos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: movements.length,
                      itemBuilder: (context, index) {
                        return _PointsMovementTile(movement: movements[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<PointsMovementModel>>(
          future: movementsFuture,
          builder: (context, snapshot) {
            final movements = snapshot.data ?? const <PointsMovementModel>[];
            final recentMovements = movements.take(3).toList();
            final hasMore = movements.length > 3;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Historial de puntos',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _PointsHistoryLoading()
                else if (snapshot.hasError)
                  _PointsHistoryMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'No se cargaron los movimientos',
                    message: 'Intenta nuevamente.',
                    onRetry: onRetry,
                  )
                else if (movements.isEmpty)
                  const _PointsHistoryMessage(
                    icon: Icons.stars_outlined,
                    title: 'Sin movimientos',
                    message: 'Obtendrás puntos al reportar o votar.',
                  )
                else ...[
                  ...recentMovements.map((movement) {
                    return _PointsMovementTile(movement: movement);
                  }),
                  if (hasMore) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showAllMovementsSheet(context, movements),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppColors.teal),
                          foregroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Ver historial completo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PointsHistoryLoading extends StatelessWidget {
  const _PointsHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 58,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }
}

class _PointsHistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _PointsHistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsMovementTile extends StatelessWidget {
  final PointsMovementModel movement;

  const _PointsMovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final date = movement.creadoEn == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM, HH:mm').format(movement.creadoEn!.toLocal());
    final pointsLabel = movement.puntos >= 0 ? '+${movement.puntos}' : '${movement.puntos}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_task_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.nombreAccion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  movement.tituloIncidencia?.trim().isNotEmpty == true
                      ? movement.tituloIncidencia!.trim()
                      : date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (movement.tituloIncidencia?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$pointsLabel pts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _VerifyPhoneSheet extends StatefulWidget {
  final AuthUserModel user;

  const _VerifyPhoneSheet({required this.user});

  @override
  State<_VerifyPhoneSheet> createState() => _VerifyPhoneSheetState();
}

class _VerifyPhoneSheetState extends State<_VerifyPhoneSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1 = Enter Phone, 2 = Enter OTP
  String? _verificationId;
  String? _errorMessage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initialPhone = widget.user.telefonoPendiente ?? widget.user.telefono ?? '';
    String displayPhone = initialPhone;
    if (displayPhone.startsWith('+593')) {
      displayPhone = '0${displayPhone.substring(4)}';
    }
    _phoneController.text = displayPhone;
  }

  String _normalizarTelefono(String rawPhone) {
    String phone = rawPhone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (phone.startsWith('+')) {
      return phone;
    }
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return '+593$phone';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _mapFirebasePhoneError(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('invalid-phone-number') || text.contains('invalid_phone_number')) {
      return 'El número de teléfono no es válido. Debe tener formato E.164 (ej: +5939XXXXXXXX).';
    }
    if (text.contains('provider-already-linked') || 
        text.contains('credential-already-in-use') ||
        text.contains('already-in-use')) {
      return 'Este número celular ya está verificado por otra cuenta.';
    }
    if (text.contains('invalid-verification-code') || text.contains('invalid-otp') || text.contains('session-expired')) {
      return 'El código de verificación ingresado es incorrecto o ha expirado.';
    }
    if (text.contains('too-many-requests')) {
      return 'Demasiados intentos. Por favor, inténtalo más tarde.';
    }
    if (error is FirebaseAuthException && error.message != null) {
      return error.message!;
    }
    return 'Ocurrió un error al verificar el celular. Inténtalo nuevamente.';
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final phone = _normalizarTelefono(_phoneController.text.trim());

    try {
      await context.read<AuthCubit>().verificarDisponibilidadTelefono(phone);
      if (!mounted) return;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          try {
            await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
            final error = await context.read<AuthCubit>().sincronizarTelefono();
            if (!mounted) return;
            if (error == null) {
              Navigator.of(context).pop(true);
            } else {
              setState(() {
                _errorMessage = error;
                _loading = false;
              });
            }
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _errorMessage = _mapFirebasePhoneError(e);
              _loading = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = _mapFirebasePhoneError(e);
            _loading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _step = 2;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapFirebasePhoneError(e);
        _loading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'El código debe tener exactamente 6 dígitos.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      if (!mounted) return;

      final error = await context.read<AuthCubit>().sincronizarTelefono();
      if (!mounted) return;

      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = error;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapFirebasePhoneError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _step == 1 ? 'Verificar celular' : 'Ingresar código OTP',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _step == 1
                        ? 'Enviaremos un SMS de verificación. Ingresa tu número celular de Ecuador (comenzando con 09 o 9).'
                        : 'Ingresa el código de seguridad de 6 dígitos que enviamos a tu número celular.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_step == 1) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Número celular (Ecuador)',
                        prefixIcon: Icon(Icons.phone_rounded),
                        hintText: '09XXXXXXXX',
                        helperText: 'Ingresa tu número celular (ej: 0998765432 o 998765432)',
                      ),
                      validator: (value) {
                        final val = (value ?? '').trim().replaceAll(RegExp(r'[\s\-()]+'), '');
                        if (val.isEmpty) {
                          return 'Ingresa tu número celular.';
                        }
                        if (val.startsWith('+')) {
                          if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(val)) {
                            return 'Formato internacional inválido.';
                          }
                        } else {
                          final hasLeadingZero = val.startsWith('0');
                          final expectedLength = hasLeadingZero ? 10 : 9;
                          final cleanVal = hasLeadingZero ? val.substring(1) : val;
                          if (!cleanVal.startsWith('9') || val.length != expectedLength || !RegExp(r'^\d+$').hasMatch(val)) {
                            return 'Ingresa un celular válido de Ecuador (ej: 0998765432).';
                          }
                        }
                        print('Normalized phone: ${_normalizarTelefono(val)}');
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _sendCode,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_loading ? 'Enviando...' : 'Enviar SMS'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Código de seguridad',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _step = 1;
                                      _errorMessage = null;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Volver'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _loading ? null : _verifyCode,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Text('Verificar código'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
