import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/catalogo/presentation/pages/catalogo_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/estructura_catalogo/presentation/pages/estructura_catalogo_page.dart';
import '../../features/auth/domain/entities/app_permission.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/hojas_pedido/presentation/pages/hojas_pedido_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/pedidos/presentation/pages/nuevo_pedido_page.dart';
import '../../features/pedidos/presentation/pages/pedidos_page.dart';
import '../../core/navigation/app_destination.dart';
import 'app_destination_access_policy.dart';
import 'widgets/app_navigation_rail.dart';

export 'widgets/app_navigation_rail.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({this.isAdministrator = true, this.session, super.key});

  /// Adaptador histórico. Una sesión explícita tiene precedencia.
  final bool isAdministrator;
  final AuthSession? session;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late AppDestination selectedDestination;
  bool isRailExpanded = false;
  int _pedidosInitialTab = 0;
  String? _pedidosHojaCodigo;
  int _nuevoPedidoRevision = 0;
  int _pedidosRevision = 0;
  int _hojasRevision = 0;
  int _clientesRevision = 0;
  int _dashboardRevision = 0;
  late final Set<AppDestination> _mountedDestinations;
  String? _clienteInicialId;
  String? _hojaInicialCodigo;

  AuthSession get _session =>
      widget.session ??
      (widget.isAdministrator
          ? AuthSession.legacyAdministrator
          : AuthSession.legacySeller);

  Set<AppDestination> get _visibleDestinations =>
      AppDestinationAccessPolicy.visibleDestinations(_session);

  @override
  void initState() {
    super.initState();
    selectedDestination = _initialDestination();
    _mountedDestinations = <AppDestination>{selectedDestination};
  }

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AppDestinationAccessPolicy.canOpen(_session, selectedDestination)) {
      selectedDestination = _initialDestination();
      _mountedDestinations.add(selectedDestination);
    }
  }

  AppDestination _initialDestination() {
    final visible = _visibleDestinations;
    if (visible.contains(AppDestination.home)) return AppDestination.home;
    return AppDestination.values.firstWhere(
      visible.contains,
      orElse: () => AppDestination.home,
    );
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[
      HomePage(onNavigate: _onDestinationSelected),
      const CatalogoPage(),
      ClientesPage(
        key: ValueKey('clientes-$_clientesRevision-$_clienteInicialId'),
        initialClienteId: _clienteInicialId,
      ),
      NuevoPedidoPage(
        key: ValueKey('nuevo-pedido-$_nuevoPedidoRevision'),
        sellerName: _session.user.displayName,
      ),
      PedidosPage(
        key: ValueKey(
          'pedidos-$_pedidosRevision-$_pedidosInitialTab-$_pedidosHojaCodigo',
        ),
        initialTab: _pedidosInitialTab,
        initialHojaCodigo: _pedidosHojaCodigo,
        onOpenCliente: _openCliente,
        onOpenHoja: _openHoja,
      ),
      HojasPedidoPage(
        key: ValueKey('hojas-pedido-$_hojasRevision'),
        onNavigate: _onDestinationSelected,
        onOpenPedidos: _openPedidos,
        initialHojaCodigo: _hojaInicialCodigo,
        sellerName: _session.user.displayName,
      ),
      DashboardPage(
        key: ValueKey('dashboard-$_dashboardRevision'),
        onNavigate: _onDestinationSelected,
        onOpenPedidos: _openPedidos,
        onOpenHoja: _openHoja,
        onOpenCliente: _openCliente,
      ),
    ];
    if (AppDestinationAccessPolicy.canOpen(
      _session,
      AppDestination.estructuraCatalogo,
    )) {
      pages.add(const EstructuraCatalogoPage());
    }
    return pages;
  }

  void _toggleRailExpansion() {
    setState(() {
      isRailExpanded = !isRailExpanded;
    });
  }

  void _onRailItemSelected(int index) {
    final destination = AppDestination.tryFromIndex(index);
    if (destination == null) return;
    _onDestinationSelected(destination);
  }

  void _onDestinationSelected(AppDestination destination) {
    if (!AppDestinationAccessPolicy.canOpen(_session, destination)) return;
    setState(() {
      selectedDestination = destination;
      _mountedDestinations.add(destination);
      switch (destination) {
        case AppDestination.home:
          context.read<HomeBloc>().add(const HomeRefreshed());
        case AppDestination.catalogo:
          break;
        case AppDestination.clientes:
          _clientesRevision++;
          _clienteInicialId = null;
        case AppDestination.nuevoPedido:
          _nuevoPedidoRevision++;
        case AppDestination.pedidos:
          _pedidosRevision++;
          _pedidosInitialTab = 0;
          _pedidosHojaCodigo = null;
        case AppDestination.hojasPedido:
          _hojasRevision++;
          _hojaInicialCodigo = null;
        case AppDestination.dashboard:
          _dashboardRevision++;
        case AppDestination.estructuraCatalogo:
          break;
      }
    });
  }

  void _openCliente(String clienteId) {
    if (!AppDestinationAccessPolicy.canOpen(
      _session,
      AppDestination.clientes,
    )) {
      return;
    }
    setState(() {
      _clientesRevision++;
      _clienteInicialId = clienteId;
      _mountedDestinations.add(AppDestination.clientes);
      selectedDestination = AppDestination.clientes;
    });
  }

  void _openHoja(String hojaCodigo) {
    if (!AppDestinationAccessPolicy.canOpen(
      _session,
      AppDestination.hojasPedido,
    )) {
      return;
    }
    setState(() {
      _hojasRevision++;
      _hojaInicialCodigo = hojaCodigo;
      _mountedDestinations.add(AppDestination.hojasPedido);
      selectedDestination = AppDestination.hojasPedido;
    });
  }

  void _openPedidos(int tab, String hojaCodigo) {
    if (!AppDestinationAccessPolicy.canOpen(_session, AppDestination.pedidos)) {
      return;
    }
    setState(() {
      _pedidosRevision++;
      _pedidosInitialTab = tab.clamp(0, 2);
      _pedidosHojaCodigo = hojaCodigo;
      _mountedDestinations.add(AppDestination.pedidos);
      selectedDestination = AppDestination.pedidos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: AppNavigationRail(
              isExpanded: isRailExpanded,
              selectedIndex: selectedDestination.navigationIndex,
              onItemSelected: _onRailItemSelected,
              onToggleExpansion: _toggleRailExpansion,
              isAdministrator: _session.hasPermission(
                AppPermission.manageCatalogStructure,
              ),
              allowedDestinations: _visibleDestinations,
              userName: _session.user.displayName,
              roleLabel: _session.primaryRoleName,
            ),
          ),
          Container(width: 1, color: const Color(0xFFE0E0E0)),
          Expanded(
            child: IndexedStack(
              index: selectedDestination.navigationIndex,
              children: List<Widget>.generate(pages.length, (index) {
                final destination = AppDestination.tryFromIndex(index)!;
                final mounted = _mountedDestinations.contains(destination);
                return HeroMode(
                  enabled: destination == selectedDestination,
                  child: mounted ? pages[index] : const SizedBox.shrink(),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
