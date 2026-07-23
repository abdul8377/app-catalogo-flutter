import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/catalogo/presentation/pages/catalogo_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/hojas_pedido/presentation/pages/hojas_pedido_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/pedidos/presentation/pages/nuevo_pedido_page.dart';
import '../../features/pedidos/presentation/pages/pedidos_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int selectedIndex = 0;
  bool isRailExpanded = false;
  int _pedidosInitialTab = 0;
  String? _pedidosHojaCodigo;
  int _nuevoPedidoRevision = 0;
  int _pedidosRevision = 0;
  int _hojasRevision = 0;
  int _clientesRevision = 0;
  String? _clienteInicialId;
  String? _hojaInicialCodigo;

  List<Widget> _buildPages() {
    return [
      HomePage(onNavigate: _onItemSelected),
      const CatalogoPage(),
      ClientesPage(
        key: ValueKey('clientes-$_clientesRevision-$_clienteInicialId'),
        initialClienteId: _clienteInicialId,
      ),
      NuevoPedidoPage(key: ValueKey('nuevo-pedido-$_nuevoPedidoRevision')),
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
        onNavigate: _onItemSelected,
        onOpenPedidos: _openPedidos,
        initialHojaCodigo: _hojaInicialCodigo,
      ),
      const DashboardPage(),
    ];
  }

  void _toggleRailExpansion() {
    setState(() {
      isRailExpanded = !isRailExpanded;
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 0) {
        context.read<HomeBloc>().add(const HomeRefreshed());
      }
      if (index == 3) {
        _nuevoPedidoRevision++;
      }
      if (index == 2) {
        _clientesRevision++;
        _clienteInicialId = null;
      }
      if (index == 4) {
        _pedidosRevision++;
        _pedidosInitialTab = 0;
        _pedidosHojaCodigo = null;
      }
      if (index == 5) {
        _hojasRevision++;
        _hojaInicialCodigo = null;
      }
    });
  }

  void _openCliente(String clienteId) {
    setState(() {
      _clientesRevision++;
      _clienteInicialId = clienteId;
      selectedIndex = 2;
    });
  }

  void _openHoja(String hojaCodigo) {
    setState(() {
      _hojasRevision++;
      _hojaInicialCodigo = hojaCodigo;
      selectedIndex = 5;
    });
  }

  void _openPedidos(int tab, String hojaCodigo) {
    setState(() {
      _pedidosRevision++;
      _pedidosInitialTab = tab.clamp(0, 2);
      _pedidosHojaCodigo = hojaCodigo;
      selectedIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: AppNavigationRail(
              isExpanded: isRailExpanded,
              selectedIndex: selectedIndex,
              onItemSelected: _onItemSelected,
              onToggleExpansion: _toggleRailExpansion,
            ),
          ),
          Container(width: 1, color: const Color(0xFFE0E0E0)),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: _buildPages()),
          ),
        ],
      ),
    );
  }
}

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onToggleExpansion,
    super.key,
  });

  final bool isExpanded;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExpansion;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFC500);
    const railCollapsedWidth = 72.0;
    const railExpandedWidth = 220.0;

    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Inicio',
      ),
      _NavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Catálogo',
      ),
      _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Clientes',
      ),
      _NavItem(
        icon: Icons.add_shopping_cart_outlined,
        activeIcon: Icons.add_shopping_cart,
        label: 'Nuevo pedido',
      ),
      _NavItem(
        icon: Icons.list_alt,
        activeIcon: Icons.list_alt,
        label: 'Pedidos',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Hojas de pedido',
      ),
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isExpanded ? railExpandedWidth : railCollapsedWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // AnimatedContainer entrega anchos intermedios durante la transición.
          // El contenido ancho solo se muestra cuando realmente tiene espacio.
          final showExpandedContent = constraints.maxWidth >= 180;

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildToggleButton(primaryColor),
              const SizedBox(height: 32),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return _NavRailItem(
                  item: item,
                  isSelected: selectedIndex == index,
                  isExpanded: showExpandedContent,
                  primaryColor: primaryColor,
                  onTap: () => onItemSelected(index),
                );
              }),
              const Spacer(),
              if (showExpandedContent)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 16,
                    right: 16,
                  ),
                  child: _buildUserSection(),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(
                    Icons.account_circle,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleExpansion,
          child: Container(
            height: 44,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isExpanded
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isExpanded ? Icons.menu_open : Icons.menu,
                color: const Color(0xFF1A1A2E),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFC500).withValues(alpha: 0.2),
            child: Text(
              'CM',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Alfonzo Esteban',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Vendedor',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRailItem extends StatelessWidget {
  const _NavRailItem({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.primaryColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final bool isExpanded;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: isExpanded ? _buildExpandedItem() : _buildCollapsedItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedItem() {
    return Row(
      children: [
        Icon(
          isSelected ? item.activeIcon : item.icon,
          color: isSelected ? Colors.black : const Color(0xFF555555),
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            item.label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: isSelected ? Colors.black : const Color(0xFF555555),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSelected ? item.activeIcon : item.icon,
          color: isSelected ? Colors.black : const Color(0xFF555555),
          size: 22,
        ),
        if (isSelected) ...[
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
