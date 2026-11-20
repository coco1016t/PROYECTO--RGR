import 'package:flutter/material.dart';
import '../models/valoracion_model.dart';
import '../services/valoracion_service.dart';

const Color _ratingText = Color(0xFF243341);
const Color _ratingMuted = Color(0xFF667483);
const Color _ratingAccent = Color(0xFF527D7B);
const Color _ratingBorder = Color(0xFFDCE3E8);

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
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valoración',
            style: TextStyle(
              color: _ratingText,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              minHeight: 4,
              color: _ratingAccent,
              backgroundColor: _ratingBorder,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valoración',
            style: TextStyle(
              color: _ratingText,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: _ratingMuted),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () {
              setState(() => _cargando = true);
              _cargar();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(foregroundColor: _ratingAccent),
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
            color: _ratingText,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
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
              color: numero <= mia ? Colors.amber : _ratingBorder,
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
              color: _ratingAccent,
              backgroundColor: _ratingBorder,
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
          style: const TextStyle(color: _ratingMuted, height: 1.4),
        ),
        if (resumen.miPuntuacion != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFEEF5F4),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                child: Text(
                  'Tu valoración: ${resumen.miPuntuacion} de 5',
                  style: const TextStyle(
                    color: _ratingAccent,
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
