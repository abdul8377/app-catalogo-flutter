import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/estructura_catalogo.dart';
import '../../domain/repositories/estructura_catalogo_repository.dart';
import '../bloc/estructura_catalogo_bloc.dart';
import '../bloc/estructura_catalogo_event.dart';
import '../bloc/estructura_catalogo_state.dart';
import 'estructura_catalogo_integrada.dart';

class EstructuraCatalogoPage extends StatelessWidget {
  const EstructuraCatalogoPage({this.puedeAdministrar = true, super.key});

  final bool puedeAdministrar;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        EstructuraCatalogoBloc(context.read<EstructuraCatalogoRepository>())
          ..add(const EstructuraCatalogoStarted()),
    child: puedeAdministrar
        ? const EstructuraCatalogoIntegradaView()
        : _EstructuraCatalogoView(puedeAdministrar: puedeAdministrar),
  );
}

class _EstructuraCatalogoView extends StatelessWidget {
  const _EstructuraCatalogoView({required this.puedeAdministrar});

  static const primary = Color(0xFFFFC500);
  final bool puedeAdministrar;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<EstructuraCatalogoBloc, EstructuraCatalogoState>(
    listenWhen: (previous, current) =>
        previous.error != current.error || previous.mensaje != current.mensaje,
    listener: (context, state) {
      if (state.error != null) {
        AppNotice.error(context, state.error!);
      } else if (state.mensaje != null) {
        AppNotice.success(context, state.mensaje!);
      }
      context.read<EstructuraCatalogoBloc>().add(
        const MensajeEstructuraConsumido(),
      );
    },
    builder: (context, state) => DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estructura del catálogo',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                puedeAdministrar
                    ? 'Administración local y sincronización pendiente'
                    : 'Consulta de estructura',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (state.saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () => context.read<EstructuraCatalogoBloc>().add(
                  const EstructuraCatalogoRecargada(),
                ),
                icon: const Icon(Icons.refresh),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Empresas', icon: Icon(Icons.business_outlined)),
              Tab(text: 'Marcas', icon: Icon(Icons.sell_outlined)),
              Tab(text: 'Categorías', icon: Icon(Icons.account_tree)),
              Tab(text: 'Relaciones', icon: Icon(Icons.hub_outlined)),
            ],
          ),
        ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _EmpresasView(
                    snapshot: state.snapshot,
                    puedeAdministrar: puedeAdministrar,
                    onNuevo: () => _editarEmpresa(context),
                    onEditar: (value) => _editarEmpresa(context, value),
                    onDetalle: (value) =>
                        _detalleEmpresa(context, value, state.snapshot),
                    onGestionar: (value) => _editarMarca(
                      context,
                      state.snapshot,
                      empresaInicialId: value.id,
                    ),
                    onEstado: (value) => _cambiarEstado(
                      context,
                      tipo: 'empresa',
                      id: value.id,
                      nombre: value.nombre,
                      activoActual: value.activa,
                    ),
                  ),
                  _MarcasView(
                    snapshot: state.snapshot,
                    puedeAdministrar: puedeAdministrar,
                    onNuevo: () => _editarMarca(context, state.snapshot),
                    onEditar: (value) =>
                        _editarMarca(context, state.snapshot, marca: value),
                    onGestionar: (value) =>
                        _gestionarCategorias(context, state.snapshot, value),
                    onEstado: (value) => _cambiarEstado(
                      context,
                      tipo: 'marca',
                      id: value.id,
                      nombre: value.nombre,
                      activoActual: value.activa,
                    ),
                  ),
                  _CategoriasView(
                    snapshot: state.snapshot,
                    puedeAdministrar: puedeAdministrar,
                    onNueva: () => _editarCategoria(context, state.snapshot),
                    onEditar: (value) =>
                        _editarCategoria(context, state.snapshot, value),
                    onEstado: (value) => _cambiarEstado(
                      context,
                      tipo: 'categoria',
                      id: value.id,
                      nombre: value.nombre,
                      activoActual: value.activa,
                    ),
                    onGestionar: (value) => _gestionarCategoriaDesdeCategoria(
                      context,
                      state.snapshot,
                      value,
                    ),
                  ),
                  _RelacionesView(
                    snapshot: state.snapshot,
                    puedeAdministrar: puedeAdministrar,
                  ),
                ],
              ),
      ),
    ),
  );

  Future<void> _editarEmpresa(
    BuildContext context, [
    EmpresaCatalogo? empresa,
  ]) async {
    final result = await showDialog<EmpresaCatalogoDraft>(
      context: context,
      builder: (_) => _EmpresaFormDialog(empresa: empresa),
    );
    if (result != null && context.mounted) {
      context.read<EstructuraCatalogoBloc>().add(
        EmpresaCatalogoGuardada(result, id: empresa?.id),
      );
    }
  }

  Future<void> _editarMarca(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot, {
    MarcaCatalogo? marca,
    int? empresaInicialId,
  }) async {
    final selected = snapshot.relaciones
        .where((item) => item.marcaId == marca?.id && item.activa)
        .map((item) => item.categoriaId)
        .toSet();
    final result = await showDialog<MarcaCatalogoDraft>(
      context: context,
      builder: (_) => _MarcaFormDialog(
        marca: marca,
        empresaInicialId: empresaInicialId,
        empresas: snapshot.empresas,
        categorias: snapshot.categorias.where((item) => item.esRaiz).toList(),
        seleccionInicial: selected,
      ),
    );
    if (result != null && context.mounted) {
      context.read<EstructuraCatalogoBloc>().add(
        MarcaCatalogoGuardada(result, id: marca?.id),
      );
    }
  }

  Future<void> _editarCategoria(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot, [
    CategoriaCatalogo? categoria,
  ]) async {
    final result = await showDialog<CategoriaCatalogoDraft>(
      context: context,
      builder: (_) => _CategoriaFormDialog(
        categoria: categoria,
        categoriasRaiz: snapshot.categorias
            .where((item) => item.esRaiz && item.id != categoria?.id)
            .toList(),
      ),
    );
    if (result != null && context.mounted) {
      context.read<EstructuraCatalogoBloc>().add(
        CategoriaCatalogoGuardada(result, id: categoria?.id),
      );
    }
  }

  Future<void> _gestionarCategorias(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    MarcaCatalogo marca,
  ) async {
    final selected = snapshot.relaciones
        .where((item) => item.marcaId == marca.id && item.activa)
        .map((item) => item.categoriaId)
        .toSet();
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (_) => _CategoriasMarcaDialog(
        marca: marca,
        categorias: snapshot.categorias.where((item) => item.esRaiz).toList(),
        seleccionInicial: selected,
      ),
    );
    if (result != null && context.mounted) {
      context.read<EstructuraCatalogoBloc>().add(
        RelacionesCatalogoGuardadas(marcaId: marca.id, categoriaIds: result),
      );
    }
  }

  Future<void> _gestionarCategoriaDesdeCategoria(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    CategoriaCatalogo categoria,
  ) async {
    final rootId = categoria.categoriaPadreId ?? categoria.id;
    final brand = await showDialog<MarcaCatalogo>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Gestionar marcas · ${categoria.nombre}'),
        children: snapshot.marcas
            .map(
              (marca) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, marca),
                child: ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: Text(marca.nombre),
                  subtitle: Text(marca.empresaNombre),
                  trailing:
                      snapshot.relaciones.any(
                        (item) =>
                            item.marcaId == marca.id &&
                            item.categoriaId == rootId &&
                            item.activa,
                      )
                      ? const Icon(Icons.check_circle, color: primary)
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
    if (brand != null && context.mounted) {
      await _gestionarCategorias(context, snapshot, brand);
    }
  }

  Future<void> _detalleEmpresa(
    BuildContext context,
    EmpresaCatalogo empresa,
    EstructuraCatalogoSnapshot snapshot,
  ) => showDialog<void>(
    context: context,
    builder: (_) => _EmpresaDetalleDialog(
      empresa: empresa,
      marcas: snapshot.marcas
          .where((item) => item.empresaId == empresa.id)
          .toList(),
      categorias: snapshot.categorias
          .where(
            (category) => snapshot.relaciones.any(
              (relation) =>
                  relation.categoriaId == category.id &&
                  relation.activa &&
                  snapshot.marcas.any(
                    (brand) =>
                        brand.id == relation.marcaId &&
                        brand.empresaId == empresa.id,
                  ),
            ),
          )
          .toList(),
    ),
  );

  Future<void> _cambiarEstado(
    BuildContext context, {
    required String tipo,
    required int id,
    required String nombre,
    required bool activoActual,
  }) async {
    var impacto = const ImpactoEstructura(
      productos: 0,
      marcas: 0,
      categorias: 0,
    );
    if (activoActual) {
      impacto = await context
          .read<EstructuraCatalogoRepository>()
          .obtenerImpacto(tipo: tipo, id: id);
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(
          activoActual ? Icons.warning_amber_rounded : Icons.check_circle,
          color: activoActual ? const Color(0xFFE65100) : Colors.green,
        ),
        title: Text(activoActual ? 'Desactivar $nombre' : 'Activar $nombre'),
        content: Text(
          activoActual
              ? 'Dejará de estar disponible para nuevos productos. Se conservarán todos los datos históricos.\n\nImpacto: ${impacto.productos} productos, ${impacto.marcas} marcas y ${impacto.categorias} categorías relacionadas.'
              : 'El registro volverá a estar disponible para nuevas operaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: activoActual ? const Color(0xFFC62828) : primary,
              foregroundColor: activoActual ? Colors.white : Colors.black,
            ),
            child: Text(activoActual ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<EstructuraCatalogoBloc>().add(
        EstadoEstructuraCambiado(tipo: tipo, id: id, activo: !activoActual),
      );
    }
  }
}

