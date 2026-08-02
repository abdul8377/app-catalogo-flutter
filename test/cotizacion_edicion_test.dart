import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distingue borrador, generada y archivada', () {
    final base = DateTime(2026, 8, 1);
    final draft = CotizacionPedidoGuardada(
      id: 'draft',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 100,
      creadoEn: base,
      estado: 'Borrador',
      vigenciaDias: 15,
      condiciones: 'Pago a 15 días',
      observaciones: 'Entrega coordinada',
      items: const [
        CotizacionPedidoItemGuardado(
          id: 'line',
          pedidoItemId: 'order-line',
          productoId: 'product',
          codigo: 'SKU',
          nombre: 'Producto',
          presentacion: 'Caja',
          cantidad: 2,
          precioCotizacion: 50,
          descuento: 0,
          tipoDescuento: 'monto',
          precioFinal: 50,
          subtotal: 100,
        ),
      ],
    );

    expect(draft.esBorrador, isTrue);
    expect(draft.esGenerada, isFalse);
    expect(draft.items.single.toDraft().pedidoItemId, 'order-line');
    expect(draft.vigenciaDias, 15);
    expect(draft.condiciones, 'Pago a 15 días');

    final generated = draft.copyWith(estado: 'Generada');
    expect(generated.esGenerada, isTrue);

    final archived = draft.copyWith(estado: 'Archivada');
    expect(archived.esArchivada, isTrue);
  });

  test('el código de versión se presenta sin duplicar el sufijo', () {
    final date = DateTime(2026);
    final first = CotizacionPedidoGuardada(
      id: '1',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 10,
      creadoEn: date,
    );
    final second = CotizacionPedidoGuardada(
      id: '2',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 10,
      creadoEn: date,
      version: 2,
    );

    expect(first.codigoVersion, 'COT-2026-0001');
    expect(second.codigoVersion, 'COT-2026-0001-V2');
  });
}
