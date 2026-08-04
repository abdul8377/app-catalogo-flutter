# Baseline de la reestructuración

Este documento separa el estado histórico de la verificación final y protege la
regla de oro.

## Referencia previa

| Dato | Valor |
| --- | --- |
| Commit corto | `9ba8f42` |
| Commit completo | `9ba8f425850d226849d87b84cecb7038434cb79a` |
| Fecha | 2 de agosto de 2026 |
| Flutter | 3.44.5 stable |
| Dart | 3.12.2 |

El baseline previo contenía 47 diagnósticos estáticos: 0 errores, 6 warnings y
41 infos. La suite contenía 89 pruebas aprobadas y 6 fallidas.

## Fallos históricos protegidos

| # | Prueba | Resultado histórico |
| ---: | --- | --- |
| 1 | `pedidos_correcciones_test.dart` — tarjeta de cotización | No encuentra `Editar precio`. |
| 2 | `preparacion_presentaciones_test.dart` — contador | `RenderFlex overflow` de 30 px. |
| 3 | `producto_card_test.dart` — imagen | Espera altura 228; obtiene 212. |
| 4 | `producto_form_page_test.dart` — matriz angosta | No encuentra `Combinaciones generadas`. |
| 5 | `producto_form_page_test.dart` — producto único | Espera prefijo `PRD-`; obtiene `PER-001`. |
| 6 | `producto_form_page_test.dart` — lista | Espera prefijo `VAR-`; obtiene `FAM-001-001`. |

No se cambiaron UI, lógica o expectativas para ocultar estos fallos. Están
marcados con `baseline-known-failure`.

## Invariantes

1. Mismos flujos, validaciones, cálculos, defaults y efectos.
2. Mismo árbol visual, textos, dimensiones, orden y comportamiento responsive.
3. Mismos destinos, índices, permisos, callbacks e identidad de páginas.
4. Mismo archivo, versión, esquema, SQL, seed, migraciones y transacciones.
5. Toda ruta temporal se retira sólo después de migrar todos sus consumidores.
6. Ninguna fase puede agregar errores, warnings o pruebas fallidas.

## Persistencia v22

Permanecen intactos el nombre `app_catalogo.db`, la versión 22, las claves
foráneas y la secuencia `if (oldVersion < n)`.

Antes de dividir SQLite se añadieron:

- prueba de creación limpia v22;
- fixture sintético v21 y migración a v22 con conservación;
- pruebas de commit y rollback de creación de pedidos.

Después se movieron los mismos métodos a `schema/`, `migrations/` y
`seeds/`, y se separó `PedidosLocalDatasource` sin mover límites
transaccionales.

Esto habilita el refactor mecánico realizado, pero no autoriza cambios futuros
de esquema. Aún se requieren fixtures reales de todas las versiones
disponibles antes de modificar o consolidar migraciones históricas.

## Resultado integrado

| Control | Resultado |
| --- | --- |
| `dart format lib test` | 366 archivos conformes. |
| `dart analyze` | 0 errores, 0 warnings, 41 infos. |
| Gate sin deuda histórica | 130 aprobadas, 0 fallidas. |
| Suite completa | 130 aprobadas y los mismos 6 fallos. |
| Guard de arquitectura | 10 reglas aprobadas. |

La diferencia de 89 a 130 corresponde a 41 contratos añadidos. Ningún fallo
nuevo permanece.

## Fuera de alcance funcional

- login y persistencia de usuarios;
- editor visual de usuarios y roles;
- aislamiento SQL por organización/vendedor;
- sincronización remota;
- modificación del esquema o de la cadena v2–v22;
- corrección de los seis comportamientos históricos.

Esas evoluciones pueden apoyarse en los contratos actuales, pero requieren una
tarea funcional explícita y nuevas pruebas.