class _EmpresasView extends StatelessWidget {
  const _EmpresasView({
    required this.snapshot,
    required this.puedeAdministrar,
    required this.onNuevo,
    required this.onEditar,
    required this.onDetalle,
    required this.onGestionar,
    required this.onEstado,
  });

  final EstructuraCatalogoSnapshot snapshot;
  final bool puedeAdministrar;
  final VoidCallback onNuevo;
  final ValueChanged<EmpresaCatalogo> onEditar;
  final ValueChanged<EmpresaCatalogo> onDetalle;
  final ValueChanged<EmpresaCatalogo> onGestionar;
  final ValueChanged<EmpresaCatalogo> onEstado;

  @override
  Widget build(BuildContext context) => _SectionList<EmpresaCatalogo>(
    title: 'Empresas',
    subtitle: '${snapshot.empresas.length} empresas registradas',
    actionLabel: 'Nueva empresa',
    onAction: puedeAdministrar ? onNuevo : null,
    items: snapshot.empresas,
    itemBuilder: (empresa) => _EntityCard(
      icon: Icons.business_outlined,
      title: empresa.nombre,
      subtitle: [
        if (empresa.ruc.isNotEmpty) 'RUC ${empresa.ruc}',
        if (empresa.telefono.isNotEmpty) empresa.telefono,
        if (empresa.direccion.isNotEmpty) empresa.direccion,
      ].join(' · '),
      active: empresa.activa,
      chips: [
        '${empresa.cantidadMarcas} marcas',
        '${empresa.cantidadCategorias} categorías',
        '${empresa.cantidadProductos} productos',
      ],
      detail: empresa.principalesMarcas.isEmpty
          ? 'Sin marcas principales'
          : 'Marcas: ${empresa.principalesMarcas.take(3).join(', ')}',
      onView: () => onDetalle(empresa),
      onEdit: puedeAdministrar ? () => onEditar(empresa) : null,
      manageLabel: 'Gestionar marcas',
      onManage: puedeAdministrar ? () => onGestionar(empresa) : null,
      onState: puedeAdministrar ? () => onEstado(empresa) : null,
    ),
  );
}

