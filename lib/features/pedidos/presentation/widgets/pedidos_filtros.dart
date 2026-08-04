import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/pedidos_listado/pedidos_listado_state.dart';

class PedidosFiltros extends StatelessWidget {
  const PedidosFiltros({
    required this.state,
    required this.resultados,
    required this.onFiltroRapido,
    required this.onFiltrosAvanzados,
    required this.onOrdenChanged,
    required this.onLimpiarFiltros,
    super.key,
  });

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final PedidosListadoState state;
  final int resultados;
  final ValueChanged<String> onFiltroRapido;
  final ValueChanged<PedidosFiltrosSeleccion> onFiltrosAvanzados;
  final ValueChanged<String> onOrdenChanged;
  final VoidCallback onLimpiarFiltros;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        color: Colors.white,
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children:
              const [
                'Todos',
                'Pendiente',
                'En proceso',
                'Listo para entregar',
                'Entregado',
                'Cancelado',
                'Con precio completo',
                'Pendiente de valorización',
                'Sin sincronizar',
              ].map((filtro) {
                final seleccionado = state.filtrosRapidos.contains(filtro);
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
                    onSelected: (_) => onFiltroRapido(filtro),
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
                onPressed: () => _mostrarFiltrosAvanzados(context),
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  state.filtrosActivos == 0
                      ? 'Filtros avanzados'
                      : 'Filtros (${state.filtrosActivos})',
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
                onPressed: () => _mostrarOrdenamiento(context),
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
            const SizedBox(width: 12),
            Text(
              '$resultados resultados',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkColor,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _mostrarFiltrosAvanzados(BuildContext context) async {
    final result = await showDialog<PedidosFiltrosSeleccion>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _PedidosFiltrosAvanzadosDialog(
        estadoInicial: state.estado,
        hojaInicial: state.hoja,
        precioInicial: state.precio,
        sincronizacionInicial: state.sincronizacion,
        hojasDisponibles: state.hojasDisponibles,
        fechaInicio: state.fechaInicio,
        fechaFin: state.fechaFin,
        cliente: state.cliente,
        vendedor: state.vendedor,
        empresa: state.empresa,
        categoria: state.categoria,
        producto: state.producto,
        cotizacion: state.cotizacion,
      ),
    );
    if (result == null) return;
    if (result.limpiar) {
      onLimpiarFiltros();
      return;
    }
    onFiltrosAvanzados(result);
  }

  Future<void> _mostrarOrdenamiento(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _PedidosOrdenarDialog(orden: state.orden),
    );
    if (value != null) onOrdenChanged(value);
  }
}

// ---------- FILTROS AVANZADOS (DIÁLOGO CENTRADO) ----------
class _PedidosFiltrosAvanzadosDialog extends StatefulWidget {
  const _PedidosFiltrosAvanzadosDialog({
    this.estadoInicial,
    this.hojaInicial,
    this.precioInicial,
    this.sincronizacionInicial,
    required this.hojasDisponibles,
    this.fechaInicio,
    this.fechaFin,
    this.cliente,
    this.vendedor,
    this.empresa,
    this.categoria,
    this.producto,
    this.cotizacion,
  });

  final String? estadoInicial;
  final String? hojaInicial;
  final String? precioInicial;
  final String? sincronizacionInicial;
  final List<String> hojasDisponibles;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cliente;
  final String? vendedor;
  final String? empresa;
  final String? categoria;
  final String? producto;
  final String? cotizacion;

