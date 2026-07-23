import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/producto_consolidado.dart';

class ProductoDistribucionDialog extends StatelessWidget {
  const ProductoDistribucionDialog({required this.producto, super.key});

  final ProductoConsolidado producto;

  static Future<bool?> show(
    BuildContext context, {
    required ProductoConsolidado producto,
  }) => showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => ProductoDistribucionDialog(producto: producto),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: producto.distribucion.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) =>
                  _DistribucionCard(item: producto.distribucion[index]),
            ),
          ),
          _footer(context),
        ],
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total requerido: ${producto.presentaciones.map((item) => item.solicitadaTexto).join(' • ')}',
                style: GoogleFonts.inter(color: const Color(0xFF757575)),
              ),
              if (producto.variante != 'Producto único')
                Text(
                  producto.variante,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _footer(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Column(
      children: [
        _TotalRow(
          label: 'Total solicitado',
          value: producto.presentaciones
              .map((item) => item.solicitadaTexto)
              .join(' • '),
        ),
        _TotalRow(
          label: 'Total preparado',
          value: producto.presentaciones
              .where((item) => item.preparada > 0)
              .map((item) => item.preparadaTexto)
              .join(' • '),
          color: const Color(0xFF2E7D32),
        ),
        _TotalRow(
          label: 'Pendiente',
          value: producto.presentaciones
              .where((item) => item.pendiente > 0)
              .map((item) => item.pendienteTexto)
              .join(' • '),
          color: const Color(0xFFF57C00),
        ),
        _TotalRow(
          label: 'Equivalencia',
          value: producto.equivalenciaTotalTexto,
          color: const Color(0xFF757575),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: producto.pendiente > 0
                    ? () => Navigator.pop(context, true)
                    : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Registrar preparación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC500),
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
            ];
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [actions[0], const SizedBox(height: 8), actions[1]],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [actions[0], const SizedBox(width: 12), actions[1]],
            );
          },
        ),
      ],
    ),
  );
}

class _DistribucionCard extends StatelessWidget {
  const _DistribucionCard({required this.item});

  final DistribucionPedido item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8E8E8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.codigoPedido,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            if (item.completo)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          item.cliente,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: const Color(0xFF616161)),
        ),
        if (item.hojaCodigo.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Hoja ${item.hojaCodigo}',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 9),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            _Dato(label: 'Solicitado', value: item.cantidadOriginalTexto),
            _Dato(label: 'Preparado', value: item.cantidadPreparadaTexto),
            _Dato(label: 'Pendiente', value: item.cantidadPendienteTexto),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Equivalencia: ${item.equivalenciaSolicitadaTexto} • ${item.equivalencia}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF757575),
          ),
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      Text(
        value,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? '0' : value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    ),
  );
}
