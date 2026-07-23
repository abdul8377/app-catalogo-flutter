import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/productos_consolidados_state.dart';

class ConsolidadoFiltros {
  const ConsolidadoFiltros({
    this.hoja,
    this.empresa,
    this.marca,
    this.categoria,
    this.subcategoria,
    this.preparacion,
    this.estadoPedido,
    this.sinPrecio = false,
  });

  final String? hoja;
  final String? empresa;
  final String? marca;
  final String? categoria;
  final String? subcategoria;
  final String? preparacion;
  final String? estadoPedido;
  final bool sinPrecio;
}

class ConsolidadoFiltrosDialog extends StatefulWidget {
  const ConsolidadoFiltrosDialog({required this.state, super.key});

  final ProductosConsolidadosState state;

  static Future<ConsolidadoFiltros?> show(
    BuildContext context, {
    required ProductosConsolidadosState state,
  }) => showDialog<ConsolidadoFiltros>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => ConsolidadoFiltrosDialog(state: state),
  );

  @override
  State<ConsolidadoFiltrosDialog> createState() =>
      _ConsolidadoFiltrosDialogState();
}

class _ConsolidadoFiltrosDialogState extends State<ConsolidadoFiltrosDialog> {
  String? hoja;
  String? empresa;
  String? marca;
  String? categoria;
  String? subcategoria;
  String? preparacion;
  String? estadoPedido;
  bool sinPrecio = false;

  @override
  void initState() {
    super.initState();
    final state = widget.state;
    hoja = state.hojaCodigo;
    empresa = state.empresa;
    marca = state.marca;
    categoria = state.categoria;
    subcategoria = state.subcategoria;
    preparacion = state.estadoPreparacion;
    estadoPedido = state.estadoPedido;
    sinPrecio = state.soloSinPrecio;
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros del consolidado',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                _dropdown(
                  'Hoja de pedido',
                  hoja,
                  widget.state.hojasDisponibles,
                  (value) => hoja = value,
                ),
                _dropdown(
                  'Empresa',
                  empresa,
                  widget.state.empresas,
                  (value) => empresa = value,
                ),
                _dropdown(
                  'Marca',
                  marca,
                  widget.state.marcas,
                  (value) => marca = value,
                ),
                _dropdown(
                  'Categoría',
                  categoria,
                  widget.state.categorias,
                  (value) => categoria = value,
                ),
                _dropdown(
                  'Subcategoría',
                  subcategoria,
                  widget.state.subcategorias,
                  (value) => subcategoria = value,
                ),
                _dropdown(
                  'Preparación',
                  preparacion,
                  const ['pendiente', 'parcial', 'completo'],
                  (value) => preparacion = value,
                  labels: const {
                    'pendiente': 'Pendiente de preparar',
                    'parcial': 'Preparado parcialmente',
                    'completo': 'Preparado completamente',
                  },
                ),
                _dropdown(
                  'Estado del pedido',
                  estadoPedido,
                  const ['pendiente', 'en_proceso', 'listo', 'entregado'],
                  (value) => estadoPedido = value,
                  labels: const {
                    'pendiente': 'Pendiente',
                    'en_proceso': 'En proceso',
                    'listo': 'Listo para entregar',
                    'entregado': 'Entregado',
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: const Color(0xFFFFC500),
                  title: const Text('Solo productos pendientes de precio'),
                  value: sinPrecio,
                  onChanged: (value) => setState(() => sinPrecio = value),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ConsolidadoFiltros(hoja: widget.state.hojaCodigo),
                  ),
                  child: const Text('Limpiar filtros'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ConsolidadoFiltros(
                      hoja: hoja,
                      empresa: empresa,
                      marca: marca,
                      categoria: categoria,
                      subcategoria: subcategoria,
                      preparacion: preparacion,
                      estadoPedido: estadoPedido,
                      sinPrecio: sinPrecio,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC500),
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged, {
    Map<String, String> labels = const {},
  }) {
    final options = {...values, ?value}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Todos')),
          ...options.map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                labels[item] ?? item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (newValue) => setState(() => onChanged(newValue)),
      ),
    );
  }
}
