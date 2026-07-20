import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientesFiltros extends StatefulWidget {
  const ClientesFiltros({
    required this.busqueda,
    required this.filtrosRapidos,
    required this.ordenSeleccionado,
    required this.onBusquedaCambiada,
    required this.onFiltroRapido,
    required this.onFiltrosAplicados,
    required this.onOrdenCambiado,
    super.key,
  });

  final String busqueda;
  final Set<String> filtrosRapidos;
  final String ordenSeleccionado;
  final ValueChanged<String> onBusquedaCambiada;
  final ValueChanged<String> onFiltroRapido;
  final ValueChanged<String> onFiltrosAplicados;
  final ValueChanged<String> onOrdenCambiado;

  @override
  State<ClientesFiltros> createState() => _ClientesFiltrosState();
}

class _ClientesFiltrosState extends State<ClientesFiltros> {
  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.busqueda);
  }

  @override
  void didUpdateWidget(covariant ClientesFiltros oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busqueda != _searchCtrl.text) {
      _searchCtrl.text = widget.busqueda;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: widget.onBusquedaCambiada,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, teléfono, DNI o RUC...',
            hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
            suffixIcon: widget.busqueda.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      widget.onBusquedaCambiada('');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      Container(
        color: Colors.white,
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children:
              const [
                'Todos',
                'Activos',
                'Inactivos',
                'Con pedidos',
                'Sin pedidos',
              ].map((filtro) {
                final seleccionado = widget.filtrosRapidos.contains(filtro);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: FilterChip(
                    label: Text(
                      filtro,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: seleccionado ? Colors.black : darkColor,
                      ),
                    ),
                    selected: seleccionado,
                    onSelected: (_) => widget.onFiltroRapido(filtro),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: primaryColor,
                    checkmarkColor: Colors.black,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _mostrarFiltrosAvanzados,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  'Filtros avanzados',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkColor,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _mostrarOrdenamiento,
                icon: const Icon(Icons.sort, size: 18),
                label: Text(
                  'Ordenar',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkColor,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _mostrarFiltrosAvanzados() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _FiltrosAvanzadosClientesDialog(
        ordenSeleccionado: widget.ordenSeleccionado,
      ),
    );
    if (result == null) return;
    widget.onFiltrosAplicados(result);
  }

  Future<void> _mostrarOrdenamiento() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ordenar clientes'),
        children: [
          for (final option in _ordenes)
            ListTile(
              leading: Icon(
                widget.ordenSeleccionado == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: widget.ordenSeleccionado == option
                    ? primaryColor
                    : const Color(0xFF757575),
              ),
              title: Text(option),
              selected: widget.ordenSeleccionado == option,
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
    if (value != null) widget.onOrdenCambiado(value);
  }
}

const _ordenes = [
  'Nombre A-Z',
  'Nombre Z-A',
  'Más recientes',
  'Mayor cantidad de pedidos',
];

class _FiltrosAvanzadosClientesDialog extends StatefulWidget {
  const _FiltrosAvanzadosClientesDialog({required this.ordenSeleccionado});

  final String ordenSeleccionado;

  @override
  State<_FiltrosAvanzadosClientesDialog> createState() =>
      _FiltrosAvanzadosClientesDialogState();
}

class _FiltrosAvanzadosClientesDialogState
    extends State<_FiltrosAvanzadosClientesDialog> {
  late String _orden;

  @override
  void initState() {
    super.initState();
    _orden = widget.ordenSeleccionado;
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros avanzados',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _orden,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: _ordenes
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _orden = value ?? 'Nombre A-Z'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'Nombre A-Z'),
                    child: const Text('Limpiar filtros'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _orden),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC500),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
