import 'package:flutter/material.dart';
import '../models/comentario_model.dart';
import '../models/mensaje_model.dart';
import '../models/post_model.dart';
import '../services/comentario_service.dart';
import '../services/mensajeria_service.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/valoracion_estrellas.dart';
import 'mensajes_page.dart';

const Color _detailBackground = Color(0xFFF7F9F8);
const Color _detailSurface = Color(0xFFFFFFFF);
const Color _detailText = Color(0xFF243341);
const Color _detailMuted = Color(0xFF667483);
const Color _detailAccent = Color(0xFF527D7B);
const Color _detailTint = Color(0xFFEEF5F4);
const Color _detailBorder = Color(0xFFDCE3E8);

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
  final MensajeriaService _mensajeriaService = MensajeriaService();
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
    _mensajeriaService.dispose();
    super.dispose();
  }

  Future<void> _enviarMensajeAutor() async {
    final autorId = widget.post.usuarioId;
    final miId = SesionService.instance.idUsuario;
    if (autorId == null || autorId == miId) return;

    try {
      final conversacion = await _mensajeriaService.abrirConversacion(autorId);
      var nombreContacto = conversacion.contacto.nombre;
      try {
        final contactos = await _mensajeriaService.obtenerContactos();
        nombreContacto = nombreContactoVisible(
          conversacion.contacto.nombre,
          conversacion.contacto.id,
          contactos,
        );
      } catch (_) {
        if (!SesionService.instance.activa) return;
        nombreContacto =
            '${conversacion.contacto.nombre} (#${conversacion.contacto.id})';
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatPrivadoPage(
            conversacionId: conversacion.id,
            contacto: ContactoMensajeria(
              id: conversacion.contacto.id,
              nombre: conversacion.contacto.nombre,
            ),
            nombreContacto: nombreContacto,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _detailText,
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ComentarioModel>>(
          future: _futuroComentarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: _detailAccent),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _detailBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _detailBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snapshot.error}'.replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: _detailMuted),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style:
                          TextButton.styleFrom(foregroundColor: _detailAccent),
                    ),
                  ],
                ),
              );
            }

            final comentarios = snapshot.data ?? <ComentarioModel>[];

            if (comentarios.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _detailBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _detailBorder),
                ),
                child: const Text(
                  'Aún no hay comentarios. ¡Sé el primero!',
                  style: TextStyle(color: _detailMuted),
                ),
              );
            }

            return Column(
              children: comentarios.map((c) {
                final esMio = c.usuarioId == miId;
                final nombre = esMio
                    ? '${c.autor.isEmpty ? 'Usuario' : c.autor} (tú)'
                    : (c.autor.isEmpty ? 'Usuario' : c.autor);

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: esMio ? _detailTint : _detailSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _detailBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final autor = Row(
                            children: [
                              const CircleAvatar(
                                radius: 17,
                                backgroundColor: _detailTint,
                                child: Icon(
                                  Icons.person_outline,
                                  size: 19,
                                  color: _detailAccent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _detailText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                          final fecha = Text(
                            _fechaCorta(c.fecha),
                            style: const TextStyle(
                              color: _detailMuted,
                              fontSize: 12,
                            ),
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                autor,
                                const SizedBox(height: 7),
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
                                  child: fecha,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: autor),
                              const SizedBox(width: 12),
                              fecha,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.comentario,
                        style: const TextStyle(
                          color: _detailText,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          cursorColor: _detailAccent,
          style: const TextStyle(color: _detailText, fontSize: 15),
          maxLength: 1000,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe un comentario...',
            hintStyle: const TextStyle(color: _detailMuted),
            filled: true,
            fillColor: _detailSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _detailBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _detailAccent, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _detailBorder),
            ),
            suffixIcon: _enviando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _detailAccent,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Enviar',
                    color: _detailAccent,
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
    final tags = post.tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _detailBackground,
      appBar: AppBar(
        title: const Text('Detalle de publicación'),
        backgroundColor: _detailSurface,
        foregroundColor: _detailText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: _detailText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;
          final outerMargin =
              narrow ? 16.0 : (constraints.maxWidth >= 1200 ? 32.0 : 24.0);
          final cardPadding = narrow ? 16.0 : 32.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              outerMargin,
              narrow ? 12 : 28,
              outerMargin,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _detailSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _detailBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) {
                              final etiqueta =
                                  tag.startsWith('#') ? tag : '#$tag';
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _detailTint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  child: Text(
                                    etiqueta,
                                    style: const TextStyle(
                                      color: _detailAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          post.titulo,
                          style: TextStyle(
                            color: _detailText,
                            fontSize: narrow ? 26 : 32,
                            height: 1.22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, authorConstraints) {
                            final autor = Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _detailTint,
                                  child: Icon(
                                    Icons.person_outline,
                                    color: _detailAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    post.autor.isEmpty
                                        ? 'Autor desconocido'
                                        : post.autor,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _detailText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (post.usuarioId != null &&
                                post.usuarioId !=
                                    SesionService.instance.idUsuario) {
                              final botonMensaje = OutlinedButton.icon(
                                onPressed: _enviarMensajeAutor,
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Enviar mensaje'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _detailAccent,
                                  side: const BorderSide(color: _detailAccent),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );

                              if (authorConstraints.maxWidth < 560) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    autor,
                                    const SizedBox(height: 12),
                                    botonMensaje,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: autor),
                                  const SizedBox(width: 16),
                                  botonMensaje,
                                ],
                              );
                            }

                            return autor;
                          },
                        ),
                        if (post.imagen.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, imageConstraints) {
                              final imageHeight =
                                  imageConstraints.maxWidth >= 900
                                      ? (imageConstraints.maxWidth * 0.36)
                                          .clamp(300.0, 380.0)
                                          .toDouble()
                                      : (imageConstraints.maxWidth * 0.62)
                                          .clamp(180.0, 260.0)
                                          .toDouble();

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: ColoredBox(
                                  color: _detailBackground,
                                  child: Image.network(
                                    PostService.urlImagen(post.imagen)
                                        .toString(),
                                    width: double.infinity,
                                    height: imageHeight,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return SizedBox(
                                        width: double.infinity,
                                        height: imageHeight,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: _detailMuted,
                                            size: 30,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: Text(
                              post.descripcion.isNotEmpty
                                  ? post.descripcion
                                  : 'Esta publicación no tiene descripción.',
                              style: const TextStyle(
                                color: _detailText,
                                fontSize: 17,
                                height: 1.65,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Divider(color: _detailBorder, height: 1),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(narrow ? 14 : 18),
                          decoration: BoxDecoration(
                            color: _detailBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _detailBorder),
                          ),
                          child: ValoracionEstrellas(blogId: post.id),
                        ),
                        const SizedBox(height: 28),
                        _seccionComentarios(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
