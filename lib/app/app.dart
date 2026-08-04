import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/catalogo/domain/repositories/catalogo_repository.dart';
import '../features/catalogo/presentation/bloc/catalogo/catalogo_bloc.dart';
import '../features/catalogo/presentation/bloc/catalogo/catalogo_event.dart';
import '../features/clientes/domain/repositories/clientes_repository.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/estructura_catalogo/domain/repositories/estructura_catalogo_repository.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/home/presentation/bloc/home_event.dart';
import '../features/hojas_pedido/domain/repositories/hojas_pedido_repository.dart';
import '../features/pedidos/domain/repositories/pedidos_repository.dart';
import '../features/sync/domain/repositories/sync_repository.dart';
import 'di/app_dependencies.dart';
import 'navigation/main_shell_page.dart';

class AppCatalogo extends StatelessWidget {
  const AppCatalogo({
    this.initialSession = AuthSession.legacyAdministrator,
    super.key,
  });

  final AuthSession initialSession;

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.create(session: initialSession);
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogoRepository>.value(
          value: dependencies.catalogoRepository,
        ),
        RepositoryProvider<PedidosRepository>.value(
          value: dependencies.pedidosRepository,
        ),
        RepositoryProvider<ClientesRepository>.value(
          value: dependencies.clientesRepository,
        ),
        RepositoryProvider<HojasPedidoRepository>.value(
          value: dependencies.hojasPedidoRepository,
        ),
        RepositoryProvider<EstructuraCatalogoRepository>.value(
          value: dependencies.estructuraCatalogoRepository,
        ),
        RepositoryProvider<DashboardRepository>.value(
          value: dependencies.dashboardRepository,
        ),
        RepositoryProvider<SyncRepository>.value(
          value: dependencies.syncRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                HomeBloc(dependencies.pedidosRepository)
                  ..add(const HomeStarted()),
          ),
          BlocProvider(
            create: (_) =>
                CatalogoBloc(dependencies.catalogoRepository)
                  ..add(const CatalogoStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'App Catálogo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          home: MainShellPage(session: dependencies.session),
        ),
      ),
    );
  }
}
