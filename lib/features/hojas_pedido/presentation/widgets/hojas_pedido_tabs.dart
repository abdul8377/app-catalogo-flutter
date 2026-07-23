import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HojasPedidoTabs extends StatelessWidget {
  const HojasPedidoTabs({
    required this.currentTab,
    required this.onChanged,
    super.key,
  });

  final int currentTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Hoja activa', 'Historial'];
    const icons = [Icons.description_outlined, Icons.history];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = currentTab == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFC500)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFC500)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[index],
                        size: 18,
                        color: selected ? Colors.black : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labels[index],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
