import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/services/codigo_interno_generator.dart';
import '../../domain/services/valor_tecnico_parser.dart';
import '../bloc/producto_form/producto_form_bloc.dart';
import '../bloc/producto_form/producto_form_event.dart';
import '../bloc/producto_form/producto_form_state.dart';

class ProductoVariantesStep extends StatefulWidget {
  const ProductoVariantesStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  State<ProductoVariantesStep> createState() => _ProductoVariantesStepState();
}

class _ProductoVariantesStepState extends State<ProductoVariantesStep> {
  static const _primary = Color(0xFFFFC500);
  static const _ink = Color(0xFF20242B);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFD5DDE8);

  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _codigoProveedor = TextEditingController();
  final _nombre = TextEditingController();
  final Map<String, TextEditingController> _valores = {};
  final Map<String, String> _unidades = {};

  String? _seleccionadaId;
  String? _editandoId;
  bool _panelAbierto = false;
  bool _activa = true;
  bool _dirty = false;
  bool _sincronizandoCampos = false;
  String? _panelError;

  @override
  void initState() {
    super.initState();
    final primera = widget.state.variantes.firstOrNull;
    if (primera != null) {
      _cargarVariante(primera, rebuild: false, notify: false);
    }
  }

  @override
  void didUpdateWidget(covariant ProductoVariantesStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dirty || oldWidget.state.variantes == widget.state.variantes) return;
    final seleccionada = _buscar(_seleccionadaId);
    if (seleccionada != null) {
      _cargarVariante(seleccionada, rebuild: false, notify: false);
      return;
    }
    final primera = widget.state.variantes.firstOrNull;
    if (primera == null) {
      _seleccionadaId = null;
      _editandoId = null;
      _panelAbierto = false;
    } else {
      _cargarVariante(primera, rebuild: false, notify: false);
    }
  }

  @override
  void dispose() {
    _sku.dispose();
    _codigoProveedor.dispose();
    _nombre.dispose();
    for (final controller in _valores.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Text(
              'Cada variante recibe un código interno automático y puede conservar el código del proveedor.',
              style: GoogleFonts.inter(color: _muted, fontSize: 14),
            ),
            _familiaChip(),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1020;
            final lista = _listaCard();
            final panel = _panelAbierto ? _editorPanel() : _panelSinSeleccion();
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [lista, const SizedBox(height: 18), panel],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lista),
                const SizedBox(width: 20),
                SizedBox(width: 410, child: panel),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _familiaChip() => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3C4),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      'Familia: ${widget.state.nombre.trim().isEmpty ? 'Sin nombre' : widget.state.nombre.trim()}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _listaCard() {
    final selected = _buscar(_seleccionadaId);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Variantes creadas',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.state.variantes.length} registradas · '
                      '${widget.state.variantes.where((item) => item.activa).length} activas',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  key: const Key('agregar_variante'),
                  onPressed:
                      widget.state.tipoRegistro == 'unico' &&
                          widget.state.variantes.isNotEmpty
                      ? null
                      : _abrirNueva,
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Agregar variante'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF1C1C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (widget.state.variantes.isEmpty)
              _estadoVacio()
            else
              _tablaVariantes(),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _botonAccionLista(
                  key: const Key('duplicar_variante_lista'),
                  icon: Icons.copy_outlined,
                  label: 'Duplicar seleccionada',
                  onPressed: selected == null ? null : _duplicarSeleccionada,
                ),
                _botonAccionLista(
                  key: const Key('editar_atributos_variante_lista'),
                  icon: Icons.tune,
                  label: 'Editar atributos',
                  onPressed: selected == null
                      ? null
                      : () => _seleccionar(selected),
                ),
                _botonAccionLista(
                  key: const Key('alternar_variante_lista'),
                  icon: selected?.activa == true
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  label: selected?.activa == true ? 'Desactivar' : 'Activar',
                  onPressed: selected == null ? null : _alternarSeleccionada,
                ),
                _botonAccionLista(
                  key: const Key('eliminar_variante_lista'),
                  icon: Icons.delete_outline,
                  label: 'Eliminar',
                  color: Colors.red.shade700,
                  onPressed: selected == null ? null : _eliminarSeleccionada,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 21, color: Color(0xFF2563EB)),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Lista flexible\n'
                      'Úsala cuando cada artículo tiene medidas, modelos o características '
                      'diferentes y no forma una cuadrícula clara. Las '
                      'presentaciones se asignan en el siguiente paso.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablaVariantes() => LayoutBuilder(
    builder: (context, constraints) => ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 42,
            dataRowMinHeight: 54,
            dataRowMaxHeight: 64,
            horizontalMargin: 14,
            columnSpacing: 22,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F8)),
            columns: const [
              DataColumn(label: Text('Código interno')),
              DataColumn(label: Text('Código proveedor')),
              DataColumn(label: Text('Nombre corto')),
              DataColumn(label: Text('Atributos principales')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acción')),
            ],
            rows: widget.state.variantes.map((variante) {
              final selected = variante.id == _seleccionadaId;
              return DataRow(
                selected: selected,
                color: WidgetStateProperty.all(
                  selected ? _primary.withValues(alpha: .12) : Colors.white,
                ),
                onSelectChanged: (_) => _seleccionar(variante),
                cells: [
                  DataCell(
                    SizedBox(
                      width: 110,
                      child: Text(
                        variante.sku,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Text(
                        variante.codigoProveedor.trim().isEmpty
                            ? '—'
                            : variante.codigoProveedor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        variante.nombreCorto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: variante.atributos
                          .map(
                            (atributo) =>
                                '${atributo.nombre}: ${atributo.texto}',
                          )
                          .join('\n'),
                      child: SizedBox(
                        width: 190,
                        child: Text(
                          variante.atributosTexto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  DataCell(_estado(variante)),
                  DataCell(
                    TextButton(
                      onPressed: () => _seleccionar(variante),
                      child: const Text(
                        'Editar',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );

  Widget _estado(ProductoVariante variante) => Tooltip(
    message: 'Variante registrada en este producto',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: variante.activa
            ? const Color(0xFFE7F7EF)
            : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        variante.activa ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: variante.activa
              ? const Color(0xFF16794A)
              : const Color(0xFF4B5563),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _estadoVacio() => Container(
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      children: [
        Icon(Icons.view_list_outlined, size: 38, color: _muted),
        SizedBox(height: 10),
        Text(
          'Todavía no hay variantes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Agrega el primer artículo; el código interno se generará automáticamente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _botonAccionLista({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color color = _ink,
  }) => OutlinedButton.icon(
    key: key,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: const BorderSide(color: Color(0xFFBAC4D2)),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  );

  Widget _panelSinSeleccion() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xFFF8FAFC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const Icon(Icons.touch_app_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(
            widget.state.variantes.isEmpty
                ? 'Agrega tu primera variante'
                : 'Selecciona una variante',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'La información se editará en este panel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _muted, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _editorPanel() {
    final editing = _editandoId != null;
    final selected = _buscar(_seleccionadaId);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Editar variante' : 'Nueva variante',
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (editing && selected != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _dirty ? null : _duplicarSeleccionada,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Duplicar'),
                      style: _outlinedStyle(),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _activa = !_activa);
                        _marcarPendiente();
                      },
                      icon: Icon(
                        _activa
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                      ),
                      label: Text(_activa ? 'Desactivar' : 'Activar'),
                      style: _outlinedStyle(
                        _activa
                            ? const Color(0xFFB42318)
                            : const Color(0xFF16794A),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (_panelError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFC62828),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _panelError!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC62828),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _field(
                key: const Key('variante_codigo_interno'),
                label: 'Código interno',
                controller: _sku,
                hint: 'PER-001-001',
                validator: _validarSku,
                readOnly: true,
              ),
              const SizedBox(height: 15),
              _field(
                key: const Key('variante_codigo_proveedor'),
                label: 'Código del proveedor (opcional)',
                controller: _codigoProveedor,
                hint: 'UY-BTR204',
                capitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 15),
              _field(
                key: const Key('variante_nombre'),
                label: 'Nombre corto *',
                controller: _nombre,
                hint: 'Batería 20 V 4 Ah',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa un nombre corto.'
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Atributos de la variante',
                style: GoogleFonts.inter(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El valor y la unidad se guardan por separado.',
                style: GoogleFonts.inter(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 13),
              if (_specs.isEmpty)
                Text(
                  'Esta categoría no define atributos de variante.',
                  style: GoogleFonts.inter(color: _muted, fontSize: 14),
                )
              else
                ..._specs.map(_atributoField),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('agregar_atributo_adicional_lista'),
                  onPressed: _agregarAtributoAdicional,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir característica adicional'),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activa en el catálogo',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _activa
                                ? 'Disponible al publicar.'
                                : 'No estará disponible para pedidos.',
                            style: GoogleFonts.inter(
                              color: _muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _activa,
                      activeTrackColor: _primary,
                      onChanged: (value) {
                        setState(() => _activa = value);
                        _marcarPendiente();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancelar_variante'),
                      onPressed: _cancelarEdicion,
                      style: _outlinedStyle(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('guardar_variante'),
                      onPressed: _guardarVariante,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: Text(
                        editing ? 'Guardar cambios' : 'Agregar a la lista',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
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

  Widget _atributoField(_VariantAttributeSpec spec) {
    final controller = _valores.putIfAbsent(
      spec.nombre,
      TextEditingController.new,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${spec.nombre}${spec.required ? ' *' : ''}',
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('atributo_${spec.nombre}'),
                  controller: controller,
                  onChanged: (_) => _marcarPendiente(),
                  keyboardType: spec.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  inputFormatters: spec.numeric
                      ? [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return RegExp(
                                  r'^[0-9\s/.,aA+\-–—]*$',
                                ).hasMatch(newValue.text)
                                ? newValue
                                : oldValue;
                          }),
                        ]
                      : null,
                  validator: (value) => _validarAtributo(spec, value),
                  decoration: _inputDecoration(
                    spec.numeric ? 'Ej. 20' : 'Ingresa el valor',
                  ),
                ),
              ),
              if (spec.unidades.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 86,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${spec.nombre}-${_unidades[spec.nombre]}'),
                    initialValue: _unidades[spec.nombre],
                    isExpanded: true,
                    items: spec.unidades
                        .map(
                          (unidad) => DropdownMenuItem(
                            value: unidad,
                            child: Text(
                              unidad,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _unidades[spec.nombre] = value);
                      _marcarPendiente();
                    },
                    decoration: _inputDecoration('Unidad'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required Key key,
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
    bool readOnly = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      TextFormField(
        key: key,
        controller: controller,
        validator: validator,
        textCapitalization: capitalization,
        readOnly: readOnly,
        onChanged: readOnly ? null : (_) => _marcarPendiente(),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: _inputDecoration(hint),
      ),
    ],
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: _primary, width: 2),
    ),
  );

  ButtonStyle _outlinedStyle([Color color = _ink]) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: const BorderSide(color: Color(0xFFBAC4D2)),
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );

  void _abrirNueva() {
    if (!_puedeCambiarSeleccion()) return;
    _sincronizandoCampos = true;
    _formKey.currentState?.reset();
    _sku.text = CodigoInternoGenerator.siguienteVariante(
      codigoFamilia: widget.state.codigo,
      codigosExistentes: widget.state.variantes.map((item) => item.sku),
    );
    _codigoProveedor.clear();
    _nombre.clear();
    _prepararAtributos();
    _sincronizandoCampos = false;
    setState(() {
      _editandoId = null;
      _panelAbierto = true;
      _activa = true;
      _dirty = true;
      _panelError = null;
    });
    _notificarPendiente(true);
  }

  void _seleccionar(ProductoVariante variante) {
    if (variante.id == _seleccionadaId && _panelAbierto) return;
    if (!_puedeCambiarSeleccion()) return;
    _cargarVariante(variante);
  }

  void _cargarVariante(
    ProductoVariante variante, {
    bool rebuild = true,
    bool notify = true,
  }) {
    _sincronizandoCampos = true;
    _formKey.currentState?.reset();
    _sku.text = variante.sku;
    _codigoProveedor.text = variante.codigoProveedor;
    _nombre.text = variante.nombreCorto;
    _prepararAtributos(variante.atributos);
    _sincronizandoCampos = false;
    void update() {
      _seleccionadaId = variante.id;
      _editandoId = variante.id;
      _panelAbierto = true;
      _activa = variante.activa;
      _dirty = false;
      _panelError = null;
    }

    if (rebuild && mounted) {
      setState(update);
    } else {
      update();
    }
    if (notify && mounted) _notificarPendiente(false);
  }

  void _prepararAtributos([
    List<AtributoProductoVariante> atributos = const [],
  ]) {
    final controllers = Map<String, TextEditingController>.from(_valores);
    _valores.clear();
    _unidades.clear();
    final values = {for (final item in atributos) item.nombre: item};
    final nombres = <String>{
      ..._specs.map((spec) => spec.nombre),
      ...values.keys,
    };
    for (final nombre in nombres) {
      final item = values[nombre];
      final spec = _specFor(nombre);
      final controller =
          controllers.remove(nombre) ??
          TextEditingController(text: item?.valor ?? '');
      controller.text = item?.valor ?? '';
      _valores[nombre] = controller;
      _unidades[nombre] =
          item?.unidad ?? (spec.unidades.isEmpty ? '' : spec.unidades.first);
    }
    if (controllers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      });
    }
  }

  Future<void> _agregarAtributoAdicional() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Característica adicional'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Norma especial',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.trim().isEmpty) return;
    if (_valores.containsKey(name) ||
        _specs.any((spec) => spec.nombre == name)) {
      setState(() => _panelError = 'La característica “$name” ya existe.');
      return;
    }
    setState(() {
      _valores[name] = TextEditingController();
      _unidades[name] = '';
      _dirty = true;
    });
    _notificarPendiente(true);
  }

  void _marcarPendiente() {
    if (_sincronizandoCampos) return;
    if (_dirty) {
      if (_panelError != null) setState(() => _panelError = null);
      return;
    }
    setState(() {
      _dirty = true;
      _panelError = null;
    });
    _notificarPendiente(true);
  }

  bool _puedeCambiarSeleccion() {
    if (!_dirty) return true;
    setState(
      () => _panelError =
          'Guarda o cancela los cambios antes de seleccionar otra variante.',
    );
    return false;
  }

  void _cancelarEdicion() {
    final selected = _buscar(_seleccionadaId);
    if (selected != null) {
      _cargarVariante(selected);
      return;
    }
    setState(() {
      _panelAbierto = false;
      _editandoId = null;
      _dirty = false;
      _panelError = null;
    });
    _notificarPendiente(false);
  }

  void _guardarVariante() {
    setState(() => _panelError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final atributos = _specs
        .map((spec) {
          final value = _valores[spec.nombre]?.text.trim() ?? '';
          return AtributoProductoVariante(
            nombre: spec.nombre,
            valor: value.replaceAll(',', '.'),
            unidad: value.isEmpty ? '' : _unidades[spec.nombre] ?? '',
          );
        })
        .where((atributo) => atributo.valor.isNotEmpty)
        .toList();
    final draft = ProductoVariante(
      id: _editandoId ?? const Uuid().v4(),
      sku: _sku.text.trim().toUpperCase(),
      codigoProveedor: _codigoProveedor.text.trim().toUpperCase(),
      nombreCorto: _nombre.text.trim(),
      atributos: atributos,
      activa: _activa,
    );
    final combination = draft.combinacionNormalizada;
    final duplicated =
        combination.isNotEmpty &&
        widget.state.variantes.any(
          (variante) =>
              variante.id != _editandoId &&
              variante.combinacionNormalizada == combination,
        );
    if (duplicated) {
      setState(
        () =>
            _panelError = 'Ya existe una variante con ${draft.atributosTexto}.',
      );
      return;
    }

    setState(() {
      _seleccionadaId = draft.id;
      _editandoId = draft.id;
      _dirty = false;
      _panelError = null;
    });
    context.read<ProductoFormBloc>().add(ProductoFormVarianteGuardada(draft));
  }

  void _duplicarSeleccionada() {
    if (!_puedeCambiarSeleccion()) return;
    final selected = _buscar(_seleccionadaId);
    if (selected == null) return;
    final copy = selected.copyWith(
      id: const Uuid().v4(),
      sku: CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: widget.state.codigo,
        codigosExistentes: widget.state.variantes.map((item) => item.sku),
      ),
      codigoProveedor: '',
      nombreCorto: '${selected.nombreCorto} (copia)',
    );
    _cargarVariante(copy, notify: false);
    context.read<ProductoFormBloc>().add(ProductoFormVarianteGuardada(copy));
  }

  void _alternarSeleccionada() {
    if (!_puedeCambiarSeleccion()) return;
    final selected = _buscar(_seleccionadaId);
    if (selected == null) return;
    final updated = selected.copyWith(activa: !selected.activa);
    _cargarVariante(updated, notify: false);
    context.read<ProductoFormBloc>().add(ProductoFormVarianteGuardada(updated));
  }

  Future<void> _eliminarSeleccionada() async {
    if (!_puedeCambiarSeleccion()) return;
    final selected = _buscar(_seleccionadaId);
    if (selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar variante'),
        content: Text(
          'Se eliminará ${selected.sku} del borrador. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final remaining = widget.state.variantes
        .where((variante) => variante.id != selected.id)
        .toList();
    if (remaining.isEmpty) {
      setState(() {
        _seleccionadaId = null;
        _editandoId = null;
        _panelAbierto = false;
        _dirty = false;
        _panelError = null;
      });
      _notificarPendiente(false);
    } else {
      _cargarVariante(remaining.first, notify: false);
    }
    context.read<ProductoFormBloc>().add(
      ProductoFormVarianteEliminada(selected.id),
    );
  }

  String? _validarSku(String? value) {
    final sku = value?.trim().toUpperCase() ?? '';
    if (sku.isEmpty) return 'No se pudo generar el código interno.';
    final duplicated = widget.state.variantes.any(
      (variante) =>
          variante.id != _editandoId &&
          variante.sku.trim().toUpperCase() == sku,
    );
    return duplicated ? 'El código interno está duplicado.' : null;
  }

  String? _validarAtributo(_VariantAttributeSpec spec, String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return spec.required ? 'Ingresa ${spec.nombre.toLowerCase()}.' : null;
    }
    if (!spec.numeric) return null;
    final number = _parseVariantNumber(value);
    if (number == null || number <= 0) {
      return '${spec.nombre} debe ser un número, fracción o número mixto válido.';
    }
    return null;
  }

  double? _parseVariantNumber(String raw) {
    final parsed = ValorTecnicoParser.parse(raw);
    return parsed.esNumerico ? parsed.minimo : null;
  }

  void _notificarPendiente(bool value) {
    context.read<ProductoFormBloc>().add(
      ProductoFormEdicionVarianteCambiada(value),
    );
  }

  ProductoVariante? _buscar(String? id) {
    if (id == null) return null;
    for (final variante in widget.state.variantes) {
      if (variante.id == id) return variante;
    }
    return null;
  }

  List<_VariantAttributeSpec> get _specs {
    final definitions = widget.state.atributosDisponibles
        .where((atributo) => atributo.esVariante)
        .map(_specFromDefinition)
        .toList();
    if (definitions.isNotEmpty) {
      final extras = _valores.keys
          .where((nombre) => !definitions.any((spec) => spec.nombre == nombre))
          .map((nombre) => _VariantAttributeSpec(nombre: nombre))
          .toList();
      return [...definitions, ...extras];
    }
    final category =
        '${widget.state.categoria ?? ''} ${widget.state.subcategoria ?? ''}'
            .toLowerCase();
    if (category.contains('bater')) {
      return const [
        _VariantAttributeSpec(
          nombre: 'Voltaje',
          numeric: true,
          required: true,
          unidades: ['V'],
        ),
        _VariantAttributeSpec(
          nombre: 'Capacidad',
          numeric: true,
          required: true,
          unidades: ['Ah'],
        ),
        _VariantAttributeSpec(nombre: 'Sistema compatible'),
      ];
    }
    if (category.contains('pern') ||
        category.contains('broca') ||
        category.contains('tornill')) {
      return const [
        _VariantAttributeSpec(
          nombre: 'Diámetro',
          numeric: true,
          required: true,
          unidades: ['mm', 'in'],
        ),
        _VariantAttributeSpec(
          nombre: 'Largo',
          numeric: true,
          required: true,
          unidades: ['mm', 'in'],
        ),
        _VariantAttributeSpec(nombre: 'Material'),
      ];
    }
    return const [
      _VariantAttributeSpec(nombre: 'Medida'),
      _VariantAttributeSpec(nombre: 'Material'),
      _VariantAttributeSpec(nombre: 'Modelo compatible'),
    ];
  }

  _VariantAttributeSpec _specFromDefinition(AtributoDef definition) {
    final lower = definition.nombre.toLowerCase();
    final numeric =
        definition.tipo == 'numero' ||
        definition.tipo == 'numero_unidad' ||
        lower.contains('voltaje') ||
        lower.contains('capacidad') ||
        lower.contains('diámetro') ||
        lower.contains('diametro') ||
        lower.contains('largo');
    final fallbackUnits = switch (lower) {
      String value when value.contains('voltaje') => const ['V'],
      String value when value.contains('capacidad') => const ['Ah'],
      String value
          when value.contains('diámetro') ||
              value.contains('diametro') ||
              value.contains('largo') =>
        const ['mm', 'in'],
      _ => const <String>[],
    };
    return _VariantAttributeSpec(
      nombre: definition.nombre,
      numeric: numeric,
      required: definition.requerido,
      unidades: definition.unidades.isEmpty
          ? fallbackUnits
          : definition.unidades,
    );
  }

  _VariantAttributeSpec _specFor(String nombre) => _specs.firstWhere(
    (spec) => spec.nombre == nombre,
    orElse: () => _VariantAttributeSpec(nombre: nombre),
  );
}

class _VariantAttributeSpec {
  const _VariantAttributeSpec({
    required this.nombre,
    this.numeric = false,
    this.required = false,
    this.unidades = const [],
  });

  final String nombre;
  final bool numeric;
  final bool required;
  final List<String> unidades;
}
