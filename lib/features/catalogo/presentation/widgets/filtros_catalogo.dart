import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/catalogo_state.dart';

class FiltrosCatalogo extends StatefulWidget {
  const FiltrosCatalogo({
    required this.state,
    required this.onBusquedaCambiada,
    required this.onFiltroRapido,
    required this.onFiltrosAplicados,
    required this.onFiltrosLimpiados,
    super.key,
  });

  final CatalogoState state;
  final ValueChanged<String> onBusquedaCambiada;
  final ValueChanged<String> onFiltroRapido;
  final ValueChanged<CatalogoFiltros> onFiltrosAplicados;
  final VoidCallback onFiltrosLimpiados;

  @override
  State<FiltrosCatalogo> createState() => _FiltrosCatalogoState();
}

class _FiltrosCatalogoState extends State<FiltrosCatalogo> {
  late final TextEditingController _busqueda;

  @override
  void initState() {
    super.initState();
    _busqueda = TextEditingController(text: widget.state.busqueda);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _busqueda,
            onChanged: widget.onBusquedaCambiada,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código, marca o atributo…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.state.busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _busqueda.clear();
                        widget.onBusquedaCambiada('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _filtrosRapidos.map((filtro) {
              final selected = widget.state.filtrosRapidos.contains(filtro);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                child: FilterChip(
                  label: Text(filtro),
                  selected: selected,
                  onSelected: (_) => widget.onFiltroRapido(filtro),
                  selectedColor: const Color(0xFFFFC500),
                  checkmarkColor: Colors.black,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('abrir_filtros_avanzados'),
                  onPressed: _abrirFiltros,
                  icon: Badge(
                    isLabelVisible: widget.state.filtros.tieneActivos,
                    child: const Icon(Icons.filter_list, size: 18),
                  ),
                  label: const Text('Filtros avanzados'),
                  style: _buttonStyle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('abrir_ordenamiento'),
                  onPressed: _abrirOrden,
                  icon: const Icon(Icons.sort, size: 18),
                  label: Text(
                    MediaQuery.sizeOf(context).width < 520
                        ? 'Ordenar'
                        : widget.state.filtros.orden,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: _buttonStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  ButtonStyle get _buttonStyle => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1F1F1F),
    side: const BorderSide(color: Color(0xFFE0E0E0)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Future<void> _abrirFiltros() async {
    final result = await showDialog<CatalogoFiltros>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _FiltrosAvanzadosDialog(
        inicial: widget.state.filtros,
        empresas: widget.state.empresas,
        marcas: widget.state.marcas,
        categorias: widget.state.categorias,
      ),
    );
    if (result != null) widget.onFiltrosAplicados(result);
  }

  Future<void> _abrirOrden() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          _OrdenamientoDialog(ordenActual: widget.state.filtros.orden),
    );
    if (result != null) {
      final f = widget.state.filtros;
      widget.onFiltrosAplicados(
        CatalogoFiltros(
          empresa: f.empresa,
          marca: f.marca,
          categoria: f.categoria,
          estado: f.estado,
          precio: f.precio,
          imagen: f.imagen,
          orden: result,
        ),
      );
    }
  }

  static const _filtrosRapidos = [
    'Todos',
    'Activos',
    'Inactivos',
    'Con precio',
    'Sin precio',
    'Con imagen',
    'Sin imagen',
    'Con variantes',
    'Sin variantes',
  ];
}

class _FiltrosAvanzadosDialog extends StatefulWidget {
  const _FiltrosAvanzadosDialog({
    required this.inicial,
    required this.empresas,
    required this.marcas,
    required this.categorias,
  });
  final CatalogoFiltros inicial;
  final List<String> empresas, marcas, categorias;

  @override
  State<_FiltrosAvanzadosDialog> createState() =>
      _FiltrosAvanzadosDialogState();
}

class _FiltrosAvanzadosDialogState extends State<_FiltrosAvanzadosDialog> {
  String? empresa, marca, categoria, estado, precio, imagen;
  late String orden;