class _MarcasView extends StatelessWidget {
  const _MarcasView({
    required this.snapshot,
    required this.puedeAdministrar,
    required this.onNuevo,
    required this.onEditar,
    required this.onGestionar,
    required this.onEstado,
  });

  final EstructuraCatalogoSnapshot snapshot;
  final bool puedeAdministrar;
  final VoidCallback onNuevo;
  final ValueChanged<MarcaCatalogo> onEditar;
  final ValueChanged<MarcaCatalogo> onGestionar;
  final ValueChanged<MarcaCatalogo> onEstado;

  @override
  Widget build(BuildContext context) => _SectionList<MarcaCatalogo>(
    title: 'Marcas',
    subtitle: '${snapshot.marcas.length} marcas registradas',
    actionLabel: 'Nueva marca',
    onAction: puedeAdministrar ? onNuevo : null,
    items: snapshot.marcas,
    itemBuilder: (marca) => _EntityCard(
      icon: Icons.sell_outlined,
      title: marca.nombre,
      subtitle: 'Empresa propietaria: ${marca.empresaNombre}',
      active: marca.activa,
      chips: [
        '${marca.categorias.length} categorías',
        '${marca.cantidadProductos} productos',
      ],
      detail: marca.categorias.isEmpty
          ? 'Sin categorías asociadas'
          : marca.categorias.join(' · '),
      onView: () => onGestionar(marca),
      onEdit: puedeAdministrar ? () => onEditar(marca) : null,
      manageLabel: 'Gestionar categorías',
      onManage: puedeAdministrar ? () => onGestionar(marca) : null,
      onState: puedeAdministrar ? () => onEstado(marca) : null,
    ),
  );
}

