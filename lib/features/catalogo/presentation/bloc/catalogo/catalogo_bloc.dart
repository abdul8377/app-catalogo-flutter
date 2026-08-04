import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/producto_resumen.dart';
import '../../../domain/repositories/catalogo_repository.dart';
import 'catalogo_event.dart';
import 'catalogo_state.dart';

class CatalogoBloc extends Bloc<CatalogoEvent, CatalogoState> {
  CatalogoBloc(this._repository) : super(CatalogoState.initial()) {
    on<CatalogoStarted>(_cargar);
    on<CatalogoRecargado>(_cargar);
    on<CatalogoBusquedaCambiada>(
      (event, emit) => emit(
        _filtrar(state.copyWith(busqueda: event.texto, limpiarError: true)),
      ),
    );
    on<CatalogoFiltroRapidoCambiado>(_filtroRapido);
    on<CatalogoFiltrosAplicados>(
      (event, emit) => emit(_filtrar(state.copyWith(filtros: event.filtros))),
    );
    on<CatalogoFiltrosLimpiados>(
      (_, emit) => emit(
        _filtrar(
          state.copyWith(
            filtros: const CatalogoFiltros(),
            filtrosRapidos: const {'Todos'},
          ),
        ),
      ),
    );
    on<CatalogoVistaCambiada>(
      (event, emit) => emit(state.copyWith(vistaGrilla: event.vistaGrilla)),
    );
    on<CatalogoEstadoProductoCambiado>(_cambiarEstado);
  }

  final CatalogoRepository _repository;

  Future<void> _cargar(CatalogoEvent event, Emitter<CatalogoState> emit) async {
    emit(state.copyWith(loading: true, limpiarError: true));
    try {
      final productos = await _repository.obtenerProductos();
      emit(_filtrar(state.copyWith(loading: false, productos: productos)));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar el catálogo local.',
        ),
      );
    }
  }

  void _filtroRapido(
    CatalogoFiltroRapidoCambiado event,
    Emitter<CatalogoState> emit,
  ) {
    final filtros = {...state.filtrosRapidos};
    if (event.filtro == 'Todos') {
      filtros
        ..clear()
        ..add('Todos');
    } else {
      filtros.remove('Todos');
      if (!filtros.remove(event.filtro)) {
        const opuestos = {
          'Activos': 'Inactivos',
          'Inactivos': 'Activos',
          'Con precio': 'Sin precio',
          'Sin precio': 'Con precio',
          'Con imagen': 'Sin imagen',
          'Sin imagen': 'Con imagen',
          'Con variantes': 'Sin variantes',
          'Sin variantes': 'Con variantes',
        };
        filtros
          ..remove(opuestos[event.filtro])
          ..add(event.filtro);
      }
      if (filtros.isEmpty) filtros.add('Todos');
    }
    emit(_filtrar(state.copyWith(filtrosRapidos: filtros)));
  }

  Future<void> _cambiarEstado(
    CatalogoEstadoProductoCambiado event,
    Emitter<CatalogoState> emit,
  ) async {
    emit(state.copyWith(actualizando: true, limpiarError: true));
    try {
      await _repository.cambiarEstadoProducto(event.id, activo: event.activo);
      final productos = await _repository.obtenerProductos();
      emit(_filtrar(state.copyWith(actualizando: false, productos: productos)));
    } catch (_) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo actualizar el estado del producto.',
        ),
      );
    }
  }

  CatalogoState _filtrar(CatalogoState estado) {
    final texto = estado.busqueda.trim().toLowerCase();
    var productos = estado.productos.where((p) {
      final textoOk =
          texto.isEmpty ||
          p.codigo.toLowerCase().contains(texto) ||
          p.nombre.toLowerCase().contains(texto) ||
          p.empresa.toLowerCase().contains(texto) ||
          p.marca.toLowerCase().contains(texto) ||
          p.categoria.toLowerCase().contains(texto) ||
          p.subcategoria.toLowerCase().contains(texto) ||
          p.atributosClave.any((a) => a.toLowerCase().contains(texto));
      final r = estado.filtrosRapidos;
      return textoOk &&
          (!r.contains('Activos') || p.activo) &&
          (!r.contains('Inactivos') || !p.activo) &&
          (!r.contains('Con precio') || !p.sinPrecio) &&
          (!r.contains('Sin precio') || p.sinPrecio) &&
          (!r.contains('Con imagen') || p.imagenPath != null) &&
          (!r.contains('Sin imagen') || p.imagenPath == null) &&
          (!r.contains('Con variantes') || p.tipoRegistro != 'unico') &&
          (!r.contains('Sin variantes') || p.tipoRegistro == 'unico');
    }).toList();
    final f = estado.filtros;
    final subcategorias = f.subcategoriasActivas;
    productos = productos
        .where(
          (p) =>
              (f.empresa == null || p.empresa == f.empresa) &&
              (f.marca == null || p.marca == f.marca) &&
              (f.categoria == null || p.categoria == f.categoria) &&
              (subcategorias.isEmpty ||
                  subcategorias.contains(p.subcategoria)) &&
              (f.estado == null ||
                  (f.estado == 'Activo' ? p.activo : !p.activo)) &&
              (f.precio == null ||
                  (f.precio == 'Con precio' ? !p.sinPrecio : p.sinPrecio)) &&
              (f.imagen == null ||
                  (f.imagen == 'Con imagen'
                      ? p.imagenPath != null
                      : p.imagenPath == null)),
        )
        .toList();
    _ordenar(productos, f.orden);
    return estado.copyWith(productosFiltrados: productos);
  }

  void _ordenar(List<ProductoResumen> productos, String orden) {
    switch (orden) {
      case 'Nombre Z-A':
        productos.sort((a, b) => b.nombre.compareTo(a.nombre));
      case 'Precio menor a mayor':
        productos.sort(
          (a, b) => (a.precio ?? double.infinity).compareTo(
            b.precio ?? double.infinity,
          ),
        );
      case 'Precio mayor a menor':
        productos.sort((a, b) => (b.precio ?? -1).compareTo(a.precio ?? -1));
      case 'Activos primero':
        productos.sort(
          (a, b) => (b.activo ? 1 : 0).compareTo(a.activo ? 1 : 0),
        );
      case 'Más recientes':
        productos.sort(
          (a, b) => (b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      default:
        productos.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
  }
}
