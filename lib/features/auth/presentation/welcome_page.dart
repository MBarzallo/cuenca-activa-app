import 'package:cuenca_activa_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  Hero(
                    tag: 'auth-logo',
                    child: Image.asset(
                      "assets/logos/icon_only_white.png",
                      width: size.width / 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"Tu ciudad, más cerca de ti."',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: AppColors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 34,
                ),
                child: Column(
                  children: [
                    Text(
                      "Bienvenido a CuencaActiva",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                        ),
                        onPressed: () => context.push("/login"),
                        child: Text(
                          "Iniciar sesión",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => context.go("/register"),
                        child: Text(
                          "Crear cuenta",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
