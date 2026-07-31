import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';
import '../widgets/producto_matriz_step.dart';
import '../widgets/producto_imagenes_step.dart';
import '../widgets/producto_precios_step.dart';
import '../widgets/producto_revision_step.dart';
import '../widgets/producto_unico_step.dart';
import '../widgets/producto_venta_logistica_step.dart';
import '../widgets/producto_variantes_step.dart';

class ProductoFormPage extends StatelessWidget {
  const ProductoFormPage({this.productoId, super.key});

  final String? productoId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ProductoFormBloc(context.read<CatalogoRepository>())
          ..add(ProductoFormStarted(productoId: productoId)),
    child: const _ProductoFormView(),
  );
}

class _ProductoFormView extends StatelessWidget {
  const _ProductoFormView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProductoFormBloc, ProductoFormState>(
        listenWhen: (previous, current) =>
            previous.guardado != current.guardado,
        listener: (context, state) {
          if (state.guardado) Navigator.of(context).pop(true);
        },
        builder: (context, state) => state.editando
            ? _EditarProductoScaffold(state: state)
            : _RegistrarProductoScaffold(state: state),
      );
}

class _RegistrarProductoScaffold extends StatelessWidget {
  const _RegistrarProductoScaffold({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F9FA),
    appBar: AppBar(
      title: Text(
        'Nuevo producto',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A2E),
    ),
    body: state.loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _StepIndicator(
                paso: state.paso,
                tipoRegistro: state.tipoRegistro,
              ),
              if (state.error != null)
                MaterialBanner(
                  content: Text(state.error!),
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  actions: [
                    TextButton(
                      onPressed: () => context.read<ProductoFormBloc>().add(
                        const ProductoFormErrorLimpiado(),
                      ),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _PasoActual(key: ValueKey(state.paso), state: state),
                ),
              ),
              if (state.paso <= 1) _BottomNavigation(state: state),
            ],
          ),
  );
}

class _EditarProductoScaffold extends StatelessWidget {
  const _EditarProductoScaffold({required this.state});
  final ProductoFormState state;

  static const _secciones = [
    (Icons.info_outline, 'General'),
    (Icons.style_outlined, 'Variantes'),
    (Icons.list_alt_outlined, 'Atributos'),
    (Icons.inventory_2_outlined, 'Presentaciones'),
    (Icons.payments_outlined, 'Precios'),
    (Icons.image_outlined, 'Imágenes'),
    (Icons.history_outlined, 'Estado'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    appBar: AppBar(
      title: Text(
        'Editar Producto',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
    ),
    body: state.loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (state.error != null) _ErrorBanner(message: state.error!),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [
                          _EditSectionBar(
                            secciones: _secciones,
                            paso: state.paso,
                            horizontal: true,
                          ),
                          Expanded(child: _SeccionEdicionActual(state: state)),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: 190,
                          child: _EditSectionBar(
                            secciones: _secciones,
                            paso: state.paso,
                            horizontal: false,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _SeccionEdicionActual(state: state)),
                      ],
                    );
                  },
                ),
              ),
              _EditBottomBar(state: state),
            ],
          ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    leading: const Icon(Icons.error_outline, color: Colors.red),
    actions: const [SizedBox.shrink()],
  );
}

class _EditSectionBar extends StatelessWidget {
  const _EditSectionBar({
    required this.secciones,
    required this.paso,
    required this.horizontal,
  });
  final List<(IconData, String)> secciones;
  final int paso;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = secciones.asMap().entries.map(
      (entry) => _EditSectionItem(
        icon: entry.value.$1,
        label: entry.value.$2,
        selected: paso == entry.key,
        horizontal: horizontal,
        onTap: () => context.read<ProductoFormBloc>().add(
          ProductoFormPasoSeleccionado(entry.key),
        ),
      ),
    );
    if (horizontal) {
      return Material(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: items.toList()),
        ),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        children: items.toList(),
      ),
    );
  }
}

