import 'package:flutter/material.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/valoracion_estrellas.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ComentarioService _servicio = ComentarioService();
  final TextEditingController _controller = TextEditingController();
  late Future<List<ComentarioModel>> _futuroComentarios;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _futuroComentarios = _servicio.obtenerComentarios(widget.post.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _futuroComentarios = _servicio.obtenerComentarios(widget.post.id);
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _servicio.agregarComentario(
        blogId: widget.post.id,
        texto: texto,
      );
      if (!mounted) return;
      _controller.clear();
      FocusScope.of(context).unfocus();
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _fechaCorta(String fecha) {
    // "2026-11-17T20:48:05" -> "2026-11-17 20:48"
    final limpia = fecha.replaceFirst('T', ' ');
    return limpia.length >= 16 ? limpia.substring(0, 16) : limpia;
  }

  Widget _seccionComentarios() {
    final miId = SesionService.instance.idUsuario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentarios',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08245C),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<ComentarioModel>>(
          future: _futuroComentarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${snapshot.error}'.replaceFirst('Exception: ', ''),
                  ),
                  TextButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }

            final comentarios = snapshot.data ?? <ComentarioModel>[];

            if (comentarios.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aún no hay comentarios. ¡Sé el primero!'),
              );
            }

            return Column(
              children: comentarios.map((c) {
                final esMio = c.usuarioId == miId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: esMio ? const Color(0xFFE8F0FE) : null,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      esMio
                          ? '${c.autor.isEmpty ? 'Usuario' : c.autor} (tú)'
                          : (c.autor.isEmpty ? 'Usuario' : c.autor),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.comentario),
                    trailing: Text(
                      _fechaCorta(c.fecha),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLength: 1000,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe un comentario...',
            border: const OutlineInputBorder(),
            suffixIcon: _enviando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.send),
                    onPressed: _enviar,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de publicación'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imagen.isNotEmpty)
              Image.network(
                PostService.urlImagen(post.imagen).toString(),
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.tags.isNotEmpty) ...[
                    Text(
                      post.tags,
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    post.titulo,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08245C),
                    ),
                  ),
                  if (post.autor.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Por ${post.autor}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    post.descripcion.isNotEmpty
                        ? post.descripcion
                        : 'Esta publicación no tiene descripción.',
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  ValoracionEstrellas(blogId: post.id),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _seccionComentarios(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}