import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../navigation/user_profile_navigation.dart';
import '../services/post_service.dart';
import '../services/sesion_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/blog/blog_topic_filter.dart';
import '../widgets/blog/blog_top_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/user_drawer.dart';
import 'post_detail_page.dart';

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
  late final TextEditingController _searchController = TextEditingController();
  String _consulta = '';
  String? _temaSeleccionado;
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
        final tabInicial = usuarioActual['tab_inicial'];
        if (tabInicial is num &&
            tabInicial.toInt() >= 0 &&
            tabInicial.toInt() < 2) {
          _tabs.index = tabInicial.toInt();
        }
      } else if (SesionService.instance.activa) {
        usuarioActual =
            Map<String, dynamic>.from(SesionService.instance.usuario);
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
    _searchController.dispose();
    super.dispose();
  }

  void recargarPosts() {
    setState(() {
      futurePosts = postService.obtenerPosts();
      futureMisPosts = postService.obtenerMisPosts();
    });
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
        final scheme = Theme.of(context).colorScheme;

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
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 45,
                    color: scheme.onSurface.withValues(alpha: .55),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No fue posible cargar el blog.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}'.replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: .65)),
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
        final topics = _temas(posts);
        final filteredPosts = posts.where(_coincideConFiltros).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlogTopicFilter(
                topics: topics,
                selectedTopic: _temaSeleccionado,
                onSelected: (topic) {
                  setState(() => _temaSeleccionado = topic);
                },
              ),
            ),
            if (filteredPosts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _estadoVacio(
                  context,
                  posts.isEmpty
                      ? textoVacio
                      : 'No encontramos publicaciones\ncon esos filtros.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = filteredPosts[index];
                      return PostCard(
                        post: post,
                        onTap: () => abrirDetalle(post),
                        onOpenProfile: post.usuarioId == null
                            ? null
                            : () => abrirPerfilUsuario(
                                  context,
                                  userId: post.usuarioId!,
                                  userName: post.autor.isEmpty
                                      ? 'Usuario'
                                      : post.autor,
                                ),
                      );
                    },
                    childCount: filteredPosts.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<String> _temas(List<PostModel> posts) {
    final temas = <String, String>{};
    for (final post in posts) {
      for (final tag in post.tags.split(',')) {
        final etiqueta = tag.trim().replaceFirst(RegExp(r'^#'), '');
        if (etiqueta.isEmpty) continue;
        temas.putIfAbsent(_claveTema(etiqueta), () => _formatearTema(etiqueta));
      }
    }
    final resultado = temas.values.toList()
      ..sort((a, b) => _claveTema(a).compareTo(_claveTema(b)));
    return resultado.take(10).toList();
  }

  String _claveTema(String tema) {
    return tema
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  String _formatearTema(String tema) {
    return tema
        .trim()
        .split(RegExp(r'\s+'))
        .map((palabra) => palabra.isEmpty
            ? palabra
            : '${palabra[0].toUpperCase()}${palabra.substring(1).toLowerCase()}')
        .join(' ');
  }

  bool _coincideConFiltros(PostModel post) {
    final texto = _consulta;
    if (texto.isNotEmpty) {
      final contenido =
          '${post.titulo} ${post.descripcion} ${post.autor} ${post.tags}'
              .toLowerCase();
      if (!contenido.contains(texto)) return false;
    }

    final tema = _temaSeleccionado;
    if (tema == null) return true;
    return post.tags
        .split(',')
        .map((tag) => _claveTema(tag.replaceFirst(RegExp(r'^#'), '')))
        .contains(_claveTema(tema));
  }

  Widget _estadoVacio(BuildContext context, String mensaje) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 38,
              color: scheme.primary.withValues(alpha: .8),
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: .68),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenidoFeed(BuildContext context, {required bool mostrarPestanas}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scheme = Theme.of(context).colorScheme;
    final showMobileSearch = screenWidth < 900;
    final tabTitle =
        _tabs.index == 0 ? 'Un espacio para compartir' : 'Tus publicaciones';
    final tabDescription = _tabs.index == 0
        ? 'Ideas, historias y conversaciones de la comunidad.'
        : 'Todo lo que has publicado, reunido en un solo lugar.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMobileSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: BlogSearchField(
              controller: _searchController,
              onChanged: _actualizarConsulta,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMUNIDAD  /  RGR',
                style: TextStyle(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.15,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 9),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  tabTitle,
                  key: ValueKey(_tabs.index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: screenWidth < 400 ? 23 : 29,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                tabDescription,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (mostrarPestanas)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              dividerColor: scheme.outline.withValues(alpha: .45),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: scheme.onSecondaryContainer,
              unselectedLabelColor: scheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(
                    icon: Icon(Icons.dynamic_feed_outlined, size: 18),
                    text: 'Para ti'),
                Tab(
                    icon: Icon(Icons.person_outline_rounded, size: 18),
                    text: 'Mis publicaciones'),
              ],
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

  void _actualizarConsulta(String value) {
    setState(() => _consulta = value.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = (usuarioActual['tip_usu'] as num? ?? 2).toInt() == 1;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mostrarMenuPermanente = !esAdmin && screenWidth >= 1120;
    void cambiarPestana(int indice) => _tabs.animateTo(indice);

    return Scaffold(
      appBar: BlogTopBar(
        searchController: _searchController,
        onSearchChanged: _actualizarConsulta,
        hasDrawer: !mostrarMenuPermanente,
        onRefresh: recargarPosts,
      ),
      drawer: esAdmin
          ? AdminDrawer(usuario: usuarioActual, rutaActual: '/blog')
          : (mostrarMenuPermanente ? null : UserDrawer(usuario: usuarioActual)),
      floatingActionButton: FloatingActionButton.small(
        onPressed: nuevaPublicacion,
        tooltip: 'Crear publicación',
        child: const Icon(Icons.add_rounded),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarMenuPermanente)
            UserNavigationPanel(
              usuario: usuarioActual,
              tabActual: _tabs.index,
              onCambiarTab: cambiarPestana,
            ),
          Expanded(
            child: _contenidoFeed(
              context,
              mostrarPestanas: !mostrarMenuPermanente,
            ),
          ),
        ],
      ),
    );
  }
}
