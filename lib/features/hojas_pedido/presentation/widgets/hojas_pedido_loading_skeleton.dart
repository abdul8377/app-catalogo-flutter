import 'package:flutter/material.dart';

class HojasPedidoLoadingSkeleton extends StatelessWidget {
  const HojasPedidoLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _block(290, 20),
      const SizedBox(height: 16),
      SizedBox(
        height: 90,
        child: Row(
          children: [
            Expanded(child: _block(90, 16)),
            const SizedBox(width: 10),
            Expanded(child: _block(90, 16)),
            const SizedBox(width: 10),
            Expanded(child: _block(90, 16)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _block(180, 20),
      const SizedBox(height: 20),
      _block(140, 20),
    ],
  );

  Widget _block(double height, double radius) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE8E8E8),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
