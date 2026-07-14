import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppFlow();
    });
  }

  Future<void> _initAppFlow() async {
    try {
      await Permission.locationWhenInUse.request();
    } catch (e) {
      debugPrint('Error requesting location permission on startup: $e');
    }
    _checkCurrentState();
  }

  void _checkCurrentState() {
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    _handleState(state);
  }

  void _handleState(AuthState state) {
    if (!mounted) return;
    if (state is AuthAuthenticated) {
      context.go('/home');
    } else if (state is AuthUnauthenticated || state is AuthFailure) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _handleState(state);
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'auth-logo',
                child: Image.asset(
                  "assets/logos/icon_only_white.png",
                  width: 110,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "CuencaActiva",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tu ciudad, más cerca de ti.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
