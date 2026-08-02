import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_actions_service.dart';
import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../widgets/cotizacion_preview.dart';
import '../widgets/cotizacion_producto_item.dart';
import '../widgets/cotizacion_totales.dart';

class GenerarCotizacionDialog extends StatefulWidget {
  const GenerarCotizacionDialog({
    required this.pedidoId,
    this.modoEdicion = false,
    super.key,
  });

  final String pedidoId;
  final bool modoEdicion;

  static Future<CotizacionPedidoGuardada?> show(
    BuildContext context, {
    required String pedidoId,
    bool modoEdicion = false,
  }) => showDialog<CotizacionPedidoGuardada>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) =>
        GenerarCotizacionDialog(pedidoId: pedidoId, modoEdicion: modoEdicion),
  );

  @override
  State<GenerarCotizacionDialog> createState() =>
      _GenerarCotizacionDialogState();
}

class _GenerarCotizacionDialogState extends State<GenerarCotizacionDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  late final Future<PedidoDetalle?> _pedidoFuture;
  final _pdfExporter = _CotizacionPdfExporter();

  int _currentStep = 0;
  bool _initialized = false;
  bool _saving = false;
  List<CotizacionProductoFormItem> _productos = [];
  CotizacionTotalesValue _totalesValue = const CotizacionTotalesValue(
    descuentoGlobalPorcentaje: 0,
    descuentoGlobalMonto: 0,
    observaciones: '',
  );

  @override
  void initState() {
    super.initState();
    _pedidoFuture = context.read<PedidosRepository>().obtenerPedidoDetalle(
      widget.pedidoId,
    );
  }

  bool get _todosConPrecio =>
      _productos.isNotEmpty && _productos.every((item) => item.valorizado);

  double get _subtotalProductos => _productos.fold<double>(
    0,
    (sum, item) => sum + item.subtotalSinDescuento,
  );

  double get _descuentosProductos =>
      _productos.fold<double>(0, (sum, item) => sum + item.descuentoAplicado);

  double get _subtotalNeto =>
      (_subtotalProductos - _descuentosProductos).clamp(0, double.infinity);

  double get _descuentoGeneral =>
      _totalesValue.descuentoGeneralSobre(_subtotalNeto);

  double get _totalConDescuento => CotizacionCalculo.totalConDescuentos(
    subtotalProductos: _subtotalProductos,
    descuentosProductos: _descuentosProductos,
    descuentoGeneral: _descuentoGeneral,
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;
        final height = constraints.maxHeight > 760
            ? 760.0
            : constraints.maxHeight;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: FutureBuilder<PedidoDetalle?>(
            future: _pedidoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }
              if (snapshot.hasError) {
                return _DialogError(
                  title: 'No se pudo cargar el pedido',
                  message:
                      'Ocurrió un problema leyendo el pedido desde la base local.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              final pedido = snapshot.data;
              if (pedido == null) {
                return _DialogError(
                  title: 'Pedido no encontrado',
                  message: 'El pedido seleccionado ya no existe.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              _ensureInitialized(pedido);
              return Column(
                children: [
                  _Header(pedido: pedido),
                  _StepHeader(currentStep: _currentStep),
                  Expanded(child: _buildStep(pedido)),
                  _BottomBar(
                    currentStep: _currentStep,
                    saving: _saving,
                    canContinue: _todosConPrecio,
                    onBack: _currentStep > 0
                        ? () => setState(() => _currentStep--)
                        : null,
                    onClose: () => Navigator.of(context).pop(),
                    onContinue: () => _continuar(),
                    onSaveDraft: () => _guardar(pedido, exportarPdf: false),
                    onExport: () => _guardar(pedido, exportarPdf: true),
                    modoEdicion: widget.modoEdicion,
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );

  void _ensureInitialized(PedidoDetalle pedido) {
    if (_initialized) return;
    _productos = pedido.productos
        .map(
          (producto) => CotizacionProductoFormItem(
            producto: producto,
            precioCotizacion: producto.precioUnitario ?? 0,
            descuento: producto.descuentoCotizado,
            tipoDescuento: producto.tipoDescuentoCotizado,
          ),
        )
        .toList();
    if (pedido.cotizacionVigente) {
      _totalesValue = CotizacionTotalesValue(
        descuentoGlobalPorcentaje: pedido.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: pedido.descuentoGlobalMonto,
        observaciones: pedido.observacionesCotizacion,
      );
    }
    _initialized = true;
  }

  Widget _buildStep(PedidoDetalle pedido) {
    switch (_currentStep) {
      case 0:
        return _PasoConfigurarPrecios(
          productos: _productos,
          onChanged: () => setState(() {}),
        );
      case 1:
        return CotizacionTotales(
          subtotalProductos: _subtotalProductos,
          descuentosProductos: _descuentosProductos,
          value: _totalesValue,
          onChanged: (value) => setState(() => _totalesValue = value),
        );
      default:
        return CotizacionPreview(
          pedido: pedido,
          productos: _productos,
          subtotalProductos: _subtotalProductos,
          descuentosProductos: _descuentosProductos,
          descuentoGeneral: _descuentoGeneral,
          total: _totalConDescuento,
          observaciones: _totalesValue.observaciones,
        );
    }
  }

  void _continuar() {
    if (_currentStep == 0 && !_todosConPrecio) {
      AppNotice.warning(
        context,
        'Todos los productos deben tener precio para continuar.',
      );
      return;
    }
    setState(() => _currentStep++);
  }

  Future<void> _guardar(
    PedidoDetalle pedido, {
    required bool exportarPdf,
  }) async {
    if (_saving) return;
    if (!_todosConPrecio) {
      setState(() => _currentStep = 0);
      _continuar();
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = context.read<PedidosRepository>();
      final draft = CotizacionPedidoDraft(
        pedidoId: pedido.id,
        items: _productos.map((item) => item.toDraft()).toList(),
        subtotal: _subtotalProductos,
        descuentoGlobal: _descuentoGeneral,
        tipoDescuentoGlobal: 'combinado',
        total: _totalConDescuento,
        vigenciaDias: 0,
        condiciones: '',
        observaciones: _totalesValue.observaciones,
        descuentoGlobalPorcentaje: _totalesValue.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: _totalesValue.descuentoGlobalMonto,
        estado: exportarPdf || widget.modoEdicion ? 'Generada' : 'Borrador',
      );
      final guardada = await repository.guardarCotizacion(draft);
      if (!exportarPdf) {
        if (!mounted) return;
        Navigator.of(context).pop(guardada);
        return;
      }

      final pdfPath = await _pdfExporter.exportar(
        cotizacion: guardada,
        pedido: pedido,
        productos: _productos,
        subtotalProductos: _subtotalProductos,
        descuentosProductos: _descuentosProductos,
        descuentoGeneral: _descuentoGeneral,
        total: _totalConDescuento,
        observaciones: _totalesValue.observaciones,
      );
      await repository.registrarPdfCotizacion(
        cotizacionId: guardada.id,
        pdfPath: pdfPath,
      );
      final result = guardada.copyWith(pdfPath: pdfPath);
      if (!mounted) return;
      await _mostrarCotizacionGenerada(result);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppNotice.error(context, 'No se pudo guardar la cotización: $error');
    }
  }

  Future<void> _mostrarCotizacionGenerada(
    CotizacionPedidoGuardada cotizacion,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          SizedBox(width: 10),
          Expanded(child: Text('Cotización generada correctamente')),
        ],
      ),
      content: Text(
        '${cotizacion.codigo} • Versión ${cotizacion.version}\n'
        'El PDF se guardó localmente y quedó asociado al pedido.',
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _ejecutarAccionArchivo(
            () => FileActionsService.openPdf(cotizacion.pdfPath!),
          ),
          icon: const Icon(Icons.visibility),
          label: const Text('Ver PDF'),
        ),
        TextButton.icon(
          onPressed: () => _ejecutarAccionArchivo(
            () => FileActionsService.sharePdf(cotizacion.pdfPath!),
          ),
          icon: const Icon(Icons.share),
          label: const Text('Compartir'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
          ),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  Future<void> _ejecutarAccionArchivo(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      AppNotice.error(context, 'No se pudo abrir el archivo: $error');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pedido});

  final PedidoDetalle pedido;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Generar cotización • ${pedido.codigo}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: _GenerarCotizacionDialogState.darkColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 22),
              splashRadius: 20,
              style: IconButton.styleFrom(
                foregroundColor: Colors.grey,
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cliente: ${pedido.clienteNombre}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF757575),
          ),
        ),
      ],
    ),
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        _StepChip(
          label: 'Configurar precios',
          stepIndex: 0,
          currentStep: currentStep,
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        _StepChip(label: 'Resumen', stepIndex: 1, currentStep: currentStep),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        _StepChip(
          label: 'Vista previa',
          stepIndex: 2,
          currentStep: currentStep,
        ),
      ],
    ),
  );
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.stepIndex,
    required this.currentStep,
  });

  final String label;
  final int stepIndex;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep == stepIndex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFFC500).withValues(alpha: .2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFFFC500) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PasoConfigurarPrecios extends StatelessWidget {
  const _PasoConfigurarPrecios({
    required this.productos,
    required this.onChanged,
  });

  final List<CotizacionProductoFormItem> productos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final valorizados = productos.where((item) => item.valorizado).length;
    final pendientes = productos.length - valorizados;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$valorizados de ${productos.length} productos valorizados',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              if (pendientes > 0) ...[
                const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$pendientes precios pendientes',
                  style: GoogleFonts.inter(color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: productos.length,
            itemBuilder: (_, index) => CotizacionProductoItem(
              item: productos[index],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentStep,
    required this.saving,
    required this.canContinue,
    required this.onClose,
    required this.onContinue,
    required this.onSaveDraft,
    required this.onExport,
    required this.modoEdicion,
    this.onBack,
  });

  final int currentStep;
  final bool saving;
  final bool canContinue;
  final VoidCallback onClose;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final VoidCallback onSaveDraft;
  final VoidCallback onExport;
  final bool modoEdicion;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Wrap(
      alignment: currentStep < 2
          ? WrapAlignment.spaceBetween
          : WrapAlignment.end,
      runAlignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        if (currentStep > 0)
          OutlinedButton(
            onPressed: saving ? null : onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: _GenerarCotizacionDialogState.darkColor,
            ),
            child: const Text('Volver'),
          )
        else
          OutlinedButton(
            onPressed: saving ? null : onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: _GenerarCotizacionDialogState.darkColor,
            ),
            child: const Text('Cancelar'),
          ),
        if (currentStep < 2)
          ElevatedButton(
            onPressed: saving ? null : onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _GenerarCotizacionDialogState.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Continuar'),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: saving || !canContinue ? null : onSaveDraft,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              modoEdicion ? 'Guardar nueva versión' : 'Guardar borrador',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _GenerarCotizacionDialogState.darkColor,
            ),
          ),
          ElevatedButton.icon(
            onPressed: saving || !canContinue ? null : onExport,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(saving ? 'Guardando...' : 'Exportar en PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _GenerarCotizacionDialogState.primaryColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ],
    ),
  );
}

