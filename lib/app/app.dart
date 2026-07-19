import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/database/app_database.dart';
import '../features/catalogo/data/datasources/catalogo_local_datasource.dart';
import '../features/catalogo/data/datasources/catalogo_remote_datasource.dart';
import '../features/catalogo/data/repositories/catalogo_repository_impl.dart';
import '../features/catalogo/domain/repositories/catalogo_repository.dart';
import '../features/catalogo/presentation/bloc/catalogo_bloc.dart';
import '../features/catalogo/presentation/bloc/catalogo_event.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/home/presentation/bloc/home_event.dart';
import '../features/pedidos/data/datasources/pedidos_local_datasource.dart';
import '../features/pedidos/data/repositories/pedidos_repository_impl.dart';
import '../features/pedidos/domain/repositories/pedidos_repository.dart';
import 'navigation/main_shell_page.dart';

class AppCatalogo extends StatelessWidget {
  const AppCatalogo({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogoRepository = CatalogoRepositoryImpl(
      localDatasource: CatalogoLocalDatasource(AppDatabase.instance),
      remoteDatasource: CatalogoRemoteDatasource(),
    );
    final pedidosRepository = PedidosRepositoryImpl(
      PedidosLocalDatasource(AppDatabase.instance),
    );
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogoRepository>.value(value: catalogoRepository),
        RepositoryProvider<PedidosRepository>.value(value: pedidosRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                HomeBloc(pedidosRepository)..add(const HomeStarted()),
          ),
          BlocProvider(
            create: (_) =>
                CatalogoBloc(catalogoRepository)..add(const CatalogoStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'App Catálogo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          home: const MainShellPage(),
        ),
      ),
    );
  }
}
