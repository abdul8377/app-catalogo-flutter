import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/repositories/clientes_repository.dart';

class ClienteSelector extends StatefulWidget {
  const ClienteSelector({
    required this.onClienteSeleccionado,
    this.clienteSeleccionadoId,
    this.titulo = 'Seleccionar cliente existente',
    super.key,
  });

  final ValueChanged<Cliente> onClienteSeleccionado;
  final String? clienteSeleccionadoId;
  final String titulo;

  @override
  State<ClienteSelector> createState() => _ClienteSelectorState();
}

class _ClienteSelectorState extends State<ClienteSelector> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final _searchCtrl = TextEditingController();
  List<Cliente> _clientes = const [];
  bool _loading = true;
  String? _error;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String query) async {
    final token = ++_searchToken;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clientes = await context
          .read<ClientesRepository>()
          .obtenerClientes();
      if (!mounted || token != _searchToken) return;
      final text = query.trim().toLowerCase();
      setState(() {
        _loading = false;
        _clientes = text.isEmpty
            ? clientes
            : clientes.where((cliente) {
                final dni = cliente.dni ?? '';
                final ruc = cliente.ruc ?? '';
                final direccion = cliente.direccion ?? '';
                return cliente.nombre.toLowerCase().contains(text) ||
                    cliente.telefono.contains(text) ||
                    dni.contains(text) ||
                    ruc.contains(text) ||
                    direccion.toLowerCase().contains(text);
              }).toList();
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los clientes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.titulo,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, DNI, RUC o teléfono',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _buscar('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _buscar(value);
        },
      ),
      const SizedBox(height: 12),
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null)
        _message(_error!, Icons.error_outline, Colors.redAccent)
      else if (_clientes.isEmpty)
        _message(
          'No se encontraron clientes registrados.',
          Icons.person_search_outlined,
          Colors.grey,
        )
      else
        ..._clientes.take(8).map(_clienteTile),
    ],
  );

  Widget _clienteTile(Cliente cliente) {
    final selected = cliente.id == widget.clienteSeleccionadoId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? primaryColor.withValues(alpha: .12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onClienteSeleccionado(cliente),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primaryColor : const Color(0xFFEDEDED),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cliente.activo
                        ? primaryColor.withValues(alpha: .2)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      cliente.iniciales,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: cliente.activo ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cliente.telefono} • ${_documento(cliente)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      if ((cliente.direccion ?? '').isNotEmpty)
                        Text(
                          cliente.direccion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: primaryColor)
                else
                  const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String text, IconData icon, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEDEDED)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(color: const Color(0xFF757575)),
          ),
        ),
      ],
    ),
  );

  String _documento(Cliente cliente) {
    final ruc = cliente.ruc ?? '';
    if (ruc.isNotEmpty) return 'RUC: $ruc';
    final dni = cliente.dni ?? '';
    if (dni.isNotEmpty) return 'DNI: $dni';
    return cliente.tipo;
  }
}
