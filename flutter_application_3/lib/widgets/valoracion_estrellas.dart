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
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (_error != null) {
      return Row(
        children: [
          Expanded(child: Text(_error!)),
          TextButton(
            onPressed: () {
              setState(() => _cargando = true);
              _cargar();
            },
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    final resumen = _resumen!;
    final mia = resumen.miPuntuacion ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valoración',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08245C),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final numero = i + 1;
            return IconButton(
              tooltip: '$numero ${numero == 1 ? 'estrella' : 'estrellas'}',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              iconSize: 32,
              color: Colors.amber,
              icon: Icon(numero <= mia ? Icons.star : Icons.star_border),
              onPressed: _enviando ? null : () => _votar(numero),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          resumen.total == 0
              ? 'Aún sin valoraciones. ¡Sé el primero!'
              : 'Promedio ${resumen.promedio.toStringAsFixed(1)} '
                  '· ${resumen.total} '
                  '${resumen.total == 1 ? 'valoración' : 'valoraciones'}',
          style: const TextStyle(color: Colors.grey),
        ),
        if (resumen.miPuntuacion != null)
          Text(
            'Tu valoración: ${resumen.miPuntuacion} de 5',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }
}