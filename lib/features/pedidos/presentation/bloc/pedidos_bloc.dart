import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../domain/repositories/pedidos_repository.dart';
import 'pedidos_event.dart';
import 'pedidos_state.dart';

class PedidosBloc extends Bloc<PedidosEvent, PedidosState> {
  PedidosBloc(this._catalogoRepository, this._pedidosRepository)
    : super(PedidosState.initial()) {
    on<PedidosStarted>(_started);
    on<PedidosBusquedaCambiada>(
      (event, emit) => emit(state.copyWith(busqueda: event.value)),
    );
    on<PedidosFiltroPrecioCambiado>(
      (event, emit) => emit(state.copyWith(filtroPrecio: event.value)),
    );
    on<PedidosFiltrosAplicados>(
      (event, emit) => emit(
        state
            .copyWith(
              empresa: event.empresa,
              marca: event.marca,
              categoria: event.categoria,
              limpiarFiltros: true,
            )
            .copyWith(
              empresa: event.empresa,
              marca: event.marca,
              categoria: event.categoria,
            ),
      ),
    );
    on<PedidosFiltrosLimpiados>(
      (_, emit) => emit(state.copyWith(limpiarFiltros: true)),
    );
    on<PedidosOrdenCambiado>(
      (event, emit) => emit(state.copyWith(orden: event.value)),
    );
    on<PedidosVistaCambiada>(
      (event, emit) => emit(state.copyWith(vistaGrilla: event.vistaGrilla)),
    );
    on<PedidoProductoAgregado>(_agregarProducto);
    on<PedidoItemCantidadCambiada>(_cambiarCantidad);
    on<PedidoItemPresentacionCambiada>(_cambiarPresentacion);
    on<PedidoItemEliminado>(_eliminarItem);
    on<PedidoClienteBuscado>(_buscarClientes);
    on<PedidoClienteSeleccionado>(
      (event, emit) =>
          emit(state.copyWith(cliente: event.cliente, limpiarError: true)),
    );
    on<PedidoClienteLimpiado>(
      (_, emit) =>
          emit(state.copyWith(limpiarCliente: true, limpiarError: true)),
    );
    on<PedidoConfirmado>(_confirmar);
    on<PedidoHojaActivaCreada>(_crearHoja);
    on<PedidoNuevoSolicitado>(
      (_, emit) => emit(
        state.copyWith(
          carrito: const [],
          limpiarCliente: true,
          limpiarResultado: true,
          limpiarError: true,
        ),
      ),
    );
  }

  final CatalogoRepository _catalogoRepository;
  final PedidosRepository _pedidosRepository;

  Future<void> _started(
    PedidosStarted event,
    Emitter<PedidosState> emit,
  ) async {
    emit(state.copyWith(loading: true, limpiarError: true));
    try {
      final results = await Future.wait([
        _catalogoRepository.obtenerProductos(),
        _pedidosRepository.obtenerHojaActiva(),
        _pedidosRepository.buscarClientes(''),
      ]);
      emit(
        state.copyWith(
          loading: false,
          productos: results[0] as dynamic,
          hojaActiva: results[1] as dynamic,
          limpiarHoja: results[1] == null,
          clientes: results[2] as dynamic,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo cargar el módulo de pedidos.',
        ),
      );
    }
  }

  void _agregarProducto(
    PedidoProductoAgregado event,
    Emitter<PedidosState> emit,
  ) {
    final index = state.carrito.indexWhere(
      (item) =>
          item.productoId == event.item.productoId &&
          item.presentacion == event.item.presentacion,
    );
    final items = [...state.carrito];
    if (index < 0) {
      items.add(event.item);
    } else {
      items[index] = items[index].copyWith(
        cantidad: items[index].cantidad + event.item.cantidad,
      );
    }
    emit(state.copyWith(carrito: items, limpiarError: true));
  }

  void _cambiarCantidad(
    PedidoItemCantidadCambiada event,
    Emitter<PedidosState> emit,
  ) {
    if (event.index < 0 || event.index >= state.carrito.length) return;
    final items = [...state.carrito];
    if (event.cantidad <= 0) {
      items.removeAt(event.index);
    } else {
      items[event.index] = items[event.index].copyWith(
        cantidad: event.cantidad,
      );
    }
    emit(state.copyWith(carrito: items));
  }

  void _cambiarPresentacion(
    PedidoItemPresentacionCambiada event,
    Emitter<PedidosState> emit,
  ) {
    if (event.index < 0 || event.index >= state.carrito.length) return;
    final items = [...state.carrito];
    final item = items[event.index];
    final opcion = item.opciones
        .where((opcion) => opcion.nombre == event.presentacion)
        .firstOrNull;
    if (opcion == null) return;
    items[event.index] = item.copyWith(
      presentacion: opcion.nombre,
      equivalencia: opcion.equivalencia,
      precioUnitario: opcion.precio,
      limpiarPrecio: opcion.precio == null,
    );
    emit(state.copyWith(carrito: items));
  }

  void _eliminarItem(PedidoItemEliminado event, Emitter<PedidosState> emit) {
    if (event.index < 0 || event.index >= state.carrito.length) return;
    final items = [...state.carrito]..removeAt(event.index);
    emit(state.copyWith(carrito: items));
  }

  Future<void> _buscarClientes(
    PedidoClienteBuscado event,
    Emitter<PedidosState> emit,
  ) async {
    try {
      final clientes = await _pedidosRepository.buscarClientes(event.query);
      emit(state.copyWith(clientes: clientes, limpiarError: true));
    } catch (_) {
      emit(state.copyWith(error: 'No se pudieron buscar clientes.'));
    }
  }

  Future<void> _confirmar(
    PedidoConfirmado event,
    Emitter<PedidosState> emit,
  ) async {
    if (state.carrito.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un producto.'));
      return;
    }
    final cliente = state.cliente;
    if (cliente == null || cliente.nombre.trim().isEmpty) {
      emit(state.copyWith(error: 'Selecciona o registra un cliente.'));
      return;
    }
    final digits = cliente.telefono.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      emit(state.copyWith(error: 'Ingresa un teléfono válido.'));
      return;
    }
    if (cliente.direccion.trim().isEmpty) {
      emit(state.copyWith(error: 'La dirección del cliente es obligatoria.'));
      return;
    }
    emit(state.copyWith(guardando: true, limpiarError: true));
    try {
      final hojaActiva = await _pedidosRepository.obtenerHojaActiva();
      if (hojaActiva == null) {
        emit(
          state.copyWith(
            guardando: false,
            limpiarHoja: true,
            error: 'No existe una hoja de pedido activa.',
          ),
        );
        return;
      }
      final result = await _pedidosRepository.guardarPedido(
        hoja: hojaActiva,
        cliente: cliente,
        items: state.carrito,
        vendedor: 'Alfonzo Esteban',
      );
      emit(
        state.copyWith(
          guardando: false,
          hojaActiva: hojaActiva,
          carrito: const [],
          limpiarCliente: true,
          resultado: result,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          guardando: false,
          error: error is StateError
              ? error.message.toString()
              : 'No se pudo registrar el pedido.',
        ),
      );
    }
  }

  Future<void> _crearHoja(
    PedidoHojaActivaCreada event,
    Emitter<PedidosState> emit,
  ) async {
    emit(state.copyWith(loading: true, limpiarError: true));
    try {
      final hoja = await _pedidosRepository.crearHojaActiva();
      emit(state.copyWith(loading: false, hojaActiva: hoja));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No se pudo crear la hoja de pedido.',
        ),
      );
    }
  }
}
