import 'dart:async';

import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_bloc.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_event.dart';
import 'package:app_catalogo/features/catalogo/presentation/pages/producto_form_page.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso4_venta_logistica_contenido.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso5_precios_corregido.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso6_imagenes_corregido.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso7_revisar_activar_corregido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el indicador usa seis pasos y bloquea pasos futuros', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();
    expect(find.byKey(const ValueKey('paso_flujo_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_6')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_7')), findsNothing);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('paso_flujo_3'))).onTap,
      isNull,
    );
    expect(bloc.state.paso, 0);

    bloc
      ..add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      )
      ..add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      );
    await tester.pumpAndSettle();

    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('paso_flujo_2'))).onTap,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('paso_flujo_2')));
    await tester.pumpAndSettle();
    expect(bloc.state.paso, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el paso 2 combina tipo, familia y variantes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();

    Future<void> selectDropdown(int index, String value) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    await selectDropdown(0, 'DINA');
    await selectDropdown(1, 'DINA');
    await selectDropdown(2, 'Pernería');
    await selectDropdown(3, 'Pernos métricos');

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(bloc.state.paso, 1);
    expect(find.text('¿Cómo se organiza este producto?'), findsOneWidget);
    expect(find.text('Atributos de la categoría'), findsNothing);

    await tester.tap(find.text('Lista de variantes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('familia_nombre')), findsOneWidget);
    expect(find.text('Variantes creadas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('familia_nombre')),
      'Familia de prueba',
    );
    await tester.pump();

    expect(bloc.state.nombre, 'Familia de prueba');
    expect(bloc.state.tipoRegistro, 'variantes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Matriz inicia vacía y crea solo combinaciones incluidas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();
    bloc
      ..add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      )
      ..add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      )
      ..add(const ProductoFormFamiliaCambiada(nombre: 'Perno hexagonal'))
      ..add(const ProductoFormTipoCambiado('matriz'))
      ..add(const ProductoFormPasoSeleccionado(1));
    await tester.pumpAndSettle();

    expect(find.text('Matriz de variantes'), findsWidgets);
    expect(
      find.text('0 combinaciones · 0 variantes a crear · 0 no existen'),
      findsOneWidget,
    );
    expect(bloc.state.variantes, isEmpty);

    Future<void> addMeasure(int chipIndex, String value) async {
      await tester.tap(
        find.widgetWithText(ActionChip, 'Añadir medida').at(chipIndex),
      );
      await tester.pumpAndSettle();
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(dialogFields.at(0), value);
      await tester.enterText(dialogFields.at(1), 'mm');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();
    }

    await addMeasure(0, '10');
    await addMeasure(1, '40');
    tester
        .widget<OutlinedButton>(find.byKey(const Key('actualizar_matriz')))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(
      find.text('1 combinaciones · 0 variantes a crear · 1 no existen'),
      findsOneWidget,
    );
    expect(bloc.state.variantes, isEmpty);

    await tester.ensureVisible(
      find.byKey(const Key('alternar_combinacion_matriz')),
    );
    await tester.tap(find.byKey(const Key('alternar_combinacion_matriz')));
    await tester.pumpAndSettle();
    expect(bloc.state.variantes, hasLength(1));
    expect(bloc.state.variantes.single.id, isNot(contains('matrix:')));
    expect(
      bloc.state.variantes.single.atributos.map((item) => item.nombre),
      containsAll(['Diámetro', 'Largo']),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Matriz no desborda en una pantalla angosta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();
    bloc
      ..add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      )
      ..add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      )
      ..add(const ProductoFormFamiliaCambiada(nombre: 'Perno hexagonal'))
      ..add(const ProductoFormTipoCambiado('matriz'))
      ..add(const ProductoFormPasoSeleccionado(1));
    await tester.pumpAndSettle();

    expect(find.text('Combinaciones generadas'), findsOneWidget);
    expect(bloc.state.variantes, isEmpty);
    expect(
      find.text('0 combinaciones · 0 variantes a crear · 0 no existen'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Producto único abre su pestaña, valida y crea la variante automática',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final bloc = tester
          .element(find.byType(Scaffold))
          .read<ProductoFormBloc>();
      bloc
        ..add(
          const ProductoFormClasificacionCambiada(
            empresa: 'DINA',
            marca: 'DINA',
            categoria: 'Pernería',
          ),
        )
        ..add(
          const ProductoFormClasificacionCambiada(
            subcategoria: 'Pernos métricos',
          ),
        )
        ..add(const ProductoFormFamiliaCambiada(nombre: 'Perno hexagonal'))
        ..add(const ProductoFormTipoCambiado('unico'))
        ..add(const ProductoFormPasoSeleccionado(1));
      await tester.pumpAndSettle();

      expect(find.text('Producto único'), findsWidgets);
      expect(find.text('Producto vendible'), findsOneWidget);
      expect(find.text('1 variante automática'), findsOneWidget);
      expect(find.text('Se define en este paso'), findsNothing);
      expect(find.text('Se configura después'), findsNothing);
      expect(find.text('Diámetro'), findsOneWidget);
      expect(find.text('Largo'), findsOneWidget);
      expect(bloc.state.codigo, startsWith('PRD-'));
      expect(bloc.state.variantes, hasLength(1));
      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));

      final siguiente = find.widgetWithText(
        FilledButton,
        'Siguiente: venta y empaques',
      );
      tester.widget<FilledButton>(siguiente).onPressed?.call();
      await tester.pumpAndSettle();
      expect(bloc.state.paso, 1);
      expect(
        find.textContaining('Ingresa el nombre comercial'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('producto_unico_codigo_proveedor')),
        'DINA-PER-12',
      );
      await tester.enterText(
        find.byKey(const Key('producto_unico_nombre')),
        'Perno hexagonal 1/2',
      );
      await tester.enterText(
        find.byKey(const Key('producto_unico_descripcion')),
        'Perno único para venta.',
      );
      await tester.pumpAndSettle();

      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('guardar_borrador_unico')),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(find.text('Borrador guardado'), findsOneWidget);
      expect(bloc.state.variantes, hasLength(1));
      expect(bloc.state.variantes.single.nombreCorto, 'Perno hexagonal 1/2');
      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));
      expect(bloc.state.variantes.single.codigoProveedor, 'DINA-PER-12');
      expect(bloc.state.descripcion, 'Perno único para venta.');

      tester.widget<FilledButton>(siguiente).onPressed?.call();
      await tester.pumpAndSettle();
      expect(bloc.state.paso, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Producto único no desborda en una pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();
    bloc
      ..add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      )
      ..add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      )
      ..add(const ProductoFormFamiliaCambiada(nombre: 'Perno hexagonal'))
      ..add(const ProductoFormTipoCambiado('unico'))
      ..add(const ProductoFormPasoSeleccionado(1));
    await tester.pumpAndSettle();

    expect(find.text('Producto vendible'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(bloc.state.variantes, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'la lista genera códigos internos y conserva el código del proveedor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final bloc = context.read<ProductoFormBloc>();
      bloc
        ..add(
          const ProductoFormClasificacionCambiada(
            empresa: 'DINA',
            marca: 'DINA',
            categoria: 'Pernería',
          ),
        )
        ..add(
          const ProductoFormClasificacionCambiada(
            subcategoria: 'Pernos métricos',
          ),
        )
        ..add(const ProductoFormFamiliaCambiada(nombre: 'Familia de pernos'))
        ..add(const ProductoFormTipoCambiado('variantes'))
        ..add(
          const ProductoFormVarianteGuardada(
            ProductoVariante(
              id: 'v1',
              sku: 'SKU-001',
              codigoProveedor: 'PROV-001',
              nombreCorto: 'Perno 10 x 40',
              atributos: [
                AtributoProductoVariante(
                  nombre: 'Diámetro',
                  valor: '10',
                  unidad: 'mm',
                ),
                AtributoProductoVariante(
                  nombre: 'Largo',
                  valor: '40',
                  unidad: 'mm',
                ),
              ],
            ),
          ),
        )
        ..add(
          const ProductoFormVarianteGuardada(
            ProductoVariante(
              id: 'v2',
              sku: 'SKU-002',
              codigoProveedor: 'PROV-002',
              nombreCorto: 'Perno 12 x 50',
              atributos: [
                AtributoProductoVariante(
                  nombre: 'Diámetro',
                  valor: '12',
                  unidad: 'mm',
                ),
                AtributoProductoVariante(
                  nombre: 'Largo',
                  valor: '50',
                  unidad: 'mm',
                ),
              ],
            ),
          ),
        )
        ..add(const ProductoFormPasoSeleccionado(1));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SKU-002').first);
      await tester.tap(find.text('SKU-002').first);
      await tester.pumpAndSettle();

      final internalField = tester.widget<TextFormField>(
        find.byKey(const Key('variante_codigo_interno')),
      );
      expect(internalField.controller?.text, 'SKU-002');
      final internalEditable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('variante_codigo_interno')),
          matching: find.byType(EditableText),
        ),
      );
      expect(internalEditable.readOnly, isTrue);

      await tester.ensureVisible(find.byKey(const Key('agregar_variante')));
      await tester.tap(find.byKey(const Key('agregar_variante')));
      await tester.pumpAndSettle();

      final generatedInternal = tester
          .widget<TextFormField>(
            find.byKey(const Key('variante_codigo_interno')),
          )
          .controller
          ?.text;
      expect(generatedInternal, startsWith('VAR-'));

      await tester.enterText(
        find.byKey(const Key('variante_codigo_proveedor')),
        'PROV-003',
      );
      await tester.enterText(
        find.byKey(const Key('variante_nombre')),
        'Perno repetido',
      );
      await tester.enterText(find.byKey(const Key('atributo_Diámetro')), '12');
      await tester.enterText(find.byKey(const Key('atributo_Largo')), '50');
      await tester.ensureVisible(find.byKey(const Key('guardar_variante')));
      tester
          .widget<ElevatedButton>(find.byKey(const Key('guardar_variante')))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ya existe una variante con 12 mm · 50 mm'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('atributo_Largo')), '60');
      tester
          .widget<ElevatedButton>(find.byKey(const Key('guardar_variante')))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(bloc.state.variantes, hasLength(3));
      expect(bloc.state.variantes.last.sku, generatedInternal);
      expect(bloc.state.variantes.last.codigoProveedor, 'PROV-003');

      final originalInternal = bloc.state.variantes.last.sku;
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('duplicar_variante_lista')),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(bloc.state.variantes, hasLength(4));
      expect(bloc.state.variantes.last.sku, startsWith('VAR-'));
      expect(bloc.state.variantes.last.sku, isNot(originalInternal));
      expect(bloc.state.variantes.last.codigoProveedor, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el paso 4 configura venta, logística y contenido sin desbordar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final bloc = context.read<ProductoFormBloc>();
      bloc.add(
        const ProductoFormClasificacionCambiada(
          empresa: 'DINA',
          marca: 'DINA',
          categoria: 'Pernería',
        ),
      );
      await tester.pump();
      bloc.add(
        const ProductoFormClasificacionCambiada(
          subcategoria: 'Pernos métricos',
        ),
      );
      bloc.add(
        const ProductoFormFamiliaCambiada(
          codigo: 'TEST-001',
          nombre: 'Perno de prueba',
        ),
      );
      bloc.add(
        const ProductoFormVarianteGuardada(
          ProductoVariante(
            id: 'variante-test',
            sku: 'TEST-001',
            nombreCorto: 'Perno de prueba',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '10',
                unidad: 'mm',
              ),
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '40',
                unidad: 'mm',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        bloc.add(const ProductoFormPasoSiguiente());
        await tester.pumpAndSettle();
      }
      expect(bloc.state.paso, 3);

      expect(
        find.text('Paso 3 · Venta, logística y contenido'),
        findsOneWidget,
      );
      expect(find.text('Presentaciones de venta'), findsOneWidget);
      expect(find.text('Empaques logísticos'), findsOneWidget);
      expect(find.text('Contenido del producto'), findsOneWidget);
      expect(
        find.text('¿Cómo puede pedir este producto el cliente?'),
        findsOneWidget,
      );

      final presentationFields = find.byType(TextFormField);
      await tester.enterText(presentationFields.at(0), 'Docena');
      await tester.enterText(presentationFields.at(1), '12');
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar presentación'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(find.text('Docena'), findsWidgets);
      expect(bloc.state.presentaciones.single.nombre, 'Docena');
      expect(bloc.state.presentaciones.single.unidad, '12 PZA');
      expect(
        bloc
            .state
            .ventaLogisticaContenido
            ?.presentations
            .single
            .assignedVariantIds,
        {bloc.state.variantes.single.id},
      );

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: empaques'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(
        find.text(
          '¿Este producto utiliza empaques de transporte o abastecimiento?',
        ),
        findsOneWidget,
      );
      final noAplicaEmpaques = find.widgetWithText(ChoiceChip, 'No aplica');

      await tester.ensureVisible(noAplicaEmpaques);
      await tester.pumpAndSettle();
      await tester.tap(noAplicaEmpaques);
      await tester.pumpAndSettle();

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: contenido'),
          )
          .onPressed
          ?.call();

      await tester.pumpAndSettle();

      expect(
        find.text('¿El producto vendido contiene varios elementos?'),
        findsOneWidget,
      );

      final noAplicaContenido = find.widgetWithText(ChoiceChip, 'No aplica');

      await tester.ensureVisible(noAplicaContenido);
      await tester.pumpAndSettle();
      await tester.tap(noAplicaContenido);
      await tester.pumpAndSettle();

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: precios'),
          )
          .onPressed
          ?.call();

      await tester.pumpAndSettle();

      expect(bloc.state.paso, 4);
      expect(
        bloc.state.ventaLogisticaContenido?.usesLogisticsPackages,
        isFalse,
      );
      expect(bloc.state.ventaLogisticaContenido?.hasProductContent, isFalse);

      bloc.add(const ProductoFormPasoAnterior());
      await tester.pumpAndSettle();
      expect(bloc.state.paso, 3);
      expect(find.text('Docena'), findsWidgets);
      expect(
        find.text('12 PZA · Pedido mínimo: 1 · Incremento: 1'),
        findsOneWidget,
      );

      bloc.add(const ProductoFormPasoSeleccionado(4));
      await tester.pumpAndSettle();
      expect(find.text('Paso 4 · Precios'), findsOneWidget);
      expect(
        find.text(
          'Un campo vacío queda pendiente. Un valor de 0.00 '
          'significa gratuito y requiere confirmación.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('0 de 1 combinaciones listas · 1 pendientes'),
        findsOneWidget,
      );
      expect(find.text('Siguiente: imágenes'), findsOneWidget);
      expect(find.text('Imágenes del producto'), findsNothing);

      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Configurar'))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Precio fijo'))
          .onSelected
          ?.call(true);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Precio por Docena'),
        '21.50',
      );
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar configuración'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(find.text('US\$ 21.50 por Docena'), findsOneWidget);
      expect(
        find.text('1 de 1 combinaciones listas · 0 pendientes'),
        findsOneWidget,
      );
      expect(
        bloc.state.preciosConfigurados?.prices.single.variantId,
        bloc.state.variantes.single.id,
      );
      expect(
        bloc.state.preciosConfigurados?.prices.single.presentationId,
        bloc.state.ventaLogisticaContenido?.presentations.single.id,
      );

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: imágenes'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(bloc.state.paso, 5);
      expect(find.text('Paso 5 · Imágenes'), findsOneWidget);
      expect(find.text('Galería de la familia'), findsOneWidget);
      expect(find.text('Siguiente: revisar y activar'), findsOneWidget);
      expect(find.text('Excepciones por variante'), findsNothing);
      bloc.add(
        const ProductoFormImagenesConfiguradasCambiadas(
          Step6ImagesDraft(
            familyImages: [
              Step6ProductImageDraft(
                id: 'imagen-principal',
                owner: Step6ImageOwner.family,
                familyId: 'familia-borrador',
                candidate: Step6ImageCandidate(
                  fileName: 'imagen-principal.jpg',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                  localPath: 'imagen-principal.jpg',
                ),
                label: 'Principal',
                order: 0,
                isPrimary: true,
                processState: Step6ImageProcessState.ready,
                syncState: Step6ImageSyncState.pending,
              ),
            ],
            variantSpecificImages: [],
            exceptions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bloc.state.imagenesConfiguradas?.canActivate, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test('serializa y restaura el código del proveedor', () {
    const variante = ProductoVariante(
      id: 'variante-1',
      sku: 'VAR-1234567890',
      codigoProveedor: 'UY-ITL02-202',
      nombreCorto: 'Taladro 20 V',
      atributos: [],
    );

    final restored = ProductoVariante.fromMap(variante.toMap());

    expect(restored.sku, 'VAR-1234567890');
    expect(restored.codigoProveedor, 'UY-ITL02-202');
  });

  test('precarga y actualiza un producto existente', () async {
    final repository = _FakeCatalogoRepository();
    final bloc = ProductoFormBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const ProductoFormStarted(productoId: 'editar'));
    await bloc.stream.firstWhere((state) => !state.loading);

    expect(bloc.state.editando, isTrue);
    expect(bloc.state.codigo, 'EDIT-001');
    expect(bloc.state.nombre, 'Producto editable');

    bloc.add(const ProductoFormGuardado());
    await bloc.stream.firstWhere((state) => state.guardado);
    expect(repository.idActualizado, 'editar');
    expect(repository.productoActualizado?.codigo, 'EDIT-001');
  });

  test('serializa y restaura todos los datos enriquecidos del paso 4', () {
    const draft = Step4SalesDraft(
      presentations: [
        SalesPresentationDraft(
          id: 'presentacion-1',
          name: 'Docena',
          baseUnit: 'PZA',
          equivalentTo: 12,
          minimumOrder: 1,
          purchaseIncrement: 1,
          allowsDecimals: false,
          assignedVariantIds: {'variante-1'},
          defaultVariantIds: {'variante-1'},
          linkedLogisticsPackageId: 'empaque-1',
        ),
      ],
      usesLogisticsPackages: true,
      logisticsPackages: [
        LogisticsPackageDraft(
          id: 'empaque-1',
          name: 'Caja máster',
          contains: 10,
          contentKind: PackageContentKind.salesPresentation,
          contentReferenceId: 'presentacion-1',
          totalBaseUnits: 120,
          baseUnit: 'PZA',
          assignedVariantIds: {'variante-1'},
          supplierCode: 'CM-001',
          description: 'Caja de transporte.',
          linkedSalesPresentationId: 'presentacion-1',
        ),
      ],
      hasProductContent: true,
      contentItems: [
        ProductContentItemDraft(
          id: 'componente-1',
          ownerVariantId: 'variante-1',
          componentName: 'Accesorio',
          quantity: 2,
          unit: 'PZA',
          relatedCatalogVariantId: 'catalogo-1',
        ),
      ],
    );

    final restored = step4SalesDraftFromMap(step4SalesDraftToMap(draft));

    expect(restored?.presentations.single.name, 'Docena');
    expect(restored?.presentations.single.assignedVariantIds, {'variante-1'});
    expect(restored?.usesLogisticsPackages, isTrue);
    expect(restored?.logisticsPackages.single.totalBaseUnits, 120);
    expect(
      restored?.logisticsPackages.single.contentKind,
      PackageContentKind.salesPresentation,
    );
    expect(restored?.hasProductContent, isTrue);
    expect(restored?.contentItems.single.componentName, 'Accesorio');
  });

  test(
    'el paso 5 distingue pendiente, gratuito, cotización y precio normal',
    () {
      final draft = PricingStep5Draft(
        lists: [
          PriceListDraft(
            id: 'regular',
            name: 'Regular',
            currencyCode: 'USD',
            includesIgv: true,
            validFrom: DateTime(2026, 7, 29),
          ),
        ],
        prices: const [
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-pendiente',
            presentationId: 'p-unidad',
            configuration: PriceConfigurationType.unconfigured,
          ),
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-gratis',
            presentationId: 'p-unidad',
            configuration: PriceConfigurationType.fixed,
            fixedPrice: 0,
          ),
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-cotizar',
            presentationId: 'p-unidad',
            configuration: PriceConfigurationType.quote,
          ),
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-normal',
            presentationId: 'p-unidad',
            configuration: PriceConfigurationType.fixed,
            fixedPrice: 21.50,
          ),
        ],
        sellableCombinations: const [
          SellablePriceCombination(
            variantId: 'v-pendiente',
            variantLabel: 'Pendiente',
            presentationId: 'p-unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'PZA',
            equivalentToBaseUnit: 1,
          ),
          SellablePriceCombination(
            variantId: 'v-gratis',
            variantLabel: 'Gratuito',
            presentationId: 'p-unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'PZA',
            equivalentToBaseUnit: 1,
          ),
          SellablePriceCombination(
            variantId: 'v-cotizar',
            variantLabel: 'Por cotizar',
            presentationId: 'p-unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'PZA',
            equivalentToBaseUnit: 1,
          ),
          SellablePriceCombination(
            variantId: 'v-normal',
            variantLabel: 'Normal',
            presentationId: 'p-unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'PZA',
            equivalentToBaseUnit: 1,
          ),
        ],
      );

      expect(draft.prices[0].isReady, isFalse);
      expect(draft.prices[1].isReady, isTrue);
      expect(draft.prices[1].fixedPrice, 0);
      expect(draft.prices[2].isReady, isTrue);
      expect(draft.prices[3].isReady, isTrue);
      expect(draft.pendingForList('regular'), 1);
      expect(draft.canActivate('regular'), isFalse);

      final restored = step5PricingDraftFromMap(step5PricingDraftToMap(draft));
      expect(restored?.prices, hasLength(4));
      expect(restored?.prices[1].fixedPrice, 0);
      expect(restored?.prices[2].configuration, PriceConfigurationType.quote);
      expect(restored?.prices[3].variantId, 'v-normal');
      expect(restored?.prices[3].presentationId, 'p-unidad');
    },
  );

  test(
    'un precio pendiente impide activar y por cotizar sí permite activar',
    () async {
      final bloc = ProductoFormBloc(_FakeCatalogoRepository());
      addTearDown(bloc.close);
      bloc.add(const ProductoFormStarted());
      await bloc.stream.firstWhere((state) => !state.loading);

      final list = PriceListDraft(
        id: 'regular',
        name: 'Regular',
        currencyCode: 'USD',
        includesIgv: true,
        validFrom: DateTime(2026, 7, 29),
      );
      const combination = SellablePriceCombination(
        variantId: 'v-1',
        variantLabel: 'Variante',
        presentationId: 'p-1',
        presentationLabel: 'Unidad',
        baseUnit: 'PZA',
        equivalentToBaseUnit: 1,
      );
      final pending = PricingStep5Draft(
        lists: [list],
        prices: const [
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-1',
            presentationId: 'p-1',
            configuration: PriceConfigurationType.unconfigured,
          ),
        ],
        sellableCombinations: const [combination],
      );

      bloc.add(ProductoFormPreciosConfiguradosCambiados(pending));
      await bloc.stream.firstWhere(
        (state) => identical(state.preciosConfigurados, pending),
      );
      const imagesReady = Step6ImagesDraft(
        familyImages: [
          Step6ProductImageDraft(
            id: 'family-image',
            owner: Step6ImageOwner.family,
            familyId: 'family',
            candidate: Step6ImageCandidate(
              fileName: 'principal.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 1024,
              localPath: 'principal.jpg',
            ),
            label: 'Principal',
            order: 0,
            isPrimary: true,
            processState: Step6ImageProcessState.ready,
            syncState: Step6ImageSyncState.pending,
          ),
        ],
        variantSpecificImages: [],
        exceptions: [],
      );
      bloc.add(const ProductoFormImagenesConfiguradasCambiadas(imagesReady));
      await bloc.stream.firstWhere(
        (state) => identical(state.imagenesConfiguradas, imagesReady),
      );
      expect(bloc.state.activo, isFalse);

      bloc.add(const ProductoFormEstadoCambiado(true));
      await bloc.stream.firstWhere((state) => state.error != null);
      expect(bloc.state.activo, isFalse);

      final quote = PricingStep5Draft(
        lists: [list],
        prices: const [
          ProductPriceDraft(
            listId: 'regular',
            variantId: 'v-1',
            presentationId: 'p-1',
            configuration: PriceConfigurationType.quote,
          ),
        ],
        sellableCombinations: const [combination],
      );
      bloc.add(ProductoFormPreciosConfiguradosCambiados(quote));
      await bloc.stream.firstWhere(
        (state) => identical(state.preciosConfigurados, quote),
      );
      bloc.add(const ProductoFormEstadoCambiado(true));
      await bloc.stream.firstWhere((state) => state.activo);
      expect(bloc.state.preciosListosParaActivar, isTrue);
    },
  );

  testWidgets('el valor 0.00 exige confirmación y queda como gratuito', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    PricingStep5Draft? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step5PricingPanel(
            familyName: 'Familia gratuita',
            totalVariantCount: 1,
            sellableCombinations: const [
              SellablePriceCombination(
                variantId: 'v-1',
                variantLabel: 'Variante',
                presentationId: 'p-1',
                presentationLabel: 'Unidad',
                baseUnit: 'PZA',
                equivalentToBaseUnit: 1,
              ),
            ],
            onBack: () {},
            onNext: (_) {},
            onChanged: (draft) => changed = draft,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Configurar'))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Precio fijo'))
        .onSelected
        ?.call(true);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Precio por Unidad'),
      '0.00',
    );
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Guardar configuración'),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('Confirmar producto gratuito'), findsOneWidget);
    expect(
      find.text(
        'El valor 0.00 se guardará como un precio válido y gratuito. '
        'No se considerará pendiente ni por cotizar.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar 0.00'));
    await tester.pumpAndSettle();

    expect(changed?.prices.single.fixedPrice, 0);
    expect(changed?.prices.single.isReady, isTrue);
    expect(
      find.text('1 de 1 combinaciones listas · 0 pendientes'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('el paso 7 bloquea la activación sin principal familiar', () async {
    final bloc = ProductoFormBloc(_FakeCatalogoRepository());
    addTearDown(bloc.close);
    bloc.add(const ProductoFormStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    final pricing = PricingStep5Draft(
      lists: [
        PriceListDraft(
          id: 'regular',
          name: 'Regular',
          currencyCode: 'USD',
          includesIgv: true,
          validFrom: DateTime(2026, 7, 29),
        ),
      ],
      prices: const [
        ProductPriceDraft(
          listId: 'regular',
          variantId: 'v-1',
          presentationId: 'p-1',
          configuration: PriceConfigurationType.quote,
        ),
      ],
      sellableCombinations: const [
        SellablePriceCombination(
          variantId: 'v-1',
          variantLabel: 'Variante',
          presentationId: 'p-1',
          presentationLabel: 'Unidad',
          baseUnit: 'PZA',
          equivalentToBaseUnit: 1,
        ),
      ],
    );
    bloc.add(ProductoFormPreciosConfiguradosCambiados(pricing));
    await bloc.stream.firstWhere(
      (state) => identical(state.preciosConfigurados, pricing),
    );

    const withoutImages = Step6ImagesDraft(
      familyImages: [],
      variantSpecificImages: [],
      exceptions: [],
    );
    bloc.add(const ProductoFormImagenesConfiguradasCambiadas(withoutImages));
    await bloc.stream.firstWhere(
      (state) => identical(state.imagenesConfiguradas, withoutImages),
    );
    bloc.add(const ProductoFormEstadoCambiado(true));
    await bloc.stream.firstWhere(
      (state) => state.error?.contains('imagen principal') ?? false,
    );

    expect(bloc.state.activo, isFalse);
    expect(bloc.state.imagenesListasParaActivar, isFalse);
  });

  test(
    'el paso 7 persiste la activación local y marca sincronización',
    () async {
      final repository = _FakeCatalogoRepository();
      final bloc = ProductoFormBloc(repository);
      addTearDown(bloc.close);
      bloc.add(const ProductoFormStarted(productoId: 'editar'));
      await bloc.stream.firstWhere((state) => !state.loading);

      final variantId = bloc.state.variantes.single.id;
      final pricing = PricingStep5Draft(
        lists: [
          PriceListDraft(
            id: 'regular',
            name: 'Regular',
            currencyCode: 'USD',
            includesIgv: true,
            validFrom: DateTime(2026, 7, 29),
          ),
        ],
        prices: [
          ProductPriceDraft(
            listId: 'regular',
            variantId: variantId,
            presentationId: 'unidad',
            configuration: PriceConfigurationType.quote,
          ),
        ],
        sellableCombinations: [
          SellablePriceCombination(
            variantId: variantId,
            variantLabel: 'Producto editable',
            presentationId: 'unidad',
            presentationLabel: 'Unidad',
            baseUnit: 'UND',
            equivalentToBaseUnit: 1,
          ),
        ],
      );
      bloc.add(ProductoFormPreciosConfiguradosCambiados(pricing));
      await bloc.stream.firstWhere(
        (state) => identical(state.preciosConfigurados, pricing),
      );

      const images = Step6ImagesDraft(
        familyImages: [
          Step6ProductImageDraft(
            id: 'principal',
            owner: Step6ImageOwner.family,
            familyId: 'editar',
            candidate: Step6ImageCandidate(
              fileName: 'principal.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 1024,
              localPath: 'principal.jpg',
            ),
            label: 'Principal',
            order: 0,
            isPrimary: true,
            processState: Step6ImageProcessState.ready,
            syncState: Step6ImageSyncState.pending,
          ),
        ],
        variantSpecificImages: [],
        exceptions: [],
      );
      bloc.add(const ProductoFormImagenesConfiguradasCambiadas(images));
      await bloc.stream.firstWhere(
        (state) => identical(state.imagenesConfiguradas, images),
      );
      bloc.add(const ProductoFormEstadoCambiado(false));
      await bloc.stream.firstWhere((state) => !state.activo);

      final completer = Completer<Step7ActivationResult>();
      bloc.add(
        ProductoFormActivadoDesdeRevision(
          request: const Step7ActivationRequest(
            productId: 'editar',
            confirmed: true,
            validation: Step7ValidationResult(blockers: [], warnings: []),
          ),
          completer: completer,
        ),
      );
      final result = await completer.future;

      expect(result.pendingSynchronization, isTrue);
      expect(repository.idActualizado, 'editar');
      expect(repository.productoActualizado?.activo, isTrue);
      expect(bloc.state.activo, isTrue);
    },
  );

  testWidgets('el paso 5 muestra el resumen 18 de 20 y no incluye imágenes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final combinations = List.generate(
      20,
      (index) => SellablePriceCombination(
        variantId: 'variante-$index',
        variantLabel: 'Variante ${index + 1}',
        presentationId: 'presentacion-$index',
        presentationLabel: 'Unidad ${index + 1}',
        baseUnit: 'PZA',
        equivalentToBaseUnit: 1,
      ),
    );
    final prices = List.generate(
      20,
      (index) => ProductPriceDraft(
        listId: 'regular',
        variantId: 'variante-$index',
        presentationId: 'presentacion-$index',
        configuration: index < 18
            ? PriceConfigurationType.fixed
            : PriceConfigurationType.unconfigured,
        fixedPrice: index < 18 ? index.toDouble() : null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step5PricingPanel(
            familyName: 'Familia de prueba',
            totalVariantCount: 20,
            sellableCombinations: combinations,
            initialLists: [
              PriceListDraft(
                id: 'regular',
                name: 'Regular',
                currencyCode: 'USD',
                includesIgv: true,
                validFrom: DateTime(2026, 7, 29),
              ),
            ],
            initialPrices: prices,
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('18 de 20 combinaciones listas · 2 pendientes'),
      findsOneWidget,
    );
    expect(find.text('Siguiente: imágenes'), findsOneWidget);
    expect(find.text('Imágenes del producto'), findsNothing);
    expect(
      find.text(
        'Un campo vacío queda pendiente. Un valor de 0.00 '
        'significa gratuito y requiere confirmación.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'serializa galería, orden, principal y propietario exclusivo del paso 6',
    () {
      const draft = Step6ImagesDraft(
        familyImages: [
          Step6ProductImageDraft(
            id: 'familia-principal',
            owner: Step6ImageOwner.family,
            familyId: 'familia-1',
            candidate: Step6ImageCandidate(
              fileName: 'principal.webp',
              mimeType: 'image/webp',
              sizeBytes: 2048,
              width: 1400,
              height: 1400,
              localPath: 'principal.webp',
            ),
            label: 'Principal',
            order: 0,
            isPrimary: true,
            processState: Step6ImageProcessState.ready,
            syncState: Step6ImageSyncState.pending,
          ),
          Step6ProductImageDraft(
            id: 'familia-detalle',
            owner: Step6ImageOwner.family,
            familyId: 'familia-1',
            candidate: Step6ImageCandidate(
              fileName: 'detalle.png',
              mimeType: 'image/png',
              sizeBytes: 1024,
              localPath: 'detalle.png',
            ),
            label: 'Detalle',
            order: 1,
            isPrimary: false,
            processState: Step6ImageProcessState.ready,
            syncState: Step6ImageSyncState.synced,
          ),
        ],
        variantSpecificImages: [
          Step6ProductImageDraft(
            id: 'variante-principal',
            owner: Step6ImageOwner.variant,
            variantId: 'variante-1',
            candidate: Step6ImageCandidate(
              fileName: 'variante.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 1536,
              localPath: 'variante.jpg',
            ),
            label: 'Principal específica',
            order: 0,
            isPrimary: true,
            processState: Step6ImageProcessState.ready,
            syncState: Step6ImageSyncState.pending,
          ),
        ],
        exceptions: [
          Step6VariantImageExceptionDraft(
            variantId: 'variante-1',
            imageId: 'variante-principal',
            origin: Step6ExceptionOrigin.variantSpecific,
          ),
        ],
      );

      expect(draft.canActivate, isTrue);
      expect(draft.effectiveGalleryFor('variante-1').map((item) => item.id), [
        'variante-principal',
        'familia-principal',
        'familia-detalle',
      ]);
      expect(draft.effectiveGalleryFor('variante-2').map((item) => item.id), [
        'familia-principal',
        'familia-detalle',
      ]);

      final restored = step6ImagesDraftFromMap(step6ImagesDraftToMap(draft));
      expect(restored?.familyImages.first.isPrimary, isTrue);
      expect(restored?.familyImages.last.order, 1);
      expect(restored?.familyImages.last.label, 'Detalle');
      expect(restored?.familyImages.first.familyId, 'familia-1');
      expect(restored?.familyImages.first.variantId, isNull);
      expect(restored?.variantSpecificImages.single.familyId, isNull);
      expect(restored?.variantSpecificImages.single.variantId, 'variante-1');
      expect(
        restored?.exceptions.single.origin,
        Step6ExceptionOrigin.variantSpecific,
      );
    },
  );

  testWidgets(
    'el paso 6 crea principal familiar y excepción específica sin duplicar la galería',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Step6ImagesDraft? changed;
      var pickNumber = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step6ImagesPanel(
              familyId: 'familia-1',
              familyName: 'Perno hexagonal UNC 304',
              productLayout: Step6ProductLayout.variantList,
              variants: const [
                Step6VariantOption(
                  id: 'variante-1',
                  label: '3/8″ × 4″',
                  sku: 'PER-384',
                ),
                Step6VariantOption(
                  id: 'variante-2',
                  label: '1/4″ × 4″',
                  sku: 'PER-144',
                ),
              ],
              pickImages: (request) async {
                pickNumber++;
                if (request.forFamilyGallery) {
                  return const [
                    Step6ImageCandidate(
                      fileName: 'principal.jpg',
                      mimeType: 'image/jpeg',
                      sizeBytes: 2048,
                    ),
                    Step6ImageCandidate(
                      fileName: 'detalle.webp',
                      mimeType: 'image/webp',
                      sizeBytes: 2048,
                    ),
                  ];
                }
                return const [
                  Step6ImageCandidate(
                    fileName: 'variante.png',
                    mimeType: 'image/png',
                    sizeBytes: 2048,
                  ),
                ];
              },
              processImage: (candidate) async => candidate,
              onChanged: (draft) => changed = draft,
              onBack: () {},
              onNext: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paso 5 · Imágenes'), findsOneWidget);
      expect(find.text('Galería de la familia'), findsOneWidget);
      expect(find.text('Excepciones por variante'), findsOneWidget);
      expect(find.text('Buscar por medida o SKU'), findsOneWidget);
      expect(find.text('Configurar excepción'), findsOneWidget);
      expect(
        find.textContaining(
          'Todas las variantes utilizan la galería familiar.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(OutlinedButton, '+ Agregar imágenes'),
      );
      await tester.pumpAndSettle();
      expect(changed?.familyImages, hasLength(2));
      expect(changed?.familyImages.first.isPrimary, isTrue);
      expect(changed?.canActivate, isTrue);
      expect(
        find.text('2 imágenes de familia · 1 principal · 0 excepciones'),
        findsOneWidget,
      );

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Configurar excepción'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Subir una imagen específica'));
      await tester.pumpAndSettle();
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              'Seleccionar imagen específica',
            ),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar excepción'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(pickNumber, 2);
      expect(changed?.exceptions, hasLength(1));
      expect(changed?.variantSpecificImages, hasLength(1));
      expect(changed?.variantSpecificImages.single.familyId, isNull);
      expect(changed?.variantSpecificImages.single.variantId, 'variante-1');
      expect(changed?.familyImages, hasLength(2));
      expect(find.text('Principal reemplazada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el paso 4 permite registrar empaque y contenido en pantalla angosta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Step4SalesDraft? changedDraft;
      Step4SalesDraft? completedDraft;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step4SalesLogisticsContentPanel(
              familyName: 'Kit de prueba',
              variantLayout: Step4VariantLayout.single,
              variants: const [
                Step4VariantOption(id: 'variante-1', label: 'Kit de prueba'),
              ],
              onBack: () {},
              onChanged: (draft) => changedDraft = draft,
              onNext: (draft) => completedDraft = draft,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Unidad');
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar presentación'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: empaques'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sí, agregar empaque'));
      await tester.pumpAndSettle();

      fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Caja máster');
      await tester.enterText(fields.at(1), '10');
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar empaque'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(changedDraft?.logisticsPackages.single.name, 'Caja máster');

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: contenido'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Sí, definir contenido'),
      );
      await tester.pumpAndSettle();

      fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Accesorio');
      await tester.enterText(fields.at(1), '2');
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Agregar componente'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(changedDraft?.contentItems.single.componentName, 'Accesorio');

      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Siguiente: precios'),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(completedDraft?.presentations, hasLength(1));
      expect(completedDraft?.logisticsPackages, hasLength(1));
      expect(completedDraft?.contentItems, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el selector matricial del paso 4 funciona en pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step4SalesLogisticsContentPanel(
            familyName: 'Pernos',
            variantLayout: Step4VariantLayout.matrix,
            variants: const [
              Step4VariantOption(
                id: 'v-1',
                label: '10 mm × 40 mm',
                rowValue: '10 mm',
                columnValue: '40 mm',
              ),
              Step4VariantOption(
                id: 'v-2',
                label: '10 mm × 50 mm',
                rowValue: '10 mm',
                columnValue: '50 mm',
              ),
              Step4VariantOption(
                id: 'v-3',
                label: '12 mm × 40 mm',
                rowValue: '12 mm',
                columnValue: '40 mm',
              ),
              Step4VariantOption(
                id: 'v-4',
                label: '12 mm × 50 mm',
                rowValue: '12 mm',
                columnValue: '50 mm',
              ),
            ],
            initialPresentations: const [
              SalesPresentationDraft(
                id: 'p-1',
                name: 'Unidad',
                baseUnit: 'PZA',
                equivalentTo: 1,
                minimumOrder: 1,
                purchaseIncrement: 1,
                allowsDecimals: false,
                assignedVariantIds: {'v-1', 'v-2', 'v-3', 'v-4'},
                defaultVariantIds: {'v-1', 'v-2', 'v-3', 'v-4'},
              ),
            ],
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Variantes seleccionadas (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variantes seleccionadas (4)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Cambiar selección'),
    );
    await tester.pumpAndSettle();
    tester
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Cambiar selección'),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar en la matriz'), findsOneWidget);
    expect(find.text('10 mm'), findsWidgets);
    expect(find.text('40 mm'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test(
    'administra varias imágenes y conserva la principal al actualizar',
    () async {
      final repository = _FakeCatalogoRepository();
      final bloc = ProductoFormBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const ProductoFormStarted(productoId: 'editar'));
      await bloc.stream.firstWhere((state) => !state.loading);

      bloc.add(
        const ProductoFormImagenesAgregadas(['primera.jpg', 'segunda.jpg']),
      );
      await bloc.stream.firstWhere((state) => state.imagenesPaths.length == 2);
      bloc.add(const ProductoFormImagenPrincipalCambiada(1));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.first == 'segunda.jpg',
      );
      bloc.add(const ProductoFormImagenReemplazada(1, 'reemplazo.jpg'));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.last == 'reemplazo.jpg',
      );
      bloc.add(const ProductoFormImagenReordenada(1, 0));
      await bloc.stream.firstWhere(
        (state) => state.imagenesPaths.first == 'reemplazo.jpg',
      );
      bloc.add(const ProductoFormImagenEliminada(1));
      await bloc.stream.firstWhere((state) => state.imagenesPaths.length == 1);
      bloc.add(const ProductoFormEstadoCambiado(false));
      await bloc.stream.firstWhere((state) => !state.activo);
      bloc.add(const ProductoFormGuardado());
      await bloc.stream.firstWhere((state) => state.guardado);

      expect(repository.productoActualizado?.imagenesPaths, ['reemplazo.jpg']);
      expect(repository.productoActualizado?.activo, isFalse);
    },
  );

  testWidgets('la edición conserva el mismo flujo de seis pasos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage(productoId: 'editar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_6')), findsOneWidget);
    expect(find.text('General'), findsNothing);
    expect(find.byKey(const Key('guardar_cambios')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeCatalogoRepository implements CatalogoRepository {
  String? idActualizado;
  NuevoProducto? productoActualizado;

  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}

  @override
  Future<CatalogoFormData> obtenerDatosFormulario() async =>
      const CatalogoFormData(
        empresas: ['DINA'],
        marcas: ['DINA'],
        subcategorias: {
          'Pernería': ['Pernos métricos'],
        },
        atributos: {
          'Pernería': [
            AtributoDef(
              nombre: 'Diámetro',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm', 'in', '″'],
              unidadPredeterminada: 'mm',
              puedeSerEje: true,
            ),
            AtributoDef(
              nombre: 'Largo',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm', 'cm', 'in', '″'],
              unidadPredeterminada: 'mm',
              puedeSerEje: true,
            ),
          ],
          'Pernos métricos': [
            AtributoDef(
              nombre: 'Diámetro',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm'],
              unidadPredeterminada: 'mm',
              puedeSerEje: true,
            ),
            AtributoDef(
              nombre: 'Largo',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm'],
              unidadPredeterminada: 'mm',
              puedeSerEje: true,
            ),
          ],
        },
        marcasPorEmpresa: {
          'DINA': ['DINA'],
        },
        categoriasPorMarca: {
          'DINA::DINA': ['Pernería'],
        },
      );

  @override
  Future<void> guardarProducto(NuevoProducto producto) async {}

  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) async {
    idActualizado = id;
    productoActualizado = producto;
  }

  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async => [];

  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async {
    if (id != 'editar') return null;
    return ProductoDetalle(
      id: id,
      codigo: 'EDIT-001',
      nombre: 'Producto editable',
      descripcion: 'Descripción',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      subcategoria: 'Pernos métricos',
      tipoRegistro: 'unico',
      atributos: const {'Rosca': 'RF'},
      presentaciones: const [
        PresentacionProducto(nombre: 'Unidad', unidad: '1 UND'),
      ],
      precios: const [PrecioProducto(presentacion: 'Unidad', valor: 2)],
      activo: true,
      creadoEn: DateTime(2026, 7, 13),
    );
  }

  @override
  Future<List<ProductoResumen>> obtenerProductos() async => [];
}
