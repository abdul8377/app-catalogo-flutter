import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/cotizacion_pedido.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/entities/pedido_preparacion.dart';
import '../../domain/entities/pedido_resumen.dart';
import '../../domain/entities/producto_consolidado.dart';
import '../../domain/entities/resumen_hoy.dart';

part '../models/pedido_preparacion_builder.dart';
part '../models/producto_consolidado_builder.dart';
part 'pedidos/carga_sincronizacion_local_datasource.dart';
part 'pedidos/clientes_busqueda_local_datasource.dart';
part 'pedidos/clientes_persistencia.dart';
part 'pedidos/consolidado_local_datasource.dart';
part 'pedidos/cotizaciones_consulta_local_datasource.dart';
part 'pedidos/cotizaciones_escritura_local_datasource.dart';
part 'pedidos/cotizaciones_mapping.dart';
part 'pedidos/pedidos_consulta_local_datasource.dart';
part 'pedidos/pedidos_creacion_local_datasource.dart';
part 'pedidos/pedidos_detalle_mapping.dart';
part 'pedidos/pedidos_edicion_local_datasource.dart';
part 'pedidos/pedidos_estado_helpers.dart';
part 'pedidos/pedidos_estado_local_datasource.dart';
part 'pedidos/pedidos_operacion_helpers.dart';
part 'pedidos/pedidos_resumen_mapping.dart';
part 'pedidos/preparacion_estado_local_datasource.dart';
part 'pedidos/preparacion_local_datasource.dart';
part 'pedidos/preparacion_mapping.dart';
part 'pedidos/preparacion_queries.dart';
part 'pedidos/resumen_hoja_local_datasource.dart';

class PedidosLocalDatasource {
  const PedidosLocalDatasource(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;
}
