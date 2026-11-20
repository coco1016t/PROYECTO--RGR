import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/post_card.dart';
import '../widgets/user_drawer.dart';
import 'post_detail_page.dart';

const Color _blogBackground = Color(0xFFF7F9F8);
const Color _blogSurface = Color(0xFFFFFFFF);
const Color _blogText = Color(0xFF243341);
const Color _blogMuted = Color(0xFF667483);
const Color _blogAccent = Color(0xFF527D7B);
const Color _blogTint = Color(0xFFEEF5F4);

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage>
    with SingleTickerProviderStateMixin {
  final PostService postService = PostService();
  late final TabController _tabs;
  late Future<List<PostModel>> futurePosts;
  late Future<List<PostModel>> futureMisPosts;
  String nombreUsuario = 'Usuario';
  Map<String, dynamic> usuarioActual = {
    'nom_usr': 'Usuario',
    'mail': '',
    'tip_usu': 2,
  };
  bool argumentoLeido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!argumentoLeido) {
      final argumento = ModalRoute.of(context)?.settings.arguments;

      if (argumento is Map<String, dynamic>) {
        usuarioActual = Map<String, dynamic>.from(argumento);
        nombreUsuario = usuarioActual['nom_usr']?.toString() ?? 'Usuario';
      } else if (SesionService.instance.activa) {
        usuarioActual =
            Map<String, dynamic>.from(SesionService.instance.usuario);
        nombreUsuario = usuarioActual['nom_usr']?.toString() ?? 'Usuario';
      }
      argumentoLeido = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Controlador compartido por las pestañas y la navegación lateral.
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) setState(() {});
    });
    futurePosts = postService.obtenerPosts();
    futureMisPosts = postService.obtenerMisPosts();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void recargarPosts() {
    setState(() {
      futurePosts = postService.obtenerPosts();
      futureMisPosts = postService.obtenerMisPosts();
    });
  }

  void cerrarSesion() {
    SesionService.instance.cerrar();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> abrirDetalle(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PostDetailPage(post: post),
      ),
    );
    // Al volver del detalle se recarga para ver el promedio actualizado.
    if (!mounted) return;
    recargarPosts();
  }

  Future<void> nuevaPublicacion() async {
    await Navigator.pushNamed(
      context,
      '/add-blog',
      arguments: usuarioActual,
    );
    if (!mounted) return;
    recargarPosts();
  }

  Widget _lista(Future<List<PostModel>> futuro, String textoVacio) {
    return FutureBuilder<List<PostModel>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _blogAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 45, color: _blogMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No fue posible cargar el blog.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _blogText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}'.replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _blogMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blogAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: recargarPosts,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data ?? <PostModel>[];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                textoVacio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _blogMuted),
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: posts
              .map(
                (post) => PostCard(
                  post: post,
                  onTap: () => abrirDetalle(post),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _contenidoFeed() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 960 ? 24.0 : 18.0;
    final titleSize = screenWidth < 360 ? 22.0 : 27.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            22,
            horizontalPadding,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explora la comunidad',
                style: TextStyle(
                  color: _blogText,
                  fontSize: titleSize,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Ideas, historias y conversaciones.',
                style: TextStyle(color: _blogMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _blogTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: _blogSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelColor: _blogAccent,
                  unselectedLabelColor: _blogMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Todos'),
                    Tab(text: 'Mis posts'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _lista(futurePosts, 'No hay publicaciones registradas.'),
              _lista(futureMisPosts, 'Aún no has publicado nada.'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = (usuarioActual['tip_usu'] as num? ?? 2).toInt() == 1;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mostrarMenuPermanente = !esAdmin && screenWidth >= 960;
    final narrowActions = screenWidth < 400;
    final userMenu = UserDrawer(
      usuario: usuarioActual,
      tabActual: _tabs.index,
      onCambiarTab: (indice) => _tabs.animateTo(indice),
    );

    return Scaffold(
      backgroundColor: _blogBackground,
      appBar: AppBar(
        automaticallyImplyLeading: !mostrarMenuPermanente,
        toolbarHeight: 64,
        titleSpacing: narrowActions ? 8 : 16,
        backgroundColor: _blogSurface,
        foregroundColor: _blogText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mi Blog',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Bienvenido, $nombreUsuario',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _blogMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            constraints: BoxConstraints.tightFor(
              width: narrowActions ? 40 : 48,
              height: 48,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Mensajes privados',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.pushNamed(context, '/mensajes'),
          ),
          IconButton(
            constraints: BoxConstraints.tightFor(
              width: narrowActions ? 40 : 48,
              height: 48,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: recargarPosts,
          ),
          IconButton(
            constraints: BoxConstraints.tightFor(
              width: narrowActions ? 40 : 48,
              height: 48,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      drawer: esAdmin
          ? AdminDrawer(usuario: usuarioActual, rutaActual: '/blog')
          : (mostrarMenuPermanente ? null : userMenu),
      floatingActionButton: FloatingActionButton.small(
        onPressed: nuevaPublicacion,
        tooltip: 'Nueva publicación',
        backgroundColor: _blogAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarMenuPermanente)
            UserNavigationPanel(
              usuario: usuarioActual,
              tabActual: _tabs.index,
              onCambiarTab: (indice) => _tabs.animateTo(indice),
            ),
          Expanded(child: _contenidoFeed()),
        ],
      ),
    );
  }
}
