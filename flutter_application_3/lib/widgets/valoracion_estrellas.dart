import 'package:flutter/material.dart';
import '../models/valoracion_model.dart';
import '../services/valoracion_service.dart';

/// Muestra el promedio del post y deja al usuario elegir de 1 a 5 estrellas.
class ValoracionEstrellas extends StatefulWidget {
  final int blogId;

  const ValoracionEstrellas({
    super.key,
    required this.blogId,
  });

  @override
  State<ValoracionEstrellas> createState() => _ValoracionEstrellasState();
}

class _ValoracionEstrellasState extends State<ValoracionEstrellas> {
  final ValoracionService _servicio = ValoracionService();
  ValoracionModel? _resumen;
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final resumen = await _servicio.obtener(widget.blogId);
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _votar(int puntos) async {
    setState(() => _enviando = true);
    try {
      final resumen = await _servicio.enviar(widget.blogId, puntos);
      if (!mounted) return;
      setState(() => _resumen = resumen);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heading = Text(
      'Valoración',
      style: TextStyle(
        color: scheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );

    if (_cargando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 14),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              minHeight: 4,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () {
              setState(() => _cargando = true);
              _cargar();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final resumen = _resumen!;
    final mia = resumen.miPuntuacion ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading,
        const SizedBox(height: 10),
        Wrap(
          spacing: 0,
          runSpacing: 4,
          children: List.generate(5, (i) {
            final numero = i + 1;
            return IconButton(
              tooltip: '$numero ${numero == 1 ? 'estrella' : 'estrellas'}',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              iconSize: 28,
              color: numero <= mia ? Colors.amber : scheme.onSurfaceVariant,
              icon: Icon(numero <= mia ? Icons.star : Icons.star_border),
              onPressed: _enviando ? null : () => _votar(numero),
            );
          }),
        ),
        if (_enviando) ...[
          const SizedBox(height: 4),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              minHeight: 3,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          resumen.total == 0
              ? 'Aún sin valoraciones. ¡Sé el primero!'
              : 'Promedio ${resumen.promedio.toStringAsFixed(1)} '
                  '· ${resumen.total} '
                  '${resumen.total == 1 ? 'valoración' : 'valoraciones'}',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        if (resumen.miPuntuacion != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                child: Text(
                  'Tu valoración: ${resumen.miPuntuacion} de 5',
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
