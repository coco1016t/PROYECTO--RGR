import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/user_drawer.dart';

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
    // Controlador de pestañas propio para poder cambiarlas desde la barra lateral.
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

  Widget _lista(
    Future<List<PostModel>> futuro,
    String textoVacio,
    bool mostrarBienvenida,
  ) {
    return FutureBuilder<List<PostModel>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 45),
                  const SizedBox(height: 12),
                  const Text(
                    'No fue posible cargar el blog.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}'.replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
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
          return Center(child: Text(textoVacio));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (mostrarBienvenida) ...[
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08245C),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Descubre nuevas ideas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
            ],
            ...posts.map(
              (post) => PostCard(
                post: post,
                onTap: () => abrirDetalle(post),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = (usuarioActual['tip_usu'] as num? ?? 2).toInt() == 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mi Blog'),
            Text(
              'Bienvenido, $nombreUsuario',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mensajes privados',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.pushNamed(context, '/mensajes'),
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: recargarPosts,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Mis posts'),
          ],
        ),
      ),
      // Administrador: su menú de siempre. Usuario normal: menú nuevo.
      drawer: esAdmin
          ? AdminDrawer(usuario: usuarioActual, rutaActual: '/blog')
          : UserDrawer(
              usuario: usuarioActual,
              tabActual: _tabs.index,
              onCambiarTab: (indice) => _tabs.animateTo(indice),
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: nuevaPublicacion,
        tooltip: 'Nueva publicación',
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _lista(futurePosts, 'No hay publicaciones registradas.', true),
          _lista(futureMisPosts, 'Aún no has publicado nada.', false),
        ],
      ),
    );
  }
}