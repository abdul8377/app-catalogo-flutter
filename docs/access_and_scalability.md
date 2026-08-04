# Acceso y escalabilidad futura

Estado documentado: 3 de agosto de 2026.

La base de identidad y autorización está integrada sin activar una función de
login ni cambiar la experiencia existente. El objetivo es que usuarios,
vendedores y roles futuros se conecten mediante adaptadores, no mediante
condiciones dispersas en widgets o consultas.

## Contratos disponibles

| Concepto | Ubicación | Responsabilidad |
| --- | --- | --- |
| `AppUser` | `features/auth/domain/entities` | Identidad, organización, nombre visible y vendedor asociado. |
| `AppRole` | `features/auth/domain/entities` | Rol dinámico identificado por datos, no por un enum cerrado. |
| `AppPermission` | `features/auth/domain/entities` | Capacidades estables reconocidas por el código. |
| `AuthSession` | `features/auth/domain/entities` | Snapshot inmutable de usuario y roles. |
| `SellerScope` | `features/auth/domain/entities` | Límite de organización y vendedor para futuras consultas. |
| `AuthRepository` | `features/auth/domain/repositories` | Puerto para restaurar, observar, iniciar y cerrar sesión. |
| `RoleRepository` | `features/auth/domain/repositories` | Puerto para administrar y asignar roles. |
| `AppDestinationAccessPolicy` | `app/navigation` | Mapeo único entre permisos y destinos. |

## Compatibilidad actual

La aplicación arranca con `AuthSession.legacyAdministrator`:

- usuario visible: `Alfonzo Esteban`;
- rol visible: `Administrador`;
- vendedor asociado: `legacy-seller`;
- organización: `legacy-organization`;
- permisos: todos los definidos actualmente.

`MainShellPage(isAdministrator: false)` continúa representando el vendedor
histórico y conserva exactamente los destinos 0 a 6. Los constructores de
Nuevo pedido, Hojas y el rail mantienen sus valores anteriores como fallback.

## Reglas para múltiples vendedores

Una implementación futura debe cumplir:

1. Toda fila operativa nueva debe guardar un identificador estable de vendedor,
   no depender solo del nombre visible.
2. Toda consulta debe recibir un `SellerScope` desde la capa de aplicación.
3. Un vendedor solo puede leer y modificar su alcance.
4. `viewAllSellers` amplía el alcance únicamente dentro de la misma
   organización.
5. Los permisos se validan nuevamente en repositorios/backend; ocultar un
   destino no constituye seguridad suficiente.
6. Cambios de asignación deben quedar en un registro de auditoría.

## Secuencia de implementación futura

### 1. Autenticación

Implementar `AuthRepository` mediante un adaptador local o remoto. La UI de
login deberá consumir el contrato y entregar un `AuthSession` a `AppCatalogo`.

### 2. Persistencia de acceso

Crear una migración aprobada por separado para organizaciones, usuarios,
roles, permisos, asignaciones y vendedor estable. No debe reutilizar nombres
visibles como claves.

### 3. Aislamiento de datos

Añadir el identificador de vendedor a pedidos, hojas, cotizaciones y eventos de
auditoría. Migrar datos heredados a `legacy-seller` y probar conservación,
claves foráneas y rollback.

### 4. Administración

Construir pantallas de usuarios y roles después de que repositorios y pruebas
de autorización existan. Los roles se crean como `AppRole`; no se agregan
condicionales del tipo `if (roleName == ...)`.

### 5. Sincronización y backend

El backend debe ser la autoridad final de permisos y organización. La base
local conserva un snapshot para el modo offline y rechaza sincronizaciones que
no pertenezcan al alcance vigente.

## Condiciones antes de modificar SQLite

- la creación limpia de v22 ya está cubierta;
- la migración sintética v21 → v22 y el rollback transaccional ya están
  cubiertos;
- todavía se requieren fixtures de bases históricas reales para cada versión
  disponible;
- pruebas de dos vendedores con datos separados;
- pruebas de administrador con acceso agregado;
- copia recuperable de la base productiva.

Hasta cumplir esas condiciones, `app_catalogo.db`, su versión 22, sus tablas y
sus transacciones permanecen intactas.
