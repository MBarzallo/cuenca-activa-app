import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.gold,
                          foregroundImage:
                              (user.fotoPerfilUrl ?? '').trim().isEmpty
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
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _savingProfile
                              ? null
                              : () => _changeProfilePhoto(user),
                          icon: _savingProfile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_camera_outlined),
                          label: const Text('Cambiar foto'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user.nombres} ${user.apellidos}'.trim().isEmpty
                              ? 'Ciudadano'
                              : '${user.nombres} ${user.apellidos}'.trim(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.aliasPublico.isEmpty
                              ? user.email
                              : '@${user.aliasPublico}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _savingProfile
                        ? null
                        : () => _showEditProfileSheet(user),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar datos'),
                  ),
                  const SizedBox(height: 12),
                  _LevelProgressCard(
                    levelName: user.nombreNivelActual,
                    points: user.puntosTotales,
                    minPoints: user.puntosMinimosNivel,
                    maxPoints: user.puntosMaximosNivel,
                    progress: user.nivelProgress,
                    pointsToNextLevel: user.puntosParaSiguienteNivel,
                  ),
                  const SizedBox(height: 12),
                  _ProfileMetricCard(
                    icon: Icons.stars_rounded,
                    title: 'Puntos comunitarios',
                    value: '${user.puntosTotales}',
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Correo',
                    value: user.email,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Telefono',
                    value: (user.telefono ?? '').isEmpty
                        ? 'No registrado'
                        : user.telefono!,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Estado de cuenta',
                    value: user.estadoCuenta.isEmpty
                        ? 'Activo'
                        : user.estadoCuenta,
                  ),
                  const SizedBox(height: 12),
                  _PointsHistorySection(
                    movementsFuture: _movementsFuture,
                    onRetry: _reloadMovements,
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesion'),
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
      final photoUrl = await context.read<AuthCubit>().uploadProfilePhoto(
        image,
      );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    _telefonoController = TextEditingController(
      text: widget.user.telefono ?? '',
    );
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_submitting ? 'Guardando...' : 'Guardar cambios'),
                ),
              ),
            ],
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

class _LevelProgressCard extends StatelessWidget {
  final String levelName;
  final int points;
  final int minPoints;
  final int maxPoints;
  final double progress;
  final int pointsToNextLevel;

  const _LevelProgressCard({
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelName.isEmpty ? 'Nivel ciudadano' : levelName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$points puntos acumulados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
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
                minHeight: 10,
                backgroundColor: AppColors.lightGray,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$minPoints pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  pointsToNextLevel == 0
                      ? 'Nivel máximo'
                      : '$pointsToNextLevel pts para subir',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '$maxPoints pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
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

class _PointsHistorySection extends StatelessWidget {
  final Future<List<PointsMovementModel>> movementsFuture;
  final VoidCallback onRetry;

  const _PointsHistorySection({
    required this.movementsFuture,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<PointsMovementModel>>(
          future: movementsFuture,
          builder: (context, snapshot) {
            final movements = snapshot.data ?? const <PointsMovementModel>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Historial de puntos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _PointsHistoryLoading()
                else if (snapshot.hasError)
                  _PointsHistoryMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'No pudimos cargar tus movimientos',
                    message: 'Intenta nuevamente en unos segundos.',
                    onRetry: onRetry,
                  )
                else if (movements.isEmpty)
                  const _PointsHistoryMessage(
                    icon: Icons.stars_outlined,
                    title: 'Sin movimientos todavía',
                    message:
                        'Cuando reportes, votes o confirmes incidencias, verás tus puntos aquí.',
                  )
                else
                  ...movements.map((movement) {
                    return _PointsMovementTile(movement: movement);
                  }),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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
    final pointsLabel = movement.puntos >= 0
        ? '+${movement.puntos}'
        : '${movement.puntos}';

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
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

class _ProfileMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ProfileMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
