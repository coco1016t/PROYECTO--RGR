import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> restablecerPassword() async {
    final error = authService.validarRestablecimiento(
      correo: correoController.text,
      password: passwordController.text,
    );
    if (error != null) {
      _mostrarMensaje(error);
      return;
    }

    setState(() => cargando = true);
    try {
      await authService.restablecerPassword(
        correo: correoController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: AuthCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: 36,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'RECUPERAR CONTRASEÑA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: correoController,
                          label: 'Correo electrónico',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: passwordController,
                          label: 'Nueva contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: ocultarPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(
                                  () => ocultarPassword = !ocultarPassword);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          text: cargando
                              ? 'PROCESANDO...'
                              : 'ACTUALIZAR CONTRASEÑA',
                          onPressed: cargando ? () {} : restablecerPassword,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Volver a iniciar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
