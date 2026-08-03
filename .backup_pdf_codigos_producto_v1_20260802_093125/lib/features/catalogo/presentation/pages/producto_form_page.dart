import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/repositories/catalogo_repository.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';
import '../widgets/producto_matriz_step.dart';
import '../widgets/producto_atributos_familia.dart';
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
        builder: (context, state) => _RegistrarProductoScaffold(state: state),
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
        state.editando ? 'Editar producto' : 'Nuevo producto',
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
              _StepIndicator(state: state),
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.state});

  final ProductoFormState state;

  static const _pasosInternos = ProductoFormState.pasosFlujo;
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
    'Define la familia, sus características y los artículos vendibles.',
    'Configura unidades de venta, equivalencias y empaques.',
    'Asigna precios por lista, variante y presentación.',
    'Adjunta fotografías y define la imagen principal.',
    'Comprueba la información antes de publicar el producto.',
  ];

  int get _indiceVisual {
    final index = _pasosInternos.indexOf(state.paso);
    return index < 0 ? 1 : index;
  }

  String get _nombreActual {
    if (_indiceVisual != 1) return _nombres[_indiceVisual];
    return switch (state.tipoRegistro) {
      'matriz' => 'Producto y matriz de variantes',
      'unico' => 'Producto único',
      _ => 'Producto y lista de variantes',
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
                      Builder(
                        builder: (context) {
                          final internalStep = _pasosInternos[index];
                          final accessible = state.pasoEsAccesible(
                            internalStep,
                          );
                          return Tooltip(
                            message: accessible
                                ? 'Ir al paso ${index + 1}: ${_nombres[index]}'
                                : 'Completa los pasos anteriores',
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: ValueKey('paso_flujo_${index + 1}'),
                                customBorder: const CircleBorder(),
                                onTap: accessible
                                    ? () =>
                                          context.read<ProductoFormBloc>().add(
                                            ProductoFormPasoSeleccionado(
                                              internalStep,
                                            ),
                                          )
                                    : null,
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
                                      color: accessible
                                          ? const Color(0xFFFFC500)
                                          : const Color(0xFFD0D5DD),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(
                                      color: accessible
                                          ? const Color(0xFF1A1A1A)
                                          : const Color(0xFF98A2B3),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
              _subtitulos[_indiceVisual],
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
          _ => ProductoRevisionStep(state: state),
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
              : (nextValue) async {
                  if (nextValue == value) return;
                  var accepted = true;
                  if (state.tieneConfiguracionDependiente) {
                    accepted =
                        await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Reiniciar configuración'),
                            content: const Text(
                              'Cambiar la clasificación reiniciará atributos, '
                              'variantes, presentaciones, precios e imágenes '
                              'dependientes para evitar datos incompatibles.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Cambiar y reiniciar'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  }
                  if (!accepted || !context.mounted) return;
                  context.read<ProductoFormBloc>().add(onChanged(nextValue));
                },
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
      return NestedScrollView(
        key: const Key('producto_estructura_scroll'),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                compact ? 10 : 20,
                compact ? 12 : 20,
                0,
              ),
              child: _configurationCard(context, compact: compact),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: compact ? 8 : 14)),
        ],
        body: AnimatedSwitcher(
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
          const SizedBox(height: 5),
          const Text(
            'Elige la estructura que corresponda al catálogo del proveedor.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          SizedBox(height: compact ? 10 : 14),
          _typeSelector(context, compact: compact),
          SizedBox(height: compact ? 12 : 16),
          if (state.tipoRegistro == 'unico')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'El nombre de la familia se tomará del nombre comercial.',
                style: TextStyle(color: Color(0xFF5F4A00), fontSize: 12),
              ),
            )
          else ...[
            _familyFields(context, compact: compact),
            if (state.atributosFamilia.isNotEmpty) ...[
              const SizedBox(height: 14),
              ProductoAtributosFamilia(state: state),
            ],
          ],
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
        subtitle: 'Dos atributos como ejes',
        icon: Icons.grid_view_outlined,
      ),
    ];
    final children = options
        .map(
          (option) => SizedBox(
            width: compact ? 176 : null,
            child: _typeOption(
              context,
              value: option.value,
              title: option.title,
              subtitle: option.subtitle,
              icon: option.icon,
              compact: compact,
            ),
          ),
        )
        .toList();
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1) const SizedBox(width: 10),
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
        labelText: 'Nombre de la familia *',
        hintText: 'Ej. Broca para metal HSS',
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
        labelText: 'Descripción compartida (opcional)',
        hintText: 'Información que aplica a todas las variantes.',
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
      key: Key('tipo_producto_$value'),
      onTap: () async {
        if (selected) return;
        var accepted = true;
        if (state.tieneConfiguracionDependiente) {
          accepted =
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Cambiar estructura del producto'),
                  content: const Text(
                    'Se reiniciarán variantes, presentaciones, precios e '
                    'imágenes dependientes para evitar referencias inválidas.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Cambiar y reiniciar'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
        if (!accepted || !context.mounted) return;
        context.read<ProductoFormBloc>().add(ProductoFormTipoCambiado(value));
      },
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
