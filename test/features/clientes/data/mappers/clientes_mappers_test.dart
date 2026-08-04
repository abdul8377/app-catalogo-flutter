import 'package:app_catalogo/features/clientes/data/mappers/cliente_mapper.dart';
import 'package:app_catalogo/features/clientes/data/mappers/cliente_pedido_resumen_mapper.dart';
import 'package:app_catalogo/features/clientes/data/models/cliente_local_model.dart';
import 'package:app_catalogo/features/clientes/data/models/cliente_pedido_resumen_local_model.dart';
import 'package:app_catalogo/features/clientes/domain/entities/cliente.dart';
import 'package:app_catalogo/features/clientes/domain/entities/cliente_pedido_resumen.dart';
import 'package:app_catalogo/features/clientes/domain/entities/nuevo_cliente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteMapper', () {
    test('convierte una fila usando exactamente los defaults locales', () {
      final fechaRegistro = DateTime(2026, 7, 1, 10, 30);
      final entity = ClienteMapper.toEntity(
        ClienteLocalModel.fromRow({
          'id': 'cliente-1',
          'nombre': 'Ana Torres',
          'telefono': '987654321',
          'creado_en': fechaRegistro.toIso8601String(),
        }),
      );

      expect(
        entity,
        Cliente(
          id: 'cliente-1',
          nombre: 'Ana Torres',
          tipo: 'Persona',
          telefono: '987654321',
          dni: '',
          ruc: '',
          direccion: '',
          referencia: '',
          fotoUbicacionPath: null,
          activo: true,
          pedidosCount: 0,
          ultimoPedido: null,
          observaciones: '',
          fechaRegistro: fechaRegistro,
          ultimaActualizacion: null,
        ),
      );
    });

    test('preserva columnas, fechas y fallback de empresa por RUC', () {
      final fechaRegistro = DateTime(2025, 1, 10, 8);
      final ultimaActualizacion = DateTime(2026, 7, 3, 9, 15);
      final ultimoPedido = DateTime(2026, 7, 2, 16, 45);
      final entity = ClienteMapper.toEntity(
        ClienteLocalModel.fromRow({
          'id': 'cliente-2',
          'nombre': 'Comercial del Sur',
          'tipo': null,
          'telefono': '054123456',
          'dni': '12345678',
          'ruc': '20123456789',
          'direccion': 'Av. Principal 123',
          'referencia': 'Frente a la plaza',
          'foto_ubicacion_path': 'clientes/cliente-2.jpg',
          'activo': 0,
          'pedidos_count': 7,
          'ultimo_pedido': ultimoPedido.toIso8601String(),
          'observaciones': 'Llamar antes de entregar',
          'creado_en': fechaRegistro.toIso8601String(),
          'actualizado_en': ultimaActualizacion.toIso8601String(),
        }),
      );

      expect(
        entity,
        Cliente(
          id: 'cliente-2',
          nombre: 'Comercial del Sur',
          tipo: 'Empresa',
          telefono: '054123456',
          dni: '12345678',
          ruc: '20123456789',
          direccion: 'Av. Principal 123',
          referencia: 'Frente a la plaza',
          fotoUbicacionPath: 'clientes/cliente-2.jpg',
          activo: false,
          pedidosCount: 7,
          ultimoPedido: ultimoPedido,
          observaciones: 'Llamar antes de entregar',
          fechaRegistro: fechaRegistro,
          ultimaActualizacion: ultimaActualizacion,
        ),
      );
    });

    test('convierte NuevoCliente al mismo mapa de persistencia', () {
      const cliente = NuevoCliente(
        nombre: 'María Pérez',
        tipo: 'Persona',
        telefono: '999888777',
        dni: '44556677',
        ruc: '',
        direccion: 'Calle Uno 100',
        referencia: 'Puerta azul',
        fotoUbicacionPath: 'clientes/maria.jpg',
        activo: false,
        observaciones: 'Cliente nuevo',
      );

      expect(ClienteMapper.nuevoClienteToMap(cliente), {
        'nombre': 'María Pérez',
        'tipo': 'Persona',
        'telefono': '999888777',
        'dni': '44556677',
        'ruc': '',
        'tipo_entrega': 'entrega',
        'direccion': 'Calle Uno 100',
        'referencia': 'Puerta azul',
        'foto_ubicacion_path': 'clientes/maria.jpg',
        'activo': 0,
        'observaciones': 'Cliente nuevo',
      });
    });
  });

  group('ClientePedidoResumenMapper', () {
    test('convierte una fila conservando total, estado y fecha', () {
      final fecha = DateTime(2026, 7, 20, 14, 5);
      final entity = ClientePedidoResumenMapper.toEntity(
        ClientePedidoResumenLocalModel.fromRow({
          'id': 'pedido-1',
          'codigo': 'PED-0001',
          'creado_en': fecha.toIso8601String(),
          'estado': 'Pendiente',
          'cantidad_productos': 3,
          'subtotal_conocido': 125,
          'total_parcial': 1,
        }),
      );

      expect(
        entity,
        ClientePedidoResumen(
          id: 'pedido-1',
          codigo: 'PED-0001',
          fecha: fecha,
          estado: 'Pendiente',
          cantidadProductos: 3,
          total: 125.0,
          totalParcial: true,
        ),
      );
    });

    test('mantiene los defaults de agregados ausentes', () {
      final fecha = DateTime(2026, 7, 21);
      final entity = ClientePedidoResumenMapper.toEntity(
        ClientePedidoResumenLocalModel.fromRow({
          'id': 'pedido-2',
          'codigo': 'PED-0002',
          'creado_en': fecha.toIso8601String(),
          'estado': 'Registrado',
        }),
      );

      expect(
        entity,
        ClientePedidoResumen(
          id: 'pedido-2',
          codigo: 'PED-0002',
          fecha: fecha,
          estado: 'Registrado',
          cantidadProductos: 0,
          total: 0,
          totalParcial: false,
        ),
      );
    });
  });
}
