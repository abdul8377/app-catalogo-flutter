import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CambiarEstadoPedidoResult {
  const CambiarEstadoPedidoResult({
    required this.nuevoEstado,
    required this.observacion,
  });

  final String nuevoEstado;
  final String observacion;
}

class CambiarEstadoDialog extends StatefulWidget {
  const CambiarEstadoDialog({
    required this.estadoActual,
    this.permitirCambioAdministrativo = false,
    super.key,
  });

  final String estadoActual;
  final bool permitirCambioAdministrativo;

  static Future<CambiarEstadoPedidoResult?> show(
    BuildContext context, {
    required String estadoActual,
    bool permitirCambioAdministrativo = false,
  }) => showDialog<CambiarEstadoPedidoResult>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => CambiarEstadoDialog(
      estadoActual: estadoActual,
      permitirCambioAdministrativo: permitirCambioAdministrativo,
    ),
  );

  @override
  State<CambiarEstadoDialog> createState() => _CambiarEstadoDialogState();
}

class _CambiarEstadoDialogState extends State<CambiarEstadoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();
  late final String _estadoActualKey;
  late final List<String> _estadosPermitidos;
  late String? _nuevoEstado;

  @override
  void initState() {
    super.initState();
    _estadoActualKey = _normalizarEstado(widget.estadoActual);
    _estadosPermitidos = _resolverEstadosPermitidos();
    _nuevoEstado = _estadosPermitidos.isEmpty ? null : _estadosPermitidos.first;
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_estadosPermitidos.isEmpty) {
      return AlertDialog(
        title: const Text('Cambio no permitido'),
        content: Text(
          'El pedido en estado "${_formatearEstado(_estadoActualKey)}" no puede cambiar de estado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cambiar estado del pedido',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Estado actual',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatearEstado(_estadoActualKey),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _nuevoEstado,
                decoration: InputDecoration(
                  labelText: 'Nuevo estado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: _estadosPermitidos
                    .map(
                      (estado) => DropdownMenuItem(
                        value: estado,
                        child: Text(_formatearEstado(estado)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _nuevoEstado = value),
                validator: (value) =>
                    value == null ? 'Seleccione un estado' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionController,
                decoration: InputDecoration(
                  labelText: 'Observación opcional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _actualizarEstado,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC500),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Actualizar estado'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _actualizarEstado() {
    if (!_formKey.currentState!.validate() || _nuevoEstado == null) return;
    Navigator.of(context).pop(
      CambiarEstadoPedidoResult(
        nuevoEstado: _formatearEstado(_nuevoEstado!),
        observacion: _observacionController.text.trim(),
      ),
    );
  }

  List<String> _resolverEstadosPermitidos() {
    const flujoNormal = {
      'pendiente': 'en_proceso',
      'en_proceso': 'listo',
      'listo': 'entregado',
    };
    final siguiente = flujoNormal[_estadoActualKey];
    if (!widget.permitirCambioAdministrativo) {
      return siguiente == null ? const [] : [siguiente];
    }
    const todos = ['pendiente', 'en_proceso', 'listo', 'entregado'];
    return todos.where((estado) => estado != _estadoActualKey).toList();
  }

  String _normalizarEstado(String estado) {
    final value = estado.trim().toLowerCase();
    if (value.contains('proceso')) return 'en_proceso';
    if (value.contains('listo')) return 'listo';
    if (value.contains('entregado')) return 'entregado';
    if (value.contains('cancelado')) return 'cancelado';
    return 'pendiente';
  }

  String _formatearEstado(String estado) {
    switch (estado) {
      case 'en_proceso':
        return 'En proceso';
      case 'listo':
        return 'Listo para entregar';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}
