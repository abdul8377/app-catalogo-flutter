import 'package:flutter/material.dart';

import '../../features/catalogo/presentation/pages/catalogo_page.dart';
import '../../features/catalogo/presentation/pages/producto_detalle_page.dart';

class AppRouter {
  const AppRouter._();

  static const catalogo = '/catalogo';
  static const productoDetalle = '/catalogo/producto';

  static Map<String, WidgetBuilder> get routes => {
    catalogo: (_) => const CatalogoPage(),
    productoDetalle: (_) => const ProductoDetallePage(),
  };
}
