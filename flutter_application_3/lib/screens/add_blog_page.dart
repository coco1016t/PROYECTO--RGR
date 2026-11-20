import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/admin_drawer.dart';

class AddBlogPage extends StatefulWidget {
  final PostModel? publicacion;

  const AddBlogPage({super.key, this.publicacion});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.publicacion?.titulo);
  late final _descripcion =
      TextEditingController(text: widget.publicacion?.descripcion);
  late final _tags = TextEditingController(text: widget.publicacion?.tags);
  final _servicio = PostService();
  final _picker = ImagePicker();
  XFile? _foto;
  Uint8List? _imagenBytes;
  bool _guardando = false;
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    } else if (SesionService.instance.activa) {
      _usuario = Map<String, dynamic>.from(SesionService.instance.usuario);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (foto == null) {
        return;
      }

      final bytes = await foto.readAsBytes();
      if (!mounted) return;
      setState(() {
        _foto = foto;
        _imagenBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la cámara: $error')),
      );
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    final publicacion = widget.publicacion;
    final foto = _foto;
    final imagenBytes = _imagenBytes;
    if (publicacion == null && (foto == null || imagenBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toma una fotografía para continuar')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      if (publicacion != null) {
        await _servicio.editarPost(
          id: publicacion.id,
          titulo: _titulo.text,
          descripcion: _descripcion.text,
          tags: _tags.text,
          imagenBytes: imagenBytes,
          nombreImagen: foto?.name,
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }

      await _servicio.agregarPost(
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        imagenBytes: imagenBytes!,
        nombreImagen: foto!.name,
        tags: _tags.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación agregada correctamente')),
      );
      _titulo.clear();
      _descripcion.clear();
      _tags.clear();
      setState(() {
        _foto = null;
        _imagenBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.publicacion != null;
    final esAdmin = (_usuario['tip_usu'] as num?)?.toInt() == 1;
    final rol = esAdmin ? 'Administrador' : 'Autor';
    final nombre = _usuario['nom_usr']?.toString() ?? 'Usuario';
    final imagenActual = widget.publicacion?.imagen ?? '';
    final imagenBytes = _imagenBytes;
    final ImageProvider? vistaPrevia = imagenBytes != null
        ? MemoryImage(imagenBytes)
        : imagenActual.isEmpty
            ? null
            : NetworkImage(PostService.urlImagen(imagenActual).toString());

    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(editando ? 'Editar publicación' : 'Agregar blog'),
        ),
        drawer: !editando && esAdmin
            ? AdminDrawer(usuario: _usuario, rutaActual: '/add-blog')
            : null,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                        if (!editando) ...[
                          Text('Nueva publicación',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text('$rol: $nombre'),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _titulo,
                          enabled: !_guardando,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                          ),
                          validator: (valor) {
                            final longitud = valor?.trim().length ?? 0;
                            if (longitud < 2 || longitud > 150) {
                              return 'El título debe tener entre 2 y 150 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descripcion,
                          enabled: !_guardando,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              !editando && (v == null || v.trim().isEmpty)
                                  ? 'Ingresa la descripción'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _guardando ? null : _tomarFoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            vistaPrevia == null
                                ? 'Tomar fotografía'
                                : 'Cambiar fotografía',
                          ),
                        ),
                        if (vistaPrevia != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: vistaPrevia,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Text('Imagen no disponible')),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tags,
                          enabled: !_guardando,
                          decoration: const InputDecoration(
                            labelText: 'Etiquetas (opcional)',
                            hintText: 'flutter, tecnología, móvil',
                          ),
                          validator: (valor) =>
                              (valor?.trim().length ?? 0) > 255
                                  ? 'Las etiquetas admiten hasta 255 caracteres'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _guardando ? null : _guardar,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _guardando
                                ? 'Guardando...'
                                : (editando
                                    ? 'Guardar cambios'
                                    : 'Guardar publicación'),
                          ),
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
