import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PedidosBuscador extends StatefulWidget {
  const PedidosBuscador({
    required this.busqueda,
    required this.onChanged,
    super.key,
  });

  final String busqueda;
  final ValueChanged<String> onChanged;

  @override
  State<PedidosBuscador> createState() => _PedidosBuscadorState();
}

class _PedidosBuscadorState extends State<PedidosBuscador> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.busqueda);
  }

  @override
  void didUpdateWidget(covariant PedidosBuscador oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busqueda != _controller.text) {
      _controller.text = widget.busqueda;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText:
            'Buscar por pedido, cliente, producto, teléfono o dirección...',
        hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
        suffixIcon: widget.busqueda.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}