class _CategoriasView extends StatelessWidget {
  const _CategoriasView({
    required this.snapshot,
    required this.puedeAdministrar,
    required this.onNueva,
    required this.onEditar,
    required this.onEstado,
    required this.onGestionar,
  });

  final EstructuraCatalogoSnapshot snapshot;
  final bool puedeAdministrar;
  final VoidCallback onNueva;
  final ValueChanged<CategoriaCatalogo> onEditar;
  final ValueChanged<CategoriaCatalogo> onEstado;
  final ValueChanged<CategoriaCatalogo> onGestionar;

  @override
  Widget build(BuildContext context) {
    final roots = snapshot.categorias.where((item) => item.esRaiz).toList();
    return Column(
      children: [
        _SectionHeader(
          title: 'Categorías y subcategorías',
          subtitle: '${snapshot.categorias.length} elementos jerárquicos',
          actionLabel: 'Nueva categoría',
          onAction: puedeAdministrar ? onNueva : null,
        ),
        Expanded(
          child: roots.isEmpty
              ? const _EmptyState(
                  icon: Icons.account_tree_outlined,
                  message: 'No hay categorías registradas.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: roots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final root = roots[index];
                    final children = snapshot.categorias
                        .where((item) => item.categoriaPadreId == root.id)
                        .toList();
                    return _CategoryTreeCard(
                      category: root,
                      children: children,
                      puedeAdministrar: puedeAdministrar,
                      onEdit: onEditar,
                      onState: onEstado,
                      onManage: onGestionar,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RelacionesView extends StatefulWidget {
  const _RelacionesView({
    required this.snapshot,
    required this.puedeAdministrar,
  });

  final EstructuraCatalogoSnapshot snapshot;
  final bool puedeAdministrar;

  @override
  State<_RelacionesView> createState() => _RelacionesViewState();
}

class _RelacionesViewState extends State<_RelacionesView> {
  int? empresaId;
  int? marcaId;
  Set<int> categoryIds = {};

  @override
  void didUpdateWidget(covariant _RelacionesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (empresaId != null &&
        !widget.snapshot.empresas.any((item) => item.id == empresaId)) {
      empresaId = null;
      marcaId = null;
      categoryIds = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.snapshot.marcas
        .where((item) => item.empresaId == empresaId)
        .toList();
    final roots = widget.snapshot.categorias
        .where((item) => item.esRaiz)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empresas → Marcas → Categorías',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Selecciona una empresa, una de sus marcas y define las categorías habilitadas.',
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sections = [
                    _RelationPanel(
                      title: '1. Empresa',
                      children: widget.snapshot.empresas
                          .map(
                            (item) => ListTile(
                              selected: empresaId == item.id,
                              selectedTileColor: const Color(
                                0xFFFFC500,
                              ).withValues(alpha: .12),
                              leading: Icon(
                                empresaId == item.id
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: empresaId == item.id
                                    ? const Color(0xFFFFC500)
                                    : null,
                              ),
                              title: Text(item.nombre),
                              subtitle: Text(
                                item.activa ? 'Activa' : 'Inactiva',
                              ),
                              onTap: item.activa
                                  ? () => setState(() {
                                      empresaId = item.id;
                                      marcaId = null;
                                      categoryIds = {};
                                    })
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                    _RelationPanel(
                      title: '2. Marca',
                      children: brands.isEmpty
                          ? const [
                              _EmptyState(
                                icon: Icons.sell_outlined,
                                message: 'Selecciona una empresa.',
                              ),
                            ]
                          : brands
                                .map(
                                  (item) => ListTile(
                                    selected: marcaId == item.id,
                                    selectedTileColor: const Color(
                                      0xFFFFC500,
                                    ).withValues(alpha: .12),
                                    leading: Icon(
                                      marcaId == item.id
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: marcaId == item.id
                                          ? const Color(0xFFFFC500)
                                          : null,
                                    ),
                                    title: Text(item.nombre),
                                    onTap: item.activa
                                        ? () => setState(() {
                                            marcaId = item.id;
                                            categoryIds = widget
                                                .snapshot
                                                .relaciones
                                                .where(
                                                  (relation) =>
                                                      relation.marcaId ==
                                                          item.id &&
                                                      relation.activa,
                                                )
                                                .map(
                                                  (relation) =>
                                                      relation.categoriaId,
                                                )
                                                .toSet();
                                          })
                                        : null,
                                  ),
                                )
                                .toList(),
                    ),
                    _RelationPanel(
                      title: '3. Categorías',
                      children: marcaId == null
                          ? const [
                              _EmptyState(
                                icon: Icons.category_outlined,
                                message: 'Selecciona una marca.',
                              ),
                            ]
                          : roots
                                .map(
                                  (item) => CheckboxListTile(
                                    value: categoryIds.contains(item.id),
                                    title: Text(item.nombre),
                                    subtitle: Text(
                                      item.activa ? 'Activa' : 'Inactiva',
                                    ),
                                    activeColor: const Color(0xFFFFC500),
                                    checkColor: Colors.black,
                                    onChanged:
                                        widget.puedeAdministrar && item.activa
                                        ? (selected) => setState(() {
                                            if (selected == true) {
                                              categoryIds.add(item.id);
                                            } else {
                                              categoryIds.remove(item.id);
                                            }
                                          })
                                        : null,
                                  ),
                                )
                                .toList(),
                    ),
                  ];
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: sections
                          .expand((item) => [item, const SizedBox(height: 12)])
                          .toList(),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        sections
                            .expand(
                              (item) => [
                                Expanded(child: item),
                                const SizedBox(width: 12),
                              ],
                            )
                            .toList()
                          ..removeLast(),
                  );
                },
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: !widget.puedeAdministrar || marcaId == null
                      ? null
                      : () => context.read<EstructuraCatalogoBloc>().add(
                          RelacionesCatalogoGuardadas(
                            marcaId: marcaId!,
                            categoriaIds: categoryIds,
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC500),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar relaciones'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionList<T> extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.items,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final List<T> items;
  final Widget Function(T) itemBuilder;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SectionHeader(
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
      Expanded(
        child: items.isEmpty
            ? _EmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'No hay $title registrados.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => itemBuilder(items[index]),
              ),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(subtitle, style: const TextStyle(color: Color(0xFF757575))),
            ],
          ),
        ),
        if (onAction != null)
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC500),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
      ],
    ),
  );
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.chips,
    required this.detail,
    required this.onView,
    required this.onEdit,
    required this.manageLabel,
    required this.onManage,
    required this.onState,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final List<String> chips;
  final String detail;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final String manageLabel;
  final VoidCallback? onManage;
  final VoidCallback? onState;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE4E6EA)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC500).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1F1F1F)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF757575)),
                      ),
                  ],
                ),
              ),
              _StatusBadge(active: active),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (text) => Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(text),
                    backgroundColor: const Color(0xFFF3F4F6),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(color: Color(0xFF616161))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Ver'),
              ),
              if (onEdit != null)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              if (onManage != null)
                OutlinedButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings_suggest_outlined, size: 18),
                  label: Text(manageLabel),
                ),
              if (onState != null)
                TextButton.icon(
                  onPressed: onState,
                  icon: Icon(
                    active ? Icons.block : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(active ? 'Desactivar' : 'Activar'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CategoryTreeCard extends StatelessWidget {
  const _CategoryTreeCard({
    required this.category,
    required this.children,
    required this.puedeAdministrar,
    required this.onEdit,
    required this.onState,
    required this.onManage,
  });

  final CategoriaCatalogo category;
  final List<CategoriaCatalogo> children;
  final bool puedeAdministrar;
  final ValueChanged<CategoriaCatalogo> onEdit;
  final ValueChanged<CategoriaCatalogo> onState;
  final ValueChanged<CategoriaCatalogo> onManage;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE4E6EA)),
    ),
    child: ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.folder_outlined, color: Color(0xFFFFC500)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              category.nombre,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
          _StatusBadge(active: category.activa),
        ],
      ),
      subtitle: Text(
        '${category.cantidadProductos} productos · ${category.marcas.length} marcas',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'editar') onEdit(category);
          if (value == 'marcas') onManage(category);
          if (value == 'estado') onState(category);
        },
        itemBuilder: (_) => [
          if (puedeAdministrar)
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
          const PopupMenuItem(value: 'marcas', child: Text('Gestionar marcas')),
          if (puedeAdministrar)
            PopupMenuItem(
              value: 'estado',
              child: Text(category.activa ? 'Desactivar' : 'Activar'),
            ),
        ],
      ),
      children: [
        if (category.descripcion.isNotEmpty)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(category.descripcion),
          ),
        for (final child in children)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 52, right: 16),
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(child.nombre),
            subtitle: Text(
              '${child.cantidadProductos} productos · ${child.marcas.length} marcas',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBadge(active: child.activa),
                if (puedeAdministrar)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') onEdit(child);
                      if (value == 'marcas') onManage(child);
                      if (value == 'estado') onState(child);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'marcas',
                        child: Text('Gestionar marcas'),
                      ),
                      PopupMenuItem(
                        value: 'estado',
                        child: Text(child.activa ? 'Desactivar' : 'Activar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RelationPanel extends StatelessWidget {
  const _RelationPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 310),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E6EA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        const Divider(height: 1),
        ...children,
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'Activo' : 'Inactivo',
      style: TextStyle(
        color: active ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmpresaFormDialog extends StatefulWidget {
  const _EmpresaFormDialog({this.empresa});

  final EmpresaCatalogo? empresa;

  @override
  State<_EmpresaFormDialog> createState() => _EmpresaFormDialogState();
}

class _EmpresaFormDialogState extends State<_EmpresaFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nombre;
  late final TextEditingController ruc;
  late final TextEditingController telefono;
  late final TextEditingController direccion;

  @override
  void initState() {
    super.initState();
    nombre = TextEditingController(text: widget.empresa?.nombre);
    ruc = TextEditingController(text: widget.empresa?.ruc);
    telefono = TextEditingController(text: widget.empresa?.telefono);
    direccion = TextEditingController(text: widget.empresa?.direccion);
  }

  @override
  void dispose() {
    nombre.dispose();
    ruc.dispose();
    telefono.dispose();
    direccion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialogShell(
    title: widget.empresa == null ? 'Nueva empresa' : 'Editar empresa',
    formKey: formKey,
    onSave: () {
      if (!formKey.currentState!.validate()) return;
      Navigator.pop(
        context,
        EmpresaCatalogoDraft(
          nombre: nombre.text,
          ruc: ruc.text,
          telefono: telefono.text,
          direccion: direccion.text,
        ),
      );
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _textField(nombre, 'Nombre *', Icons.business_outlined, required: true),
        _textField(ruc, 'RUC', Icons.badge_outlined),
        _textField(telefono, 'Teléfono', Icons.phone_outlined),
        _textField(direccion, 'Dirección', Icons.location_on_outlined),
      ],
    ),
  );
}

class _MarcaFormDialog extends StatefulWidget {
  const _MarcaFormDialog({
    required this.empresas,
    required this.categorias,
    required this.seleccionInicial,
    this.marca,
    this.empresaInicialId,
  });

  final MarcaCatalogo? marca;
  final int? empresaInicialId;
  final List<EmpresaCatalogo> empresas;
  final List<CategoriaCatalogo> categorias;
  final Set<int> seleccionInicial;

  @override
  State<_MarcaFormDialog> createState() => _MarcaFormDialogState();
}

class _MarcaFormDialogState extends State<_MarcaFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nombre;
  int? empresaId;
  late Set<int> categories;

  @override
  void initState() {
    super.initState();
    nombre = TextEditingController(text: widget.marca?.nombre);
    empresaId = widget.marca?.empresaId ?? widget.empresaInicialId;
    categories = {...widget.seleccionInicial};
  }

  @override
  void dispose() {
    nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialogShell(
    title: widget.marca == null ? 'Nueva marca' : 'Editar marca',
    formKey: formKey,
    onSave: () {
      if (!formKey.currentState!.validate()) return;
      Navigator.pop(
        context,
        MarcaCatalogoDraft(
          empresaId: empresaId!,
          nombre: nombre.text,
          categoriaIds: categories,
        ),
      );
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int>(
          initialValue: empresaId,
          isExpanded: true,
          decoration: _inputDecoration('Empresa propietaria *'),
          items: widget.empresas
              .where((item) => item.activa || item.id == empresaId)
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.nombre)),
              )
              .toList(),
          validator: (value) =>
              value == null ? 'Selecciona una empresa.' : null,
          onChanged: (value) => setState(() => empresaId = value),
        ),
        const SizedBox(height: 14),
        _textField(nombre, 'Nombre *', Icons.sell_outlined, required: true),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Categorías habilitadas',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        ...widget.categorias.map(
          (item) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: categories.contains(item.id),
            title: Text(item.nombre),
            activeColor: const Color(0xFFFFC500),
            checkColor: Colors.black,
            onChanged: item.activa
                ? (value) => setState(() {
                    if (value == true) {
                      categories.add(item.id);
                    } else {
                      categories.remove(item.id);
                    }
                  })
                : null,
          ),
        ),
      ],
    ),
  );
}

