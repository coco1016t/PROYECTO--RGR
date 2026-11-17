import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/admin_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  final _userService = UserService();
  Map<String, dynamic> _usuario = {};
  bool _cargando = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
    _nombre.text = _usuario['nom_usr']?.toString() ?? '';
    _correo.text = _usuario['mail']?.toString() ?? '';
    _direccion.text = _usuario['dir_usr']?.toString() ?? '';
    _inicializado = true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _usuario['id_usr'];
    if (id is! num) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se recibió el identificador del usuario. Vuelve a iniciar sesión.')),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      final usuarioActualizado = await _userService.actualizarUsuario(
        UserModel(
          id: id.toInt(),
          nombre: _nombre.text.trim(),
          correo: _correo.text.trim().toLowerCase(),
          direccion:
              _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
          tipoUsuario: (_usuario['tip_usu'] as num?)?.toInt() ?? 2,
        ),
      );
      _usuario = {
        'id_usr': usuarioActualizado.id,
        'nom_usr': usuarioActualizado.nombre,
        'mail': usuarioActualizado.correo,
        'dir_usr': usuarioActualizado.direccion,
        'tip_usu': usuarioActualizado.tipoUsuario,
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      drawer: AdminDrawer(usuario: _usuario, rutaActual: '/profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        child: Icon(Icons.person, size: 42),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().length < 2
                            ? 'Ingresa un nombre válido' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Ingresa un correo válido' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _direccion,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _cargando ? null : _guardar,
                        icon: const Icon(Icons.save),
                        label: Text(_cargando ? 'Guardando...' : 'Guardar cambios'),
                      ),
                    ],
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
