import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../services/mensajeria_service.dart';
import '../services/sesion_service.dart';
import '../widgets/admin_drawer.dart';

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
  List<ConversacionMensajeria> _conversaciones = [];
  List<ContactoMensajeria> _contactos = [];
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
      final contactos = await _servicio.obtenerContactos();
      if (!mounted) return;
      setState(() {
        _conversaciones = conversaciones;
        _contactos = contactos;
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
      _contactos,
    );
  }

  Future<void> _seleccionarContacto() async {
    if (_abriendoContacto) return;
    if (_contactos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay otros usuarios registrados.')),
      );
      return;
    }

    final contacto = await showModalBottomSheet<ContactoMensajeria>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectorContactos(contactos: _contactos),
    );
    if (contacto == null || !mounted) return;

    setState(() => _abriendoContacto = true);
    try {
      final conversacion = await _servicio.abrirConversacion(contacto.id);
      if (!mounted) return;
      await _abrirChat(
        conversacion.id,
        conversacion.contacto,
      );
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

  Future<void> _abrirChat(
    int conversacionId,
    ContactoMensajeria contacto,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatPrivadoPage(
          conversacionId: conversacionId,
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

  Widget _contenido() {
    if (_cargando && _conversaciones.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _conversaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 12),
              const Text('No se pudieron cargar tus mensajes.'),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _cargarBandeja,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_conversaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.forum_outlined,
                size: 58,
                color: Color(0xFF08245C),
              ),
              const SizedBox(height: 14),
              const Text(
                'Aún no tienes conversaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inicia un chat privado con otro usuario.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _abriendoContacto ? null : _seleccionarContacto,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nuevo mensaje'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarBandeja,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _conversaciones.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
        itemBuilder: (context, index) {
          final conversacion = _conversaciones[index];
          final contacto = conversacion.contacto;
          final nombre = _nombreVisible(contacto);
          final pendientes = conversacion.noLeidos;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE7EEFC),
              foregroundColor: const Color(0xFF08245C),
              child: Text(
                contacto.nombre.trim().isEmpty
                    ? '?'
                    : contacto.nombre.trim()[0].toUpperCase(),
              ),
            ),
            title: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: pendientes > 0 ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              conversacion.ultimoMensaje ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pendientes > 0 ? Colors.black87 : Colors.black54,
                fontWeight:
                    pendientes > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _hora(conversacion.fechaUltimoMensaje),
                  style: TextStyle(
                    fontSize: 11,
                    color: pendientes > 0
                        ? const Color(0xFF08245C)
                        : Colors.black54,
                  ),
                ),
                if (pendientes > 0) ...[
                  const SizedBox(height: 5),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      pendientes > 99 ? '99+' : '$pendientes',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () => _abrirChat(conversacion.id, contacto),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = SesionService.instance.usuario;
    final esAdmin = SesionService.instance.tipoUsuario == 1;
    return Scaffold(
      drawer: esAdmin
          ? AdminDrawer(usuario: usuario, rutaActual: '/mensajes')
          : null,
      appBar: AppBar(
        title: const Text('Mensajes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar bandeja',
            onPressed: _cargando ? null : _cargarBandeja,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _error != null && _conversaciones.isNotEmpty
          ? Column(
              children: [
                MaterialBanner(
                  content: Text('No se pudo actualizar: $_error'),
                  actions: [
                    TextButton(
                      onPressed: _cargarBandeja,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                Expanded(child: _contenido()),
              ],
            )
          : _contenido(),
      floatingActionButton: _conversaciones.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _abriendoContacto ? null : _seleccionarContacto,
              icon: _abriendoContacto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.edit_outlined),
              label: Text(_abriendoContacto ? 'Abriendo...' : 'Nuevo mensaje'),
            )
          : null,
    );
  }
}

class _SelectorContactos extends StatefulWidget {
  final List<ContactoMensajeria> contactos;

  const _SelectorContactos({required this.contactos});

  @override
  State<_SelectorContactos> createState() => _SelectorContactosState();
}

class _SelectorContactosState extends State<_SelectorContactos> {
  final TextEditingController _busqueda = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtro = _normalizarNombre(_filtro);
    final visibles = widget.contactos.where((contacto) {
      return _normalizarNombre(contacto.nombre).contains(filtro);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nuevo mensaje',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busqueda,
                onChanged: (value) => setState(() => _filtro = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar usuario',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visibles.isEmpty
                    ? const Center(child: Text('No se encontraron usuarios.'))
                    : ListView.builder(
                        itemCount: visibles.length,
                        itemBuilder: (context, index) {
                          final contacto = visibles[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(
                              nombreContactoVisible(
                                contacto.nombre,
                                contacto.id,
                                widget.contactos,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, contacto),
                          );
                        },
                      ),
              ),
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

  const ChatPrivadoPage({
    super.key,
    required this.conversacionId,
    required this.contacto,
    required this.nombreContacto,
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
    final esMio = mensaje.emisorId == _miId;
    final color = esMio ? const Color(0xFF08245C) : Colors.white;
    final texto = esMio ? Colors.white : const Color(0xFF172033);
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.fromLTRB(13, 9, 11, 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMio ? 16 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 16),
          ),
          border: esMio ? null : Border.all(color: const Color(0xFFE2E7EF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 3,
              offset: Offset(0, 1),
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
                style: TextStyle(color: texto, fontSize: 15, height: 1.3),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _hora(mensaje.fechaEnvio),
              style: TextStyle(
                color: esMio ? Colors.white70 : Colors.black45,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaMensajes() {
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
              const Icon(Icons.cloud_off, size: 42),
              const SizedBox(height: 10),
              Text(_errorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _cargarInicial,
                icon: const Icon(Icons.refresh),
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
          const Center(
            child: Text('Envía un mensaje para iniciar la conversación.'),
          )
        else
          ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 10, bottom: 14),
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
              color: const Color(0xFFFFF4D5),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Text(
                  'No se pudo actualizar. Reintentando…',
                  style: TextStyle(color: Colors.brown.shade800, fontSize: 12),
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
                icon: const Icon(Icons.arrow_downward),
                label: Text('$_nuevosSinVer mensajes nuevos'),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreContacto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar mensajes',
            onPressed: _consultarNuevos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _listaMensajes()),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E7EF))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