  @override
  State<_PedidosFiltrosAvanzadosDialog> createState() =>
      _PedidosFiltrosAvanzadosDialogState();
}

class _PedidosFiltrosAvanzadosDialogState
    extends State<_PedidosFiltrosAvanzadosDialog> {
  final _formKey = GlobalKey<FormState>();

  late String? _estado;
  late String? _hoja;
  late String? _precio;
  late String? _sincronizacion;
  late TextEditingController _fechaInicioCtrl;
  late TextEditingController _fechaFinCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _vendedorCtrl;
  late TextEditingController _empresaCtrl;
  late TextEditingController _categoriaCtrl;
  late TextEditingController _productoCtrl;
  String? _cotizacion;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _estado = widget.estadoInicial;
    _hoja = widget.hojaInicial;
    _precio = widget.precioInicial;
    _sincronizacion = widget.sincronizacionInicial;
    _fechaInicioCtrl = TextEditingController(
      text: widget.fechaInicio != null
          ? '${widget.fechaInicio!.day}/${widget.fechaInicio!.month}/${widget.fechaInicio!.year}'
          : '',
    );
    _fechaFinCtrl = TextEditingController(
      text: widget.fechaFin != null
          ? '${widget.fechaFin!.day}/${widget.fechaFin!.month}/${widget.fechaFin!.year}'
          : '',
    );
    _clienteCtrl = TextEditingController(text: widget.cliente ?? '');
    _vendedorCtrl = TextEditingController(text: widget.vendedor ?? '');
    _empresaCtrl = TextEditingController(text: widget.empresa ?? '');
    _categoriaCtrl = TextEditingController(text: widget.categoria ?? '');
    _productoCtrl = TextEditingController(text: widget.producto ?? '');
    _cotizacion = widget.cotizacion;
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
  }

  @override
  void dispose() {
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _clienteCtrl.dispose();
    _vendedorCtrl.dispose();
    _empresaCtrl.dispose();
    _categoriaCtrl.dispose();
    _productoCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_fechaInicio ?? DateTime.now())
          : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: const Color(0xFFFFC500)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
          _fechaInicioCtrl.text =
              '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _fechaFin = picked;
          _fechaFinCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
  }

  void _aplicar() {
    if (_fechaInicio != null &&
        _fechaFin != null &&
        _fechaInicio!.isAfter(_fechaFin!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha inicial no puede ser posterior a la fecha final.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      PedidosFiltrosSeleccion(
        estado: _estado,
        hoja: _hoja,
        precio: _precio,
        sincronizacion: _sincronizacion,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        cliente: _clienteCtrl.text.trim().isEmpty
            ? null
            : _clienteCtrl.text.trim(),
        vendedor: _vendedorCtrl.text.trim().isEmpty
            ? null
            : _vendedorCtrl.text.trim(),
        empresa: _empresaCtrl.text.trim().isEmpty
            ? null
            : _empresaCtrl.text.trim(),
        categoria: _categoriaCtrl.text.trim().isEmpty
            ? null
            : _categoriaCtrl.text.trim(),
        producto: _productoCtrl.text.trim().isEmpty
            ? null
            : _productoCtrl.text.trim(),
        cotizacion: _cotizacion,
      ),
    );
  }

  void _limpiar() {
    Navigator.pop(context, const PedidosFiltrosSeleccion(limpiar: true));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFFC500);
    final darkColor = const Color(0xFF1F1F1F);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Filtros avanzados',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: darkColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.grey,
                        backgroundColor: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Cuerpo con scroll
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Información del pedido',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Estado',
                              value: _estado,
                              items: const {
                                'pendiente': 'Pendiente',
                                'en_proceso': 'En proceso',
                                'listo': 'Listo para entregar',
                                'entregado': 'Entregado',
                                'cancelado': 'Cancelado',
                              },
                              onChanged: (v) => setState(() => _estado = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Hoja de pedido',
                              value: _hoja,
                              items: {
                                for (final h in widget.hojasDisponibles)
                                  if (h.isNotEmpty) h: h,
                              },
                              onChanged: (v) => setState(() => _hoja = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Fecha inicio',
                              controller: _fechaInicioCtrl,
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'Fecha fin',
                              controller: _fechaFinCtrl,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        'Cliente y vendedor',
                        Icons.people_outline,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _clienteCtrl,
                        decoration: _inputDecoration('Cliente', Icons.person),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vendedorCtrl,
                        decoration: _inputDecoration('Vendedor', Icons.badge),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Producto', Icons.inventory),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _empresaCtrl,
                        decoration: _inputDecoration(
                          'Empresa o marca',
                          Icons.business,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _categoriaCtrl,
                        decoration: _inputDecoration(
                          'Categoría',
                          Icons.category,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _productoCtrl,
                        decoration: _inputDecoration(
                          'Producto específico',
                          Icons.search,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        'Valorización y cotización',
                        Icons.attach_money,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Precio',
                              value: _precio,
                              items: const {
                                'completo': 'Con precio completo',
                                'pendiente': 'Pendiente de valorización',
                              },
                              onChanged: (v) => setState(() => _precio = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Cotización',
                              value: _cotizacion,
                              items: const {
                                'generada': 'Generada',
                                'no_generada': 'No generada',
                              },
                              onChanged: (v) => setState(() => _cotizacion = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        'Sincronización',
                        Icons.cloud_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Estado de sincronización',
                        value: _sincronizacion,
                        items: const {
                          'sincronizado': 'Sincronizado',
                          'local': 'Guardado local',
                          'error': 'Con error de sincronización',
                        },
                        onChanged: (v) => setState(() => _sincronizacion = v),
                      ),
                    ],
                  ),
                ),
              ),
              // Botones inferiores
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limpiar,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Limpiar filtros'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkColor,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _aplicar,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aplicar filtros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFFC500)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFFFC500), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFFFC500), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Todos', style: TextStyle(color: Color(0xFF9E9E9E))),
        ),
        ...items.entries.map(
          (entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ),
      ],
      onChanged: (selected) => onChanged(selected),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
      style: GoogleFonts.inter(color: const Color(0xFF1F1F1F)),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.calendar_today,
          size: 18,
          color: Color(0xFF9E9E9E),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFFFC500), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

