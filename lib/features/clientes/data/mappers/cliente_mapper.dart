import '../../domain/entities/cliente.dart';
import '../../domain/entities/nuevo_cliente.dart';
import '../models/cliente_local_model.dart';

abstract final class ClienteMapper {
  static Cliente toEntity(ClienteLocalModel model) => Cliente(
    id: model.id,
    nombre: model.nombre,
    tipo: model.tipo,
    telefono: model.telefono,
    dni: model.dni,
    ruc: model.ruc,
    direccion: model.direccion,
    referencia: model.referencia,
    fotoUbicacionPath: model.fotoUbicacionPath,
    activo: model.activo,
    pedidosCount: model.pedidosCount,
    ultimoPedido: model.ultimoPedido,
    observaciones: model.observaciones,
    fechaRegistro: model.fechaRegistro,
    ultimaActualizacion: model.ultimaActualizacion,
  );

  static Map<String, Object?> nuevoClienteToMap(NuevoCliente cliente) => {
    'nombre': cliente.nombre,
    'tipo': cliente.tipo,
    'telefono': cliente.telefono,
    'dni': cliente.dni,
    'ruc': cliente.ruc,
    'tipo_entrega': 'entrega',
    'direccion': cliente.direccion,
    'referencia': cliente.referencia,
    'foto_ubicacion_path': cliente.fotoUbicacionPath,
    'activo': cliente.activo ? 1 : 0,
    'observaciones': cliente.observaciones,
  };
}