class _EditSectionItem extends StatelessWidget {
  const _EditSectionItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.horizontal,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      right: horizontal ? 6 : 0,
      bottom: horizontal ? 0 : 6,
    ),
    child: Material(
      color: selected
          ? const Color(0xFFFFC500).withValues(alpha: .16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: horizontal ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.black : const Color(0xFF757575),
              ),
              const SizedBox(width: 10),
              if (horizontal)
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.black : const Color(0xFF757575),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.black : const Color(0xFF757575),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EditBottomBar extends StatelessWidget {
  const _EditBottomBar({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cancelar = OutlinedButton.icon(
            onPressed: state.saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
          );
          final guardar = FilledButton.icon(
            key: const Key('guardar_cambios'),
            onPressed: state.saving
                ? null
                : () => context.read<ProductoFormBloc>().add(
                    const ProductoFormGuardado(),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: state.saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar cambios'),
          );
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [guardar, const SizedBox(height: 8), cancelar],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [cancelar, guardar],
          );
        },
      ),
    ),
  );
}

class _SeccionEdicionActual extends StatelessWidget {
  const _SeccionEdicionActual({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: switch (state.paso) {
        0 => _PasoGeneralEdicion(state: state),
        1 => _PasoTipo(state: state),
        2 => _PasoAtributos(state: state),
        3 => _PasoPresentaciones(
          state: state,
          mostrarPresentaciones: true,
          mostrarPrecios: false,
        ),
        4 => _PasoPresentaciones(
          state: state,
          mostrarPresentaciones: false,
          mostrarPrecios: true,
        ),
        5 => _PasoImagenes(state: state),
        _ => _PasoEstado(state: state),
      },
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.paso, required this.tipoRegistro});

  final int paso;
  final String tipoRegistro;

  static const _pasosInternos = [0, 1, 3, 4, 5, 6];
  static const _nombres = [
    'Empresa, marca y categoría',
    'Producto y variantes',
    'Venta, presentaciones y logística',
    'Precios',
    'Imágenes y archivos',
    'Publicación y revisión',
  ];
  static const _subtitulos = [
    'Selecciona la clasificación comercial del producto.',
    'Define el producto vendible y sus variantes en una sola pantalla.',
    'Configura unidades de venta, equivalencias y empaques.',
    'Asigna precios o deja combinaciones pendientes de cotización.',
    'Adjunta fotografías y define la imagen principal.',
    'Comprueba la información antes de publicar el producto.',
  ];

  int get _indiceVisual {
    final index = _pasosInternos.indexOf(paso);
    return index < 0 ? 1 : index;
  }

  String get _nombreActual {
    if (_indiceVisual != 1) return _nombres[_indiceVisual];
    return switch (tipoRegistro) {
      'matriz' => 'Producto y matriz de variantes',
      'unico' => 'Producto único',
      _ => 'Producto y lista de variantes',
    };
  }

