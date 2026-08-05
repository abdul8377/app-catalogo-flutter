import '../../core/database/app_database.dart';
import '../../features/catalogo/data/datasources/catalogo_local_datasource.dart';
import '../../features/catalogo/data/repositories/catalogo_repository_impl.dart';
import '../../features/catalogo/domain/repositories/catalogo_repository.dart';
import '../../features/clientes/data/datasources/clientes_local_datasource.dart';
import '../../features/clientes/data/repositories/clientes_repository_impl.dart';
import '../../features/clientes/domain/repositories/clientes_repository.dart';
import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/estructura_catalogo/data/datasources/estructura_catalogo_local_datasource.dart';
import '../../features/estructura_catalogo/data/repositories/estructura_catalogo_repository_impl.dart';
import '../../features/estructura_catalogo/domain/repositories/estructura_catalogo_repository.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/hojas_pedido/data/datasources/hojas_pedido_local_datasource.dart';
import '../../features/hojas_pedido/data/repositories/hojas_pedido_repository_impl.dart';
import '../../features/hojas_pedido/domain/repositories/hojas_pedido_repository.dart';
import '../../features/pedidos/data/datasources/pedidos_local_datasource.dart';
import '../../features/pedidos/data/repositories/pedidos_repository_impl.dart';
import '../../features/pedidos/domain/repositories/pedidos_repository.dart';
import '../../features/sync/data/datasources/sync_discovery_datasource.dart';
import '../../features/sync/data/datasources/sync_local_datasource.dart';
import '../../features/sync/data/datasources/sync_remote_datasource.dart';
import '../../features/sync/data/datasources/sync_secure_credentials_datasource.dart';
import '../../features/sync/data/mappers/product_sync_backup_mapper.dart';
import '../../features/sync/data/mappers/sync_entity_registry.dart';
import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/domain/repositories/sync_repository.dart';

/// Raíz de composición de repositorios y fuentes de datos de la aplicación.
class AppDependencies {
  const AppDependencies._({
    required this.catalogoRepository,
    required this.pedidosRepository,
    required this.clientesRepository,
    required this.hojasPedidoRepository,
    required this.estructuraCatalogoRepository,
    required this.dashboardRepository,
    required this.syncRepository,
    required this.session,
  });

  factory AppDependencies.create({
    AppDatabase? database,
    AuthSession session = AuthSession.legacyAdministrator,
  }) {
    final appDatabase = database ?? AppDatabase.instance;
    final catalogoRepository = CatalogoRepositoryImpl(
      CatalogoLocalDatasource(appDatabase),
    );
    final pedidosRepository = PedidosRepositoryImpl(
      PedidosLocalDatasource(appDatabase),
    );
    final clientesRepository = ClientesRepositoryImpl(
      ClientesLocalDatasource(appDatabase),
    );
    final hojasPedidoRepository = HojasPedidoRepositoryImpl(
      HojasPedidoLocalDatasource(appDatabase),
    );
    final estructuraCatalogoRepository = EstructuraCatalogoRepositoryImpl(
      EstructuraCatalogoLocalDatasource(appDatabase),
    );
    final dashboardRepository = DashboardRepositoryImpl(
      DashboardLocalDatasource(appDatabase),
      pedidosRepository,
    );
    final syncRepository = SyncRepositoryImpl(
      SyncLocalDatasource(
        appDatabase,
        const SyncEntityRegistry(ProductSyncBackupMapper()),
      ),
      SyncRemoteDatasource(),
      SyncSecureCredentialsDatasource.create(),
      const SyncDiscoveryDatasource(),
    );

    return AppDependencies._(
      catalogoRepository: catalogoRepository,
      pedidosRepository: pedidosRepository,
      clientesRepository: clientesRepository,
      hojasPedidoRepository: hojasPedidoRepository,
      estructuraCatalogoRepository: estructuraCatalogoRepository,
      dashboardRepository: dashboardRepository,
      syncRepository: syncRepository,
      session: session,
    );
  }

  final CatalogoRepository catalogoRepository;
  final PedidosRepository pedidosRepository;
  final ClientesRepository clientesRepository;
  final HojasPedidoRepository hojasPedidoRepository;
  final EstructuraCatalogoRepository estructuraCatalogoRepository;
  final DashboardRepository dashboardRepository;
  final SyncRepository syncRepository;
  final AuthSession session;
}