  @override
  void initState() {
    super.initState();
    final f = widget.inicial;
    empresa = f.empresa;
    marca = f.marca;
    categoria = f.categoria;
    estado = f.estado;
    precio = f.precio;
    imagen = f.imagen;
    orden = f.orden;
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filtros avanzados',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 520
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        _tile(
                          fieldWidth,
                          Icons.business,
                          'Empresa',
                          empresa,
                          widget.empresas,
                          (v) => empresa = v,
                        ),
                        _tile(
                          fieldWidth,
                          Icons.bookmark_outline,
                          'Marca',
                          marca,
                          widget.marcas,
                          (v) => marca = v,
                        ),
                        _tile(
                          fieldWidth,
                          Icons.category_outlined,
                          'Categoría',
                          categoria,
                          widget.categorias,
                          (v) => categoria = v,
                        ),
                        _tile(
                          fieldWidth,
                          Icons.toggle_on_outlined,
                          'Estado',
                          estado,
                          const ['Activo', 'Inactivo'],
                          (v) => estado = v,
                        ),
                        _tile(
                          fieldWidth,
                          Icons.attach_money,
                          'Precio',
                          precio,
                          const ['Con precio', 'Sin precio'],
                          (v) => precio = v,
                        ),
                        _tile(
                          fieldWidth,
                          Icons.image_outlined,
                          'Imagen',
                          imagen,
                          const ['Con imagen', 'Sin imagen'],
                          (v) => imagen = v,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, const CatalogoFiltros()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF757575),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        backgroundColor: const Color(0xFFF8F9FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Limpiar todo'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        CatalogoFiltros(
                          empresa: empresa,
                          marca: marca,
                          categoria: categoria,
                          estado: estado,
                          precio: precio,
                          imagen: imagen,
                          orden: orden,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC500),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shadowColor: const Color(
                          0xFFFFC500,
                        ).withValues(alpha: .4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tile(
    double width,
    IconData icon,
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool allowAll = true,
  }) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF757575)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(allowAll ? 'Todos' : 'Seleccionar'),
          items: [
            if (allowAll)
              const DropdownMenuItem(value: '__todos__', child: Text('Todos')),
            ...items.map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (selected) => setState(
            () => onChanged(selected == '__todos__' ? null : selected),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrdenamientoDialog extends StatelessWidget {
  const _OrdenamientoDialog({required this.ordenActual});
  final String ordenActual;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC500),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ordenar productos',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: _opcionesOrden.map((opcion) {
                  final selected = ordenActual == opcion.title;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, opcion.title),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFFC500).withValues(alpha: .11)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFFC500)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(
                                        0xFFFFC500,
                                      ).withValues(alpha: .2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                opcion.icon,
                                size: 20,
                                color: const Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opcion.title,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opcion.subtitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFFFC500),
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFBDBDBD),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrdenOpcion {
  const _OrdenOpcion(this.title, this.icon, this.subtitle);
  final String title;
  final IconData icon;
  final String subtitle;
}

const _opcionesOrden = [
  _OrdenOpcion('Nombre A-Z', Icons.sort_by_alpha, 'Alfabético ascendente'),
  _OrdenOpcion('Nombre Z-A', Icons.sort_by_alpha, 'Alfabético descendente'),
  _OrdenOpcion(
    'Precio menor a mayor',
    Icons.arrow_upward,
    'Más económico primero',
  ),
  _OrdenOpcion(
    'Precio mayor a menor',
    Icons.arrow_downward,
    'Más caro primero',
  ),
  _OrdenOpcion('Más recientes', Icons.access_time, 'Últimos agregados'),
  _OrdenOpcion(
    'Activos primero',
    Icons.check_circle_outline,
    'Productos activos arriba',
  ),
];