class _CategoriaFormDialog extends StatefulWidget {
  const _CategoriaFormDialog({required this.categoriasRaiz, this.categoria});

  final CategoriaCatalogo? categoria;
  final List<CategoriaCatalogo> categoriasRaiz;

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nombre;
  late final TextEditingController descripcion;
  int? parentId;

  @override
  void initState() {
    super.initState();
    nombre = TextEditingController(text: widget.categoria?.nombre);
    descripcion = TextEditingController(text: widget.categoria?.descripcion);
    parentId = widget.categoria?.categoriaPadreId;
  }

  @override
  void dispose() {
    nombre.dispose();
    descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormDialogShell(
    title: widget.categoria == null ? 'Nueva categoría' : 'Editar categoría',
    formKey: formKey,
    onSave: () {
      if (!formKey.currentState!.validate()) return;
      Navigator.pop(
        context,
        CategoriaCatalogoDraft(
          nombre: nombre.text,
          descripcion: descripcion.text,
          categoriaPadreId: parentId,
        ),
      );
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _textField(nombre, 'Nombre *', Icons.category_outlined, required: true),
        DropdownButtonFormField<int?>(
          initialValue: parentId,
          isExpanded: true,
          decoration: _inputDecoration('Categoría superior'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Sin categoría superior'),
            ),
            ...widget.categoriasRaiz.map(
              (item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(item.nombre),
              ),
            ),
          ],
          onChanged: widget.categoria != null
              ? null
              : (value) => setState(() => parentId = value),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: descripcion,
          maxLines: 3,
          decoration: _inputDecoration('Descripción'),
        ),
      ],
    ),
  );
}

