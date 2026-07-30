import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/estructura_catalogo.dart';
import '../bloc/estructura_catalogo_bloc.dart';
import '../bloc/estructura_catalogo_event.dart';
import '../bloc/estructura_catalogo_state.dart';
import 'gestionar_atributos_categoria.dart' as manager;
import '../widgets/estructura_catalogo_corregida.dart' as design;

class EstructuraCatalogoIntegradaView extends StatelessWidget {
  const EstructuraCatalogoIntegradaView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<EstructuraCatalogoBloc, EstructuraCatalogoState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.mensaje != current.mensaje,
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
        builder: (context, state) {
          if (state.loading) {
            return const Scaffold(
              backgroundColor: Color(0xFFF4F6F8),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final snapshot = state.snapshot;
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            body: Stack(
              children: [
                design.CatalogStructurePanel(
                  key: ValueKey(snapshot),
                  companies: _companies(snapshot),
                  brands: _brands(snapshot),
                  categories: _categories(snapshot),
                  attributes: _simpleAttributes(snapshot),
                  relations: _relations(snapshot),
                  onCompaniesChanged: (items) =>
                      _saveCompanies(context, snapshot, items),
                  onBrandsChanged: (items) =>
                      _saveBrands(context, snapshot, items),
                  onCategoriesChanged: (items) =>
                      _saveCategories(context, snapshot, items),
                  onAttributesChanged: (items) =>
                      _saveSimpleAttributes(context, snapshot, items),
                  onRelationsChanged: (items) =>
                      _saveRelations(context, snapshot, items),
                  onManageCategoryAttributes: (id) =>
                      _openAttributeManager(context, snapshot, int.parse(id)),
                ),
                if (state.saving)
                  const Positioned(
                    top: 18,
                    right: 20,
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  static List<design.CatalogCompany> _companies(
    EstructuraCatalogoSnapshot snapshot,
  ) => snapshot.empresas
      .map(
        (item) => design.CatalogCompany(
          id: '${item.id}',
          name: item.nombre,
          initials: _initials(item.nombre),
          ruc: item.ruc,
          phone: item.telefono,
          address: item.direccion,
          brandCount: item.cantidadMarcas,
          productCount: item.cantidadProductos,
          active: item.activa,
        ),
      )
      .toList();

  static List<design.CatalogBrand> _brands(
    EstructuraCatalogoSnapshot snapshot,
  ) => snapshot.marcas
      .map(
        (item) => design.CatalogBrand(
          id: '${item.id}',
          companyId: '${item.empresaId}',
          name: item.nombre,
          initials: _initials(item.nombre),
          productCount: item.cantidadProductos,
          active: item.activa,
        ),
      )
      .toList();

  static List<design.CatalogCategory> _categories(
    EstructuraCatalogoSnapshot snapshot,
  ) => snapshot.categorias
      .map(
        (item) => design.CatalogCategory(
          id: '${item.id}',
          parentId: item.categoriaPadreId?.toString(),
          name: item.nombre,
          description: item.descripcion,
          directProductCount: item.cantidadProductos,
          includingDescendantProductCount:
              item.cantidadProductos + _descendantProducts(snapshot, item.id),
          active: item.activa,
        ),
      )
      .toList();

  static List<design.CategoryAttributeDefinition> _simpleAttributes(
    EstructuraCatalogoSnapshot snapshot,
  ) => snapshot.atributos
      .map(
        (item) => design.CategoryAttributeDefinition(
          id: item.id,
          categoryId: '${item.categoriaId}',
          name: item.nombre,
          type: _simpleType(item.tipoDato),
          units: item.codigosUnidad,
          options: item.opciones.map((option) => option.etiqueta).toList(),
          required: item.requeridoActivar,
          filterable: item.filtrable,
          variantAxis: item.puedeSerEje,
          multiple: item.tipoDato == 'lista_multiple',
          active: item.activo,
          usedByProductCount: item.usadoPorProductos,
        ),
      )
      .toList();

  static List<design.BrandCategoryRelation> _relations(
    EstructuraCatalogoSnapshot snapshot,
  ) => snapshot.relaciones
      .where((item) => item.activa)
      .map(
        (item) => design.BrandCategoryRelation(
          brandId: '${item.marcaId}',
          categoryId: '${item.categoriaId}',
          activeProductCount: snapshot.categorias
              .where((category) => category.id == item.categoriaId)
              .fold(0, (total, category) => total + category.cantidadProductos),
        ),
      )
      .toList();

  static void _saveCompanies(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    List<design.CatalogCompany> items,
  ) {
    final bloc = context.read<EstructuraCatalogoBloc>();
    for (final item in items) {
      final id = int.tryParse(item.id);
      final previous = snapshot.empresas
          .where((value) => value.id == id)
          .firstOrNull;
      final draft = EmpresaCatalogoDraft(
        nombre: item.name,
        ruc: item.ruc ?? '',
        telefono: item.phone ?? '',
        direccion: item.address ?? '',
        activa: item.active,
      );
      if (previous == null || !_sameCompany(previous, draft)) {
        bloc.add(EmpresaCatalogoGuardada(draft, id: previous?.id));
      }
    }
  }

  static void _saveBrands(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    List<design.CatalogBrand> items,
  ) {
    final bloc = context.read<EstructuraCatalogoBloc>();
    for (final item in items) {
      final id = int.tryParse(item.id);
      final companyId = int.tryParse(item.companyId);
      if (companyId == null) continue;
      final previous = snapshot.marcas
          .where((value) => value.id == id)
          .firstOrNull;
      final assigned = snapshot.relaciones
          .where((value) => value.marcaId == id && value.activa)
          .map((value) => value.categoriaId)
          .toSet();
      final draft = MarcaCatalogoDraft(
        empresaId: companyId,
        nombre: item.name,
        categoriaIds: assigned,
        activa: item.active,
      );
      if (previous == null || !_sameBrand(previous, draft)) {
        bloc.add(MarcaCatalogoGuardada(draft, id: previous?.id));
      }
    }
  }

  static void _saveCategories(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    List<design.CatalogCategory> items,
  ) {
    final bloc = context.read<EstructuraCatalogoBloc>();
    for (final item in items) {
      final id = int.tryParse(item.id);
      final previous = snapshot.categorias
          .where((value) => value.id == id)
          .firstOrNull;
      final draft = CategoriaCatalogoDraft(
        nombre: item.name,
        descripcion: item.description ?? '',
        categoriaPadreId: int.tryParse(item.parentId ?? ''),
        activa: item.active,
      );
      if (previous == null || !_sameCategory(previous, draft)) {
        bloc.add(CategoriaCatalogoGuardada(draft, id: previous?.id));
      }
    }
  }

  static void _saveSimpleAttributes(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    List<design.CategoryAttributeDefinition> items,
  ) {
    final grouped = <int, List<AtributoCategoriaCatalogo>>{};
    for (final item in items) {
      final categoryId = int.tryParse(item.categoryId);
      if (categoryId == null) continue;
      final previous = snapshot.atributos
          .where((value) => value.id == item.id)
          .firstOrNull;
      grouped
          .putIfAbsent(categoryId, () => [])
          .add(
            previous == null
                ? _domainFromSimple(snapshot, categoryId, item)
                : AtributoCategoriaCatalogo(
                    id: previous.id,
                    categoriaId: previous.categoriaId,
                    categoriaNombre: previous.categoriaNombre,
                    nombre: item.name,
                    clave: previous.clave,
                    tipoDato: _domainSimpleType(
                      item.type,
                      item.multiple,
                      hasUnits: item.units.isNotEmpty,
                    ),
                    nivelCaptura: previous.nivelCaptura,
                    requeridoActivar: item.required,
                    visibleFicha: previous.visibleFicha,
                    filtrable: item.filterable,
                    puedeSerEje: item.variantAxis,
                    activoNuevos: previous.activoNuevos,
                    orden: previous.orden,
                    activo: item.active,
                    ayuda: previous.ayuda,
                    longitudMaxima: previous.longitudMaxima,
                    ejemplo: previous.ejemplo,
                    minimo: previous.minimo,
                    maximo: previous.maximo,
                    decimales: previous.decimales,
                    magnitud: previous.magnitud,
                    codigosUnidad: item.units,
                    unidadPredeterminada:
                        item.units.contains(previous.unidadPredeterminada)
                        ? previous.unidadPredeterminada
                        : item.units.firstOrNull,
                    opciones: _optionsFromSimple(
                      previous.opciones,
                      item.id,
                      item.options,
                    ),
                    maximoSelecciones: previous.maximoSelecciones,
                    etiquetaVerdadero: previous.etiquetaVerdadero,
                    etiquetaFalso: previous.etiquetaFalso,
                    usadoPorProductos: previous.usadoPorProductos,
                    categoriasAfectadas: previous.categoriasAfectadas,
                    usadoComoEje: previous.usadoComoEje,
                    sincronizacionPendiente: previous.sincronizacionPendiente,
                  ),
          );
    }
    final bloc = context.read<EstructuraCatalogoBloc>();
    for (final entry in grouped.entries) {
      bloc.add(
        AtributosCategoriaGuardados(
          categoriaId: entry.key,
          atributos: entry.value,
        ),
      );
    }
  }

  static void _saveRelations(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    List<design.BrandCategoryRelation> items,
  ) {
    final newByBrand = <int, Set<int>>{};
    for (final item in items) {
      final brandId = int.tryParse(item.brandId);
      final categoryId = int.tryParse(item.categoryId);
      if (brandId == null || categoryId == null) continue;
      newByBrand.putIfAbsent(brandId, () => {}).add(categoryId);
    }
    final bloc = context.read<EstructuraCatalogoBloc>();
    for (final brand in snapshot.marcas) {
      final previous = snapshot.relaciones
          .where((item) => item.marcaId == brand.id && item.activa)
          .map((item) => item.categoriaId)
          .toSet();
      final next = newByBrand[brand.id] ?? <int>{};
      if (!_sameSet(previous, next)) {
        bloc.add(
          RelacionesCatalogoGuardadas(marcaId: brand.id, categoriaIds: next),
        );
      }
    }
  }

  static Future<void> _openAttributeManager(
    BuildContext context,
    EstructuraCatalogoSnapshot snapshot,
    int categoryId,
  ) async {
    final category = snapshot.categorias
        .where((item) => item.id == categoryId)
        .firstOrNull;
    if (category == null) return;
    final path = _categoryPath(snapshot, category);
    final chainIds = path.map((item) => item.id).toSet();
    final attributes = snapshot.atributos
        .where((item) => chainIds.contains(item.categoriaId))
        .map(
          (item) => _managerAttribute(
            item,
            inherited: item.categoriaId != categoryId,
          ),
        )
        .toList();
    final bloc = context.read<EstructuraCatalogoBloc>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => manager.CategoryAttributesManagerPage(
          categoryId: '$categoryId',
          categoryName: category.nombre,
          categoryPath: path.map((item) => item.nombre).toList(),
          attributes: attributes,
          units: snapshot.unidades
              .where((item) => item.activa)
              .map(
                (item) => manager.AttributeUnit(
                  code: item.codigo,
                  label: '${item.nombre} (${item.simbolo})',
                  magnitude: item.magnitud,
                  factorToBase: item.factorBase,
                ),
              )
              .toList(),
          reservedNamesInDescendants: _descendantAttributes(
            snapshot,
            categoryId,
          ).map((item) => item.nombre).toSet(),
          reservedKeysInDescendants: _descendantAttributes(
            snapshot,
            categoryId,
          ).map((item) => item.clave).toSet(),
          onBack: () => Navigator.of(context).pop(),
          onAttributesChanged: (items) => bloc.add(
            AtributosCategoriaGuardados(
              categoriaId: categoryId,
              atributos: items
                  .map((item) => _domainFromManager(snapshot, item))
                  .toList(),
            ),
          ),
          onOpenOwnerCategory: (ownerId) {
            final parsedId = int.tryParse(ownerId);
            if (parsedId == null) return;
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _openAttributeManager(context, snapshot, parsedId);
              }
            });
          },
          onShowAffectedProducts: (_) => AppNotice.info(
            context,
            'Los productos afectados conservan sus valores históricos.',
          ),
        ),
      ),
    );
  }

  static manager.CategoryAttributeDefinition _managerAttribute(
    AtributoCategoriaCatalogo item, {
    required bool inherited,
  }) => manager.CategoryAttributeDefinition(
    id: item.id,
    ownerCategoryId: '${item.categoriaId}',
    ownerCategoryName: item.categoriaNombre,
    name: item.nombre,
    keyName: item.clave,
    helpText: item.ayuda,
    dataType: _managerType(item.tipoDato),
    captureLevel: _managerCapture(item.nivelCaptura),
    requiredToActivate: item.requeridoActivar,
    visibleInTechnicalSheet: item.visibleFicha,
    filterable: item.filtrable,
    canBeVariantAxis: item.puedeSerEje,
    activeForNewProducts: item.activoNuevos,
    order: item.orden,
    active: item.activo,
    inherited: inherited,
    textMaxLength: item.longitudMaxima,
    example: item.ejemplo,
    minimum: item.minimo,
    maximum: item.maximo,
    decimals: item.decimales,
    magnitude: item.magnitud,
    allowedUnitCodes: item.codigosUnidad,
    defaultUnitCode: item.unidadPredeterminada,
    options: item.opciones
        .map(
          (option) => manager.CategoryAttributeOption(
            id: option.id,
            label: option.etiqueta,
            code: option.codigo,
            active: option.activa,
            usedByProductCount: option.usadaPorProductos,
          ),
        )
        .toList(),
    maximumSelections: item.maximoSelecciones,
    trueLabel: item.etiquetaVerdadero,
    falseLabel: item.etiquetaFalso,
    usedByProductCount: item.usadoPorProductos,
    affectedCategoryCount: item.categoriasAfectadas,
    usedAsAxisByProductCount: item.usadoComoEje,
    syncState: item.sincronizacionPendiente
        ? manager.AttributeSyncState.pending
        : manager.AttributeSyncState.synced,
  );

  static AtributoCategoriaCatalogo _domainFromManager(
    EstructuraCatalogoSnapshot snapshot,
    manager.CategoryAttributeDefinition item,
  ) {
    final categoryId = int.parse(item.ownerCategoryId);
    final categoryName = snapshot.categorias
        .where((value) => value.id == categoryId)
        .map((value) => value.nombre)
        .firstOrNull;
    return AtributoCategoriaCatalogo(
      id: item.id,
      categoriaId: categoryId,
      categoriaNombre: categoryName ?? item.ownerCategoryName,
      nombre: item.name,
      clave: item.keyName,
      tipoDato: _domainManagerType(item.dataType),
      nivelCaptura: _domainManagerCapture(item.captureLevel),
      requeridoActivar: item.requiredToActivate,
      visibleFicha: item.visibleInTechnicalSheet,
      filtrable: item.filterable,
      puedeSerEje: item.canBeVariantAxis,
      activoNuevos: item.activeForNewProducts,
      orden: item.order,
      activo: item.active,
      ayuda: item.helpText,
      longitudMaxima: item.textMaxLength,
      ejemplo: item.example,
      minimo: item.minimum,
      maximo: item.maximum,
      decimales: item.decimals,
      magnitud: item.magnitude,
      codigosUnidad: item.allowedUnitCodes,
      unidadPredeterminada: item.defaultUnitCode,
      opciones: item.options
          .asMap()
          .entries
          .map(
            (entry) => OpcionAtributoCategoriaCatalogo(
              id: entry.value.id,
              etiqueta: entry.value.label,
              codigo: entry.value.code,
              activa: entry.value.active,
              orden: entry.key,
              usadaPorProductos: entry.value.usedByProductCount,
            ),
          )
          .toList(),
      maximoSelecciones: item.maximumSelections,
      etiquetaVerdadero: item.trueLabel,
      etiquetaFalso: item.falseLabel,
      usadoPorProductos: item.usedByProductCount,
      categoriasAfectadas: item.affectedCategoryCount,
      usadoComoEje: item.usedAsAxisByProductCount,
      sincronizacionPendiente:
          item.syncState == manager.AttributeSyncState.pending,
    );
  }

  static AtributoCategoriaCatalogo _domainFromSimple(
    EstructuraCatalogoSnapshot snapshot,
    int categoryId,
    design.CategoryAttributeDefinition item,
  ) => AtributoCategoriaCatalogo(
    id: item.id,
    categoriaId: categoryId,
    categoriaNombre:
        snapshot.categorias
            .where((value) => value.id == categoryId)
            .map((value) => value.nombre)
            .firstOrNull ??
        '',
    nombre: item.name,
    clave: _key(item.name),
    tipoDato: _domainSimpleType(
      item.type,
      item.multiple,
      hasUnits: item.units.isNotEmpty,
    ),
    nivelCaptura: item.variantAxis ? 'variante' : 'familia',
    requeridoActivar: item.required,
    visibleFicha: true,
    filtrable: item.filterable,
    puedeSerEje: item.variantAxis,
    activoNuevos: true,
    orden: snapshot.atributos
        .where((value) => value.categoriaId == categoryId)
        .length,
    activo: item.active,
    codigosUnidad: item.units,
    opciones: _optionsFromSimple(const [], item.id, item.options),
  );

  static List<OpcionAtributoCategoriaCatalogo> _optionsFromSimple(
    List<OpcionAtributoCategoriaCatalogo> existing,
    String attributeId,
    List<String> labels,
  ) => labels.asMap().entries.map((entry) {
    final previous = existing
        .where((item) => _key(item.etiqueta) == _key(entry.value))
        .firstOrNull;
    return OpcionAtributoCategoriaCatalogo(
      id: previous?.id ?? '$attributeId-${entry.key}',
      etiqueta: entry.value,
      codigo: previous?.codigo ?? _key(entry.value),
      activa: previous?.activa ?? true,
      orden: entry.key,
      usadaPorProductos: previous?.usadaPorProductos ?? 0,
    );
  }).toList();

  static List<CategoriaCatalogo> _categoryPath(
    EstructuraCatalogoSnapshot snapshot,
    CategoriaCatalogo category,
  ) {
    final result = <CategoriaCatalogo>[category];
    var parentId = category.categoriaPadreId;
    while (parentId != null) {
      final parent = snapshot.categorias
          .where((item) => item.id == parentId)
          .firstOrNull;
      if (parent == null) break;
      result.insert(0, parent);
      parentId = parent.categoriaPadreId;
    }
    return result;
  }

  static Iterable<AtributoCategoriaCatalogo> _descendantAttributes(
    EstructuraCatalogoSnapshot snapshot,
    int categoryId,
  ) {
    final ids = <int>{};
    void visit(int parentId) {
      for (final child in snapshot.categorias.where(
        (item) => item.categoriaPadreId == parentId,
      )) {
        if (ids.add(child.id)) visit(child.id);
      }
    }

    visit(categoryId);
    return snapshot.atributos.where((item) => ids.contains(item.categoriaId));
  }

  static int _descendantProducts(
    EstructuraCatalogoSnapshot snapshot,
    int categoryId,
  ) {
    var result = 0;
    for (final child in snapshot.categorias.where(
      (item) => item.categoriaPadreId == categoryId,
    )) {
      result +=
          child.cantidadProductos + _descendantProducts(snapshot, child.id);
    }
    return result;
  }

  static bool _sameCompany(EmpresaCatalogo item, EmpresaCatalogoDraft draft) =>
      item.nombre == draft.nombre &&
      item.ruc == draft.ruc &&
      item.telefono == draft.telefono &&
      item.direccion == draft.direccion &&
      item.activa == draft.activa;

  static bool _sameBrand(MarcaCatalogo item, MarcaCatalogoDraft draft) =>
      item.empresaId == draft.empresaId &&
      item.nombre == draft.nombre &&
      item.activa == draft.activa;

  static bool _sameCategory(
    CategoriaCatalogo item,
    CategoriaCatalogoDraft draft,
  ) =>
      item.nombre == draft.nombre &&
      item.descripcion == draft.descripcion &&
      item.categoriaPadreId == draft.categoriaPadreId &&
      item.activa == draft.activa;

  static bool _sameSet(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  static String _key(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ø', 'diametro')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static design.CategoryAttributeType _simpleType(String value) =>
      switch (value) {
        'numero' || 'numero_unidad' => design.CategoryAttributeType.number,
        'lista_unica' || 'lista_multiple' => design.CategoryAttributeType.list,
        'si_no' => design.CategoryAttributeType.boolean,
        _ => design.CategoryAttributeType.text,
      };

  static String _domainSimpleType(
    design.CategoryAttributeType value,
    bool multiple, {
    bool hasUnits = false,
  }) => switch (value) {
    design.CategoryAttributeType.number =>
      hasUnits ? 'numero_unidad' : 'numero',
    design.CategoryAttributeType.list =>
      multiple ? 'lista_multiple' : 'lista_unica',
    design.CategoryAttributeType.boolean => 'si_no',
    _ => 'texto_corto',
  };

  static manager.CategoryAttributeDataType _managerType(String value) =>
      switch (value) {
        'numero' => manager.CategoryAttributeDataType.number,
        'numero_unidad' => manager.CategoryAttributeDataType.numberWithUnit,
        'lista_unica' => manager.CategoryAttributeDataType.singleList,
        'lista_multiple' => manager.CategoryAttributeDataType.multipleList,
        'si_no' => manager.CategoryAttributeDataType.yesNo,
        _ => manager.CategoryAttributeDataType.shortText,
      };

  static String _domainManagerType(manager.CategoryAttributeDataType value) =>
      switch (value) {
        manager.CategoryAttributeDataType.number => 'numero',
        manager.CategoryAttributeDataType.numberWithUnit => 'numero_unidad',
        manager.CategoryAttributeDataType.singleList => 'lista_unica',
        manager.CategoryAttributeDataType.multipleList => 'lista_multiple',
        manager.CategoryAttributeDataType.yesNo => 'si_no',
        manager.CategoryAttributeDataType.shortText => 'texto_corto',
      };

  static manager.AttributeCaptureLevel _managerCapture(String value) =>
      switch (value) {
        'variante' => manager.AttributeCaptureLevel.variant,
        'decidir' => manager.AttributeCaptureLevel.decideWhenRegistering,
        _ => manager.AttributeCaptureLevel.family,
      };

  static String _domainManagerCapture(manager.AttributeCaptureLevel value) =>
      switch (value) {
        manager.AttributeCaptureLevel.variant => 'variante',
        manager.AttributeCaptureLevel.decideWhenRegistering => 'decidir',
        manager.AttributeCaptureLevel.family => 'familia',
      };
}
