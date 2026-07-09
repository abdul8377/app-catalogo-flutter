sealed class CatalogoEvent {
  const CatalogoEvent();
}

class ObtenerProductosEvent extends CatalogoEvent {
  const ObtenerProductosEvent();
}

class BuscarProductosEvent extends CatalogoEvent {
  const BuscarProductosEvent(this.query);

  final String query;
}
