from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

DATASOURCE_PATH = ROOT / "lib/features/dashboard/data/datasources/dashboard_local_datasource.dart"
BLOC_PATH = ROOT / "lib/features/dashboard/presentation/bloc/dashboard_bloc.dart"
PAGE_PATH = ROOT / "lib/features/dashboard/presentation/pages/dashboard_page.dart"
SHELL_PATH = ROOT / "lib/app/navigation/main_shell_page.dart"
TEST_PATH = ROOT / "test/dashboard_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
    label: str,
) -> str:
    if source.count(start_marker) != 1 or source.count(end_marker) != 1:
        fail(f"No se pudo delimitar “{label}”.")
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


for path in (DATASOURCE_PATH, BLOC_PATH, PAGE_PATH, SHELL_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

datasource = DATASOURCE_PATH.read_text(encoding="utf-8")
bloc = BLOC_PATH.read_text(encoding="utf-8")
page = PAGE_PATH.read_text(encoding="utf-8")
shell = SHELL_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

if "ORDER BY actividad.creado_en DESC" in datasource:
    fail("La consulta del Dashboard ya parece estar corregida.")
if "_DashboardRepositoryFailing" in tests:
    fail("La prueba de error del Dashboard ya existe.")

new_activity_query = "    final actividadRows = await db.rawQuery(\n      '''\n      SELECT actividad.evento,\n             actividad.detalle,\n             actividad.creado_en,\n             actividad.tipo\n      FROM (\n        SELECT ph.evento AS evento,\n               ph.observacion AS detalle,\n               ph.creado_en AS creado_en,\n               'pedido' AS tipo\n        FROM pedido_historial ph\n        INNER JOIN pedidos p ON p.id = ph.pedido_id\n        WHERE ${scope.where}\n        UNION ALL\n        SELECT 'Cotización ' || co.codigo || ' guardada' AS evento,\n               co.estado AS detalle,\n               co.creado_en AS creado_en,\n               'cotizacion' AS tipo\n        FROM cotizaciones co\n        INNER JOIN pedidos p ON p.id = co.pedido_id\n        WHERE ${scope.where}\n      ) AS actividad\n      ORDER BY actividad.creado_en DESC\n      LIMIT 8\n    ''',\n      [...scope.args, ...scope.args],\n    );\n"
old_message_method = "  String _mensaje(String prefix, Object error) {\n    final detalle = error\n        .toString()\n        .replaceFirst('Bad state: ', '')\n        .replaceFirst('Invalid argument(s): ', '');\n    return '$prefix: $detalle';\n  }\n"
new_message_method = "  String _mensaje(String prefix, Object error) {\n    debugPrint('$prefix\\n$error');\n    return '$prefix. Tus pedidos y hojas permanecen guardados en el '\n        'dispositivo. Intenta nuevamente.';\n  }\n"
old_listener = '        final text = state.error ?? state.message;\n        if (text == null) return;\n        ScaffoldMessenger.of(context)\n          ..hideCurrentSnackBar()\n          ..showSnackBar(\n            SnackBar(\n              content: Text(text),\n              backgroundColor: state.error == null\n                  ? const Color(0xFF16794B)\n                  : const Color(0xFFB42318),\n            ),\n          );\n'
new_listener = '        final initialLoadFailed =\n            state.error != null && state.data == const DashboardData.empty();\n        if (initialLoadFailed) return;\n\n        final text = state.error ?? state.message;\n        if (text == null) return;\n        ScaffoldMessenger.of(context)\n          ..hideCurrentSnackBar()\n          ..showSnackBar(\n            SnackBar(\n              content: Text(text),\n              backgroundColor: state.error == null\n                  ? const Color(0xFF16794B)\n                  : const Color(0xFFB42318),\n            ),\n          );\n'
new_error_state = "class _ErrorState extends StatelessWidget {\n  const _ErrorState({required this.message, required this.onRetry});\n\n  final String message;\n  final VoidCallback onRetry;\n\n  @override\n  Widget build(BuildContext context) {\n    return LayoutBuilder(\n      builder: (context, constraints) {\n        final availableHeight = constraints.maxHeight > 40\n            ? constraints.maxHeight - 40\n            : 0.0;\n\n        return SingleChildScrollView(\n          physics: const AlwaysScrollableScrollPhysics(),\n          padding: const EdgeInsets.all(20),\n          child: ConstrainedBox(\n            constraints: BoxConstraints(minHeight: availableHeight),\n            child: Center(\n              child: Container(\n                width: double.infinity,\n                constraints: const BoxConstraints(maxWidth: 560),\n                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),\n                decoration: BoxDecoration(\n                  color: Colors.white,\n                  borderRadius: BorderRadius.circular(20),\n                  border: Border.all(color: const Color(0xFFEAECF0)),\n                  boxShadow: const [\n                    BoxShadow(\n                      color: Color(0x14000000),\n                      blurRadius: 18,\n                      offset: Offset(0, 6),\n                    ),\n                  ],\n                ),\n                child: Column(\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    Container(\n                      width: 58,\n                      height: 58,\n                      decoration: const BoxDecoration(\n                        color: Color(0xFFFEECEB),\n                        shape: BoxShape.circle,\n                      ),\n                      child: const Icon(\n                        Icons.dashboard_customize_outlined,\n                        size: 30,\n                        color: Color(0xFFB42318),\n                      ),\n                    ),\n                    const SizedBox(height: 16),\n                    Text(\n                      'No pudimos preparar el Dashboard',\n                      textAlign: TextAlign.center,\n                      style: GoogleFonts.inter(\n                        color: _ink,\n                        fontSize: 19,\n                        fontWeight: FontWeight.w800,\n                      ),\n                    ),\n                    const SizedBox(height: 8),\n                    Text(\n                      message,\n                      maxLines: 4,\n                      overflow: TextOverflow.ellipsis,\n                      textAlign: TextAlign.center,\n                      style: GoogleFonts.inter(\n                        color: _muted,\n                        fontSize: 13,\n                        height: 1.45,\n                      ),\n                    ),\n                    const SizedBox(height: 12),\n                    Container(\n                      width: double.infinity,\n                      padding: const EdgeInsets.all(12),\n                      decoration: BoxDecoration(\n                        color: const Color(0xFFFFF8DD),\n                        borderRadius: BorderRadius.circular(12),\n                        border: const Border(\n                          left: BorderSide(color: _yellow, width: 4),\n                        ),\n                      ),\n                      child: Text(\n                        'La información comercial sigue disponible en Pedidos, '\n                        'Hojas de pedido y Clientes.',\n                        style: GoogleFonts.inter(\n                          color: _ink,\n                          fontSize: 12,\n                          height: 1.4,\n                        ),\n                      ),\n                    ),\n                    const SizedBox(height: 18),\n                    FilledButton.icon(\n                      onPressed: onRetry,\n                      style: FilledButton.styleFrom(\n                        backgroundColor: _yellow,\n                        foregroundColor: _ink,\n                        minimumSize: const Size(170, 46),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(12),\n                        ),\n                      ),\n                      icon: const Icon(Icons.refresh_rounded),\n                      label: const Text(\n                        'Reintentar',\n                        style: TextStyle(fontWeight: FontWeight.w700),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ),\n          ),\n        );\n      },\n    );\n  }\n}\n"
old_stack = '          Expanded(\n            child: IndexedStack(index: selectedIndex, children: _buildPages()),\n          ),\n'
new_stack = '          Expanded(\n            child: IndexedStack(\n              index: selectedIndex,\n              children: List<Widget>.generate(pages.length, (index) {\n                final mounted = _mountedPageIndexes.contains(index);\n                return HeroMode(\n                  enabled: index == selectedIndex,\n                  child: mounted ? pages[index] : const SizedBox.shrink(),\n                );\n              }),\n            ),\n          ),\n'
error_test = "  testWidgets('el error inicial es breve, recuperable y no desborda', (\n    tester,\n  ) async {\n    tester.view.physicalSize = const Size(800, 1280);\n    tester.view.devicePixelRatio = 1;\n    addTearDown(tester.view.resetPhysicalSize);\n    addTearDown(tester.view.resetDevicePixelRatio);\n\n    await tester.pumpWidget(\n      const _TestApp(\n        repository: _DashboardRepositoryFailing(),\n        child: DashboardPage(),\n      ),\n    );\n    await tester.pumpAndSettle();\n\n    expect(find.text('No pudimos preparar el Dashboard'), findsOneWidget);\n    expect(find.text('Reintentar'), findsOneWidget);\n    expect(find.textContaining('SELECT ph.evento'), findsNothing);\n    expect(find.textContaining('SQLITE_ERROR'), findsNothing);\n    expect(tester.takeException(), isNull);\n  });\n\n"
failing_repository = "class _DashboardRepositoryFailing implements DashboardRepository {\n  const _DashboardRepositoryFailing();\n\n  @override\n  Future<DashboardData> obtenerDashboard(DashboardFiltro filtro) {\n    throw Exception(\n      'DatabaseException(SQLITE_ERROR): SELECT ph.evento FROM pedido_historial',\n    );\n  }\n\n  @override\n  Future<void> marcarPedidoCargado({\n    required String pedidoId,\n    required int paquetes,\n    String observacion = '',\n  }) async {}\n}\n\n"

datasource = replace_between(
    datasource,
    "    final actividadRows = await db.rawQuery(",
    "    final faltantesRows = await db.rawQuery(",
    new_activity_query,
    "consulta de actividad reciente",
)

bloc = replace_once(
    bloc,
    "import 'package:flutter_bloc/flutter_bloc.dart';\n",
    "import 'package:flutter/foundation.dart';\n"
    "import 'package:flutter_bloc/flutter_bloc.dart';\n",
    "importar debugPrint",
)
bloc = replace_once(
    bloc,
    old_message_method,
    new_message_method,
    "ocultar detalles técnicos en la interfaz",
)

page = replace_once(
    page,
    old_listener,
    new_listener,
    "evitar el SnackBar rojo durante el error inicial",
)
page = replace_between(
    page,
    "class _ErrorState extends StatelessWidget {",
    "Color _estadoColor(String estado) {",
    new_error_state,
    "estado de error adaptable",
)

shell = replace_once(
    shell,
    "  int _dashboardRevision = 0;\n",
    "  int _dashboardRevision = 0;\n"
    "  final Set<int> _mountedPageIndexes = <int>{0};\n",
    "registrar páginas montadas",
)
shell = replace_once(
    shell,
    "      selectedIndex = index;\n",
    "      selectedIndex = index;\n"
    "      _mountedPageIndexes.add(index);\n",
    "montar la pestaña seleccionada",
)
shell = replace_once(
    shell,
    "      _clientesRevision++;\n"
    "      _clienteInicialId = clienteId;\n"
    "      selectedIndex = 2;\n",
    "      _clientesRevision++;\n"
    "      _clienteInicialId = clienteId;\n"
    "      _mountedPageIndexes.add(2);\n"
    "      selectedIndex = 2;\n",
    "montar Clientes desde acceso contextual",
)
shell = replace_once(
    shell,
    "      _hojasRevision++;\n"
    "      _hojaInicialCodigo = hojaCodigo;\n"
    "      selectedIndex = 5;\n",
    "      _hojasRevision++;\n"
    "      _hojaInicialCodigo = hojaCodigo;\n"
    "      _mountedPageIndexes.add(5);\n"
    "      selectedIndex = 5;\n",
    "montar Hojas desde acceso contextual",
)
shell = replace_once(
    shell,
    "      _pedidosRevision++;\n"
    "      _pedidosInitialTab = tab.clamp(0, 2);\n"
    "      _pedidosHojaCodigo = hojaCodigo;\n"
    "      selectedIndex = 4;\n",
    "      _pedidosRevision++;\n"
    "      _pedidosInitialTab = tab.clamp(0, 2);\n"
    "      _pedidosHojaCodigo = hojaCodigo;\n"
    "      _mountedPageIndexes.add(4);\n"
    "      selectedIndex = 4;\n",
    "montar Pedidos desde acceso contextual",
)
shell = replace_once(
    shell,
    "  Widget build(BuildContext context) {\n"
    "    return Scaffold(\n",
    "  Widget build(BuildContext context) {\n"
    "    final pages = _buildPages();\n"
    "    return Scaffold(\n",
    "preparar páginas del shell",
)
shell = replace_once(
    shell,
    old_stack,
    new_stack,
    "montaje diferido y HeroMode del shell",
)

test_anchor = "  testWidgets('registra una carga desde un pedido completamente preparado', (\n"
if tests.count(test_anchor) != 1:
    fail("No se encontró dónde insertar la prueba del estado de error.")
tests = tests.replace(test_anchor, error_test + test_anchor, 1)

repo_anchor = "class _DashboardRepositoryFake implements DashboardRepository {\n"
if tests.count(repo_anchor) != 1:
    fail("No se encontró dónde insertar el repositorio de error.")
tests = tests.replace(repo_anchor, failing_repository + repo_anchor, 1)

updates = {
    DATASOURCE_PATH: datasource,
    BLOC_PATH: bloc,
    PAGE_PATH: page,
    SHELL_PATH: shell,
    TEST_PATH: tests,
}

backup_dir = ROOT / (
    ".backup_dashboard_operativo_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nDashboard operativo corregido.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/dashboard_page_test.dart")
print("  flutter test test/main_shell_page_test.dart")
print("  flutter analyze")
