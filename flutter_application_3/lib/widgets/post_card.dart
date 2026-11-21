import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool deleting;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onOpenProfile,
    this.onEdit,
    this.onDelete,
    this.deleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final scheme = Theme.of(context).colorScheme;
    final cardBorder = scheme.outline.withValues(alpha: .55);
    final cardText = scheme.onSurface;
    final cardMuted = scheme.onSurface.withValues(alpha: .68);
    final cardAccent = scheme.primary;
    final cardTint = scheme.secondaryContainer;
    final author = post.usuarioId != null &&
            post.usuarioId == SesionService.instance.idUsuario
        ? 'Publicado por ti'
        : (post.autor.isEmpty ? 'Autor desconocido' : 'Por ${post.autor}');
    final authorLabel = Text(
      author,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: onOpenProfile == null ? cardText : cardAccent,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
    final tags = post.tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final rating = post.totalValoraciones == 0
        ? 'Sin valoraciones'
        : '${post.promedio.toStringAsFixed(1)} '
            '(${post.totalValoraciones})';

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cardBorder),
            ),
          ),
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: cardTint,
                    child: Icon(
                      Icons.person_outline,
                      color: cardAccent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: onOpenProfile == null
                        ? authorLabel
                        : InkWell(
                            onTap: onOpenProfile,
                            mouseCursor: SystemMouseCursors.click,
                            child: authorLabel,
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
                        color: cardTint,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: cardAccent,
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
                  color: cardText,
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
                style: TextStyle(
                  color: cardMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (post.imagen.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final imageHeight = (constraints.maxWidth * 9 / 16)
                        .clamp(180.0, 350.0)
                        .toDouble();
                    return Image.network(
                      PostService.urlImagen(post.imagen).toString(),
                      width: double.infinity,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: imageHeight,
                          color: cardTint,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: cardMuted,
                            size: 28,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 17),
              Divider(height: 1, color: cardBorder),
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
                        style: TextStyle(
                          color: cardText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 18, color: cardAccent),
                      SizedBox(width: 6),
                      Text(
                        'Leer publicación',
                        style: TextStyle(
                          color: cardAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: deleting ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: deleting ? null : onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(deleting ? 'Eliminando…' : 'Eliminar'),
                      style:
                          TextButton.styleFrom(foregroundColor: scheme.error),
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