class _CategoriasMarcaDialog extends StatefulWidget {
  const _CategoriasMarcaDialog({
    required this.marca,
    required this.categorias,
    required this.seleccionInicial,
  });

  final MarcaCatalogo marca;
  final List<CategoriaCatalogo> categorias;
  final Set<int> seleccionInicial;

  @override
  State<_CategoriasMarcaDialog> createState() => _CategoriasMarcaDialogState();
}

class _CategoriasMarcaDialogState extends State<_CategoriasMarcaDialog> {
  late Set<int> selected;

  @override
  void initState() {
    super.initState();
    selected = {...widget.seleccionInicial};
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Categorías · ${widget.marca.nombre}'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.categorias
            .map(
              (item) => CheckboxListTile(
                value: selected.contains(item.id),
                title: Text(item.nombre),
                subtitle: Text('${item.cantidadProductos} productos'),
                activeColor: const Color(0xFFFFC500),
                checkColor: Colors.black,
                onChanged: item.activa
                    ? (value) => setState(() {
                        if (value == true) {
                          selected.add(item.id);
                        } else {
                          selected.remove(item.id);
                        }
                      })
                    : null,
              ),
            )
            .toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, selected),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFC500),
          foregroundColor: Colors.black,
        ),
        child: const Text('Guardar relaciones'),
      ),
    ],
  );
}

