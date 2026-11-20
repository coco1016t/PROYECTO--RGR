import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../navigation/user_profile_navigation.dart';
import '../services/mensajeria_service.dart';
import '../services/sesion_service.dart';
import '../theme/blog_theme.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/mensajeria/chat_header.dart';
import '../widgets/mensajeria/contactos_panel.dart';
import '../widgets/mensajeria/text_message_composer.dart';
import '../widgets/theme_mode_buttons.dart';

String _normalizarNombre(String nombre) =>
    nombre.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String nombreContactoVisible(
  String nombre,
  int id,
  Iterable<ContactoMensajeria> contactos,
) {
  final normalizado = _normalizarNombre(nombre);
  final listaContactos = contactos.toList();
  final duplicado = listaContactos
          .where(
              (contacto) => _normalizarNombre(contacto.nombre) == normalizado)
          .length >
      1;
  return duplicado || listaContactos.isEmpty ? '$nombre (#$id)' : nombre;
}

class MensajesPage extends StatefulWidget {
  const MensajesPage({super.key});

  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
  final MensajeriaService _servicio = MensajeriaService();
  final TextEditingController _busqueda = TextEditingController();
  List<ConversacionMensajeria> _conversaciones = [];
  ConversacionMensajeria? _seleccionada;
  bool _cargando = true;
  bool _cargandoBandeja = false;
  bool _abriendoContacto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_cargarBandeja());
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _servicio.dispose();
    super.dispose();
  }

  Future<void> _cargarBandeja() async {
    if (_cargandoBandeja) return;
    _cargandoBandeja = true;
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final conversaciones = await _servicio.obtenerConversaciones();
      if (!mounted) return;

      setState(() {
        _conversaciones = conversaciones;

        final selectedId = _seleccionada?.id;
        if (selectedId != null) {
          for (final conversacion in conversaciones) {
            if (conversacion.id == selectedId) {
              _seleccionada = conversacion;
              break;
            }
          }
        } else if (MediaQuery.sizeOf(context).width >= 900 &&
            conversaciones.isNotEmpty) {
          _seleccionada = conversaciones.first;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      _cargandoBandeja = false;
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _nombreVisible(ContactoMensajeria contacto) {
    return nombreContactoVisible(
      contacto.nombre,
      contacto.id,
      _conversaciones.map((conversacion) => conversacion.contacto),
    );
  }

  Future<void> _seleccionarContacto() async {
    if (_abriendoContacto) return;

    final contacto = await showModalBottomSheet<ContactoMensajeria>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectorContactos(
        buscarContactos: _servicio.buscarContactos,
      ),
    );
    if (contacto != null && mounted) {
      await _abrirContacto(contacto);
    }
  }

  Future<void> _abrirContacto(ContactoMensajeria contacto) async {
    if (_abriendoContacto) return;
    setState(() => _abriendoContacto = true);

    try {
      ConversacionMensajeria? conversacion;
      for (final actual in _conversaciones) {
        if (actual.contacto.id == contacto.id) {
          conversacion = actual;
          break;
        }
      }
      conversacion ??= await _servicio.abrirConversacion(contacto.id);
      if (mounted) await _abrirChat(conversacion);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _abriendoContacto = false);
    }
  }

  Future<void> _abrirChat(ConversacionMensajeria conversacion) async {
    final contacto = conversacion.contacto;
    if (MediaQuery.sizeOf(context).width >= 900) {
      setState(() {
        _seleccionada = conversacion;
        if (!_conversaciones.any((item) => item.id == conversacion.id)) {
          _conversaciones = [conversacion, ..._conversaciones];
        }
      });
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatPrivadoPage(
          conversacionId: conversacion.id,
          contacto: contacto,
          nombreContacto: _nombreVisible(contacto),
        ),
      ),
    );
    if (mounted) await _cargarBandeja();
  }

  String _hora(DateTime? fecha) {
    if (fecha == null) return '';
    final ahora = DateTime.now();
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    if (ahora.difference(fecha).inDays == 0 && fecha.day == ahora.day) {
      return '${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';
    }
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}';
  }

  Widget _panelContactos() {
    return ContactosPanel(
      conversaciones: _conversaciones,
      conversacionSeleccionadaId: _seleccionada?.id,
      busquedaController: _busqueda,
      cargando: _cargando,
      error: _error,
      nombreVisible: _nombreVisible,
      hora: _hora,
      onNuevaConversacion: () => unawaited(_seleccionarContacto()),
      onSeleccionarConversacion: (conversacion) =>
          unawaited(_abrirChat(conversacion)),
      onCambiarBusqueda: (_) => setState(() {}),
    );
  }

  Widget _sinSeleccionar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 52,
              color: scheme.primary.withValues(alpha: .78),
            ),
            const SizedBox(height: 16),
            Text(
              'Tus mensajes privados',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Selecciona una conversación o inicia un nuevo chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: .62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVista(BuildContext context, bool darkMode) {
    final usuario = SesionService.instance.usuario;
    final esAdmin = SesionService.instance.tipoUsuario == 1;

    return Scaffold(
      drawer: esAdmin
          ? AdminDrawer(usuario: usuario, rutaActual: '/mensajes')
          : null,
      appBar: AppBar(
        title: const Text('Mensajes privados'),
        actions: [
          ThemeModeButtons(
            darkMode: darkMode,
            onLightMode: () => BlogTheme.darkMode.value = false,
            onDarkMode: () => BlogTheme.darkMode.value = true,
          ),
          IconButton(
            tooltip: 'Actualizar bandeja',
            onPressed: _cargando ? null : () => unawaited(_cargarBandeja()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return _panelContactos();
          }

          return Row(
            children: [
              SizedBox(width: 360, child: _panelContactos()),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: .45),
              ),
              Expanded(
                child: _seleccionada == null
                    ? _sinSeleccionar(context)
                    : ChatPrivadoPage(
                        key: ValueKey(_seleccionada!.id),
                        conversacionId: _seleccionada!.id,
                        contacto: _seleccionada!.contacto,
                        nombreContacto: _nombreVisible(_seleccionada!.contacto),
                        embedded: true,
                        onActividad: () => unawaited(_cargarBandeja()),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BlogTheme.darkMode,
      builder: (context, darkMode, _) => Theme(
        data: BlogTheme.forMode(darkMode),
        child: Builder(
          builder: (themeContext) => _construirVista(themeContext, darkMode),
        ),
      ),
    );
  }
}

class _SelectorContactos extends StatefulWidget {
  final Future<List<ContactoMensajeria>> Function(String) buscarContactos;

  const _SelectorContactos({
    required this.buscarContactos,
  });

  @override
  State<_SelectorContactos> createState() => _SelectorContactosState();
}

class _SelectorContactosState extends State<_SelectorContactos> {
  final TextEditingController _busqueda = TextEditingController();
  Timer? _temporizador;
  List<ContactoMensajeria> _resultados = [];
  String _filtro = '';
  String? _error;
  bool _cargando = false;
  int _idSolicitud = 0;

  @override
  void dispose() {
    _temporizador?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _actualizarBusqueda(String value) {
    _temporizador?.cancel();
    final termino = value.trim();
    final idSolicitud = ++_idSolicitud;

    setState(() {
      _filtro = termino;
      _resultados = [];
      _error = null;
      _cargando = termino.length >= 2;
    });

    if (termino.length < 2) {
      _cargando = false;
      return;
    }

    _temporizador = Timer(
      const Duration(milliseconds: 280),
      () => _buscar(termino, idSolicitud),
    );
  }

  Future<void> _buscar(String termino, int idSolicitud) async {
    try {
      final resultados = await widget.buscarContactos(termino);
      if (!mounted || idSolicitud != _idSolicitud) return;
      setState(() {
        _resultados = resultados;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || idSolicitud != _idSolicitud) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _reintentar() async {
    if (_filtro.length < 2) return;
    final idSolicitud = ++_idSolicitud;
    setState(() {
      _error = null;
      _cargando = true;
    });
    await _buscar(_filtro, idSolicitud);
  }

  Widget _contenidoResultados(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_filtro.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 42,
                color: scheme.primary.withValues(alpha: .78),
              ),
              const SizedBox(height: 12),
              Text(
                'Busca por nombre de usuario',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Escribe al menos dos letras para ver coincidencias.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: .62),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar búsqueda'),
              ),
            ],
          ),
        ),
      );
    }
    if (_resultados.isEmpty) {
      return Center(
        child: Text(
          'No encontramos usuarios con ese nombre.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurface.withValues(alpha: .62)),
        ),
      );
    }

    return ListView.separated(
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
      itemBuilder: (context, index) {
        final contacto = _resultados[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.primary,
            child: Text(
              contacto.nombre.trim().isEmpty
                  ? '?'
                  : contacto.nombre.trim()[0].toUpperCase(),
            ),
          ),
          title: Text(
            nombreContactoVisible(
              contacto.nombre,
              contacto.id,
              _resultados,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('Iniciar conversación'),
          onTap: () => Navigator.pop(context, contacto),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 5,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nuevo chat',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Encuentra a una persona por su nombre de usuario.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: .62),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _busqueda,
                autofocus: true,
                onChanged: _actualizarBusqueda,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Nombre de usuario',
                  suffixIcon: _busqueda.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _busqueda.clear();
                            _actualizarBusqueda('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _contenidoResultados(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPrivadoPage extends StatefulWidget {
  final int conversacionId;
  final ContactoMensajeria contacto;
  final String nombreContacto;
  final bool embedded;
  final VoidCallback? onActividad;

  const ChatPrivadoPage({
    super.key,
    required this.conversacionId,
    required this.contacto,
    required this.nombreContacto,
    this.embedded = false,
    this.onActividad,
  });

  @override
  State<ChatPrivadoPage> createState() => _ChatPrivadoPageState();
}

class _ChatPrivadoPageState extends State<ChatPrivadoPage>
    with WidgetsBindingObserver {
  final MensajeriaService _servicio = MensajeriaService();
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<MensajeChat> _mensajes = [];
  Timer? _timer;
  bool _cargandoInicial = true;
  bool _inicializado = false;
  bool _solicitudActiva = false;
  bool _cargandoAnteriores = false;
  bool _enviando = false;
  bool _hayMasAnteriores = false;
  bool _appEnPrimerPlano = true;
  bool _mostrarNuevos = false;
  int _nuevosSinVer = 0;
  String? _errorCarga;
  String? _errorActualizacion;

  int get _miId => SesionService.instance.idUsuario ?? -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_alDesplazarse);
    unawaited(_cargarInicial());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_alDesplazarse);
    _scroll.dispose();
    _composer.dispose();
    _servicio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _appEnPrimerPlano = false;
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _appEnPrimerPlano = true;
      if (_inicializado) {
        unawaited(_consultarNuevos());
        _iniciarTimer();
      }
    }
  }

  void _iniciarTimer() {
    if (!_appEnPrimerPlano || _timer != null || !_inicializado) return;
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_consultarNuevos()),
    );
  }

  void _alDesplazarse() {
    if (_mostrarNuevos && _cercaDelFinal) {
      setState(() {
        _mostrarNuevos = false;
        _nuevosSinVer = 0;
      });
    }
    if (!_scroll.hasClients || _cargandoAnteriores || !_hayMasAnteriores) {
      return;
    }
    if (_scroll.position.pixels <= 90) {
      unawaited(_cargarAnteriores());
    }
  }

  bool get _cercaDelFinal {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.position.pixels < 100;
  }

  void _bajarAlFinal({bool animado = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final destino = _scroll.position.maxScrollExtent;
      if (animado) {
        _scroll.animateTo(
          destino,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(destino);
      }
    });
  }

  List<MensajeChat> _combinarMensajes(
    Iterable<MensajeChat> existentes,
    Iterable<MensajeChat> entrantes,
  ) {
    final porId = <int, MensajeChat>{
      for (final mensaje in existentes) mensaje.id: mensaje,
      for (final mensaje in entrantes) mensaje.id: mensaje,
    };
    final resultado = porId.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return resultado;
  }

  bool _hayEntrantes(Iterable<MensajeChat> mensajes) {
    return mensajes.any((mensaje) => mensaje.emisorId != _miId);
  }

  Future<void> _cargarInicial() async {
    if (_solicitudActiva) return;
    _solicitudActiva = true;
    setState(() {
      _cargandoInicial = true;
      _errorCarga = null;
    });
    try {
      final pagina = await _servicio.obtenerMensajes(widget.conversacionId);
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(_combinarMensajes(const [], pagina.mensajes));
        _hayMasAnteriores = pagina.hayMasAnteriores;
        _errorActualizacion = null;
      });
      _inicializado = true;
      _bajarAlFinal();
      try {
        await _servicio.marcarLeidos(widget.conversacionId);
      } catch (error) {
        if (mounted) {
          setState(() {
            _errorActualizacion =
                error.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorCarga = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      _solicitudActiva = false;
      if (mounted) {
        setState(() => _cargandoInicial = false);
        _iniciarTimer();
      }
    }
  }

  Future<void> _consultarNuevos() async {
    if (!_inicializado || !_appEnPrimerPlano || _solicitudActiva) {
      return;
    }
    _solicitudActiva = true;
    final cursorInicial = _mensajes.isEmpty ? 0 : _mensajes.last.id;
    final recibidos = <MensajeChat>[];
    var cursor = cursorInicial;
    var hayMas = false;
    try {
      do {
        final pagina = await _servicio.obtenerMensajes(
          widget.conversacionId,
          limite: 100,
          despuesDeId: cursor,
        );
        if (!mounted) return;
        recibidos.addAll(pagina.mensajes);
        if (pagina.mensajes.isNotEmpty) {
          cursor = pagina.mensajes.last.id;
        }
        hayMas = pagina.hayMasNuevos;
      } while (hayMas && recibidos.isNotEmpty);

      if (!mounted) return;
      final estabaAlFinal = _cercaDelFinal;
      if (recibidos.isNotEmpty) {
        final combinados = _combinarMensajes(_mensajes, recibidos);
        setState(() {
          _mensajes
            ..clear()
            ..addAll(combinados);
          _errorActualizacion = null;
          if (estabaAlFinal) {
            _mostrarNuevos = false;
            _nuevosSinVer = 0;
          } else {
            _mostrarNuevos = true;
            _nuevosSinVer += recibidos.length;
          }
        });
        if (_hayEntrantes(recibidos)) {
          try {
            await _servicio.marcarLeidos(widget.conversacionId);
          } catch (error) {
            if (mounted) {
              setState(() {
                _errorActualizacion =
                    error.toString().replaceFirst('Exception: ', '');
              });
            }
          }
        }
        if (estabaAlFinal) _bajarAlFinal(animado: true);
        widget.onActividad?.call();
      } else {
        setState(() => _errorActualizacion = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorActualizacion =
              error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      _solicitudActiva = false;
    }
  }

  Future<void> _cargarAnteriores() async {
    if (_solicitudActiva ||
        _cargandoAnteriores ||
        !_hayMasAnteriores ||
        _mensajes.isEmpty) {
      return;
    }
    _solicitudActiva = true;
    _cargandoAnteriores = true;
    final posicionAnterior = _scroll.hasClients ? _scroll.position.pixels : 0.0;
    final altoAnterior =
        _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    setState(() {});
    try {
      final pagina = await _servicio.obtenerMensajes(
        widget.conversacionId,
        limite: 50,
        antesDeId: _mensajes.first.id,
      );
      if (!mounted) return;
      final combinados = _combinarMensajes(_mensajes, pagina.mensajes);
      setState(() {
        _mensajes
          ..clear()
          ..addAll(combinados);
        _hayMasAnteriores = pagina.hayMasAnteriores;
        _errorActualizacion = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final diferencia = _scroll.position.maxScrollExtent - altoAnterior;
        final nuevaPosicion = posicionAnterior + diferencia;
        _scroll.jumpTo(
          nuevaPosicion.clamp(0.0, _scroll.position.maxScrollExtent),
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorActualizacion =
              error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      _solicitudActiva = false;
      _cargandoAnteriores = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _enviar() async {
    final texto = _composer.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await _servicio.enviarMensaje(
        widget.conversacionId,
        texto,
      );
      if (!mounted) return;
      _composer.clear();
      final combinados = _combinarMensajes(_mensajes, [mensaje]);
      setState(() {
        _mensajes
          ..clear()
          ..addAll(combinados);
        _errorActualizacion = null;
        _mostrarNuevos = false;
        _nuevosSinVer = 0;
      });
      _bajarAlFinal(animado: true);
      widget.onActividad?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _hora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  Widget _burbuja(MensajeChat mensaje) {
    final scheme = Theme.of(context).colorScheme;
    final esMio = mensaje.emisorId == _miId;
    final color = esMio ? scheme.primary : scheme.surface;
    final texto = esMio ? scheme.onPrimary : scheme.onSurface;
    final maxWidth =
        (MediaQuery.sizeOf(context).width * .72).clamp(280.0, 720.0).toDouble();

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(esMio ? 17 : 5),
            bottomRight: Radius.circular(esMio ? 5 : 17),
          ),
          border: esMio
              ? null
              : Border.all(color: scheme.outline.withValues(alpha: .45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha:
                    Theme.of(context).brightness == Brightness.dark ? .18 : .06,
              ),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                mensaje.contenido,
                style: TextStyle(color: texto, fontSize: 15, height: 1.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hora(mensaje.fechaEnvio),
              style: TextStyle(
                color: esMio
                    ? scheme.onPrimary.withValues(alpha: .72)
                    : scheme.onSurface.withValues(alpha: .55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaMensajes() {
    final scheme = Theme.of(context).colorScheme;

    if (_cargandoInicial && _mensajes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorCarga != null && _mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: scheme.onSurface.withValues(alpha: .62),
              ),
              const SizedBox(height: 10),
              Text(
                _errorCarga!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _cargarInicial,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_mensajes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Env\u00EDa un mensaje para iniciar la conversaci\u00F3n.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: .62),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 14, bottom: 18),
            itemCount: _mensajes.length + (_cargandoAnteriores ? 1 : 0),
            itemBuilder: (context, index) {
              if (_cargandoAnteriores && index == 0) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final indiceMensaje = index - (_cargandoAnteriores ? 1 : 0);
              return _burbuja(_mensajes[indiceMensaje]);
            },
          ),
        if (_errorActualizacion != null)
          Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Text(
                  'No se pudo actualizar. Reintentando...',
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        if (_mostrarNuevos && _nuevosSinVer > 0)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _mostrarNuevos = false;
                    _nuevosSinVer = 0;
                  });
                  _bajarAlFinal(animado: true);
                },
                icon: const Icon(Icons.arrow_downward_rounded),
                label: Text('$_nuevosSinVer mensajes nuevos'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cuerpoChat(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          if (widget.embedded)
            ChatHeader(
              contactName: widget.nombreContacto,
              onOpenProfile: _abrirPerfilContacto,
            ),
          Expanded(child: _listaMensajes()),
          TextMessageComposer(
            controller: _composer,
            sending: _enviando,
            onSend: _enviar,
          ),
        ],
      ),
    );
  }

  void _abrirPerfilContacto() {
    unawaited(
      abrirPerfilUsuario(
        context,
        userId: widget.contacto.id,
        userName: widget.nombreContacto,
      ),
    );
  }

  Widget _vistaChat(BuildContext context, bool darkMode) {
    if (widget.embedded) return _cuerpoChat(context);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _abrirPerfilContacto,
          mouseCursor: SystemMouseCursors.click,
          child: Text(
            widget.nombreContacto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          ThemeModeButtons(
            darkMode: darkMode,
            onLightMode: () => BlogTheme.darkMode.value = false,
            onDarkMode: () => BlogTheme.darkMode.value = true,
          ),
          IconButton(
            tooltip: 'Actualizar mensajes',
            onPressed: _consultarNuevos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cuerpoChat(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BlogTheme.darkMode,
      builder: (context, darkMode, _) => Theme(
        data: BlogTheme.forMode(darkMode),
        child: Builder(
          builder: (themeContext) => _vistaChat(themeContext, darkMode),
        ),
      ),
    );
  }
}
