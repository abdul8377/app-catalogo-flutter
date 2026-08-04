import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CrearHojaResultado {
  const CrearHojaResultado({
    required this.vendedor,
    required this.referencia,
    required this.observacion,
  });

  final String vendedor;
  final String referencia;
  final String observacion;
}

class CrearHojaDialog extends StatefulWidget {
  const CrearHojaDialog({
    required this.codigoSugerido,
    this.vendedorInicial = 'Alfonzo Esteban',
    super.key,
  });

  final String codigoSugerido;
  final String vendedorInicial;

  static Future<CrearHojaResultado?> show(
    BuildContext context, {
    required String codigoSugerido,
    String vendedorInicial = 'Alfonzo Esteban',
  }) => showDialog<CrearHojaResultado>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => CrearHojaDialog(
      codigoSugerido: codigoSugerido,
      vendedorInicial: vendedorInicial,
    ),
  );

  @override
  State<CrearHojaDialog> createState() => _CrearHojaDialogState();
}

class _CrearHojaDialogState extends State<CrearHojaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vendedorController;
  final _referenciaController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vendedorController = TextEditingController(text: widget.vendedorInicial);
  }

  @override
  void dispose() {
    _vendedorController.dispose();
    _referenciaController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
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
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva hoja de pedido',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _readOnly(
                'Código',
                widget.codigoSugerido,
                'Generado automáticamente',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _vendedorController,
                decoration: _decoration(
                  'Vendedor responsable *',
                  Icons.person_outline,
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Ingresa el vendedor responsable.'
                    : null,
              ),
              const SizedBox(height: 14),
              _readOnly(
                'Fecha de apertura',
                DateFormat('dd/MM/yyyy • HH:mm').format(DateTime.now()),
                'Se registrará al crear la hoja',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _referenciaController,
                decoration: _decoration(
                  'Nombre o referencia opcional',
                  Icons.label_outline,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observacionController,
                maxLines: 3,
                decoration: _decoration('Observación', Icons.notes),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC500),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Crear hoja'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _readOnly(String label, String value, String helper) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        Text(
          helper,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    ),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      CrearHojaResultado(
        vendedor: _vendedorController.text.trim(),
        referencia: _referenciaController.text.trim(),
        observacion: _observacionController.text.trim(),
      ),
    );
  }
}
