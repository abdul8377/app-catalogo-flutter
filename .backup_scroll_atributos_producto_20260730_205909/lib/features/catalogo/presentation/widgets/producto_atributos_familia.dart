import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/services/valor_tecnico_parser.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';

class ProductoAtributosFamilia extends StatelessWidget {
  const ProductoAtributosFamilia({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    final definitions = state.atributosFamilia;
    if (definitions.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('atributos_comunes_familia'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5DDE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF20242B)),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Características comunes',
                      style: TextStyle(
                        color: Color(0xFF20242B),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Se completan una vez y se aplican a todas las variantes.',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: definitions
                    .map(
                      (definition) => SizedBox(
                        width: width,
                        child: _FamilyAttributeField(
                          key: ValueKey(
                            'familia-${definition.id}-${definition.nombre}',
                          ),
                          definition: definition,
                          initialValue:
                              state.atributos[definition.nombre] ?? '',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FamilyAttributeField extends StatefulWidget {
  const _FamilyAttributeField({
    required this.definition,
    required this.initialValue,
    super.key,
  });

  final AtributoDef definition;
  final String initialValue;

  @override
  State<_FamilyAttributeField> createState() => _FamilyAttributeFieldState();
}

class _FamilyAttributeFieldState extends State<_FamilyAttributeField> {
  late final TextEditingController _controller;
  String _unit = '';
  Set<String> _selectedValues = {};

  AtributoDef get definition => widget.definition;

  @override
  void initState() {
    super.initState();
    final separated = ValorTecnicoParser.separarValorUnidad(
      widget.initialValue,
    );
    _controller = TextEditingController(text: separated.valor);
    _selectedValues = _parseSelections(widget.initialValue);
    _unit = separated.unidad.isNotEmpty
        ? separated.unidad
        : definition.unidadPredeterminada ??
              (definition.unidades.isEmpty ? '' : definition.unidades.first);
  }

  @override
  void didUpdateWidget(covariant _FamilyAttributeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _selectedValues = _parseSelections(widget.initialValue);
    }
  }

  Set<String> _parseSelections(String raw) => raw
      .split(RegExp(r'[;|·]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit([String? directValue]) {
    final value = directValue ?? _controller.text.trim();
    final stored = definition.tipo == 'numero_unidad' && value.isNotEmpty
        ? '$value $_unit'.trim()
        : value;
    context.read<ProductoFormBloc>().add(
      ProductoFormAtributoCambiado(definition.nombre, stored),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = '${definition.nombre}${definition.requerido ? ' *' : ''}';
    final helper = definition.ayuda.trim().isNotEmpty
        ? definition.ayuda.trim()
        : null;

    if (definition.tipo == 'lista_unica' || definition.tipo == 'si_no') {
      final options = definition.tipo == 'si_no'
          ? const ['Sí', 'No']
          : definition.opciones;
      final current = options.contains(widget.initialValue)
          ? widget.initialValue
          : null;
      return DropdownButtonFormField<String>(
        key: ValueKey('atributo_familia_${definition.nombre}'),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) => _emit(value ?? ''),
      );
    }

    if (definition.tipo == 'lista_multiple') {
      return FormField<String>(
        initialValue: widget.initialValue,
        builder: (field) => InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            errorText: field.errorText,
            border: const OutlineInputBorder(),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: definition.opciones.map((option) {
              final checked = _selectedValues.contains(option);
              return FilterChip(
                label: Text(option),
                selected: checked,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedValues.add(option);
                    } else {
                      _selectedValues.remove(option);
                    }
                  });
                  _emit(_selectedValues.join(' · '));
                },
              );
            }).toList(),
          ),
        ),
      );
    }

    final numeric =
        definition.tipo == 'numero' || definition.tipo == 'numero_unidad';
    final valueField = TextFormField(
      key: ValueKey('atributo_familia_${definition.nombre}'),
      controller: _controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9\s/.,aA+\-–—]'))]
          : null,
      onChanged: (_) => _emit(),
      decoration: InputDecoration(
        labelText: label,
        hintText: definition.ejemplo.trim().isEmpty
            ? null
            : definition.ejemplo.trim(),
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    );

    if (definition.tipo != 'numero_unidad' || definition.unidades.isEmpty) {
      return valueField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: valueField),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: DropdownButtonFormField<String>(
            initialValue: definition.unidades.contains(_unit)
                ? _unit
                : definition.unidades.first,
            decoration: const InputDecoration(
              labelText: 'Unidad',
              border: OutlineInputBorder(),
            ),
            items: definition.unidades
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _unit = value);
              _emit();
            },
          ),
        ),
      ],
    );
  }
}
