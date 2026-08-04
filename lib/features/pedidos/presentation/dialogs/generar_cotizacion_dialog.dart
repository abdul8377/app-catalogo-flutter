import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/platform/file_actions_service.dart';
import '../../../../core/presentation/widgets/app_notice.dart';
import '../../application/services/cotizacion_pdf_service.dart';
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
    this.cotizacionId,
    super.key,
  });

  final String pedidoId;
  final bool modoEdicion;
  final String? cotizacionId;

  static Future<CotizacionPedidoGuardada?> show(
    BuildContext context, {
    required String pedidoId,
    bool modoEdicion = false,
    String? cotizacionId,
  }) => showDialog<CotizacionPedidoGuardada>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => GenerarCotizacionDialog(
      pedidoId: pedidoId,
      modoEdicion: modoEdicion,
      cotizacionId: cotizacionId,
    ),
  );

  @override
  State<GenerarCotizacionDialog> createState() =>
      _GenerarCotizacionDialogState();
}

class _GenerarCotizacionDialogState extends State<GenerarCotizacionDialog> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  late final Future<PedidoDetalle?> _pedidoFuture;
  late final Future<CotizacionPedidoGuardada?> _cotizacionFuture;
  final _pdfExporter = CotizacionPdfService();

  int _currentStep = 0;
  bool _initialized = false;
  bool _saving = false;
  List<CotizacionProductoFormItem> _productos = [];
  CotizacionPedidoGuardada? _cotizacionSeleccionada;
  CotizacionTotalesValue _totalesValue = const CotizacionTotalesValue(
    descuentoGlobalPorcentaje: 0,
    descuentoGlobalMonto: 0,
    observaciones: '',
    vigenciaDias: 7,
    condiciones: '',
  );

  @override
  void initState() {
    super.initState();
    final repository = context.read<PedidosRepository>();
    _pedidoFuture = repository.obtenerPedidoDetalle(widget.pedidoId);
    _cotizacionFuture = widget.cotizacionId == null
        ? Future.value(null)
        : repository.obtenerCotizacion(widget.cotizacionId!);
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
        final width = constraints.maxWidth > 1160
            ? 1160.0
            : constraints.maxWidth;
        final height = constraints.maxHeight > 900
            ? 900.0
            : constraints.maxHeight;
        return Container(
          key: const Key('generar_cotizacion_surface'),
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
              return FutureBuilder<CotizacionPedidoGuardada?>(
                future: _cotizacionFuture,
                builder: (context, quoteSnapshot) {
                  if (quoteSnapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  if (quoteSnapshot.hasError) {
                    return _DialogError(
                      title: 'No se pudo cargar la cotización',
                      message:
                          'La versión seleccionada no pudo leerse desde la base local.',
                      onClose: () => Navigator.of(context).pop(),
                    );
                  }
                  if (widget.cotizacionId != null &&
                      quoteSnapshot.data == null) {
                    return _DialogError(
                      title: 'Cotización no encontrada',
                      message:
                          'La versión seleccionada ya no existe en la base local.',
                      onClose: () => Navigator.of(context).pop(),
                    );
                  }
                  _ensureInitialized(pedido, quoteSnapshot.data);
                  return Column(
                    children: [
                      _Header(pedido: pedido, cotizacion: quoteSnapshot.data),
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
                        modoEdicion: widget.cotizacionId != null,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    ),
  );

  void _ensureInitialized(
    PedidoDetalle pedido,
    CotizacionPedidoGuardada? selected,
  ) {
    if (_initialized) return;
    _cotizacionSeleccionada = selected;
    final savedByItem = {
      for (final item in selected?.items ?? const []) item.pedidoItemId: item,
    };
    _productos = pedido.productos.map((producto) {
      final saved = savedByItem[producto.id];
      return CotizacionProductoFormItem(
        producto: producto,
        precioCotizacion:
            saved?.precioCotizacion ?? producto.precioUnitario ?? 0,
        descuento: saved?.descuento ?? producto.descuentoCotizado,
        tipoDescuento: saved?.tipoDescuento ?? producto.tipoDescuentoCotizado,
      );
    }).toList();

    if (selected != null) {
      _totalesValue = CotizacionTotalesValue(
        descuentoGlobalPorcentaje: selected.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: selected.descuentoGlobalMonto,
        observaciones: selected.observaciones,
        vigenciaDias: selected.vigenciaDias,
        condiciones: selected.condiciones,
      );
    } else if (pedido.cotizacionVigente) {
      _totalesValue = CotizacionTotalesValue(
        descuentoGlobalPorcentaje: pedido.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: pedido.descuentoGlobalMonto,
        observaciones: pedido.observacionesCotizacion,
        vigenciaDias: 7,
        condiciones: '',
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
          vigenciaDias: _totalesValue.vigenciaDias,
          condiciones: _totalesValue.condiciones,
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
    final esBorrador = !exportarPdf;
    if (!esBorrador && !_todosConPrecio) {
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
        vigenciaDias: _totalesValue.vigenciaDias,
        condiciones: _totalesValue.condiciones,
        observaciones: _totalesValue.observaciones,
        descuentoGlobalPorcentaje: _totalesValue.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: _totalesValue.descuentoGlobalMonto,
        estado: exportarPdf ? 'Generada' : 'Borrador',
      );
      final selected = _cotizacionSeleccionada;
      final guardada = selected != null && selected.esBorrador
          ? await repository.actualizarCotizacion(
              cotizacionId: selected.id,
              cotizacion: draft,
            )
          : await repository.guardarCotizacion(draft);
      if (!exportarPdf) {
        if (!mounted) return;
        Navigator.of(context).pop(guardada);
        return;
      }

      final pdfPath = await _pdfExporter.exportar(
        cotizacion: guardada,
        pedido: pedido,
        productos: _productos
            .map(
              (item) => CotizacionPdfProducto(
                producto: item.producto,
                precioUnitarioConIgv: item.precioCotizacion,
                subtotalConIgv: item.subtotalSinDescuento,
              ),
            )
            .toList(),
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
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 590),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                color: const Color(0xFFECFDF3),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 33,
                      backgroundColor: Color(0xFF12B76A),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Cotización generada',
                      style: GoogleFonts.inter(
                        color: darkColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cotizacion.codigo} · Versión ${cotizacion.version}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475467),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text(
                      'El PDF quedó guardado localmente y asociado al pedido.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 9,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _ejecutarAccionArchivo(
                            () =>
                                FileActionsService.openPdf(cotizacion.pdfPath!),
                          ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _ejecutarAccionArchivo(
                            () => FileActionsService.sharePdf(
                              cotizacion.pdfPath!,
                            ),
                          ),
                          icon: const Icon(Icons.share_outlined),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
  const _Header({required this.pedido, this.cotizacion});

  final PedidoDetalle pedido;
  final CotizacionPedidoGuardada? cotizacion;

  @override
  Widget build(BuildContext context) {
    final selected = cotizacion;
    final title = selected == null
        ? 'Nueva cotización'
        : selected.esBorrador
        ? 'Editar borrador'
        : 'Editar como nueva versión';
    final subtitle = selected == null
        ? '${pedido.codigo} · ${pedido.clienteNombre}'
        : '${selected.codigoVersion} · ${selected.estado} · ${pedido.clienteNombre}';

    return Container(
      color: _GenerarCotizacionDialogState.darkColor,
      padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _GenerarCotizacionDialogState.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.request_quote_outlined,
              color: _GenerarCotizacionDialogState.darkColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB7BAC1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
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
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      border: const Border(top: BorderSide(color: Color(0xFFE1E5EA))),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Wrap(
        alignment: WrapAlignment.end,
        runAlignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: saving
                ? null
                : currentStep > 0
                ? onBack
                : onClose,
            child: Text(currentStep > 0 ? 'Volver' : 'Cancelar'),
          ),
          OutlinedButton.icon(
            key: const Key('guardar_borrador_cotizacion'),
            onPressed: saving ? null : onSaveDraft,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              modoEdicion ? 'Guardar como borrador' : 'Guardar borrador',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _GenerarCotizacionDialogState.darkColor,
              side: const BorderSide(color: Color(0xFFFFC500)),
            ),
          ),
          if (currentStep < 2)
            FilledButton.icon(
              onPressed: saving ? null : onContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continuar'),
              style: FilledButton.styleFrom(
                backgroundColor: _GenerarCotizacionDialogState.primaryColor,
                foregroundColor: Colors.black,
              ),
            )
          else
            FilledButton.icon(
              key: const Key('generar_pdf_cotizacion'),
              onPressed: saving || !canContinue ? null : onExport,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                saving
                    ? 'Guardando...'
                    : modoEdicion
                    ? 'Guardar nueva versión'
                    : 'Generar PDF',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _GenerarCotizacionDialogState.primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
              ),
            ),
        ],
      ),
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
