import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/catalogo_form_data.dart';
import '../../../domain/entities/nuevo_producto.dart';
import '../../../domain/entities/producto_variante.dart';
import '../../../domain/services/codigo_interno_generator.dart';
import '../../../domain/repositories/catalogo_repository.dart';
import '../../models/producto_form/imagenes_draft.dart';
import '../../models/producto_form/precios_draft.dart';
import '../../models/producto_form/revision_draft.dart';
import '../../models/producto_form/venta_logistica_draft.dart';
import 'producto_form_event.dart';
import 'producto_form_state.dart';

class ProductoFormBloc extends Bloc<ProductoFormEvent, ProductoFormState> {
  ProductoFormBloc(this._repository) : super(ProductoFormState.initial()) {
    on<ProductoFormStarted>(_started);
    on<ProductoFormPasoSiguiente>((_, emit) {
      if (!state.pasoValido) {
        emit(state.copyWith(error: state.mensajePasoInvalido));
      } else if (state.paso < 6) {
        final siguiente = state.paso == 1 ? 3 : state.paso + 1;
        emit(state.copyWith(paso: siguiente, limpiarError: true));
      }
    });
    on<ProductoFormPasoAnterior>((_, emit) {
      if (state.paso > 0) {
        final anterior = state.paso == 3 ? 1 : state.paso - 1;
        emit(state.copyWith(paso: anterior, limpiarError: true));
      }
    });
    on<ProductoFormPasoSeleccionado>((event, emit) {
      if (state.pasoEsAccesible(event.paso)) {
        emit(state.copyWith(paso: event.paso, limpiarError: true));
        return;
      }
      emit(
        state.copyWith(
          error: 'Completa los pasos anteriores antes de continuar.',
        ),
      );
    });
    on<ProductoFormClasificacionCambiada>(_clasificacion);
    on<ProductoFormFamiliaCambiada>(_familiaCambiada);
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
    on<ProductoFormImagenReemplazada>((event, emit) {
      if (event.index < 0 || event.index >= state.imagenesPaths.length) return;
      final imagenes = [...state.imagenesPaths];
      imagenes[event.index] = event.path;
      emit(state.copyWith(imagenesPaths: imagenes, limpiarError: true));
    });
    on<ProductoFormImagenReordenada>((event, emit) {
      if (event.desde < 0 ||
          event.desde >= state.imagenesPaths.length ||
          event.hasta < 0 ||
          event.hasta >= state.imagenesPaths.length ||
          event.desde == event.hasta) {
        return;
      }
      final imagenes = [...state.imagenesPaths];
      final image = imagenes.removeAt(event.desde);
      imagenes.insert(event.hasta, image);
      emit(state.copyWith(imagenesPaths: imagenes, limpiarError: true));
    });
    on<ProductoFormImagenesConfiguradasCambiadas>((event, emit) {
      emit(
        state.copyWith(
          paso: event.continuar ? 6 : null,
          imagenesConfiguradas: event.draft,
          imagenesPaths: _rutasGaleriaFamiliar(event.draft),
          activo: event.draft.canActivate ? null : false,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormTipoCambiado>((event, emit) {
      if (event.tipo == state.tipoRegistro) return;
      emit(
        state.copyWith(
          tipoRegistro: event.tipo,
          variantes: const [],
          edicionVariantePendiente: false,
          matrizCombinacionesTotales: 0,
          matrizCombinacionesExcluidas: 0,
          presentaciones: const [],
          precios: const [],
          imagenesPaths: const [],
          limpiarVentaLogisticaContenido: true,
          limpiarPreciosConfigurados: true,
          limpiarImagenesConfiguradas: true,
          activo: false,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormAtributoCambiado>(
      (event, emit) => emit(
        state.copyWith(
          atributos: {...state.atributos, event.nombre: event.valor},
        ),
      ),
    );
    on<ProductoFormVarianteGuardada>((event, emit) {
      final variantes = [...state.variantes];
      final index = variantes.indexWhere(
        (variante) => variante.id == event.variante.id,
      );
      final cambiaEstructura = index < 0;
      if (cambiaEstructura) {
        variantes.add(event.variante);
      } else {
        variantes[index] = event.variante;
      }
      emit(
        state.copyWith(
          variantes: variantes,
          edicionVariantePendiente: false,
          presentaciones: cambiaEstructura ? const [] : null,
          precios: cambiaEstructura ? const [] : null,
          imagenesPaths: cambiaEstructura ? const [] : null,
          limpiarVentaLogisticaContenido: cambiaEstructura,
          limpiarPreciosConfigurados: cambiaEstructura,
          limpiarImagenesConfiguradas: cambiaEstructura,
          activo: cambiaEstructura ? false : null,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormMatrizResumenCambiado>((event, emit) {
      emit(
        state.copyWith(
          matrizCombinacionesTotales: event.total,
          matrizCombinacionesExcluidas: event.excluidas,
        ),
      );
    });
    on<ProductoFormVariantesReemplazadas>((event, emit) {
      final currentIds = state.variantes.map((item) => item.id).toSet();
      final nextIds = event.variantes.map((item) => item.id).toSet();
      final cambiaEstructura =
          currentIds.length != nextIds.length ||
          !currentIds.containsAll(nextIds);
      emit(
        state.copyWith(
          variantes: event.variantes,
          edicionVariantePendiente: false,
          presentaciones: cambiaEstructura ? const [] : null,
          precios: cambiaEstructura ? const [] : null,
          imagenesPaths: cambiaEstructura ? const [] : null,
          limpiarVentaLogisticaContenido: cambiaEstructura,
          limpiarPreciosConfigurados: cambiaEstructura,
          limpiarImagenesConfiguradas: cambiaEstructura,
          activo: cambiaEstructura ? false : null,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormVarianteEliminada>((event, emit) {
      final variantes = state.variantes
          .where((variante) => variante.id != event.id)
          .toList();
      emit(
        state.copyWith(
          variantes: variantes,
          edicionVariantePendiente: false,
          presentaciones: const [],
          precios: const [],
          imagenesPaths: const [],
          limpiarVentaLogisticaContenido: true,
          limpiarPreciosConfigurados: true,
          limpiarImagenesConfiguradas: true,
          activo: false,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormEdicionVarianteCambiada>(
      (event, emit) => emit(
        state.copyWith(
          edicionVariantePendiente: event.pendiente,
          limpiarError: event.pendiente,
        ),
      ),
    );
    on<ProductoFormErrorLimpiado>(
      (_, emit) => emit(state.copyWith(limpiarError: true)),
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
    on<ProductoFormVentaLogisticaCambiada>((event, emit) {
      final presentaciones = event.draft.presentations
          .map(
            (item) => PresentacionProducto(
              nombre: item.name,
              unidad: '${_numeroPlano(item.equivalentTo)} ${item.baseUnit}',
            ),
          )
          .toList();
      final nombres = presentaciones.map((item) => item.nombre).toSet();
      final precios = state.precios
          .where((precio) => nombres.contains(precio.presentacion))
          .toList();
      emit(
        state.copyWith(
          paso: event.continuar ? 4 : null,
          ventaLogisticaContenido: event.draft,
          presentaciones: presentaciones,
          precios: precios,
          limpiarError: true,
        ),
      );
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
    on<ProductoFormPreciosConfiguradosCambiados>((event, emit) {
      final tienePendientes =
          event.draft.lists.isEmpty ||
          event.draft.lists.any((list) => !event.draft.canActivate(list.id));
      emit(
        state.copyWith(
          paso: event.continuar ? 5 : null,
          preciosConfigurados: event.draft,
          precios: _preciosCompatibles(event.draft),
          activo: tienePendientes ? false : null,
          limpiarError: true,
        ),
      );
    });
    on<ProductoFormEstadoCambiado>((event, emit) {
      if (event.activo && !state.preciosListosParaActivar) {
        emit(
          state.copyWith(
            activo: false,
            error:
                'Completa los precios pendientes antes de activar el producto.',
          ),
        );
        return;
      }
      if (event.activo && !state.imagenesListasParaActivar) {
        emit(
          state.copyWith(
            activo: false,
            error:
                'Agrega una imagen principal lista antes de activar el producto.',
          ),
        );
        return;
      }
      emit(state.copyWith(activo: event.activo, limpiarError: true));
    });
    on<ProductoFormGuardado>(_guardar);
    on<ProductoFormActivadoDesdeRevision>(_activarDesdeRevision);
  }

  String _numeroPlano(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  List<PrecioProducto> _preciosCompatibles(PricingStep5Draft draft) {
    final combinations = {
      for (final item in draft.sellableCombinations) item.sourceKey: item,
    };
    final result = <PrecioProducto>[];
    for (final price in draft.prices) {
      final value = switch (price.configuration) {
        PriceConfigurationType.fixed => price.fixedPrice,
        PriceConfigurationType.quantity =>
          price.ranges.firstOrNull?.pricePerPresentation,
        PriceConfigurationType.quote ||
        PriceConfigurationType.unconfigured => null,
      };
      if (value == null) continue;
      final source =
          combinations['${price.variantId}::${price.presentationId}'];
      result.add(
        PrecioProducto(
          presentacion: source?.presentationLabel ?? price.presentationId,
          valor: value,
          listaPrecioId: price.listId,
          varianteId: price.variantId,
          presentacionId: price.presentationId,
          configuracion: switch (price.configuration) {
            PriceConfigurationType.fixed => 'precio_fijo',
            PriceConfigurationType.quantity => 'por_cantidad',
            PriceConfigurationType.quote => 'por_cotizar',
            PriceConfigurationType.unconfigured => 'pendiente',
          },
        ),
      );
    }
    return result;
  }

  List<String> _rutasGaleriaFamiliar(Step6ImagesDraft draft) {
    final ordered = [...draft.familyImages]
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.order.compareTo(b.order);
      });
    return ordered
        .where((image) => image.isReady)
        .map((image) => image.candidate.localPath)
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toSet()
        .toList();
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
        emit(state.copyWith(loading: false, datos: datos, codigo: ''));
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
          variantes: producto.variantes.isNotEmpty
              ? producto.variantes
              : [
                  ProductoVariante(
                    id: 'legacy-${producto.id}',
                    sku: producto.codigo,
                    nombreCorto: producto.nombre,
                    atributos: producto.atributos.entries
                        .map(
                          (entry) => AtributoProductoVariante.fromText(
                            entry.key,
                            entry.value,
                          ),
                        )
                        .toList(),
                    activa: producto.activo,
                    imagenPath:
                        producto.imagenPath ??
                        producto.imagenesPaths.firstOrNull,
                  ),
                ],
          presentaciones: producto.presentaciones,
          ventaLogisticaContenido: step4SalesDraftFromMap(
            producto.ventaLogisticaContenido,
          ),
          preciosConfigurados: step5PricingDraftFromMap(
            producto.preciosConfigurados,
          ),
          imagenesConfiguradas: step6ImagesDraftFromMap(
            producto.imagenesConfiguradas,
          ),
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

  Future<void> _familiaCambiada(
    ProductoFormFamiliaCambiada event,
    Emitter<ProductoFormState> emit,
  ) async {
    final codigoAnterior = state.codigo;
    final nombre = event.nombre ?? state.nombre;
    emit(
      state.copyWith(
        codigo: event.codigo,
        nombre: event.nombre,
        descripcion: event.descripcion,
        limpiarError: true,
      ),
    );

    if (state.editando || event.codigo != null || event.nombre == null) return;
    final nombreBase = nombre.trim();
    if (nombreBase.isEmpty) return;

    final prefijo = CodigoInternoGenerator.prefijoDesdeNombre(nombreBase);
    final codigoActual = state.codigo.trim().toUpperCase();
    final tienePrefijoActual = RegExp(
      '^${RegExp.escape(prefijo)}-\\d+\$',
    ).hasMatch(codigoActual);
    if (tienePrefijoActual) return;

    if (state.tipoRegistro != 'unico' &&
        state.variantes.isNotEmpty &&
        codigoAnterior.trim().isNotEmpty) {
      return;
    }

    try {
      final productos = await _repository.obtenerProductos();
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: nombreBase,
        codigosExistentes: productos
            .where((producto) => producto.id != state.productoId)
            .map((producto) => producto.codigo),
      );
      if (state.editando || state.nombre.trim() != nombreBase) return;
      emit(
        state.copyWith(
          codigo: codigo,
          variantes: state.tipoRegistro == 'unico'
              ? _actualizarCodigoProductoUnico(state.variantes, codigo)
              : null,
          limpiarError: true,
        ),
      );
    } catch (_) {
      final codigo = CodigoInternoGenerator.siguienteProducto(
        nombreBase: nombreBase,
        codigosExistentes: const [],
      );
      if (state.editando || state.nombre.trim() != nombreBase) return;
      emit(
        state.copyWith(
          codigo: codigo,
          variantes: state.tipoRegistro == 'unico'
              ? _actualizarCodigoProductoUnico(state.variantes, codigo)
              : null,
          limpiarError: true,
        ),
      );
    }
  }

  List<ProductoVariante> _actualizarCodigoProductoUnico(
    List<ProductoVariante> variantes,
    String codigo,
  ) {
    if (variantes.isEmpty) return variantes;
    return [
      variantes.first.copyWith(
        sku: CodigoInternoGenerator.codigoProductoUnico(codigo),
      ),
    ];
  }

  void _clasificacion(
    ProductoFormClasificacionCambiada event,
    Emitter<ProductoFormState> emit,
  ) {
    final cambioEmpresa =
        event.empresa != null && event.empresa != state.empresa;
    final cambioMarca = event.marca != null && event.marca != state.marca;
    final cambioCategoria =
        event.categoria != null && event.categoria != state.categoria;
    final cambioSubcategoria =
        event.subcategoria != null && event.subcategoria != state.subcategoria;
    final cambioEstructural =
        cambioEmpresa || cambioMarca || cambioCategoria || cambioSubcategoria;

    emit(
      state.copyWith(
        empresa: event.empresa,
        marca: event.marca,
        limpiarMarca: cambioEmpresa && event.marca == null,
        categoria: event.categoria,
        limpiarCategoria:
            (cambioEmpresa || cambioMarca) && event.categoria == null,
        subcategoria: event.subcategoria,
        limpiarSubcategoria:
            (cambioEmpresa || cambioMarca || cambioCategoria) &&
            event.subcategoria == null,
        atributos: cambioEstructural ? const {} : null,
        variantes: cambioEstructural ? const [] : null,
        edicionVariantePendiente: cambioEstructural ? false : null,
        matrizCombinacionesTotales: cambioEstructural ? 0 : null,
        matrizCombinacionesExcluidas: cambioEstructural ? 0 : null,
        presentaciones: cambioEstructural ? const [] : null,
        precios: cambioEstructural ? const [] : null,
        imagenesPaths: cambioEstructural ? const [] : null,
        limpiarVentaLogisticaContenido: cambioEstructural,
        limpiarPreciosConfigurados: cambioEstructural,
        limpiarImagenesConfiguradas: cambioEstructural,
        activo: cambioEstructural ? false : null,
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
      await _persistirProducto(_productoDesdeEstado());
      emit(state.copyWith(saving: false, guardado: true));
    } catch (error) {
      emit(
        state.copyWith(
          saving: false,
          error: error is StateError
              ? error.message.toString()
              : state.editando
              ? 'No se pudo actualizar. Verifica que el código no esté repetido.'
              : 'No se pudo guardar. Verifica que el código no esté repetido.',
        ),
      );
    }
  }

  Future<void> _activarDesdeRevision(
    ProductoFormActivadoDesdeRevision event,
    Emitter<ProductoFormState> emit,
  ) async {
    if (!event.request.confirmed || !event.request.validation.canActivate) {
      event.completer.completeError(
        StateError('Corrige los bloqueos antes de activar el producto.'),
      );
      return;
    }
    if (!state.formularioValido ||
        !state.preciosListosParaActivar ||
        !state.imagenesListasParaActivar) {
      event.completer.completeError(
        StateError('El producto cambió y ya no está listo para activarse.'),
      );
      return;
    }

    emit(state.copyWith(saving: true, limpiarError: true));
    try {
      await _persistirProducto(_productoDesdeEstado(activo: true));
      emit(
        state.copyWith(
          saving: false,
          activo: true,
          guardado: true,
          limpiarError: true,
        ),
      );
      event.completer.complete(
        const Step7ActivationResult(
          pendingSynchronization: true,
          message: 'Activado en este dispositivo · Pendiente de sincronización',
        ),
      );
    } catch (error, stackTrace) {
      final message = error is StateError
          ? error.message.toString()
          : 'No se pudo activar el producto.';
      emit(state.copyWith(saving: false, activo: false, error: message));
      event.completer.completeError(error, stackTrace);
    }
  }

  NuevoProducto _productoDesdeEstado({bool? activo}) {
    final codigo = state.codigo.trim().isEmpty
        ? CodigoInternoGenerator.siguienteProducto(
            nombreBase: state.nombre,
            codigosExistentes: const [],
          )
        : state.codigo.trim().toUpperCase();
    final variantes = state.tipoRegistro == 'unico'
        ? _actualizarCodigoProductoUnico(state.variantes, codigo)
        : state.variantes;
    return NuevoProducto(
      codigo: codigo,
      nombre: state.nombre.trim(),
      descripcion: state.descripcion.trim(),
      empresa: state.empresa!,
      marca: state.marca!,
      categoria: state.categoria!,
      subcategoria: state.subcategoria ?? '',
      tipoRegistro: state.tipoRegistro,
      atributos: state.atributos,
      variantes: variantes,
      presentaciones: state.presentaciones,
      ventaLogisticaContenido: state.ventaLogisticaContenido == null
          ? null
          : step4SalesDraftToMap(state.ventaLogisticaContenido!),
      preciosConfigurados: state.preciosConfigurados == null
          ? null
          : step5PricingDraftToMap(state.preciosConfigurados!),
      imagenesConfiguradas: state.imagenesConfiguradas == null
          ? null
          : step6ImagesDraftToMap(state.imagenesConfiguradas!),
      precios: state.precios,
      imagenesPaths: state.imagenesPaths,
      activo: activo ?? state.activo,
    );
  }

  Future<void> _persistirProducto(NuevoProducto producto) async {
    if (state.productoId == null) {
      await _repository.guardarProducto(producto);
    } else {
      await _repository.actualizarProducto(state.productoId!, producto);
    }
  }
}