// ---------- RESULTADO DE FILTROS (ACTUALIZADO) ----------
class PedidosFiltrosSeleccion {
  const PedidosFiltrosSeleccion({
    this.estado,
    this.hoja,
    this.precio,
    this.sincronizacion,
    this.fechaInicio,
    this.fechaFin,
    this.cliente,
    this.vendedor,
    this.empresa,
    this.categoria,
    this.producto,
    this.cotizacion,
    this.limpiar = false,
  });

  final String? estado;
  final String? hoja;
  final String? precio;
  final String? sincronizacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? cliente;
  final String? vendedor;
  final String? empresa;
  final String? categoria;
  final String? producto;
  final String? cotizacion;
  final bool limpiar;
}

// ---------- ORDENAMIENTO (DIÁLOGO CENTRADO MEJORADO) ----------
class _PedidosOrdenarDialog extends StatelessWidget {
  const _PedidosOrdenarDialog({required this.orden});

  final String orden;

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {
        'title': 'Más recientes',
        'icon': Icons.access_time,
        'subtitle': 'Primero los más nuevos',
      },
      {
        'title': 'Más antiguos',
        'icon': Icons.history,
        'subtitle': 'Primero los más antiguos',
      },
      {
        'title': 'Código',
        'icon': Icons.tag,
        'subtitle': 'Ordenar por código de pedido',
      },
      {
        'title': 'Cliente A-Z',
        'icon': Icons.person,
        'subtitle': 'Orden alfabético por cliente',
      },
      {
        'title': 'Estado',
        'icon': Icons.flag,
        'subtitle': 'Agrupar por estado del pedido',
      },
      {
        'title': 'Mayor total',
        'icon': Icons.trending_up,
        'subtitle': 'Mayor monto primero',
      },
      {
        'title': 'Menor total',
        'icon': Icons.trending_down,
        'subtitle': 'Menor monto primero',
      },
      {
        'title': 'Pendientes de precio primero',
        'icon': Icons.warning_amber,
        'subtitle': 'Priorizar sin valorizar',
      },
      {
        'title': 'Pendientes de sincronización primero',
        'icon': Icons.sync_problem,
        'subtitle': 'Priorizar no sincronizados',
      },
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text(
                  'Ordenar por',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...opciones.map((op) {
              final seleccionado = orden == op['title'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, op['title']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? const Color(0xFFFFC500).withValues(alpha: 0.1)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: seleccionado
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
                              color: seleccionado
                                  ? const Color(
                                      0xFFFFC500,
                                    ).withValues(alpha: 0.2)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              op['icon'] as IconData,
                              size: 20,
                              color: seleccionado
                                  ? const Color(0xFF1F1F1F)
                                  : const Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  op['title'] as String,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: seleccionado
                                        ? const Color(0xFF1F1F1F)
                                        : const Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  op['subtitle'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: seleccionado
                                        ? const Color(
                                            0xFF1F1F1F,
                                          ).withValues(alpha: 0.7)
                                        : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (seleccionado)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFC500),
                              ),
                              child: const Icon(
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
