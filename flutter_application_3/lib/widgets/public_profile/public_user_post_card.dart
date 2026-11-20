import 'package:flutter/material.dart';

import '../../models/post_model.dart';
import '../../services/post_service.dart';

class PublicUserPostCard extends StatelessWidget {
  final PostModel post;

  const PublicUserPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = post.tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final valoracion = post.totalValoraciones == 0
        ? 'Sin valoraciones'
        : '${post.promedio.toStringAsFixed(1)} (${post.totalValoraciones})';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: .55)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty) ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tag in tags)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            post.titulo,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (post.descripcion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.descripcion,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: .76),
                height: 1.5,
              ),
            ),
          ],
          if (post.imagen.isNotEmpty) ...[
            const SizedBox(height: 14),
            Image.network(
              PostService.urlImagen(post.imagen).toString(),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 110,
                color: scheme.secondaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 13),
          Divider(color: scheme.outline),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                valoracion,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
