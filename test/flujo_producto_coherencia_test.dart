import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/presentation/bloc/producto_form_state.dart';

void main() {
  CatalogoFormData data() => const CatalogoFormData(
    empresas: ['DINA'],
    marcas: ['DINA'],
    subcategorias: {
      'Pernería': ['Pernos métricos'],
    },
    atributos: {
      'Pernos métricos': [
        AtributoDef(
          nombre: 'Material',
          tipo: 'lista_unica',
          esVariante: false,
          requerido: true,
          opciones: ['Acero', 'Inoxidable'],
          nivelCaptura: 'familia',
        ),
        AtributoDef(
          nombre: 'Diámetro',
          tipo: 'numero_unidad',
          esVariante: true,
          requerido: true,
          unidades: ['mm'],
          puedeSerEje: true,
          nivelCaptura: 'variante',
        ),
        AtributoDef(
          nombre: 'Largo',
          tipo: 'numero_unidad',
          esVariante: true,
          requerido: true,
          unidades: ['mm'],
          puedeSerEje: true,
          nivelCaptura: 'variante',
        ),
      ],
    },
  );

  ProductoFormState classified() => ProductoFormState.initial().copyWith(
    loading: false,
    datos: data(),
    empresa: 'DINA',
    marca: 'DINA',
    categoria: 'Pernería',
    subcategoria: 'Pernos métricos',
  );

  test(
    'los pasos futuros permanecen bloqueados hasta completar dependencias',
    () {
      final state = classified();
      expect(state.pasoEsAccesible(1), isTrue);
      expect(state.pasoEsAccesible(3), isFalse);
      expect(state.pasoEsAccesible(4), isFalse);
    },
  );

  test(
    'un atributo común requerido forma parte de la validación del paso 2',
    () {
      final variant = ProductoVariante(
        id: 'v1',
        sku: 'VAR-0000000001',
        nombreCorto: 'Perno M8',
        atributos: const [
          AtributoProductoVariante(
            nombre: 'Diámetro',
            valor: '8',
            unidad: 'mm',
          ),
          AtributoProductoVariante(nombre: 'Largo', valor: '30', unidad: 'mm'),
        ],
      );
      final incomplete = classified().copyWith(
        paso: 1,
        nombre: 'Perno hexagonal',
        variantes: [variant],
      );
      expect(incomplete.pasoValido, isFalse);
      expect(
        incomplete.mensajePasoInvalido,
        contains('características comunes'),
      );

      final complete = incomplete.copyWith(
        atributos: const {'Material': 'Acero'},
      );
      expect(complete.pasoValido, isTrue);
      expect(complete.pasoEsAccesible(3), isTrue);
    },
  );

  test('el producto nuevo comienza como borrador inactivo', () {
    expect(ProductoFormState.initial().activo, isFalse);
  });
}
