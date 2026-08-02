import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cotizacion_pedido.dart';

class CotizacionTotalesValue {
  const CotizacionTotalesValue({
    required this.descuentoGlobalPorcentaje,
    required this.descuentoGlobalMonto,
    required this.observaciones,
    this.vigenciaDias = 7,
    this.condiciones = '',
  });

  final double descuentoGlobalPorcentaje;
  final double descuentoGlobalMonto;
  final String observaciones;
  final int vigenciaDias;
  final String condiciones;

  double descuentoGeneralSobre(double subtotalNeto) {
    final porcentaje = descuentoGlobalPorcentaje.clamp(0, 100);
    final monto = descuentoGlobalMonto < 0 ? 0 : descuentoGlobalMonto;
    return (subtotalNeto * porcentaje / 100 + monto)
        .clamp(0, subtotalNeto)
        .toDouble();
  }
}

class CotizacionTotales extends StatefulWidget {
  const CotizacionTotales({
    required this.subtotalProductos,
    required this.descuentosProductos,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double subtotalProductos;
  final double descuentosProductos;
  final CotizacionTotalesValue value;
  final ValueChanged<CotizacionTotalesValue> onChanged;

  @override
  State<CotizacionTotales> createState() => _CotizacionTotalesState();
}

class _CotizacionTotalesState extends State<CotizacionTotales> {
  static const _yellow = Color(0xFFFFC500);
  static const _ink = Color(0xFF1F1F1F);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE1E5EA);

  late final TextEditingController _porcentajeController;
  late final TextEditingController _montoController;
  late final TextEditingController _vigenciaController;
  late final TextEditingController _condicionesController;
  late final TextEditingController _observacionesController;

  double get _subtotalNeto =>
      (widget.subtotalProductos - widget.descuentosProductos)
          .clamp(0, double.infinity)
          .toDouble();

  double get _descuentoGeneral => CotizacionTotalesValue(
    descuentoGlobalPorcentaje: _parseMoney(_porcentajeController.text),
    descuentoGlobalMonto: _parseMoney(_montoController.text),
    observaciones: _observacionesController.text,
    vigenciaDias: _parseDays(_vigenciaController.text),
    condiciones: _condicionesController.text,
  ).descuentoGeneralSobre(_subtotalNeto);

  double get _total => CotizacionCalculo.totalConDescuentos(
    subtotalProductos: widget.subtotalProductos,
    descuentosProductos: widget.descuentosProductos,
    descuentoGeneral: _descuentoGeneral,
  );

  double get _totalSinIgv => CotizacionIgv.totalSinIgv(_total);

  double get _igv => CotizacionIgv.igvIncluido(_total);

  @override
  void initState() {
    super.initState();
    _porcentajeController = TextEditingController(
      text: widget.value.descuentoGlobalPorcentaje > 0
          ? widget.value.descuentoGlobalPorcentaje.toStringAsFixed(2)
          : '',
    );
    _montoController = TextEditingController(
      text: widget.value.descuentoGlobalMonto > 0
          ? widget.value.descuentoGlobalMonto.toStringAsFixed(2)
          : '',
    );
    _vigenciaController = TextEditingController(
      text: widget.value.vigenciaDias.clamp(1, 365).toString(),
    );
    _condicionesController = TextEditingController(
      text: widget.value.condiciones,
    );
    _observacionesController = TextEditingController(
      text: widget.value.observaciones,
    );
  }

  @override
  void dispose() {
    _porcentajeController.dispose();
    _montoController.dispose();
    _vigenciaController.dispose();
    _condicionesController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(
          title: 'Resumen económico',
          subtitle:
              'El total se desglosa en importe sin IGV, IGV y total final.',
          icon: Icons.calculate_outlined,
          child: Column(
            children: [
              _row(
                'Subtotal de productos',
                'S/ ${widget.subtotalProductos.toStringAsFixed(2)}',
              ),
              _row(
                'Descuento',
                '-S/ ${(widget.descuentosProductos + _descuentoGeneral).toStringAsFixed(2)}',
                color: const Color(0xFFD84315),
              ),
              _row('Total sin IGV', 'S/ ${_totalSinIgv.toStringAsFixed(2)}'),
              _row('IGV (18 %)', 'S/ ${_igv.toStringAsFixed(2)}'),
              const Divider(height: 28),
              _row(
                'Total de cotización',
                'S/ ${_total.toStringAsFixed(2)}',
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Descuentos generales',
          subtitle:
              'Se aplican después de los descuentos configurados por producto.',
          icon: Icons.percent_rounded,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final porcentaje = _numberField(
                controller: _porcentajeController,
                label: 'Porcentaje global',
                suffix: '%',
              );
              final monto = _numberField(
                controller: _montoController,
                label: 'Monto global',
                prefix: 'S/ ',
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [porcentaje, const SizedBox(height: 12), monto],
                );
              }
              return Row(
                children: [
                  Expanded(child: porcentaje),
                  const SizedBox(width: 12),
                  Expanded(child: monto),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Condiciones comerciales',
          subtitle:
              'Estos datos se guardan con la cotización y se muestran en la '
              'vista previa.',
          icon: Icons.handshake_outlined,
          child: Column(
            children: [
              TextField(
                key: const Key('cotizacion_vigencia_dias'),
                controller: _vigenciaController,
                decoration: _inputDecoration(
                  'Vigencia',
                  suffix: 'días',
                  helper: 'Entre 1 y 365 días.',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (_) => _notifyChange(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('cotizacion_condiciones'),
                controller: _condicionesController,
                decoration: _inputDecoration(
                  'Condiciones comerciales',
                  helper:
                      'Ejemplo: forma de pago, disponibilidad o tiempo de '
                      'entrega.',
                ),
                maxLines: 3,
                onChanged: (_) => _notifyChange(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('cotizacion_observaciones'),
                controller: _observacionesController,
                decoration: _inputDecoration(
                  'Observación para el cliente',
                  helper:
                      'Información adicional que aparecerá en la cotización.',
                ),
                maxLines: 3,
                onChanged: (_) => _notifyChange(),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: _ink, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
  }) => TextField(
    controller: controller,
    decoration: _inputDecoration(label, prefix: prefix, suffix: suffix),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [_MoneyInputFormatter()],
    onChanged: (_) {
      setState(() {});
      _notifyChange();
    },
  );

  InputDecoration _inputDecoration(
    String label, {
    String? prefix,
    String? suffix,
    String? helper,
  }) => InputDecoration(
    labelText: label,
    prefixText: prefix,
    suffixText: suffix,
    helperText: helper,
    alignLabelWithHint: true,
    filled: true,
    fillColor: const Color(0xFFFCFCFD),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _yellow, width: 2),
    ),
  );

  Widget _row(
    String label,
    String value, {
    Color? color,
    bool emphasize = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: _ink,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
              fontSize: emphasize ? 16 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: emphasize ? 18 : 14,
            color: color,
          ),
        ),
      ],
    ),
  );

  void _notifyChange() {
    widget.onChanged(
      CotizacionTotalesValue(
        descuentoGlobalPorcentaje: _parseMoney(_porcentajeController.text),
        descuentoGlobalMonto: _parseMoney(_montoController.text),
        observaciones: _observacionesController.text.trim(),
        vigenciaDias: _parseDays(_vigenciaController.text),
        condiciones: _condicionesController.text.trim(),
      ),
    );
  }
}

class _MoneyInputFormatter extends TextInputFormatter {
  final _allowed = RegExp(r'^\d*([,.]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _allowed.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

double _parseMoney(String value) =>
    double.tryParse(value.replaceAll(',', '.')) ?? 0;

int _parseDays(String value) {
  final parsed = int.tryParse(value) ?? 7;
  return parsed.clamp(1, 365);
}
