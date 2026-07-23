import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PedidosTabs extends StatelessWidget {
  const PedidosTabs({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  static const primaryColor = Color(0xFFFFC500);

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = const [
      'Pedidos',
      'Consolidado de productos',
      'Preparación y carga',
    ];
    final icons = const [
      Icons.receipt_long,
      Icons.inventory,
      Icons.local_shipping,
    ];

    return Row(
      children: List.generate(labels.length, (index) {
        final isSelected = currentIndex == index;
        return Expanded(
          child: GestureDetector(
            key: ValueKey('pedidos_tab_$index'),
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.white.withValues(alpha: .3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 18,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
