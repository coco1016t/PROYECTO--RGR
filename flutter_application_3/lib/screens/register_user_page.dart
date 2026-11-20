import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarPasswordController =
      TextEditingController();
  final AuthService authService = AuthService();
  final UserService userService = UserService();

  bool _cargando = false;
  bool _argumentoLeido = false;
  bool _esAdministrador = false;
  int _tipoUsuario = 2;
  Map<String, dynamic> _usuarioAdministrador = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentoLeido) return;

    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Map<String, dynamic>) {
      final tipo = argumento['tip_usu'];
      _esAdministrador = tipo is num && tipo.toInt() == 1;
      if (_esAdministrador) {
        _usuarioAdministrador = Map<String, dynamic>.from(argumento);
      }
    }
    _argumentoLeido = true;
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario() async {
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmarPassword = confirmarPasswordController.text;

    final mensaje = authService.validarRegistro(
      nombre: nombre,
      correo: correo,
      password: password,
      confirmarpassword: confirmarPassword,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      await userService.agregarUsuario(
        UserModel(
          id: 0,
          nombre: nombre,
          correo: correo,
          password: password,
          tipoUsuario: _esAdministrador ? _tipoUsuario : 2,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      if (_esAdministrador) {
        Navigator.pushReplacementNamed(
          context,
          '/users',
          arguments: _usuarioAdministrador,
        );
      } else {
        nombreController.clear();
        correoController.clear();
        passwordController.clear();
        confirmarPasswordController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo registrar el usuario: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de usuario'),
        backgroundColor: const Color(0xFFF7F9F8),
        foregroundColor: const Color(0xFF243341),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _esAdministrador
            ? Builder(
                builder: (context) => IconButton(
                  tooltip: 'Abrir menú',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                tooltip: 'Regresar',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
      ),
      drawer: _esAdministrador
          ? AdminDrawer(
              usuario: _usuarioAdministrador,
              rutaActual: '/register',
            )
          : null,
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
                            color: const Color(0xFFEEF5F4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 34,
                            color: Color(0xFF527D7B),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'CREAR CUENTA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF243341),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: nombreController,
                          label: 'Nombre completo',
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: correoController,
                          label: 'Correo electrónico',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: passwordController,
                          label: 'Contraseña',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: confirmarPasswordController,
                          label: 'Confirmar contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        if (_esAdministrador) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: _tipoUsuario,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tipo de usuario',
                              labelStyle:
                                  const TextStyle(color: Color(0xFF667483)),
                              floatingLabelStyle: const TextStyle(
                                color: Color(0xFF527D7B),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDCE3E8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDCE3E8)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF527D7B),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Color(0xFF243341)),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Administrador'),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('General'),
                              ),
                            ],
                            onChanged: _cargando
                                ? null
                                : (tipo) {
                                    if (tipo != null) {
                                      setState(() => _tipoUsuario = tipo);
                                    }
                                  },
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: _cargando ? 'REGISTRANDO...' : 'REGISTRARME',
                          onPressed: _cargando ? () {} : registrarUsuario,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _cargando ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF527D7B),
                          ),
                          child: const Text('Ya tengo una cuenta'),
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
