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

La verificación final debe ejecutar el análisis, el guard de arquitectura, las
pruebas estables y el build Android. Los fallos históricos del baseline siguen
documentados y etiquetados; no se modifica UI ni lógica para ocultarlos.

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

La base continúa siendo `app_catalogo.db` y su versión vigente es `23`. La
migración es aditiva: conserva datos de negocio y agrega outbox, inbox, cursor,
conflictos, configuración, estado por entidad y cola de archivos. Hay pruebas
de creación limpia v23, migraciones sintéticas v21 → v22 → v23, transacciones
de pedidos y atomicidad dato + outbox.

## Sincronización

`features/sync` implementa sincronización offline-first contra la PC vinculada:
QR o dirección manual, credencial fuera de SQLite, caché de IP, descubrimiento
mDNS, push idempotente, pull incremental, bootstrap, reintentos y conflictos.
SQLite continúa siendo la fuente operativa de la tablet y nunca se sube el
archivo completo de base de datos.

## Documentación

- [Arquitectura técnica](docs/architecture.md)
- [Baseline y validación](docs/refactor_baseline.md)
- [Acceso y escalabilidad futura](docs/access_and_scalability.md)
- [Sincronización tablet ↔ PC](docs/synchronization.md)
