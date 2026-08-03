import 'package:uuid/uuid.dart';

abstract final class CodigoInternoGenerator {
  static const Uuid _uuid = Uuid();

  static String nuevoProducto() => _generate('PRD');

  static String nuevaVariante() => _generate('VAR');

  static String _generate(String prefix) {
    final token = _uuid.v4().replaceAll('-', '').substring(0, 10).toUpperCase();
    return '$prefix-$token';
  }
}
