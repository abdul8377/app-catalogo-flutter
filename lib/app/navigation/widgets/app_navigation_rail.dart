import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/app_destination.dart';

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onToggleExpansion,
    this.isAdministrator = true,
    this.allowedDestinations,
    this.userName = 'Alfonzo Esteban',
    this.roleLabel,
    super.key,
  });

  final bool isExpanded;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExpansion;
  final bool isAdministrator;
  final Set<AppDestination>? allowedDestinations;
  final String userName;
  final String? roleLabel;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFC500);
    const railCollapsedWidth = 72.0;
    const railExpandedWidth = 220.0;

    final allItems = <_NavItem>[
      _NavItem(
        destination: AppDestination.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Inicio',
      ),
      _NavItem(
        destination: AppDestination.catalogo,
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Catálogo',
      ),
      _NavItem(
        destination: AppDestination.clientes,
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Clientes',
      ),
      _NavItem(
        destination: AppDestination.nuevoPedido,
        icon: Icons.add_shopping_cart_outlined,
        activeIcon: Icons.add_shopping_cart,
        label: 'Nuevo pedido',
      ),
      _NavItem(
        destination: AppDestination.pedidos,
        icon: Icons.list_alt,
        activeIcon: Icons.list_alt,
        label: 'Pedidos',
      ),
      _NavItem(
        destination: AppDestination.hojasPedido,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Hojas de pedido',
      ),
      _NavItem(
        destination: AppDestination.dashboard,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      const _NavItem(
        destination: AppDestination.estructuraCatalogo,
        icon: Icons.account_tree_outlined,
        activeIcon: Icons.account_tree,
        label: 'Estructura del catálogo',
      ),
    ];
    final effectiveDestinations =
        allowedDestinations ??
        (isAdministrator
            ? AppDestination.values.toSet()
            : AppDestination.values
                  .where(
                    (destination) =>
                        destination != AppDestination.estructuraCatalogo,
                  )
                  .toSet());
    final items = allItems
        .where((item) => effectiveDestinations.contains(item.destination))
        .toList();

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
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final navigationIndex = item.destination.navigationIndex;

                    return _NavRailItem(
                      item: item,
                      isSelected: selectedIndex == navigationIndex,
                      isExpanded: showExpandedContent,
                      primaryColor: primaryColor,
                      onTap: () => onItemSelected(navigationIndex),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
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
                  userName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleLabel ?? (isAdministrator ? 'Administrador' : 'Vendedor'),
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
    required this.destination,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final AppDestination destination;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