class _EmpresaDetalleDialog extends StatelessWidget {
  const _EmpresaDetalleDialog({
    required this.empresa,
    required this.marcas,
    required this.categorias,
  });

  final EmpresaCatalogo empresa;
  final List<MarcaCatalogo> marcas;
  final List<CategoriaCatalogo> categorias;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      empresa.nombre,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusBadge(active: empresa.activa),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Color(0xFFFFC500),
              tabs: [
                Tab(text: 'Resumen'),
                Tab(text: 'Marcas'),
                Tab(text: 'Categorías'),
                Tab(text: 'Productos'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _detailTile('RUC', empresa.ruc),
                      _detailTile('Teléfono', empresa.telefono),
                      _detailTile('Dirección', empresa.direccion),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: marcas
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.sell_outlined),
                            title: Text(item.nombre),
                            subtitle: Text(
                              '${item.categorias.length} categorías · ${item.cantidadProductos} productos',
                            ),
                            trailing: _StatusBadge(active: item.activa),
                          ),
                        )
                        .toList(),
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: categorias
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.category_outlined),
                            title: Text(item.nombre),
                            subtitle: Text(
                              '${item.cantidadProductos} productos',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  Center(
                    child: Text(
                      '${empresa.cantidadProductos} productos asociados',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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

  static Widget _detailTile(String label, String value) => ListTile(
    title: Text(label),
    subtitle: Text(value.isEmpty ? 'No registrado' : value),
  );
}

class _FormDialogShell extends StatelessWidget {
  const _FormDialogShell({
    required this.title,
    required this.formKey,
    required this.child,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final Widget child;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(child: child),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: onSave,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFC500),
          foregroundColor: Colors.black,
        ),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Guardar'),
      ),
    ],
  );
}

Widget _textField(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool required = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextFormField(
    controller: controller,
    decoration: _inputDecoration(label).copyWith(prefixIcon: Icon(icon)),
    validator: required
        ? (value) => value == null || value.trim().isEmpty
              ? 'Campo obligatorio.'
              : null
        : null,
  ),
);

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: label,
  floatingLabelBehavior: FloatingLabelBehavior.always,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: const Color(0xFFBDBDBD)),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
