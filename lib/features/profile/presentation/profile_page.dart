import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../main/presentation/main_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/');
        }
      },
      child: MainScaffold(
        currentIndex: 3,
        title: 'Perfil',
        body: SafeArea(
          child: switch (authState) {
            AuthAuthenticated(:final user) => ListView(
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
                        child: Text(
                          _initials(user.nombres, user.apellidos),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        user.aliasPublico.isEmpty
                            ? user.email
                            : '@${user.aliasPublico}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesion'),
                ),
              ],
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