  String get _subtituloActual {
    if (_indiceVisual != 1) return _subtitulos[_indiceVisual];
    return switch (tipoRegistro) {
      'matriz' =>
        'Define el nombre general y genera combinaciones por dos ejes.',
      'unico' =>
        'Completa el único artículo vendible; la familia se creará automáticamente.',
      _ => 'Define el nombre general y registra sus artículos vendibles.',
    };
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontalPadding = constraints.maxWidth < 500 ? 16.0 : 28.0;
      final current = _indiceVisual;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          16,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < _pasosInternos.length;
                      index++
                    ) ...[
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index <= current
                                ? const Color(0xFFFFC500)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                      Tooltip(
                        message: 'Ir al paso ${index + 1}: ${_nombres[index]}',
                        child: Semantics(
                          button: true,
                          selected: index == current,
                          label: 'Paso ${index + 1}: ${_nombres[index]}',
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: ValueKey('paso_flujo_${index + 1}'),
                              customBorder: const CircleBorder(),
                              onTap: () => context.read<ProductoFormBloc>().add(
                                ProductoFormPasoSeleccionado(
                                  _pasosInternos[index],
                                ),
                              ),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index <= current
                                      ? const Color(0xFFFFC500)
                                      : Colors.white,
                                  border: Border.all(
                                    color: index <= current
                                        ? const Color(0xFFFFC500)
                                        : const Color(0xFFD0D5DD),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: constraints.maxWidth < 500 ? 12 : 16),
            Text(
              _nombreActual,
              style: GoogleFonts.inter(
                color: const Color(0xFF1A1A1A),
                fontSize: constraints.maxWidth < 500 ? 18 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtituloActual,
              style: GoogleFonts.inter(
                color: const Color(0xFF667085),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PasoActual extends StatelessWidget {
  const _PasoActual({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    if (state.paso == 3) {
      return ProductoVentaLogisticaStep(state: state);
    }
    if (state.paso == 4) {
      return ProductoPreciosStep(state: state);
    }
    if (state.paso == 5) {
      return ProductoImagenesStep(state: state);
    }
    if (state.paso == 6) {
      return ProductoRevisionStep(state: state);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: switch (state.paso) {
          0 => _PasoClasificacion(state: state),
          1 || 2 => _PasoFamiliaTipo(state: state),
          _ => _PasoEstado(state: state),
        },
      ),
    );
  }
}

class _PasoClasificacion extends StatelessWidget {
  const _PasoClasificacion({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth = constraints.maxWidth < 720
          ? 680.0
          : constraints.maxWidth - 40;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _dropdown(
                            context,
                            label: 'Empresa *',
                            value: state.empresa,
                            items: state.datos!.empresas,
                            onChanged: (value) =>
                                ProductoFormClasificacionCambiada(
                                  empresa: value,
                                ),
                            icon: Icons.business_outlined,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _dropdown(
                            context,
                            label: 'Marca *',
                            value: state.marca,
                            items: state.marcasDisponibles,
                            onChanged: (value) =>
                                ProductoFormClasificacionCambiada(marca: value),
                            icon: Icons.storefront_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _dropdown(
                            context,
                            label: 'Categoría *',
                            value: state.categoria,
                            items: state.categoriasDisponibles,
                            onChanged: (value) =>
                                ProductoFormClasificacionCambiada(
                                  categoria: value,
                                ),
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _dropdown(
                            context,
                            label: 'Subcategoría',
                            value: state.subcategoria,
                            items: state.subcategorias,
                            onChanged: (value) =>
                                ProductoFormClasificacionCambiada(
                                  subcategoria: value,
                                ),
                            icon: Icons.layers_outlined,
                            helperText:
                                'Opcional si la categoría no tiene hijos.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required ProductoFormEvent Function(String?) onChanged,
    required IconData icon,
    String? helperText,
  }) => SizedBox(
    height: helperText != null ? 115 : 85,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('$label-$value-${items.join('|')}'),
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          menuMaxHeight: 300,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFFFC500), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFC500), width: 2),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: items.isEmpty
              ? null
              : (value) =>
                    context.read<ProductoFormBloc>().add(onChanged(value)),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              helperText,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ] else
          const SizedBox(height: 20),
      ],
    ),
  );
}

class _PasoFamiliaTipo extends StatelessWidget {
  const _PasoFamiliaTipo({required this.state});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 10 : 20,
              compact ? 12 : 20,
              0,
            ),
            child: _configurationCard(context, compact: compact),
          ),
          SizedBox(height: compact ? 8 : 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey('editor-${state.tipoRegistro}'),
                child: switch (state.tipoRegistro) {
                  'matriz' => ProductoMatrizStep(state: state),
                  'unico' => ProductoUnicoStep(state: state),
                  _ => ProductoVariantesStep(state: state),
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _configurationCard(
    BuildContext context, {
    required bool compact,
  }) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD5DDE8)),
    ),
    child: Padding(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Cómo se organiza este producto?',
            style: TextStyle(
              color: const Color(0xFF20242B),
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 5),
            const Text(
              'Elige una opción. Los datos del artículo se completan debajo.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
          SizedBox(height: compact ? 10 : 14),
          _typeSelector(context, compact: compact),
          SizedBox(height: compact ? 12 : 16),
          if (state.tipoRegistro == 'unico')
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compact ? 9 : 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: Color(0xFF8A6700)),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'El nombre general se tomará del nombre comercial.',
                      style: TextStyle(
                        color: Color(0xFF5F4A00),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _familyFields(context, compact: compact),
        ],
      ),
    ),
  );

