import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/nuevo_producto.dart';
import '../../domain/repositories/catalogo_repository.dart';
import 'producto_form_event.dart';
import 'producto_form_state.dart';

class ProductoFormBloc extends Bloc<ProductoFormEvent, ProductoFormState> {
  ProductoFormBloc(this._repository) : super(ProductoFormState.initial()) {
    on<ProductoFormStarted>(_started);
    on<ProductoFormPasoSiguiente>((_, emit) {
      if (state.pasoValido && state.paso < 5) {
        emit(state.copyWith(paso: state.paso + 1, limpiarError: true));
      }
    });
    on<ProductoFormPasoAnterior>((_, emit) {
      if (state.paso > 0) {
        emit(state.copyWith(paso: state.paso - 1, limpiarError: true));
      }
    });
    on<ProductoFormPasoSeleccionado>((event, emit) {
      if (event.paso >= 0 && event.paso <= 6) {
        emit(state.copyWith(paso: event.paso, limpiarError: true));
      }
    });
    on<ProductoFormClasificacionCambiada>(_clasificacion);
    on<ProductoFormFamiliaCambiada>(
      (event, emit) => emit(
        state.copyWith(
          codigo: event.codigo,
          nombre: event.nombre,
          descripcion: event.descripcion,
          limpiarError: true,
        ),
      ),
    );
    on<ProductoFormImagenCambiada>(
      (event, emit) => emit(
        state.copyWith(
          imagenesPaths: event.path == null ? const [] : [event.path!],
          limpiarError: true,
        ),
      ),
    );
    on<ProductoFormImagenesAgregadas>((event, emit) {
      final imagenes = [...state.imagenesPaths];
      for (final path in event.paths) {
        if (path.trim().isNotEmpty && !imagenes.contains(path)) {
          imagenes.add(path);
        }
      }
      emit(state.copyWith(imagenesPaths: imagenes, limpiarError: true));
    });
    on<ProductoFormImagenEliminada>((event, emit) {
      if (event.index < 0 || event.index >= state.imagenesPaths.length) return;
      final imagenes = [...state.imagenesPaths]..removeAt(event.index);
      emit(state.copyWith(imagenesPaths: imagenes, limpiarError: true));
    });
    on<ProductoFormImagenPrincipalCambiada>((event, emit) {
      if (event.index <= 0 || event.index >= state.imagenesPaths.length) return;
      final imagenes = [...state.imagenesPaths];
      final principal = imagenes.removeAt(event.index);
      imagenes.insert(0, principal);
      emit(state.copyWith(imagenesPaths: imagenes, limpiarError: true));
    });
    on<ProductoFormTipoCambiado>(
      (event, emit) => emit(state.copyWith(tipoRegistro: event.tipo)),
    );
    on<ProductoFormAtributoCambiado>(
      (event, emit) => emit(
        state.copyWith(
          atributos: {...state.atributos, event.nombre: event.valor},
        ),
      ),
    );
    on<ProductoFormPresentacionAgregada>((event, emit) {
      final nombre = event.presentacion.nombre.trim().toLowerCase();
      final repetida = state.presentaciones.any(
        (item) => item.nombre.trim().toLowerCase() == nombre,
      );
      if (repetida) {
        emit(
          state.copyWith(error: 'Ya existe una presentación con ese nombre.'),
        );
        return;
      }
      emit(
        state.copyWith(
          presentaciones: [...state.presentaciones, event.presentacion],
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormPresentacionEliminada>((event, emit) {
      final eliminada = state.presentaciones[event.index];
      final items = [...state.presentaciones]..removeAt(event.index);
      final precios = state.precios
          .where((precio) => precio.presentacion != eliminada.nombre)
          .toList();
      emit(state.copyWith(presentaciones: items, precios: precios));
    });
    on<ProductoFormPrecioAgregado>((event, emit) {
      final precios = state.precios
          .where((precio) => precio.presentacion != event.precio.presentacion)
          .toList();
      emit(
        state.copyWith(precios: [...precios, event.precio], limpiarError: true),
      );
    });
    on<ProductoFormPrecioEliminado>((event, emit) {
      final items = [...state.precios]..removeAt(event.index);
      emit(state.copyWith(precios: items));
    });
    on<ProductoFormEstadoCambiado>(
      (event, emit) =>
          emit(state.copyWith(activo: event.activo, limpiarError: true)),
    );
    on<ProductoFormGuardado>(_guardar);
  }
  final CatalogoRepository _repository;
  Future<void> _started(
    ProductoFormStarted event,
    Emitter<ProductoFormState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true, productoId: event.productoId));
      final datos = await _repository.obtenerDatosFormulario();
      if (event.productoId == null) {
        emit(state.copyWith(loading: false, datos: datos));
        return;
      }
      final producto = await _repository.obtenerDetalleProducto(
        event.productoId!,
      );
      if (producto == null) {
        emit(
          state.copyWith(
            loading: false,
            datos: datos,
            error: 'El producto ya no existe.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          datos: datos,
          productoId: producto.id,
          codigo: producto.codigo,
          nombre: producto.nombre,
          descripcion: producto.descripcion,
          empresa: producto.empresa,
          marca: producto.marca,
          categoria: producto.categoria,
          subcategoria: producto.subcategoria,
          tipoRegistro: producto.tipoRegistro,
          atributos: producto.atributos,
          presentaciones: producto.presentaciones,
          precios: producto.precios,
          imagenesPaths: producto.imagenesPaths.isNotEmpty
              ? producto.imagenesPaths
              : producto.imagenPath == null
              ? const []
              : [producto.imagenPath!],
          activo: producto.activo,
          creadoEn: producto.creadoEn,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudieron cargar los datos del formulario.',
        ),
      );
    }
  }

  void _clasificacion(
    ProductoFormClasificacionCambiada event,
    Emitter<ProductoFormState> emit,
  ) {
    final cambioCategoria =
        event.categoria != null && event.categoria != state.categoria;
    emit(
      state.copyWith(
        empresa: event.empresa,
        marca: event.marca,
        categoria: event.categoria,
        subcategoria: event.subcategoria,
        limpiarSubcategoria: cambioCategoria,
        atributos: cambioCategoria ? {} : null,
        limpiarError: true,
      ),
    );
  }

  Future<void> _guardar(
    ProductoFormGuardado event,
    Emitter<ProductoFormState> emit,
  ) async {
    if (!state.formularioValido) {
      emit(
        state.copyWith(
          paso: state.primerPasoInvalido,
          error:
              'Completa la información general y registra al menos una presentación.',
        ),
      );
      return;
    }
    emit(state.copyWith(saving: true, limpiarError: true));
    try {
      final producto = NuevoProducto(
        codigo: state.codigo.trim(),
        nombre: state.nombre.trim(),
        descripcion: state.descripcion.trim(),
        empresa: state.empresa!,
        marca: state.marca!,
        categoria: state.categoria!,
        subcategoria: state.subcategoria!,
        tipoRegistro: state.tipoRegistro,
        atributos: state.atributos,
        presentaciones: state.presentaciones,
        precios: state.precios,
        imagenesPaths: state.imagenesPaths,
        activo: state.activo,
      );
      if (state.productoId == null) {
        await _repository.guardarProducto(producto);
      } else {
        await _repository.actualizarProducto(state.productoId!, producto);
      }
      emit(state.copyWith(saving: false, guardado: true));
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          error: state.editando
              ? 'No se pudo actualizar. Verifica que el código no esté repetido.'
              : 'No se pudo guardar. Verifica que el código no esté repetido.',
        ),
      );
    }
  }
}
