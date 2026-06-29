import 'package:cuenca_activa_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final aliasController = TextEditingController();
  final telefonoController = TextEditingController();

  bool obscurePassword = true;

  void _register() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = telefonoController.text.trim();
    final phone = rawPhone.isEmpty ? '' : _normalizarTelefono(rawPhone);

    context.read<AuthCubit>().register(
      email: emailController.text.trim(),
      password: passwordController.text,
      nombres: nombresController.text.trim(),
      apellidos: apellidosController.text.trim(),
      aliasPublico: aliasController.text.trim(),
      telefono: phone,
    );
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
    emailController.dispose();
    passwordController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    aliasController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }

        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.navy,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        left: 8,
                        child: IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'auth-logo',
                              child: Image.asset(
                                'assets/logos/icon_only_white.png',
                                width: size.width * 0.25,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                    ],
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(34, 30, 34, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Crear cuenta',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Únete a la comunidad y ayuda a mejorar tu ciudad.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 26),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Usa al menos 6 caracteres';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: nombresController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Nombres',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: apellidosController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Apellidos',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: aliasController,
                              textInputAction: TextInputAction.next,
                              maxLength: 50,
                              decoration: const InputDecoration(
                                labelText: 'Alias público',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: _aliasValidator,
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: telefonoController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              maxLength: 20,
                              onFieldSubmitted: (_) {
                                if (!loading) _register();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Teléfono (Ecuador)',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '09XXXXXXXX',
                                helperText: 'Opcional. Ej: 0998765432 o 998765432',
                              ),
                              validator: (value) {
                                final val = (value ?? '').trim().replaceAll(RegExp(r'[\s\-()]+'), '');
                                if (val.isEmpty) {
                                  return null;
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
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: AppColors.white,
                                ),
                                onPressed: loading ? null : _register,
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Text('Crear cuenta'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => context.go('/login'),
                                child: const Text('Ya tengo cuenta'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (email.isEmpty) {
      return 'Ingresa tu correo';
    }

    if (!isValid) {
      return 'Ingresa un correo valido';
    }

    return null;
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    return null;
  }

  static String? _aliasValidator(String? value) {
    final alias = value?.trim() ?? '';
    final isValid = RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(alias);

    if (alias.length < 3) {
      return 'Usa al menos 3 caracteres';
    }

    if (!isValid) {
      return 'Solo letras, numeros, puntos y guiones';
    }

    return null;
  }
}