  Widget _typeSelector(BuildContext context, {required bool compact}) {
    final options = [
      (
        value: 'unico',
        title: 'Producto único',
        subtitle: 'Un artículo',
        icon: Icons.inventory_2_outlined,
      ),
      (
        value: 'variantes',
        title: 'Lista de variantes',
        subtitle: 'Medidas o modelos',
        icon: Icons.view_list_outlined,
      ),
      (
        value: 'matriz',
        title: 'Matriz',
        subtitle: 'Dos ejes',
        icon: Icons.grid_view_outlined,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              SizedBox(
                width: 176,
                child: _typeOption(
                  context,
                  value: options[index].value,
                  title: options[index].title,
                  subtitle: options[index].subtitle,
                  icon: options[index].icon,
                  compact: true,
                ),
              ),
              if (index < options.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          Expanded(
            child: _typeOption(
              context,
              value: options[index].value,
              title: options[index].title,
              subtitle: options[index].subtitle,
              icon: options[index].icon,
              compact: false,
            ),
          ),
          if (index < options.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _familyFields(BuildContext context, {required bool compact}) {
    final name = TextFormField(
      key: const Key('familia_nombre'),
      initialValue: state.nombre,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(nombre: value),
      ),
      decoration: const InputDecoration(
        labelText: 'Nombre general del producto *',
        hintText: 'Ej. Broca para metal HSS',
        helperText: 'Agrupa las medidas o modelos del mismo producto.',
        helperMaxLines: 2,
        border: OutlineInputBorder(),
      ),
    );

    final description = TextFormField(
      key: const Key('familia_descripcion'),
      initialValue: state.descripcion,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(descripcion: value),
      ),
      maxLines: compact ? 2 : 3,
      decoration: const InputDecoration(
        labelText: 'Descripción general',
        hintText: 'Características compartidas por las variantes.',
        border: OutlineInputBorder(),
      ),
    );

    if (compact) {
      return Column(children: [name, const SizedBox(height: 10), description]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: name),
        const SizedBox(width: 12),
        Expanded(child: description),
      ],
    );
  }

  Widget _typeOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool compact,
  }) {
    final selected = state.tipoRegistro == value;

    return InkWell(
      onTap: () =>
          context.read<ProductoFormBloc>().add(ProductoFormTipoCambiado(value)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 64 : 76),
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC500).withValues(alpha: .12)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFC500) : const Color(0xFFD5DDE8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF20242B), size: compact ? 20 : 24),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF20242B),
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFC500),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _PasoGeneralEdicion extends StatelessWidget {
  const _PasoGeneralEdicion({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => _StepCard(
    title: 'Información general',
    subtitle: 'Edita la identificación y clasificación del producto.',
    children: [
      LayoutBuilder(
        builder: (context, constraints) => _ResponsiveFields(
          stacked: constraints.maxWidth < 620,
          fields: [
            _editDropdown(
              context,
              'Empresa *',
              state.empresa,
              state.datos!.empresas,
              (value) => ProductoFormClasificacionCambiada(empresa: value),
            ),
            _editDropdown(
              context,
              'Marca *',
              state.marca,
              state.marcasDisponibles,
              (value) => ProductoFormClasificacionCambiada(marca: value),
            ),
          ],
          action: const SizedBox.shrink(),
          showAction: false,
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) => _ResponsiveFields(
          stacked: constraints.maxWidth < 620,
          fields: [
            _editDropdown(
              context,
              'Categoría *',
              state.categoria,
              state.categoriasDisponibles,
              (value) => ProductoFormClasificacionCambiada(categoria: value),
            ),
            _editDropdown(
              context,
              'Subcategoría *',
              state.subcategoria,
              state.subcategorias,
              (value) => ProductoFormClasificacionCambiada(subcategoria: value),
            ),
          ],
          action: const SizedBox.shrink(),
          showAction: false,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: state.codigo,
        readOnly: true,
        decoration: _decoration(
          'Código interno',
          Icons.qr_code_2,
          helperText: 'Se genera automáticamente y no cambia al renombrar.',
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: state.nombre,
        onChanged: (value) => context.read<ProductoFormBloc>().add(
          ProductoFormFamiliaCambiada(nombre: value),
        ),
        decoration: _decoration(
          'Nombre de la familia *',
          Icons.inventory_2_outlined,
          helperText: 'Nombre visible para vendedores y clientes.',
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: state.descripcion,
        maxLines: 4,
        onChanged: (value) => context.read<ProductoFormBloc>().add(
          ProductoFormFamiliaCambiada(descripcion: value),
        ),
        decoration: _decoration(
          'Descripción general',
          Icons.notes,
          helperText: 'Describe el uso o las características generales.',
        ),
      ),
    ],
  );

  Widget _editDropdown(
    BuildContext context,
    String label,
    String? value,
    List<String> items,
    ProductoFormEvent Function(String?) event,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label|$value|${items.join(',')}'),
    initialValue: items.contains(value) ? value : null,
    isExpanded: true,
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: items.isEmpty
        ? null
        : (value) => context.read<ProductoFormBloc>().add(event(value)),
    decoration: _decoration(label, Icons.keyboard_arrow_down),
  );
}

class _PasoTipo extends StatelessWidget {
  const _PasoTipo({required this.state});
  final ProductoFormState state;
  @override
  Widget build(BuildContext context) {
    const opciones = [
      (
        'unico',
        'Producto único',
        'Una sola variante, como un martillo específico.',
        Icons.inventory_2_outlined,
      ),
      (
        'variantes',
        'Producto con variantes',
        'Distintas medidas o modelos.',
        Icons.style_outlined,
      ),
      (
        'matriz',
        'Generar por matriz',
        'Combinaciones de diámetro y largo.',
        Icons.grid_view_outlined,
      ),
    ];
    return _StepCard(
      title: 'Tipo de registro',
      subtitle: 'Elige cómo se organizarán sus variantes.',
      children: opciones
          .map(
            (op) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => context.read<ProductoFormBloc>().add(
                  ProductoFormTipoCambiado(op.$1),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.tipoRegistro == op.$1
                          ? const Color(0xFFFFC500)
                          : const Color(0xFFE8E8E8),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC500).withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(op.$4),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              op.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              op.$3,
                              style: const TextStyle(color: Color(0xFF757575)),
                            ),
                          ],
                        ),
                      ),
                      if (state.tipoRegistro == op.$1)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFFFC500),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PasoAtributos extends StatelessWidget {
  const _PasoAtributos({required this.state});
  final ProductoFormState state;
  @override
  Widget build(BuildContext context) {
    final attrs = state.atributosDisponibles
        .where((item) => !item.esVariante || state.tipoRegistro != 'unico')
        .toList();
    return _StepCard(
      title: 'Atributos del producto',
      subtitle: 'Campos definidos en SQLite para ${state.categoria}.',
      children: attrs.isEmpty
          ? const [
              Center(
                child: Text('No se requieren atributos para esta categoría'),
              ),
            ]
          : attrs
                .map(
                  (attr) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: attr.tipo == 'booleano'
                        ? SwitchListTile(
                            title: Text(attr.nombre),
                            value: state.atributos[attr.nombre] == 'Sí',
                            onChanged: (value) =>
                                context.read<ProductoFormBloc>().add(
                                  ProductoFormAtributoCambiado(
                                    attr.nombre,
                                    value ? 'Sí' : 'No',
                                  ),
                                ),
                          )
                        : TextFormField(
                            initialValue: state.atributos[attr.nombre] ?? '',
                            keyboardType: attr.tipo == 'numero'
                                ? TextInputType.number
                                : TextInputType.text,
                            onChanged: (value) =>
                                context.read<ProductoFormBloc>().add(
                                  ProductoFormAtributoCambiado(
                                    attr.nombre,
                                    value,
                                  ),
                                ),
                            decoration: _decoration(attr.nombre, Icons.tune),
                          ),
                  ),
                )
                .toList(),
    );
  }
}

class _PasoPresentaciones extends StatefulWidget {
  const _PasoPresentaciones({
    required this.state,
    this.mostrarPresentaciones = true,
    this.mostrarPrecios = true,
  });
  final ProductoFormState state;
  final bool mostrarPresentaciones;
  final bool mostrarPrecios;
  @override
  State<_PasoPresentaciones> createState() => _PasoPresentacionesState();
}

class _PasoPresentacionesState extends State<_PasoPresentaciones> {
  final nombre = TextEditingController(),
      unidad = TextEditingController(),
      valor = TextEditingController();
  String? presentacionPrecio;

  @override
  void initState() {
    super.initState();
    presentacionPrecio = widget.state.presentaciones.firstOrNull?.nombre;
  }

  @override
  void didUpdateWidget(covariant _PasoPresentaciones oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nombres = widget.state.presentaciones.map((item) => item.nombre);
    if (presentacionPrecio != null && !nombres.contains(presentacionPrecio)) {
      presentacionPrecio = null;
    }
    if (presentacionPrecio == null && widget.state.presentaciones.isNotEmpty) {
      presentacionPrecio = widget.state.presentaciones.first.nombre;
    }
  }

  @override
  void dispose() {
    nombre.dispose();
    unidad.dispose();
    valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StepCard(
    title: widget.mostrarPresentaciones && widget.mostrarPrecios
        ? 'Presentaciones y precios'
        : widget.mostrarPresentaciones
        ? 'Presentaciones de venta'
        : 'Precios por presentación',
    subtitle: widget.mostrarPresentaciones
        ? 'Agrega al menos una presentación para comercializar el producto.'
        : 'Asigna o actualiza el precio de cada presentación.',
    children: [
      if (widget.mostrarPresentaciones) ...[
        if (widget.mostrarPrecios)
          const Text(
            'Presentaciones de venta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 12),
        if (widget.state.presentaciones.isEmpty)
          const _EmptySection(
            icon: Icons.inventory_2_outlined,
            text: 'Todavía no agregaste presentaciones.',
          ),
        ...widget.state.presentaciones.asMap().entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.value.nombre),
              subtitle: Text(entry.value.unidad),
              trailing: IconButton(
                tooltip: 'Eliminar presentación',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => context.read<ProductoFormBloc>().add(
                  ProductoFormPresentacionEliminada(entry.key),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => _ResponsiveFields(
            stacked: constraints.maxWidth < 560,
            fields: [
              TextField(
                controller: nombre,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Nombre (ej. Docena)', Icons.inventory),
              ),
              TextField(
                controller: unidad,
                onSubmitted: (_) => _agregarPresentacion(),
                decoration: _decoration(
                  'Equivalencia (ej. 12 UND)',
                  Icons.straighten,
                ),
              ),
            ],
            action: FilledButton.icon(
              key: const Key('agregar_presentacion'),
              onPressed: _agregarPresentacion,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
        ),
      ],
      if (widget.mostrarPrecios) ...[
        if (widget.mostrarPresentaciones) const Divider(height: 44),
        if (widget.mostrarPresentaciones)
          const Text(
            'Precios por presentación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 4),
        const Text(
          'Si no agregas precios, el producto quedará marcado como “Sin precio”.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
        const SizedBox(height: 12),
        if (widget.state.precios.isEmpty)
          const _EmptySection(
            icon: Icons.payments_outlined,
            text: 'No hay precios registrados.',
          ),
        ...widget.state.precios.asMap().entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.value.presentacion),
              subtitle: Text('S/ ${entry.value.valor.toStringAsFixed(2)}'),
              trailing: IconButton(
                tooltip: 'Eliminar precio',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => context.read<ProductoFormBloc>().add(
                  ProductoFormPrecioEliminado(entry.key),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => _ResponsiveFields(
            stacked: constraints.maxWidth < 560,
            fields: [
              DropdownButtonFormField<String>(
                key: ValueKey(
                  widget.state.presentaciones
                      .map((item) => item.nombre)
                      .join('|'),
                ),
                initialValue: presentacionPrecio,
                isExpanded: true,
                items: widget.state.presentaciones
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.nombre,
                        child: Text(
                          item.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.state.presentaciones.isEmpty
                    ? null
                    : (value) => setState(() => presentacionPrecio = value),
                decoration: _decoration('Presentación', Icons.list),
              ),
              TextField(
                controller: valor,
                enabled: widget.state.presentaciones.isNotEmpty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => _agregarPrecio(),
                decoration: _decoration(
                  'Precio en soles',
                  Icons.payments_outlined,
                ),
              ),
            ],
            action: FilledButton.icon(
              key: const Key('agregar_precio'),
              onPressed: widget.state.presentaciones.isEmpty
                  ? null
                  : _agregarPrecio,
              icon: const Icon(Icons.add),
              label: const Text('Agregar precio'),
            ),
          ),
        ),
      ],
    ],
  );

  void _agregarPresentacion() {
    final nombreValue = nombre.text.trim();
    final unidadValue = unidad.text.trim();
    if (nombreValue.isEmpty || unidadValue.isEmpty) {
      _mensaje('Completa el nombre y la equivalencia de la presentación.');
      return;
    }
    context.read<ProductoFormBloc>().add(
      ProductoFormPresentacionAgregada(
        PresentacionProducto(nombre: nombreValue, unidad: unidadValue),
      ),
    );
    setState(() => presentacionPrecio = nombreValue);
    nombre.clear();
    unidad.clear();
  }

  void _agregarPrecio() {
    final price = double.tryParse(valor.text.trim().replaceAll(',', '.'));
    if (presentacionPrecio == null) {
      _mensaje('Selecciona una presentación.');
      return;
    }
    if (price == null || price <= 0) {
      _mensaje('Ingresa un precio mayor que cero.');
      return;
    }
    context.read<ProductoFormBloc>().add(
      ProductoFormPrecioAgregado(
        PrecioProducto(presentacion: presentacionPrecio!, valor: price),
      ),
    );
    valor.clear();
  }

  void _mensaje(String texto) {
    AppNotice.info(context, texto);
  }
}

class _PasoImagenes extends StatelessWidget {
  const _PasoImagenes({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => _StepCard(
    title: 'Imágenes del producto',
    subtitle:
        'Puedes adjuntar varias imágenes. La primera se mostrará como principal en el catálogo.',
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final galeria = FilledButton.icon(
            key: const Key('seleccionar_imagenes'),
            onPressed: () => _elegirGaleria(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir imágenes'),
          );
          final camara = OutlinedButton.icon(
            onPressed: () => _tomarFoto(context),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tomar foto'),
          );
          if (constraints.maxWidth < 440) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [galeria, const SizedBox(height: 8), camara],
            );
          }
          return Row(children: [galeria, const SizedBox(width: 10), camara]);
        },
      ),
      const SizedBox(height: 14),
      Text(
        '${state.imagenesPaths.length} ${state.imagenesPaths.length == 1 ? 'imagen adjunta' : 'imágenes adjuntas'}',
        key: const Key('cantidad_imagenes'),
        style: const TextStyle(
          color: Color(0xFF616161),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      if (state.imagenesPaths.isEmpty)
        const _EmptySection(
          icon: Icons.add_photo_alternate_outlined,
          text: 'Todavía no agregaste imágenes. Este campo es opcional.',
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 190,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: state.imagenesPaths.length,
          itemBuilder: (context, index) => _ImagenProductoCard(
            path: state.imagenesPaths[index],
            index: index,
          ),
        ),
    ],
  );

  Future<void> _elegirGaleria(BuildContext context) async {
    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty && context.mounted) {
        context.read<ProductoFormBloc>().add(
          ProductoFormImagenesAgregadas(
            images.map((image) => image.path).toList(),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) _mostrarErrorImagen(context);
    }
  }

  Future<void> _tomarFoto(BuildContext context) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null && context.mounted) {
        context.read<ProductoFormBloc>().add(
          ProductoFormImagenesAgregadas([image.path]),
        );
      }
    } catch (_) {
      if (context.mounted) _mostrarErrorImagen(context);
    }
  }

  void _mostrarErrorImagen(BuildContext context) {
    AppNotice.error(context, 'No se pudieron seleccionar las imágenes.');
  }
}

class _ImagenProductoCard extends StatelessWidget {
  const _ImagenProductoCard({required this.path, required this.index});
  final String path;
  final int index;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          key: ValueKey('imagen_producto_$index'),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFF0F0F0),
            child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
          ),
        ),
      ),
      Positioned(
        top: 7,
        right: 7,
        child: PopupMenuButton<String>(
          tooltip: 'Opciones de imagen',
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .92),
            foregroundColor: Colors.black,
          ),
          onSelected: (action) async {
            final bloc = context.read<ProductoFormBloc>();
            if (action == 'principal') {
              bloc.add(ProductoFormImagenPrincipalCambiada(index));
            } else if (action == 'eliminar') {
              bloc.add(ProductoFormImagenEliminada(index));
            } else if (action == 'reemplazar') {
              try {
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 1920,
                  maxHeight: 1920,
                );
                if (image != null && context.mounted) {
                  bloc.add(ProductoFormImagenReemplazada(index, image.path));
                }
              } catch (_) {
                if (context.mounted) {
                  AppNotice.error(context, 'No se pudo reemplazar la imagen.');
                }
              }
            } else if (action == 'anterior') {
              bloc.add(ProductoFormImagenReordenada(index, index - 1));
            } else if (action == 'siguiente') {
              bloc.add(ProductoFormImagenReordenada(index, index + 1));
            } else if (action == 'ver') {
              await showDialog<void>(
                context: context,
                barrierColor: Colors.black87,
                builder: (dialogContext) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        minScale: .5,
                        maxScale: 4,
                        child: Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 260,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white,
                                size: 54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filled(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'ver',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.zoom_in),
                title: Text('Previsualizar'),
              ),
            ),
            const PopupMenuItem(
              value: 'reemplazar',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.find_replace_outlined),
                title: Text('Reemplazar'),
              ),
            ),
            if (index > 0)
              const PopupMenuItem(
                value: 'principal',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.star_outline),
                  title: Text('Hacer principal'),
                ),
              ),
            if (index > 0)
              const PopupMenuItem(
                value: 'anterior',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.arrow_back),
                  title: Text('Mover antes'),
                ),
              ),
            if (index <
                context.read<ProductoFormBloc>().state.imagenesPaths.length - 1)
              const PopupMenuItem(
                value: 'siguiente',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.arrow_forward),
                  title: Text('Mover después'),
                ),
              ),
            const PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                title: Text('Eliminar'),
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
      if (index == 0)
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC500),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 15),
                SizedBox(width: 4),
                Text(
                  'Principal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _PasoEstado extends StatelessWidget {
  const _PasoEstado({required this.state});
  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => _StepCard(
    title: 'Estado y auditoría',
    subtitle: 'Controla la disponibilidad del producto en el catálogo.',
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Producto activo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          state.activo
              ? 'Disponible para consultas y operaciones.'
              : 'Oculto de las operaciones activas, sin eliminar sus datos.',
        ),
        value: state.activo,
        activeTrackColor: const Color(0xFFFFC500),
        onChanged: (value) => context.read<ProductoFormBloc>().add(
          ProductoFormEstadoCambiado(value),
        ),
      ),
      const Divider(height: 32),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.calendar_today_outlined),
        title: const Text('Fecha de creación'),
        subtitle: Text(_fecha(state.creadoEn)),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.storage_outlined),
        title: Text('Persistencia'),
        subtitle: Text('Los cambios se guardarán en la base de datos SQLite.'),
      ),
    ],
  );

  String _fecha(DateTime? value) => value == null
      ? 'No disponible'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({
    required this.stacked,
    required this.fields,
    required this.action,
    this.showAction = true,
  });
  final bool stacked;
  final List<Widget> fields;
  final Widget action;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            fields[i],
            if (i < fields.length - 1) const SizedBox(height: 12),
          ],
          if (showAction) ...[const SizedBox(height: 12), action],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          Expanded(child: fields[index]),
          if (index < fields.length - 1) const SizedBox(width: 10),
        ],
        if (showAction) ...[
          const SizedBox(width: 10),
          SizedBox(height: 56, child: action),
        ],
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF757575))),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.all(compact ? 12 : 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF757575)),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.state});
  final ProductoFormState state;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final anterior = TextButton.icon(
          onPressed:
              state.paso == 0 ||
                  (state.paso == 1 && state.edicionVariantePendiente)
              ? null
              : () => context.read<ProductoFormBloc>().add(
                  const ProductoFormPasoAnterior(),
                ),
          icon: const Icon(Icons.arrow_back),
          label: Text(compact ? 'Atrás' : 'Anterior'),
        );
        final siguiente = FilledButton.icon(
          onPressed: state.saving
              ? null
              : () {
                  if (state.paso == 2 &&
                      state.tipoRegistro == 'unico' &&
                      !productoUnicoStepController.validateAndSave()) {
                    return;
                  }
                  context.read<ProductoFormBloc>().add(
                    state.paso < 6
                        ? const ProductoFormPasoSiguiente()
                        : const ProductoFormGuardado(),
                  );
                },
          icon: state.saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(state.paso < 6 ? Icons.arrow_forward : Icons.check),
          label: Text(
            state.paso == 6
                ? 'Publicar'
                : state.paso == 1
                ? compact
                      ? 'Siguiente'
                      : 'Siguiente: venta y empaques'
                : 'Continuar',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFC500),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 28,
              vertical: 14,
            ),
          ),
        );
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 24,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: anterior),
              ),
              const SizedBox(width: 8),
              siguiente,
            ],
          ),
        );
      },
    ),
  );
}

InputDecoration _decoration(
  String label,
  IconData icon, {
  String? helperText,
}) => InputDecoration(
  labelText: label,
  floatingLabelBehavior: FloatingLabelBehavior.always,
  helperText: helperText,
  helperMaxLines: 2,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  ),
);
