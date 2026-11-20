import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';

const Color _cardBorder = Color(0xFFDCE3E8);
const Color _cardText = Color(0xFF243341);
const Color _cardMuted = Color(0xFF667483);
const Color _cardAccent = Color(0xFF527D7B);
const Color _cardTint = Color(0xFFEEF5F4);

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final author = post.usuarioId != null &&
            post.usuarioId == SesionService.instance.idUsuario
        ? 'Publicado por ti'
        : (post.autor.isEmpty ? 'Autor desconocido' : 'Por ${post.autor}');
    final tags = post.tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final rating = post.totalValoraciones == 0
        ? 'Sin valoraciones'
        : '${post.promedio.toStringAsFixed(1)} '
            '(${post.totalValoraciones})';

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 15 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: _cardTint,
                    child: Icon(
                      Icons.person_outline,
                      color: _cardAccent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tags.map((tag) {
                    final label = tag.startsWith('#') ? tag : '#$tag';
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: _cardTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: _cardAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: tags.isEmpty ? 12 : 13),
              Text(
                post.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _cardText,
                  fontSize: compact ? 20 : 23,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                post.descripcion,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _cardMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (post.imagen.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final imageHeight = (constraints.maxWidth * 9 / 16)
                        .clamp(140.0, 240.0)
                        .toDouble();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        PostService.urlImagen(post.imagen).toString(),
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: imageHeight,
                            color: _cardTint,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: _cardMuted,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 17),
              const Divider(height: 1, color: _cardBorder),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 9,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 5),
                      Text(
                        rating,
                        style: const TextStyle(
                          color: _cardText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 18, color: _cardAccent),
                      SizedBox(width: 6),
                      Text(
                        'Leer publicación',
                        style: TextStyle(
                          color: _cardAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
