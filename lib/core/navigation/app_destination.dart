/// Contrato neutral de destinos e índices estables de la aplicación.
enum AppDestination {
  home(0),
  catalogo(1),
  clientes(2),
  nuevoPedido(3),
  pedidos(4),
  hojasPedido(5),
  dashboard(6),
  estructuraCatalogo(7);

  const AppDestination(this.navigationIndex);

  final int navigationIndex;

  static AppDestination? tryFromIndex(int index) {
    for (final destination in values) {
      if (destination.navigationIndex == index) return destination;
    }
    return null;
  }
}
