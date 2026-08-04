# App Catálogo

Aplicación Flutter offline para catálogo, clientes, pedidos, cotizaciones,
preparación, carga, hojas de pedido, dashboard y estructura comercial.

## Regla de oro

El código puede reorganizarse; la aplicación observable no. Un refactor debe
conservar funcionalidad, reglas comerciales, diseño, navegación, datos, SQL,
migraciones, transacciones y serialización.

## Requisitos

- Flutter 3.44.5 o compatible con Dart 3.12.2.
- Dependencias instaladas con `flutter pub get`.
- Dispositivo o emulador para ejecutar la aplicación.

## Comandos

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze
flutter test --no-pub --exclude-tags baseline-known-failure
flutter test --no-pub
flutter build apk --debug --no-pub
flutter run
```

El gate estable contiene 130 pruebas verdes. La suite completa conserva seis
fallos anteriores al refactor, documentados y etiquetados; no se modificó la UI
ni la lógica para hacerlos pasar.

## Organización

```text
lib/
  app/       # composición, inyección y navegación
  core/      # SQLite, plataforma y componentes transversales
  features/  # módulos por responsabilidades reales
```

Las features siguen las capas `domain`, `application`, `data` y
`presentation` cuando las necesitan. No se crean carpetas vacías para forzar
simetría: un caso de uso, servicio o modelo sólo existe cuando tiene una
responsabilidad y un consumidor.

`features/auth/domain` contiene contratos para identidad, roles dinámicos,
permisos y alcance por vendedor. La sesión heredada mantiene el comportamiento
actual; login, administración y aislamiento multi-vendedor son evoluciones
funcionales separadas.

## Persistencia

La base continúa siendo `app_catalogo.db`, versión 22. La implementación está
ordenada en esquema, migraciones y seed, pero no cambió SQL ni orden de
ejecución. Hay pruebas de creación v22, migración sintética v21 → v22 y
transacciones de pedidos.

## Documentación

- [Arquitectura técnica](docs/architecture.md)
- [Baseline y validación](docs/refactor_baseline.md)
- [Acceso y escalabilidad futura](docs/access_and_scalability.md)
