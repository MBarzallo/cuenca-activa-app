import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_showcase_step.dart';
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
  static bool _hasShownWelcomeGreeting = false;

  HomeViewMode _viewMode = HomeViewMode.map;
  bool _showBanner = false;

  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _toggleKey = GlobalKey();
  final GlobalKey _reportKey = GlobalKey();
  bool _tourScheduled = false;

  @override
  void initState() {
    super.initState();
    if (!_hasShownWelcomeGreeting) {
      _showBanner = true;
      _hasShownWelcomeGreeting = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshCurrentUser();
      context.read<IncidentsCubit>().loadInitialData();
    });
  }

  Future<void> _startShowcaseIfNeeded(
    BuildContext showcaseContext,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'has_shown_home_showcase_v2_$userId';
    final hasShownShowcase = prefs.getBool(key) ?? false;
    if (!hasShownShowcase && showcaseContext.mounted) {
      _startHomeTour(showcaseContext);
      await prefs.setBool(key, true);
    }
  }

  void _startHomeTour(BuildContext showcaseContext) {
    final keys = [_titleKey, _toggleKey, _reportKey];
    // ignore: deprecated_member_use
    ShowCaseWidget.of(showcaseContext).startShowCase(keys);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // ignore: deprecated_member_use
    return ShowCaseWidget(
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 420),
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_tourScheduled && authState is AuthAuthenticated) {
            _tourScheduled = true;
            _startShowcaseIfNeeded(showcaseContext, authState.user.idUsuario);
          }
        });

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
                AuthAuthenticated(:final user) => Stack(
                  children: [
                    // The Map is always active in the background for fluid gestures and zoom state retention
                    const Positioned.fill(
                      child: HomeMapView(key: ValueKey('map-view')),
                    ),

                    // Translucent blurred overlay when list mode is selected
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _viewMode == HomeViewMode.list
                            ? ClipRect(
                                key: const ValueKey('list-overlay'),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    color: AppColors.background.withValues(alpha: 0.92),
                                    child: HomeListView(
                                      key: const ValueKey('list-view'),
                                      user: user,
                                      topPadding: 80,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ),

                    // View toggle floats on top of all views (map and list)
                    Positioned(
                      top: 14,
                      right: 16,
                      child: AppShowcaseStep(
                        showcaseKey: _toggleKey,
                        title: 'Mapa o lista',
                        description:
                            'Cambia de mapa a lista cuando quieras comparar reportes con más detalle.',
                        child: HomeViewToggle(
                          value: _viewMode,
                          onChanged: (mode) =>
                              setState(() => _viewMode = mode),
                        ),
                      ),
                    ),

                    if (_showBanner)
                      Positioned(
                        top: 80,
                        left: 16,
                        right: 16,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _WelcomeGreetingBanner(
                            userName: user.nombres.trim().split(' ').first,
                            onDismissed: () {
                              setState(() {
                                _showBanner = false;
                              });
                            },
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
      },
    );
  }
}
class _WelcomeGreetingBanner extends StatefulWidget {
  final String userName;
  final VoidCallback onDismissed;

  const _WelcomeGreetingBanner({
    required this.userName,
    required this.onDismissed,
  });

  @override
  State<_WelcomeGreetingBanner> createState() => _WelcomeGreetingBannerState();
}

class _WelcomeGreetingBannerState extends State<_WelcomeGreetingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismissed();
      }
    });

    // Animate in
    _controller.forward();

    // Animate out after delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: FractionalTranslation(
            translation: Offset(0, _slideAnimation.value),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.lightGray.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '👋',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName.isNotEmpty
                              ? 'Bienvenido, ${widget.userName} 👋'
                              : 'Bienvenido 👋',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Gracias por ayudar a mejorar Cuenca.',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
