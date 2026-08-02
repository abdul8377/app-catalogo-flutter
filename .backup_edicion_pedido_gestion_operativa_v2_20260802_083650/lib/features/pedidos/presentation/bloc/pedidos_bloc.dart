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
      (_, emit) => emit(
        state.copyWith(
          limpiarFiltros: true,
          filtroPrecio: 'Todos',
          orden: 'Nombre A-Z',
          filtrosRapidos: const {'Todos'},
        ),
      ),
    );
    on<PedidosFiltroRapidoCatalogoCambiado>(_filtroRapidoCatalogo);
    on<PedidosFiltrosCatalogoAplicados>((event, emit) {
      final filtros = event.filtros;
      emit(
        state
            .copyWith(limpiarFiltros: true)
            .copyWith(
              empresa: filtros.empresa,
              marca: filtros.marca,
              categoria: filtros.categoria,
              subcategoria: filtros.subcategoria,
              estado: filtros.estado,
              imagen: filtros.imagen,
              filtroPrecio: filtros.precio ?? 'Todos',
              orden: filtros.orden,
            ),
      );
    });
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

  void _filtroRapidoCatalogo(
    PedidosFiltroRapidoCatalogoCambiado event,
    Emitter<PedidosState> emit,
  ) {
    final filters = {...state.filtrosRapidos};
    if (event.filtro == 'Todos') {
      filters
        ..clear()
        ..add('Todos');
    } else {
      filters.remove('Todos');
      const opposites = {
        'Activos': 'Inactivos',
        'Inactivos': 'Activos',
        'Con precio': 'Sin precio',
        'Sin precio': 'Con precio',
        'Con imagen': 'Sin imagen',
        'Sin imagen': 'Con imagen',
        'Con variantes': 'Sin variantes',
        'Sin variantes': 'Con variantes',
      };
      if (!filters.remove(event.filtro)) {
        filters
          ..remove(opposites[event.filtro])
          ..add(event.filtro);
      }
      if (filters.isEmpty) filters.add('Todos');
    }
    emit(
      state.copyWith(
        filtrosRapidos: filters,
        filtroPrecio: filters.contains('Con precio')
            ? 'Con precio'
            : filters.contains('Sin precio')
            ? 'Sin precio'
            : 'Todos',
      ),
    );
  }

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
      (item) => item.claveCarrito == event.item.claveCarrito,
    );
    final items = [...state.carrito];
    if (index < 0) {
      items.add(event.item);
    } else {
      final current = items[index];
      final quantity = current.cantidad + event.item.cantidad;
      final option = current.opcionSeleccionada;
      if (option != null && !option.cantidadValida(quantity)) {
        emit(
          state.copyWith(
            error:
                'La cantidad acumulada no respeta el pedido mínimo o el incremento.',
          ),
        );
        return;
      }
      final price = option?.precioPara(quantity) ?? current.precioUnitario;
      items[index] = current.copyWith(
        cantidad: quantity,
        precioUnitario: price,
        limpiarPrecio:
            option != null &&
            (option.configuracionPrecio == 'por_cotizar' || price == null),
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
      final current = items[event.index];
      final option = current.opcionSeleccionada;
      if (option != null && !option.cantidadValida(event.cantidad)) {
        emit(
          state.copyWith(
            error:
                'La cantidad debe respetar el pedido mínimo y el incremento.',
          ),
        );
        return;
      }
      final price =
          option?.precioPara(event.cantidad) ?? current.precioUnitario;
      items[event.index] = current.copyWith(
        cantidad: event.cantidad,
        precioUnitario: price,
        limpiarPrecio:
            option != null &&
            (option.configuracionPrecio == 'por_cotizar' || price == null),
      );
    }
    emit(state.copyWith(carrito: items, limpiarError: true));
  }

  void _cambiarPresentacion(
    PedidoItemPresentacionCambiada event,
    Emitter<PedidosState> emit,
  ) {
    if (event.index < 0 || event.index >= state.carrito.length) return;
    final items = [...state.carrito];
    final current = items[event.index];
    final option = current.opciones
        .where(
          (candidate) =>
              candidate.id == event.presentacion ||
              candidate.nombre == event.presentacion,
        )
        .firstOrNull;
    if (option == null) return;
    if (!option.cantidadValida(current.cantidad)) {
      emit(
        state.copyWith(
          error: 'La cantidad actual no es válida para esa presentación.',
        ),
      );
      return;
    }
    final price = option.precioPara(current.cantidad);
    final updated = current.copyWith(
      presentacionId: option.id,
      presentacion: option.nombre,
      equivalencia: option.equivalencia,
      precioListaId: option.listaPrecioId,
      precioListaNombre: option.listaPrecioNombre,
      precioConfiguracion: option.configuracionPrecio,
      precioUnitario: price,
      limpiarPrecio:
          option.configuracionPrecio == 'por_cotizar' || price == null,
    );

    final duplicateIndex = items.indexWhere(
      (candidate) =>
          candidate != current &&
          candidate.claveCarrito == updated.claveCarrito,
    );
    if (duplicateIndex >= 0) {
      final duplicate = items[duplicateIndex];
      final quantity = duplicate.cantidad + updated.cantidad;
      final duplicateOption = duplicate.opcionSeleccionada;
      if (duplicateOption != null &&
          !duplicateOption.cantidadValida(quantity)) {
        emit(
          state.copyWith(
            error:
                'No se pueden unir las líneas porque la cantidad resultante no es válida.',
          ),
        );
        return;
      }
      final mergedPrice =
          duplicateOption?.precioPara(quantity) ?? duplicate.precioUnitario;
      items[duplicateIndex] = duplicate.copyWith(
        cantidad: quantity,
        precioUnitario: mergedPrice,
        limpiarPrecio:
            duplicateOption != null &&
            (duplicateOption.configuracionPrecio == 'por_cotizar' ||
                mergedPrice == null),
      );
      items.removeAt(event.index);
    } else {
      items[event.index] = updated;
    }
    emit(state.copyWith(carrito: items, limpiarError: true));
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
