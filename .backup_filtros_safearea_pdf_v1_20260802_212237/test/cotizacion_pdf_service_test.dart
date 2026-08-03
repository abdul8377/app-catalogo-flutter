import 'dart:convert';

import 'package:app_catalogo/features/pedidos/data/services/cotizacion_pdf_service.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_detalle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera una cotización PDF válida', () async {
    final pedido = PedidoDetalle(
      id: 'pedido-1',
      codigo: 'PED-2026-0001',
      fecha: DateTime(2026, 8, 2),
      estado: 'Pendiente',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'cliente-1',
      clienteNombre: 'Ferretería Central S.A.C.',
      telefono: '987654321',
      clienteRuc: '20601234567',
      direccion: 'Av. Industrial 123, Arequipa',
      referencia: '',
      productos: const [],
      subtotalConocido: 118,
      productosSinPrecio: 0,
      hoja: 'HP-2026-001',
      vendedor: 'Alfonzo Esteban',
      estadoPreparacion: 'pendiente',
      estadoCarga: 'pendiente',
      historial: const [],
    );
    final cotizacion = CotizacionPedidoGuardada(
      id: 'cotizacion-1',
      pedidoId: pedido.id,
      codigo: 'COT-2026-0001',
      total: 118,
      creadoEn: DateTime(2026, 8, 2),
    );
    const producto = PedidoDetalleProducto(
      id: 'item-1',
      productoId: 'producto-1',
      codigo: 'PER-023',
      nombre: 'Perno hexagonal',
      presentacion: 'Ciento',
      equivalencia: '100 UND',
      cantidad: 2,
      precioUnitario: 59,
      subtotal: 118,
      varianteSku: 'PER-023-001',
      varianteNombre: 'Perno hexagonal 1/4 x 4',
      atributosVariante: {'Diámetro': '1/4 in', 'Largo': '4 in'},
    );

    final bytes = await CotizacionPdfService().generarBytes(
      cotizacion: cotizacion,
      pedido: pedido,
      productos: const [
        CotizacionPdfProducto(
          producto: producto,
          precioUnitarioConIgv: 59,
          subtotalConIgv: 118,
        ),
      ],
      subtotalProductos: 118,
      descuentosProductos: 0,
      descuentoGeneral: 0,
      total: 118,
      observaciones: 'Entrega sujeta a confirmación.',
    );

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1500));
  });
}
