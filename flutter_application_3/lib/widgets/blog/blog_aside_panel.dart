import 'package:flutter/material.dart';

import '../../models/post_model.dart';

class BlogAsidePanel extends StatelessWidget {
  final Future<List<PostModel>> postsFuture;
  final String userName;
  final VoidCallback onCreatePost;
  final ValueChanged<PostModel> onOpenPost;

  const BlogAsidePanel({
    super.key,
    required this.postsFuture,
    required this.userName,
    required this.onCreatePost,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
            left: BorderSide(color: scheme.outline.withValues(alpha: .5))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeCard(userName: userName, onCreatePost: onCreatePost),
            const SizedBox(height: 12),
            _FeaturedPostsCard(
              postsFuture: postsFuture,
              onOpenPost: onOpenPost,
            ),
            const SizedBox(height: 12),
            _CommunityNoteCard(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;
  final VoidCallback onCreatePost;

  const _WelcomeCard({required this.userName, required this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.waving_hand_outlined,
                    color: scheme.onPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hola, $userName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u00bfQu\u00e9 idea quieres compartir hoy?',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: .82),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCreatePost,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Crear publicaci\u00f3n'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPostsCard extends StatelessWidget {
  final Future<List<PostModel>> postsFuture;
  final ValueChanged<PostModel> onOpenPost;

  const _FeaturedPostsCard({
    required this.postsFuture,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PanelCard(
      title: 'Destacadas',
      icon: Icons.trending_up_rounded,
      child: FutureBuilder<List<PostModel>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final posts = List<PostModel>.from(snapshot.data ?? const []);
          posts.sort((a, b) {
            final ratingOrder = b.promedio.compareTo(a.promedio);
            return ratingOrder != 0
                ? ratingOrder
                : b.totalValoraciones.compareTo(a.totalValoraciones);
          });

          if (posts.isEmpty) {
            return Text(
              'Cuando haya publicaciones, aquí verás algunas destacadas.',
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: .66), height: 1.4),
            );
          }

          return Column(
            children: [
              for (var index = 0; index < posts.take(3).length; index++) ...[
                if (index > 0) const Divider(height: 20),
                _FeaturedPostTile(
                  position: index + 1,
                  post: posts[index],
                  onTap: () => onOpenPost(posts[index]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedPostTile extends StatelessWidget {
  final int position;
  final PostModel post;
  final VoidCallback onTap;

  const _FeaturedPostTile({
    required this.position,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = post.totalValoraciones == 0
        ? 'Sin valoraciones'
        : '${post.promedio.toStringAsFixed(1)} · ${post.totalValoraciones} votos';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
              ),
              child: Text(
                '$position',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: .62),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityNoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PanelCard(
      title: 'Un espacio para todos',
      icon: Icons.diversity_3_outlined,
      child: Text(
        'Comparte tus ideas con respeto. Las mejores conversaciones empiezan escuchando.',
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: .7),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: scheme.onPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}
