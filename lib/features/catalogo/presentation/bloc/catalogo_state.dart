import '../../domain/entities/producto.dart';

sealed class CatalogoState {
  const CatalogoState();
}

class CatalogoInitialState extends CatalogoState {
  const CatalogoInitialState();
}

class CatalogoLoadingState extends CatalogoState {
  const CatalogoLoadingState();
}

class CatalogoLoadedState extends CatalogoState {
  const CatalogoLoadedState(this.productos);

  final List<Producto> productos;
}

class CatalogoErrorState extends CatalogoState {
  const CatalogoErrorState(this.message);

  final String message;
}