class _DialogError extends StatelessWidget {
  const _DialogError({
    required this.title,
    required this.message,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: _GenerarCotizacionDialogState.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}

class _CotizacionPdfExporter {
  Future<String> exportar({
    required CotizacionPedidoGuardada cotizacion,
    required PedidoDetalle pedido,
    required List<CotizacionProductoFormItem> productos,
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
    required double total,
    required String observaciones,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final folder = Directory(path.join(directory.path, 'cotizaciones'));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }
    final file = File(
      path.join(folder.path, '${cotizacion.codigo}-V${cotizacion.version}.pdf'),
    );
    final lines = _buildLines(
      cotizacion: cotizacion,
      pedido: pedido,
      productos: productos,
      subtotalProductos: subtotalProductos,
      descuentosProductos: descuentosProductos,
      descuentoGeneral: descuentoGeneral,
      total: total,
      observaciones: observaciones,
    );
    await file.writeAsBytes(_buildPdf(lines), flush: true);
    return file.path;
  }

  List<String> _buildLines({
    required CotizacionPedidoGuardada cotizacion,
    required PedidoDetalle pedido,
    required List<CotizacionProductoFormItem> productos,
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
    required double total,
    required String observaciones,
  }) {
    final lines = <String>[
      'COTIZACION N. ${cotizacion.codigo} - VERSION ${cotizacion.version}',
      'Pedido: ${pedido.codigo}',
      'Cliente: ${pedido.clienteNombre}',
      if (pedido.clienteRuc.isNotEmpty) 'RUC: ${pedido.clienteRuc}',
      if (pedido.clienteDni.isNotEmpty) 'DNI: ${pedido.clienteDni}',
      'Telefono: ${pedido.telefono}',
      'Direccion: ${pedido.direccion}',
      'Fecha: ${_formatDate(DateTime.now())}',
      '',
      'PRODUCTO | CANTIDAD | P. UNITARIO | SUBTOTAL',
    ];
    for (final item in productos) {
      lines.add(
        '${item.producto.nombre} | ${item.producto.cantidad} ${item.producto.presentacion} | S/ ${item.precioCotizacion.toStringAsFixed(2)} | S/ ${item.subtotalCotizacion.toStringAsFixed(2)}',
      );
    }
    lines.addAll([
      '',
      'Subtotal de productos: S/ ${subtotalProductos.toStringAsFixed(2)}',
      'Descuento: -S/ ${(descuentosProductos + descuentoGeneral).toStringAsFixed(2)}',
      'Total sin IGV: S/ ${CotizacionIgv.totalSinIgv(total).toStringAsFixed(2)}',
      'IGV: S/ ${CotizacionIgv.igvIncluido(total).toStringAsFixed(2)}',
      'Total de cotizacion — incluye IGV: S/ ${total.toStringAsFixed(2)}',
      if (observaciones.isNotEmpty) '',
      if (observaciones.isNotEmpty) 'Observaciones: $observaciones',
    ]);
    return lines;
  }

  List<int> _buildPdf(List<String> lines) {
    final printableLines = lines.length > 48
        ? [...lines.take(47), '...']
        : lines;
    final content = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 10 Tf')
      ..writeln('50 800 Td')
      ..writeln('14 TL');
    for (final line in printableLines) {
      content
        ..write('(')
        ..write(_escapePdf(_ascii(line)))
        ..writeln(') Tj')
        ..writeln('T*');
    }
    content.writeln('ET');
    final contentBytes = latin1.encode(content.toString());
    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
      '4 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n${content.toString()}endstream\nendobj\n',
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    ];

    var pdf = '%PDF-1.4\n';
    final offsets = <int>[];
    for (final object in objects) {
      offsets.add(latin1.encode(pdf).length);
      pdf += object;
    }
    final startXref = latin1.encode(pdf).length;
    final xref = StringBuffer()
      ..writeln('xref')
      ..writeln('0 ${objects.length + 1}')
      ..writeln('0000000000 65535 f ');
    for (final offset in offsets) {
      xref.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    pdf +=
        '${xref}trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF';
    return latin1.encode(pdf);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _escapePdf(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');

  String _ascii(String value) {
    final normalized = value
        .replaceAll(RegExp('[áÁ]'), 'a')
        .replaceAll(RegExp('[éÉ]'), 'e')
        .replaceAll(RegExp('[íÍ]'), 'i')
        .replaceAll(RegExp('[óÓ]'), 'o')
        .replaceAll(RegExp('[úÚ]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('°', '.')
        .replaceAll('•', '-')
        .replaceAll('—', '-');
    final buffer = StringBuffer();
    for (final rune in normalized.runes) {
      buffer.writeCharCode(rune >= 32 && rune <= 126 ? rune : 32);
    }
    return buffer.toString();
  }
}
