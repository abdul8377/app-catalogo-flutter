import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cotizacion_pedido.dart';

class CotizacionTotalesValue {
  const CotizacionTotalesValue({
    required this.descuentoGlobalPorcentaje,
    required this.descuentoGlobalMonto,
    required this.observaciones,
  });

  final double descuentoGlobalPorcentaje;
  final double descuentoGlobalMonto;
  final String observaciones;

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
  late final TextEditingController _porcentajeController;
  late final TextEditingController _montoController;
  late final TextEditingController _observacionesController;

  double get _subtotalNeto =>
      (widget.subtotalProductos - widget.descuentosProductos).clamp(
        0,
        double.infinity,
      );

  double get _descuentoGeneral => CotizacionTotalesValue(
    descuentoGlobalPorcentaje: _parseMoney(_porcentajeController.text),
    descuentoGlobalMonto: _parseMoney(_montoController.text),
    observaciones: _observacionesController.text,
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
    _observacionesController = TextEditingController(
      text: widget.value.observaciones,
    );
  }

  @override
  void dispose() {
    _porcentajeController.dispose();
    _montoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de cotización',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 16),
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
          _row('IGV', 'S/ ${_igv.toStringAsFixed(2)}'),
          const Divider(height: 28),
          _row(
            'Total de cotización — incluye IGV',
            'S/ ${_total.toStringAsFixed(2)}',
            emphasize: true,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final porcentaje = _numberField(
                controller: _porcentajeController,
                label: 'Descuento global por porcentaje',
                suffix: '%',
              );
              final monto = _numberField(
                controller: _montoController,
                label: 'Descuento global por monto',
                prefix: 'S/ ',
              );
              if (constraints.maxWidth < 540) {
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
          const SizedBox(height: 12),
          TextField(
            controller: _observacionesController,
            decoration: InputDecoration(
              labelText: 'Observación para el cliente',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFFC500),
                  width: 2,
                ),
              ),
            ),
            maxLines: 3,
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    ),
  );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
  }) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFC500), width: 2),
      ),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [_MoneyInputFormatter()],
    onChanged: (_) {
      setState(() {});
      _notifyChange();
    },
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
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              fontSize: emphasize ? 16 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
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
        observaciones: _observacionesController.text,
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
