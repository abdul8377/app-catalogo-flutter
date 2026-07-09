import 'package:flutter/material.dart';

class HojasPedidoPage extends StatelessWidget {
  const HojasPedidoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Hojas de pedido',
      description: 'Crear, seleccionar y completar hojas de pedido.',
      icon: Icons.assignment_outlined,
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _SimplePage({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 42),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '$title\n$description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}