import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../incidents/logic/incidents_cubit.dart';
import 'widgets/home_list_view.dart';
import 'widgets/home_map_view.dart';
import 'widgets/home_view_toggle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeViewMode _viewMode = HomeViewMode.map;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshCurrentUser();
      context.read<IncidentsCubit>().loadInitialData();
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
          bottom: false,
          child: switch (authState) {
            AuthAuthenticated(:final user) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _viewMode == HomeViewMode.map
                              ? 'Reportes cerca de ti'
                              : 'Todos los reportes',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                              ),
                        ),
                      ),
                      HomeViewToggle(
                        value: _viewMode,
                        onChanged: (mode) => setState(() => _viewMode = mode),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _viewMode == HomeViewMode.map
                        ? const HomeMapView(key: ValueKey('map-view'))
                        : HomeListView(
                            key: const ValueKey('list-view'),
                            user: user,
                          ),
                  ),
                ),
              ],
            ),
            _ => const Center(child: Text('No hay usuario autenticado')),
          },
        ),
      ),
    );
  }
}
