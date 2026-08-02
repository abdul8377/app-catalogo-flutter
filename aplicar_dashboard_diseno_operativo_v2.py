from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

DOMAIN = ROOT / "lib/features/dashboard/domain/entities/dashboard_data.dart"
DATASOURCE = ROOT / "lib/features/dashboard/data/datasources/dashboard_local_datasource.dart"
PAGE = ROOT / "lib/features/dashboard/presentation/pages/dashboard_page.dart"
TEST = ROOT / "test/dashboard_page_test.dart"


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


def replace_tail(
    source: str,
    start_marker: str,
    replacement: str,
    label: str,
) -> str:
    if source.count(start_marker) != 1:
        fail(f"No se pudo localizar “{label}”.")
    start = source.index(start_marker)
    return source[:start] + replacement.rstrip() + "\n"


for path in (DOMAIN, DATASOURCE, PAGE, TEST):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

domain = DOMAIN.read_text(encoding="utf-8")
datasource = DATASOURCE.read_text(encoding="utf-8")
page = PAGE.read_text(encoding="utf-8")
tests = TEST.read_text(encoding="utf-8")

if "class _DonutPainter" in page:
    fail("El rediseño estadístico del Dashboard ya parece estar aplicado.")
if "presentacionesRequeridas" in domain:
    fail("El modelo del Dashboard ya parece estar actualizado.")

DATE_PICKER = "  Future<void> _seleccionarPeriodo(\n    BuildContext context,\n    DashboardState state,\n    DashboardPeriodoTipo periodo,\n  ) async {\n    if (periodo != DashboardPeriodoTipo.personalizado) {\n      context.read<DashboardBloc>().add(\n        DashboardPeriodoCambiado(DashboardFiltro(periodo: periodo)),\n      );\n      return;\n    }\n\n    final now = DateTime.now();\n    final initialStart =\n        state.filtro.fechaInicio ?? now.subtract(const Duration(days: 6));\n    final initialEnd = state.filtro.fechaFin ?? now;\n\n    final range = await showDialog<DateTimeRange>(\n      context: context,\n      barrierColor: Colors.black.withValues(alpha: 0.58),\n      builder: (_) => _DashboardRangeDialog(\n        firstDate: DateTime(2020),\n        lastDate: now,\n        initialStart: initialStart.isAfter(now) ? now : initialStart,\n        initialEnd: initialEnd.isAfter(now) ? now : initialEnd,\n      ),\n    );\n\n    if (!context.mounted || range == null) return;\n    context.read<DashboardBloc>().add(\n      DashboardPeriodoCambiado(\n        DashboardFiltro(\n          periodo: periodo,\n          fechaInicio: range.start,\n          fechaFin: range.end,\n        ),\n      ),\n    );\n  }\n}\n\nclass _DashboardRangeDialog extends StatefulWidget {\n  const _DashboardRangeDialog({\n    required this.firstDate,\n    required this.lastDate,\n    required this.initialStart,\n    required this.initialEnd,\n  });\n\n  final DateTime firstDate;\n  final DateTime lastDate;\n  final DateTime initialStart;\n  final DateTime initialEnd;\n\n  @override\n  State<_DashboardRangeDialog> createState() => _DashboardRangeDialogState();\n}\n\nclass _DashboardRangeDialogState extends State<_DashboardRangeDialog> {\n  late DateTime _start;\n  late DateTime _end;\n\n  @override\n  void initState() {\n    super.initState();\n    _start = DateUtils.dateOnly(widget.initialStart);\n    _end = DateUtils.dateOnly(widget.initialEnd);\n    if (_end.isBefore(_start)) _end = _start;\n  }\n\n  void _setQuickRange(int days) {\n    final end = DateUtils.dateOnly(widget.lastDate);\n    final start = end.subtract(Duration(days: days - 1));\n    setState(() {\n      _start = start.isBefore(widget.firstDate) ? widget.firstDate : start;\n      _end = end;\n    });\n  }\n\n  void _setCurrentMonth() {\n    final end = DateUtils.dateOnly(widget.lastDate);\n    setState(() {\n      _start = DateTime(end.year, end.month);\n      _end = end;\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final format = DateFormat('dd/MM/yyyy');\n    final calendarTheme = Theme.of(context).copyWith(\n      colorScheme: Theme.of(context).colorScheme.copyWith(\n        primary: _yellow,\n        onPrimary: Colors.black,\n        secondary: _yellow,\n        onSecondary: Colors.black,\n        surface: Colors.white,\n        onSurface: _ink,\n      ),\n    );\n\n    return Dialog(\n      backgroundColor: Colors.transparent,\n      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),\n      child: ConstrainedBox(\n        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 760),\n        child: Material(\n          color: Colors.white,\n          borderRadius: BorderRadius.circular(24),\n          clipBehavior: Clip.antiAlias,\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              Container(\n                width: double.infinity,\n                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),\n                color: _ink,\n                child: Row(\n                  children: [\n                    Container(\n                      width: 42,\n                      height: 42,\n                      decoration: BoxDecoration(\n                        color: _yellow,\n                        borderRadius: BorderRadius.circular(12),\n                      ),\n                      child: const Icon(\n                        Icons.calendar_month_rounded,\n                        color: _ink,\n                      ),\n                    ),\n                    const SizedBox(width: 12),\n                    Expanded(\n                      child: Column(\n                        crossAxisAlignment: CrossAxisAlignment.start,\n                        children: [\n                          Text(\n                            'Seleccionar periodo',\n                            style: GoogleFonts.inter(\n                              color: Colors.white,\n                              fontSize: 19,\n                              fontWeight: FontWeight.w800,\n                            ),\n                          ),\n                          Text(\n                            'Elige una fecha inicial y una fecha final.',\n                            style: GoogleFonts.inter(\n                              color: const Color(0xFFB7BAC1),\n                              fontSize: 12,\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                    IconButton(\n                      tooltip: 'Cerrar',\n                      onPressed: () => Navigator.pop(context),\n                      icon: const Icon(Icons.close_rounded, color: Colors.white),\n                    ),\n                  ],\n                ),\n              ),\n              Flexible(\n                child: SingleChildScrollView(\n                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.stretch,\n                    children: [\n                      Wrap(\n                        spacing: 8,\n                        runSpacing: 8,\n                        children: [\n                          _RangeQuickButton(\n                            label: 'Últimos 7 días',\n                            onPressed: () => _setQuickRange(7),\n                          ),\n                          _RangeQuickButton(\n                            label: 'Últimos 30 días',\n                            onPressed: () => _setQuickRange(30),\n                          ),\n                          _RangeQuickButton(\n                            label: 'Este mes',\n                            onPressed: _setCurrentMonth,\n                          ),\n                        ],\n                      ),\n                      const SizedBox(height: 16),\n                      LayoutBuilder(\n                        builder: (context, constraints) {\n                          final startCalendar = _CalendarPanel(\n                            title: 'Desde',\n                            value: format.format(_start),\n                            theme: calendarTheme,\n                            child: CalendarDatePicker(\n                              key: ValueKey('dashboard-start-$_start'),\n                              initialDate: _start,\n                              firstDate: widget.firstDate,\n                              lastDate: widget.lastDate,\n                              onDateChanged: (value) {\n                                final date = DateUtils.dateOnly(value);\n                                setState(() {\n                                  _start = date;\n                                  if (_end.isBefore(date)) _end = date;\n                                });\n                              },\n                            ),\n                          );\n                          final endCalendar = _CalendarPanel(\n                            title: 'Hasta',\n                            value: format.format(_end),\n                            theme: calendarTheme,\n                            child: CalendarDatePicker(\n                              key: ValueKey('dashboard-end-$_end'),\n                              initialDate: _end,\n                              firstDate: widget.firstDate,\n                              lastDate: widget.lastDate,\n                              onDateChanged: (value) {\n                                final date = DateUtils.dateOnly(value);\n                                setState(() {\n                                  _end = date;\n                                  if (_start.isAfter(date)) _start = date;\n                                });\n                              },\n                            ),\n                          );\n\n                          if (constraints.maxWidth >= 700) {\n                            return Row(\n                              crossAxisAlignment: CrossAxisAlignment.start,\n                              children: [\n                                Expanded(child: startCalendar),\n                                const SizedBox(width: 14),\n                                Expanded(child: endCalendar),\n                              ],\n                            );\n                          }\n                          return Column(\n                            children: [\n                              startCalendar,\n                              const SizedBox(height: 14),\n                              endCalendar,\n                            ],\n                          );\n                        },\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n              const Divider(height: 1),\n              Padding(\n                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),\n                child: Row(\n                  mainAxisAlignment: MainAxisAlignment.end,\n                  children: [\n                    TextButton(\n                      onPressed: () => Navigator.pop(context),\n                      child: const Text('Cancelar'),\n                    ),\n                    const SizedBox(width: 10),\n                    FilledButton.icon(\n                      onPressed: () => Navigator.pop(\n                        context,\n                        DateTimeRange(start: _start, end: _end),\n                      ),\n                      style: FilledButton.styleFrom(\n                        backgroundColor: _yellow,\n                        foregroundColor: _ink,\n                        minimumSize: const Size(140, 46),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(12),\n                        ),\n                      ),\n                      icon: const Icon(Icons.check_rounded),\n                      label: const Text(\n                        'Aplicar periodo',\n                        style: TextStyle(fontWeight: FontWeight.w700),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n\nclass _CalendarPanel extends StatelessWidget {\n  const _CalendarPanel({\n    required this.title,\n    required this.value,\n    required this.theme,\n    required this.child,\n  });\n\n  final String title;\n  final String value;\n  final ThemeData theme;\n  final Widget child;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    decoration: BoxDecoration(\n      color: const Color(0xFFF8F9FB),\n      borderRadius: BorderRadius.circular(18),\n      border: Border.all(color: const Color(0xFFEAECF0)),\n    ),\n    child: Column(\n      children: [\n        Padding(\n          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),\n          child: Row(\n            children: [\n              Text(\n                title,\n                style: GoogleFonts.inter(\n                  color: _muted,\n                  fontSize: 12,\n                  fontWeight: FontWeight.w700,\n                ),\n              ),\n              const Spacer(),\n              Container(\n                padding: const EdgeInsets.symmetric(\n                  horizontal: 10,\n                  vertical: 5,\n                ),\n                decoration: BoxDecoration(\n                  color: const Color(0xFFFFF4CC),\n                  borderRadius: BorderRadius.circular(999),\n                ),\n                child: Text(\n                  value,\n                  style: GoogleFonts.inter(\n                    color: _ink,\n                    fontSize: 11,\n                    fontWeight: FontWeight.w800,\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ),\n        Theme(data: theme, child: child),\n      ],\n    ),\n  );\n}\n\nclass _RangeQuickButton extends StatelessWidget {\n  const _RangeQuickButton({\n    required this.label,\n    required this.onPressed,\n  });\n\n  final String label;\n  final VoidCallback onPressed;\n\n  @override\n  Widget build(BuildContext context) => OutlinedButton(\n    onPressed: onPressed,\n    style: OutlinedButton.styleFrom(\n      foregroundColor: _ink,\n      side: const BorderSide(color: _yellow),\n      shape: RoundedRectangleBorder(\n        borderRadius: BorderRadius.circular(999),\n      ),\n    ),\n    child: Text(label),\n  );\n}\n"
ORDERS_STATE = "class _PedidosEstadoCard extends StatelessWidget {\n  const _PedidosEstadoCard({\n    required this.total,\n    required this.estados,\n    required this.onViewOrders,\n  });\n\n  final int total;\n  final Map<String, int> estados;\n  final VoidCallback onViewOrders;\n\n  static const _colors = {\n    'Pendiente': Color(0xFFFDB022),\n    'En proceso': Color(0xFF2E90FA),\n    'Listo para entregar': Color(0xFF06AED4),\n    'Entregado': Color(0xFF12B76A),\n    'Cancelado': Color(0xFFF04438),\n  };\n\n  @override\n  Widget build(BuildContext context) {\n    final slices = estados.entries\n        .where((entry) => entry.value > 0)\n        .map(\n          (entry) => _DonutSlice(\n            value: entry.value,\n            color: _colors[entry.key] ?? _muted,\n          ),\n        )\n        .toList();\n\n    final chart = SizedBox.square(\n      dimension: 168,\n      child: CustomPaint(\n        painter: _DonutPainter(slices),\n        child: Center(\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              Text(\n                '$total',\n                style: GoogleFonts.inter(\n                  color: _ink,\n                  fontSize: 29,\n                  fontWeight: FontWeight.w900,\n                ),\n              ),\n              Text(\n                total == 1 ? 'pedido' : 'pedidos',\n                style: GoogleFonts.inter(color: _muted, fontSize: 11),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n\n    final legend = Column(\n      children: estados.entries.map((entry) {\n        final percentage = total == 0 ? 0 : (entry.value / total * 100).round();\n        final color = _colors[entry.key] ?? _muted;\n        return Padding(\n          padding: const EdgeInsets.only(bottom: 9),\n          child: Row(\n            children: [\n              Container(\n                width: 10,\n                height: 10,\n                decoration: BoxDecoration(\n                  color: color,\n                  shape: BoxShape.circle,\n                ),\n              ),\n              const SizedBox(width: 8),\n              Expanded(\n                child: Text(\n                  entry.key,\n                  style: GoogleFonts.inter(\n                    fontSize: 12,\n                    fontWeight: FontWeight.w600,\n                  ),\n                ),\n              ),\n              Text(\n                '${entry.value}',\n                style: GoogleFonts.inter(\n                  color: _ink,\n                  fontSize: 13,\n                  fontWeight: FontWeight.w900,\n                ),\n              ),\n              const SizedBox(width: 7),\n              SizedBox(\n                width: 34,\n                child: Text(\n                  '$percentage%',\n                  textAlign: TextAlign.end,\n                  style: GoogleFonts.inter(color: _muted, fontSize: 10),\n                ),\n              ),\n            ],\n          ),\n        );\n      }).toList(),\n    );\n\n    return _Panel(\n      child: Column(\n        children: [\n          _SectionTitle(\n            title: 'Pedidos por estado',\n            subtitle: 'Distribución del periodo seleccionado',\n            action: onViewOrders,\n            actionLabel: 'Ver pedidos',\n          ),\n          const SizedBox(height: 16),\n          LayoutBuilder(\n            builder: (context, constraints) {\n              if (constraints.maxWidth >= 520) {\n                return Row(\n                  children: [\n                    chart,\n                    const SizedBox(width: 22),\n                    Expanded(child: legend),\n                  ],\n                );\n              }\n              return Column(\n                children: [\n                  chart,\n                  const SizedBox(height: 18),\n                  legend,\n                ],\n              );\n            },\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _DonutSlice {\n  const _DonutSlice({required this.value, required this.color});\n\n  final int value;\n  final Color color;\n}\n\nclass _DonutPainter extends CustomPainter {\n  const _DonutPainter(this.slices);\n\n  final List<_DonutSlice> slices;\n\n  @override\n  void paint(Canvas canvas, Size size) {\n    final strokeWidth = size.shortestSide * 0.12;\n    final rect = Offset.zero & size;\n    final arcRect = rect.deflate(strokeWidth / 2);\n    final background = Paint()\n      ..color = const Color(0xFFF0F1F3)\n      ..style = PaintingStyle.stroke\n      ..strokeWidth = strokeWidth;\n    canvas.drawArc(arcRect, 0, math.pi * 2, false, background);\n\n    final total = slices.fold<int>(0, (sum, item) => sum + item.value);\n    if (total <= 0) return;\n\n    var start = -math.pi / 2;\n    const gap = 0.035;\n    for (final slice in slices) {\n      final sweep = math.pi * 2 * slice.value / total;\n      final paint = Paint()\n        ..color = slice.color\n        ..style = PaintingStyle.stroke\n        ..strokeCap = StrokeCap.round\n        ..strokeWidth = strokeWidth;\n      final drawableSweep = (sweep - gap).clamp(0.0, math.pi * 2);\n      canvas.drawArc(arcRect, start, drawableSweep, false, paint);\n      start += sweep;\n    }\n  }\n\n  @override\n  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;\n}\n"
PROGRESS = "class _ProgresoOperativoCard extends StatelessWidget {\n  const _ProgresoOperativoCard({required this.data});\n\n  final DashboardData data;\n\n  @override\n  Widget build(BuildContext context) {\n    final total = data.totalPedidos;\n    final valorizados =\n        (total - data.pedidosPendientesValorizar).clamp(0, total);\n    final valorizacion = total == 0 ? 0.0 : valorizados / total;\n    final preparacion = data.progresoPreparacion;\n\n    return _Panel(\n      child: Column(\n        children: [\n          const _SectionTitle(\n            title: 'Progreso operativo',\n            subtitle: 'Lectura rápida del avance comercial y físico',\n          ),\n          const SizedBox(height: 18),\n          Wrap(\n            alignment: WrapAlignment.center,\n            spacing: 18,\n            runSpacing: 18,\n            children: [\n              _RadialMetric(\n                label: 'Valorizados',\n                detail: '$valorizados de $total pedidos',\n                progress: valorizacion,\n                color: const Color(0xFF2E90FA),\n                icon: Icons.price_check_rounded,\n              ),\n              _RadialMetric(\n                label: 'Preparación',\n                detail:\n                    '${data.presentacionesPreparadas} de '\n                    '${data.presentacionesRequeridas} presentaciones',\n                progress: preparacion,\n                color: const Color(0xFFF79009),\n                icon: Icons.inventory_2_outlined,\n              ),\n            ],\n          ),\n          const Divider(height: 30),\n          Wrap(\n            alignment: WrapAlignment.center,\n            spacing: 10,\n            runSpacing: 10,\n            children: [\n              _StageMetric(\n                value: data.pedidosListosCargar,\n                label: 'Listos para carga',\n                icon: Icons.inventory_outlined,\n                color: const Color(0xFF087E8B),\n              ),\n              _StageMetric(\n                value: data.pedidosCargados,\n                label: 'Cargados',\n                icon: Icons.local_shipping_outlined,\n                color: const Color(0xFF175CD3),\n              ),\n              _StageMetric(\n                value: data.pedidosEntregados,\n                label: 'Entregados',\n                icon: Icons.task_alt_rounded,\n                color: const Color(0xFF067647),\n              ),\n            ],\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _RadialMetric extends StatelessWidget {\n  const _RadialMetric({\n    required this.label,\n    required this.detail,\n    required this.progress,\n    required this.color,\n    required this.icon,\n  });\n\n  final String label;\n  final String detail;\n  final double progress;\n  final Color color;\n  final IconData icon;\n\n  @override\n  Widget build(BuildContext context) {\n    final normalized = progress.clamp(0.0, 1.0);\n    return SizedBox(\n      width: 170,\n      child: Column(\n        children: [\n          SizedBox.square(\n            dimension: 116,\n            child: Stack(\n              alignment: Alignment.center,\n              children: [\n                SizedBox.square(\n                  dimension: 104,\n                  child: CircularProgressIndicator(\n                    value: normalized,\n                    strokeWidth: 10,\n                    strokeCap: StrokeCap.round,\n                    color: color,\n                    backgroundColor: const Color(0xFFF0F1F3),\n                  ),\n                ),\n                Column(\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    Icon(icon, color: color, size: 20),\n                    const SizedBox(height: 3),\n                    Text(\n                      '${(normalized * 100).round()}%',\n                      style: GoogleFonts.inter(\n                        color: _ink,\n                        fontSize: 20,\n                        fontWeight: FontWeight.w900,\n                      ),\n                    ),\n                  ],\n                ),\n              ],\n            ),\n          ),\n          const SizedBox(height: 8),\n          Text(\n            label,\n            style: GoogleFonts.inter(\n              color: _ink,\n              fontSize: 12,\n              fontWeight: FontWeight.w800,\n            ),\n          ),\n          const SizedBox(height: 2),\n          Text(\n            detail,\n            maxLines: 2,\n            overflow: TextOverflow.ellipsis,\n            textAlign: TextAlign.center,\n            style: GoogleFonts.inter(\n              color: _muted,\n              fontSize: 10,\n              height: 1.3,\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _StageMetric extends StatelessWidget {\n  const _StageMetric({\n    required this.value,\n    required this.label,\n    required this.icon,\n    required this.color,\n  });\n\n  final int value;\n  final String label;\n  final IconData icon;\n  final Color color;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    width: 142,\n    padding: const EdgeInsets.all(12),\n    decoration: BoxDecoration(\n      color: color.withValues(alpha: 0.08),\n      borderRadius: BorderRadius.circular(14),\n      border: Border.all(color: color.withValues(alpha: 0.18)),\n    ),\n    child: Row(\n      children: [\n        Container(\n          width: 34,\n          height: 34,\n          decoration: BoxDecoration(\n            color: Colors.white,\n            borderRadius: BorderRadius.circular(10),\n          ),\n          child: Icon(icon, color: color, size: 18),\n        ),\n        const SizedBox(width: 9),\n        Expanded(\n          child: Column(\n            crossAxisAlignment: CrossAxisAlignment.start,\n            children: [\n              Text(\n                '$value',\n                style: GoogleFonts.inter(\n                  color: color,\n                  fontSize: 18,\n                  fontWeight: FontWeight.w900,\n                ),\n              ),\n              Text(\n                label,\n                maxLines: 2,\n                overflow: TextOverflow.ellipsis,\n                style: GoogleFonts.inter(\n                  color: _ink,\n                  fontSize: 9,\n                  fontWeight: FontWeight.w700,\n                ),\n              ),\n            ],\n          ),\n        ),\n      ],\n    ),\n  );\n}\n"
PRODUCTS_TOP = "class _ProductosTopCard extends StatelessWidget {\n  const _ProductosTopCard({required this.items, required this.onView});\n\n  final List<DashboardProductoTop> items;\n  final VoidCallback onView;\n\n  @override\n  Widget build(BuildContext context) => _Panel(\n    child: Column(\n      children: [\n        _SectionTitle(\n          title: 'Productos más solicitados',\n          subtitle: 'Agrupados por la presentación realmente pedida',\n          action: onView,\n          actionLabel: 'Consolidado',\n        ),\n        const SizedBox(height: 12),\n        if (items.isEmpty)\n          const _EmptyLine(\n            icon: Icons.inventory_2_outlined,\n            message: 'No hay productos en este periodo.',\n          )\n        else\n          ...items.asMap().entries.map((entry) {\n            final item = entry.value;\n            return Container(\n              margin: const EdgeInsets.only(bottom: 10),\n              padding: const EdgeInsets.all(11),\n              decoration: BoxDecoration(\n                color: const Color(0xFFF8F9FB),\n                borderRadius: BorderRadius.circular(14),\n                border: Border.all(color: const Color(0xFFEAECF0)),\n              ),\n              child: Row(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  Container(\n                    width: 32,\n                    height: 32,\n                    alignment: Alignment.center,\n                    decoration: BoxDecoration(\n                      color: entry.key == 0\n                          ? const Color(0xFFFFF3C4)\n                          : Colors.white,\n                      borderRadius: BorderRadius.circular(10),\n                    ),\n                    child: Text(\n                      '${entry.key + 1}',\n                      style: GoogleFonts.inter(\n                        color: _ink,\n                        fontWeight: FontWeight.w900,\n                      ),\n                    ),\n                  ),\n                  const SizedBox(width: 10),\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(\n                          item.nombre,\n                          maxLines: 2,\n                          overflow: TextOverflow.ellipsis,\n                          style: GoogleFonts.inter(\n                            color: _ink,\n                            fontSize: 12,\n                            fontWeight: FontWeight.w800,\n                          ),\n                        ),\n                        const SizedBox(height: 2),\n                        Text(\n                          '${item.codigo} • ${item.marca} • '\n                          '${item.pedidos} pedidos',\n                          style: GoogleFonts.inter(\n                            color: _muted,\n                            fontSize: 10,\n                          ),\n                        ),\n                        const SizedBox(height: 8),\n                        Wrap(\n                          spacing: 6,\n                          runSpacing: 6,\n                          children: [\n                            _QuantityTag(\n                              label:\n                                  '${item.cantidadRequerida} × '\n                                  '${item.presentacion}',\n                              color: const Color(0xFF175CD3),\n                            ),\n                            _QuantityTag(\n                              label: '${item.cantidadPreparada} preparadas',\n                              color: const Color(0xFF067647),\n                            ),\n                            if (item.cantidadPendiente > 0)\n                              _QuantityTag(\n                                label: '${item.cantidadPendiente} pendientes',\n                                color: const Color(0xFFB54708),\n                              ),\n                          ],\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            );\n          }),\n      ],\n    ),\n  );\n}\n\nclass _QuantityTag extends StatelessWidget {\n  const _QuantityTag({required this.label, required this.color});\n\n  final String label;\n  final Color color;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),\n    decoration: BoxDecoration(\n      color: color.withValues(alpha: 0.09),\n      borderRadius: BorderRadius.circular(999),\n    ),\n    child: Text(\n      label,\n      style: GoogleFonts.inter(\n        color: color,\n        fontSize: 9,\n        fontWeight: FontWeight.w800,\n      ),\n    ),\n  );\n}\n"
MISSING = "class _FaltantesCard extends StatelessWidget {\n  const _FaltantesCard({required this.data, required this.onView});\n\n  final DashboardData data;\n  final VoidCallback onView;\n\n  @override\n  Widget build(BuildContext context) => _Panel(\n    child: Column(\n      children: [\n        _SectionTitle(\n          title: 'Pendientes de preparación',\n          subtitle:\n              '${data.presentacionesPendientes} presentaciones por preparar',\n          action: onView,\n          actionLabel: 'Ver consolidado',\n        ),\n        const SizedBox(height: 10),\n        if (data.principalesFaltantes.isEmpty)\n          const _AllGood()\n        else ...[\n          Row(\n            children: [\n              _SummaryBox(\n                '${data.productosPendientesPreparacion}',\n                'Productos',\n                const Color(0xFFB54708),\n              ),\n              const SizedBox(width: 8),\n              _SummaryBox(\n                '${data.pedidosPreparacionParcial}',\n                'Pedidos parciales',\n                const Color(0xFF175CD3),\n              ),\n            ],\n          ),\n          const SizedBox(height: 10),\n          ...data.principalesFaltantes.map(\n            (item) => Container(\n              margin: const EdgeInsets.only(bottom: 8),\n              padding: const EdgeInsets.all(10),\n              decoration: BoxDecoration(\n                color: const Color(0xFFFFFAEB),\n                borderRadius: BorderRadius.circular(12),\n                border: Border.all(color: const Color(0xFFFED7AA)),\n              ),\n              child: Row(\n                children: [\n                  const Icon(\n                    Icons.inventory_2_outlined,\n                    color: Color(0xFFB54708),\n                    size: 19,\n                  ),\n                  const SizedBox(width: 9),\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(\n                          item.nombre,\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,\n                          style: GoogleFonts.inter(\n                            fontSize: 11,\n                            fontWeight: FontWeight.w800,\n                          ),\n                        ),\n                        Text(\n                          '${item.codigo} • ${item.pedidosAfectados} pedidos',\n                          style: GoogleFonts.inter(\n                            color: _muted,\n                            fontSize: 9,\n                          ),\n                        ),\n                      ],\n                    ),\n                  ),\n                  const SizedBox(width: 8),\n                  Container(\n                    padding: const EdgeInsets.symmetric(\n                      horizontal: 9,\n                      vertical: 6,\n                    ),\n                    decoration: BoxDecoration(\n                      color: const Color(0xFFFFEAD5),\n                      borderRadius: BorderRadius.circular(999),\n                    ),\n                    child: Text(\n                      '${item.cantidadPendiente} × ${item.presentacion}',\n                      style: GoogleFonts.inter(\n                        color: const Color(0xFFB42318),\n                        fontSize: 10,\n                        fontWeight: FontWeight.w900,\n                      ),\n                    ),\n                  ),\n                ],\n              ),\n            ),\n          ),\n        ],\n      ],\n    ),\n  );\n}\n"
SYNC_UI = "class _SyncCard extends StatelessWidget {\n  const _SyncCard({\n    required this.sync,\n    required this.updatedAt,\n    required this.onRefresh,\n    required this.onViewPending,\n  });\n\n  final DashboardSincronizacion sync;\n  final DateTime updatedAt;\n  final VoidCallback onRefresh;\n  final VoidCallback onViewPending;\n\n  @override\n  Widget build(BuildContext context) => _Panel(\n    child: Column(\n      crossAxisAlignment: CrossAxisAlignment.stretch,\n      children: [\n        LayoutBuilder(\n          builder: (context, constraints) {\n            final status = Row(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Container(\n                  width: 48,\n                  height: 48,\n                  decoration: BoxDecoration(\n                    color:\n                        (sync.sincronizado\n                                ? const Color(0xFF067647)\n                                : const Color(0xFFB54708))\n                            .withValues(alpha: 0.1),\n                    borderRadius: BorderRadius.circular(14),\n                  ),\n                  child: Icon(\n                    sync.sincronizado\n                        ? Icons.cloud_done_outlined\n                        : Icons.cloud_queue_outlined,\n                    color: sync.sincronizado\n                        ? const Color(0xFF067647)\n                        : const Color(0xFFB54708),\n                  ),\n                ),\n                const SizedBox(width: 12),\n                Expanded(\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.start,\n                    children: [\n                      Text(\n                        'Sincronización offline',\n                        style: GoogleFonts.inter(\n                          color: _ink,\n                          fontSize: 15,\n                          fontWeight: FontWeight.w900,\n                        ),\n                      ),\n                      const SizedBox(height: 3),\n                      Text(\n                        sync.sincronizado\n                            ? 'La información local está al día.'\n                            : 'Los cambios permanecen protegidos en la tablet '\n                                  'hasta recuperar conexión.',\n                        style: GoogleFonts.inter(\n                          color: _muted,\n                          fontSize: 11,\n                          height: 1.4,\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              ],\n            );\n\n            final actions = Wrap(\n              spacing: 8,\n              runSpacing: 8,\n              alignment: WrapAlignment.end,\n              children: [\n                OutlinedButton.icon(\n                  key: const ValueKey('dashboard-sync-pending'),\n                  onPressed: onViewPending,\n                  style: OutlinedButton.styleFrom(\n                    foregroundColor: _ink,\n                    side: const BorderSide(color: _yellow),\n                  ),\n                  icon: const Icon(Icons.list_alt_rounded, size: 18),\n                  label: const Text('Ver pendientes'),\n                ),\n                FilledButton.icon(\n                  onPressed: onRefresh,\n                  style: FilledButton.styleFrom(\n                    backgroundColor: _yellow,\n                    foregroundColor: _ink,\n                  ),\n                  icon: const Icon(Icons.refresh_rounded, size: 18),\n                  label: const Text('Actualizar estado'),\n                ),\n              ],\n            );\n\n            if (constraints.maxWidth >= 720) {\n              return Row(\n                children: [\n                  Expanded(child: status),\n                  const SizedBox(width: 16),\n                  actions,\n                ],\n              );\n            }\n            return Column(\n              crossAxisAlignment: CrossAxisAlignment.stretch,\n              children: [\n                status,\n                const SizedBox(height: 14),\n                actions,\n              ],\n            );\n          },\n        ),\n        const SizedBox(height: 14),\n        Wrap(\n          spacing: 9,\n          runSpacing: 9,\n          children: [\n            _SyncMetric(\n              value: sync.pedidosPendientes,\n              label: 'Pedidos',\n              icon: Icons.receipt_long_outlined,\n              color: const Color(0xFF175CD3),\n            ),\n            _SyncMetric(\n              value: sync.hojasPendientes,\n              label: 'Hojas',\n              icon: Icons.description_outlined,\n              color: const Color(0xFF6941C6),\n            ),\n            _SyncMetric(\n              value: sync.operacionesEnCola,\n              label: 'Operaciones',\n              icon: Icons.sync_alt_rounded,\n              color: const Color(0xFFB54708),\n            ),\n            if (sync.errores > 0)\n              _SyncMetric(\n                value: sync.errores,\n                label: 'Con error',\n                icon: Icons.error_outline_rounded,\n                color: const Color(0xFFB42318),\n              ),\n          ],\n        ),\n      ],\n    ),\n  );\n}\n\nclass _SyncMetric extends StatelessWidget {\n  const _SyncMetric({\n    required this.value,\n    required this.label,\n    required this.icon,\n    required this.color,\n  });\n\n  final int value;\n  final String label;\n  final IconData icon;\n  final Color color;\n\n  @override\n  Widget build(BuildContext context) => Container(\n    width: 145,\n    padding: const EdgeInsets.all(10),\n    decoration: BoxDecoration(\n      color: color.withValues(alpha: 0.07),\n      borderRadius: BorderRadius.circular(13),\n    ),\n    child: Row(\n      children: [\n        Icon(icon, color: color, size: 19),\n        const SizedBox(width: 8),\n        Text(\n          '$value',\n          style: GoogleFonts.inter(\n            color: color,\n            fontSize: 17,\n            fontWeight: FontWeight.w900,\n          ),\n        ),\n        const SizedBox(width: 6),\n        Expanded(\n          child: Text(\n            label,\n            maxLines: 1,\n            overflow: TextOverflow.ellipsis,\n            style: GoogleFonts.inter(\n              color: _ink,\n              fontSize: 10,\n              fontWeight: FontWeight.w700,\n            ),\n          ),\n        ),\n      ],\n    ),\n  );\n}\n\nclass _SyncPendingDialog extends StatelessWidget {\n  const _SyncPendingDialog({required this.sync});\n\n  final DashboardSincronizacion sync;\n\n  @override\n  Widget build(BuildContext context) => Dialog(\n    backgroundColor: Colors.transparent,\n    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),\n    child: ConstrainedBox(\n      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),\n      child: Material(\n        color: Colors.white,\n        borderRadius: BorderRadius.circular(24),\n        clipBehavior: Clip.antiAlias,\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n            Container(\n              width: double.infinity,\n              padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),\n              color: _ink,\n              child: Row(\n                children: [\n                  Container(\n                    width: 42,\n                    height: 42,\n                    decoration: BoxDecoration(\n                      color: _yellow,\n                      borderRadius: BorderRadius.circular(12),\n                    ),\n                    child: const Icon(Icons.cloud_queue_outlined, color: _ink),\n                  ),\n                  const SizedBox(width: 12),\n                  Expanded(\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Text(\n                          'Pendientes de sincronización',\n                          style: GoogleFonts.inter(\n                            color: Colors.white,\n                            fontSize: 18,\n                            fontWeight: FontWeight.w900,\n                          ),\n                        ),\n                        Text(\n                          '${sync.totalPendiente} cambios protegidos localmente',\n                          style: GoogleFonts.inter(\n                            color: const Color(0xFFB7BAC1),\n                            fontSize: 11,\n                          ),\n                        ),\n                      ],\n                    ),\n                  ),\n                  IconButton(\n                    tooltip: 'Cerrar',\n                    onPressed: () => Navigator.pop(context),\n                    icon: const Icon(Icons.close_rounded, color: Colors.white),\n                  ),\n                ],\n              ),\n            ),\n            Padding(\n              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),\n              child: Wrap(\n                spacing: 8,\n                runSpacing: 8,\n                children: [\n                  _StatusPill(\n                    label: '${sync.pedidosPendientes} pedidos',\n                    color: const Color(0xFF175CD3),\n                  ),\n                  _StatusPill(\n                    label: '${sync.hojasPendientes} hojas',\n                    color: const Color(0xFF6941C6),\n                  ),\n                  _StatusPill(\n                    label: '${sync.operacionesEnCola} operaciones',\n                    color: const Color(0xFFB54708),\n                  ),\n                  if (sync.errores > 0)\n                    _StatusPill(\n                      label: '${sync.errores} errores',\n                      color: const Color(0xFFB42318),\n                    ),\n                ],\n              ),\n            ),\n            Flexible(\n              child: sync.pendientes.isEmpty\n                  ? const _EmptyLine(\n                      icon: Icons.cloud_done_outlined,\n                      message: 'No hay detalles pendientes para mostrar.',\n                    )\n                  : ListView.separated(\n                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),\n                      itemCount: sync.pendientes.length,\n                      separatorBuilder: (_, _) => const SizedBox(height: 8),\n                      itemBuilder: (context, index) => _SyncPendingTile(\n                        item: sync.pendientes[index],\n                      ),\n                    ),\n            ),\n            const Divider(height: 1),\n            Padding(\n              padding: const EdgeInsets.all(16),\n              child: Row(\n                children: [\n                  Expanded(\n                    child: Text(\n                      'La app puede continuar trabajando sin conexión.',\n                      style: GoogleFonts.inter(\n                        color: _muted,\n                        fontSize: 11,\n                      ),\n                    ),\n                  ),\n                  FilledButton(\n                    onPressed: () => Navigator.pop(context),\n                    style: FilledButton.styleFrom(\n                      backgroundColor: _yellow,\n                      foregroundColor: _ink,\n                    ),\n                    child: const Text('Entendido'),\n                  ),\n                ],\n              ),\n            ),\n          ],\n        ),\n      ),\n    ),\n  );\n}\n\nclass _SyncPendingTile extends StatelessWidget {\n  const _SyncPendingTile({required this.item});\n\n  final DashboardSyncPendiente item;\n\n  @override\n  Widget build(BuildContext context) {\n    final color = item.estado.toLowerCase() == 'error'\n        ? const Color(0xFFB42318)\n        : const Color(0xFFB54708);\n    final icon = switch (item.tipo) {\n      'pedido' => Icons.receipt_long_outlined,\n      'hoja' => Icons.description_outlined,\n      _ => Icons.sync_alt_rounded,\n    };\n\n    return Container(\n      padding: const EdgeInsets.all(12),\n      decoration: BoxDecoration(\n        color: const Color(0xFFF8F9FB),\n        borderRadius: BorderRadius.circular(14),\n        border: Border.all(color: const Color(0xFFEAECF0)),\n      ),\n      child: Row(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Container(\n            width: 36,\n            height: 36,\n            decoration: BoxDecoration(\n              color: color.withValues(alpha: 0.09),\n              borderRadius: BorderRadius.circular(10),\n            ),\n            child: Icon(icon, color: color, size: 19),\n          ),\n          const SizedBox(width: 10),\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Text(\n                  item.titulo,\n                  style: GoogleFonts.inter(\n                    color: _ink,\n                    fontSize: 12,\n                    fontWeight: FontWeight.w800,\n                  ),\n                ),\n                const SizedBox(height: 2),\n                Text(\n                  item.detalle,\n                  maxLines: 2,\n                  overflow: TextOverflow.ellipsis,\n                  style: GoogleFonts.inter(\n                    color: _muted,\n                    fontSize: 10,\n                    height: 1.3,\n                  ),\n                ),\n                if (item.error.trim().isNotEmpty) ...[\n                  const SizedBox(height: 4),\n                  Text(\n                    item.error,\n                    maxLines: 2,\n                    overflow: TextOverflow.ellipsis,\n                    style: GoogleFonts.inter(\n                      color: const Color(0xFFB42318),\n                      fontSize: 10,\n                      fontWeight: FontWeight.w700,\n                    ),\n                  ),\n                ],\n              ],\n            ),\n          ),\n          const SizedBox(width: 8),\n          Text(\n            DateFormat('dd/MM HH:mm').format(item.fecha),\n            style: GoogleFonts.inter(color: _muted, fontSize: 9),\n          ),\n        ],\n      ),\n    );\n  }\n}\n"
SYNC_DOMAIN = "class DashboardSyncPendiente extends Equatable {\n  const DashboardSyncPendiente({\n    required this.id,\n    required this.tipo,\n    required this.titulo,\n    required this.detalle,\n    required this.estado,\n    required this.fecha,\n    this.error = '',\n  });\n\n  final String id;\n  final String tipo;\n  final String titulo;\n  final String detalle;\n  final String estado;\n  final DateTime fecha;\n  final String error;\n\n  @override\n  List<Object?> get props => [\n    id,\n    tipo,\n    titulo,\n    detalle,\n    estado,\n    fecha,\n    error,\n  ];\n}\n\nclass DashboardSincronizacion extends Equatable {\n  const DashboardSincronizacion({\n    this.pedidosPendientes = 0,\n    this.hojasPendientes = 0,\n    this.operacionesEnCola = 0,\n    this.errores = 0,\n    this.ultimaSincronizacion,\n    this.pendientes = const [],\n  });\n\n  final int pedidosPendientes;\n  final int hojasPendientes;\n  final int operacionesEnCola;\n  final int errores;\n  final DateTime? ultimaSincronizacion;\n  final List<DashboardSyncPendiente> pendientes;\n\n  int get totalPendiente =>\n      pedidosPendientes + hojasPendientes + operacionesEnCola;\n\n  bool get sincronizado => totalPendiente == 0 && errores == 0;\n\n  @override\n  List<Object?> get props => [\n    pedidosPendientes,\n    hojasPendientes,\n    operacionesEnCola,\n    errores,\n    ultimaSincronizacion,\n    pendientes,\n  ];\n}\n"
PREPARATION_QUERY = "    final preparacion = (await db.rawQuery('''\n      SELECT COALESCE(SUM(i.cantidad), 0) AS requerida,\n             COALESCE(SUM(\n               MIN(\n                 i.cantidad,\n                 COALESCE(prep.preparada, 0)\n               )\n             ), 0) AS preparada\n      FROM pedido_items i\n      INNER JOIN pedidos p ON p.id = i.pedido_id\n      LEFT JOIN (\n        SELECT pedido_item_id, SUM(cantidad) AS preparada\n        FROM preparacion_productos\n        GROUP BY pedido_item_id\n      ) prep ON prep.pedido_item_id = i.id\n      WHERE ${scope.where}\n        AND LOWER(p.estado) <> 'cancelado'\n    ''', scope.args)).first;\n"
PARTIAL_QUERY = "    final parcial =\n        Sqflite.firstIntValue(\n          await db.rawQuery('''\n            SELECT COUNT(*)\n            FROM (\n              SELECT p.id,\n                     SUM(i.cantidad) AS requerida,\n                     SUM(\n                       MIN(\n                         i.cantidad,\n                         COALESCE(prep.preparada, 0)\n                       )\n                     ) AS preparada\n              FROM pedidos p\n              INNER JOIN pedido_items i ON i.pedido_id = p.id\n              LEFT JOIN (\n                SELECT pedido_item_id, SUM(cantidad) AS preparada\n                FROM preparacion_productos\n                GROUP BY pedido_item_id\n              ) prep ON prep.pedido_item_id = i.id\n              WHERE ${scope.where}\n                AND LOWER(p.estado) <> 'cancelado'\n              GROUP BY p.id\n              HAVING preparada > 0 AND preparada < requerida\n            )\n          ''', scope.args),\n        ) ??\n        0;\n"
PRODUCTS_QUERY = "    final productosTopRows = await db.rawQuery('''\n      SELECT i.producto_id,\n             i.codigo,\n             i.nombre,\n             COALESCE(pr.marca, '') AS marca,\n             i.presentacion,\n             SUM(i.cantidad) AS requerida,\n             SUM(\n               MIN(\n                 i.cantidad,\n                 COALESCE(prep.preparada, 0)\n               )\n             ) AS preparada,\n             COUNT(DISTINCT p.id) AS pedidos\n      FROM pedido_items i\n      INNER JOIN pedidos p ON p.id = i.pedido_id\n      LEFT JOIN productos pr ON pr.id = i.producto_id\n      LEFT JOIN (\n        SELECT pedido_item_id, SUM(cantidad) AS preparada\n        FROM preparacion_productos\n        GROUP BY pedido_item_id\n      ) prep ON prep.pedido_item_id = i.id\n      WHERE ${scope.where}\n        AND LOWER(p.estado) <> 'cancelado'\n      GROUP BY\n        i.producto_id,\n        i.codigo,\n        i.nombre,\n        pr.marca,\n        i.presentacion\n      ORDER BY requerida DESC, pedidos DESC, i.nombre COLLATE NOCASE\n      LIMIT 5\n    ''', scope.args);\n"
MISSING_QUERY = "    final faltantesRows = await db.rawQuery('''\n      SELECT i.producto_id,\n             i.codigo,\n             i.nombre,\n             i.presentacion,\n             SUM(\n               MAX(\n                 i.cantidad - COALESCE(prep.preparada, 0),\n                 0\n               )\n             ) AS pendiente,\n             COUNT(DISTINCT CASE\n               WHEN COALESCE(prep.preparada, 0) < i.cantidad\n               THEN p.id\n             END) AS pedidos_afectados\n      FROM pedido_items i\n      INNER JOIN pedidos p ON p.id = i.pedido_id\n      LEFT JOIN (\n        SELECT pedido_item_id, SUM(cantidad) AS preparada\n        FROM preparacion_productos\n        GROUP BY pedido_item_id\n      ) prep ON prep.pedido_item_id = i.id\n      WHERE ${scope.where}\n        AND LOWER(p.estado) <> 'cancelado'\n      GROUP BY\n        i.producto_id,\n        i.codigo,\n        i.nombre,\n        i.presentacion\n      HAVING pendiente > 0\n      ORDER BY pendiente DESC, pedidos_afectados DESC\n      LIMIT 5\n    ''', scope.args);\n"
READY_QUERY = "    final listosRows = await db.rawQuery('''\n      SELECT p.id,\n             p.codigo,\n             c.nombre AS cliente_nombre,\n             c.direccion,\n             COUNT(i.id) AS productos\n      FROM pedidos p\n      INNER JOIN hojas_pedido h ON h.id = p.hoja_id\n      INNER JOIN clientes c ON c.id = p.cliente_id\n      INNER JOIN pedido_items i ON i.pedido_id = p.id\n      LEFT JOIN (\n        SELECT pedido_item_id, SUM(cantidad) AS preparada\n        FROM preparacion_productos\n        GROUP BY pedido_item_id\n      ) prep ON prep.pedido_item_id = i.id\n      LEFT JOIN pedido_cargas pc ON pc.pedido_id = p.id\n      WHERE ${scope.where}\n        AND h.activa = 1\n        AND LOWER(h.estado) = 'abierta'\n        AND LOWER(p.estado) NOT IN (\n          'cancelado',\n          'entregado',\n          'listo para entregar'\n        )\n        AND pc.id IS NULL\n      GROUP BY p.id\n      HAVING SUM(\n        CASE\n          WHEN COALESCE(prep.preparada, 0) < i.cantidad\n          THEN 1 ELSE 0\n        END\n      ) = 0\n      ORDER BY p.creado_en ASC\n      LIMIT 5\n    ''', scope.args);\n"
SYNC_QUERIES = "    final syncPendientesRows = await db.rawQuery('''\n      SELECT pendiente.id,\n             pendiente.tipo,\n             pendiente.titulo,\n             pendiente.detalle,\n             pendiente.estado,\n             pendiente.error,\n             pendiente.fecha\n      FROM (\n        SELECT p.id AS id,\n               'pedido' AS tipo,\n               p.codigo AS titulo,\n               'Pedido ' || p.estado AS detalle,\n               CASE\n                 WHEN COALESCE(p.sync_error, '') = '' THEN 'pendiente'\n                 ELSE 'error'\n               END AS estado,\n               COALESCE(p.sync_error, '') AS error,\n               p.creado_en AS fecha\n        FROM pedidos p\n        WHERE p.sincronizado = 0\n        UNION ALL\n        SELECT h.id AS id,\n               'hoja' AS tipo,\n               h.codigo AS titulo,\n               'Hoja ' || h.estado AS detalle,\n               'pendiente' AS estado,\n               '' AS error,\n               h.creado_en AS fecha\n        FROM hojas_pedido h\n        WHERE h.sincronizado = 0\n        UNION ALL\n        SELECT sq.id AS id,\n               'operacion' AS tipo,\n               sq.entidad || ' · ' || sq.accion AS titulo,\n               'Operación guardada en la cola local' AS detalle,\n               sq.estado AS estado,\n               COALESCE(sq.error, '') AS error,\n               sq.actualizado_en AS fecha\n        FROM sync_queue sq\n        WHERE sq.estado IN ('pendiente', 'error')\n      ) AS pendiente\n      ORDER BY pendiente.fecha DESC\n      LIMIT 40\n    ''');\n\n    final syncRow = (await db.rawQuery('''\n      SELECT\n        (\n          SELECT COUNT(*)\n          FROM pedidos\n          WHERE sincronizado = 0\n        ) AS pedidos_pendientes,\n        (\n          SELECT COUNT(*)\n          FROM hojas_pedido\n          WHERE sincronizado = 0\n        ) AS hojas_pendientes,\n        (\n          SELECT COUNT(*)\n          FROM sync_queue\n          WHERE estado = 'pendiente'\n        ) AS cola_pendiente,\n        (\n          SELECT COUNT(*)\n          FROM sync_queue\n          WHERE estado = 'error'\n        ) AS errores,\n        (\n          SELECT MAX(creado_en)\n          FROM pedido_historial\n          WHERE LOWER(evento) LIKE '%sincronizaci%'\n        ) AS ultima_sincronizacion\n    ''')).first;\n"
TEST_BLOCK = "  testWidgets('abre el periodo personalizado y los pendientes offline', (\n    tester,\n  ) async {\n    tester.view.physicalSize = const Size(800, 1180);\n    tester.view.devicePixelRatio = 1;\n    addTearDown(tester.view.resetPhysicalSize);\n    addTearDown(tester.view.resetDevicePixelRatio);\n\n    final repository = _DashboardRepositoryFake(_dashboardData());\n    await tester.pumpWidget(\n      _TestApp(repository: repository, child: const DashboardPage()),\n    );\n    await tester.pumpAndSettle();\n\n    await tester.tap(find.text('Personalizado'));\n    await tester.pumpAndSettle();\n    expect(find.text('Seleccionar periodo'), findsOneWidget);\n    expect(find.text('Desde'), findsOneWidget);\n    expect(find.text('Hasta'), findsOneWidget);\n    await tester.tap(find.text('Cancelar'));\n    await tester.pumpAndSettle();\n\n    final pendingButton = find.byKey(\n      const ValueKey('dashboard-sync-pending'),\n    );\n    await tester.scrollUntilVisible(\n      pendingButton,\n      300,\n      scrollable: find.byKey(const ValueKey('dashboard-body-list')),\n    );\n    await tester.tap(pendingButton);\n    await tester.pumpAndSettle();\n\n    expect(find.text('Pendientes de sincronización'), findsOneWidget);\n    expect(find.text('Entendido'), findsOneWidget);\n    expect(tester.takeException(), isNull);\n  });\n\n"

# Domain: aliases semánticos y detalle de presentación.
domain = replace_once(
    domain,
    "  double get progresoPreparacion {\n",
    "  int get presentacionesRequeridas => unidadesRequeridas;\n"
    "  int get presentacionesPreparadas => unidadesPreparadas;\n"
    "  int get presentacionesPendientes => unidadesPendientes;\n\n"
    "  double get progresoPreparacion {\n",
    "agregar métricas por presentación",
)

domain = replace_once(
    domain,
    "    required this.pedidos,\n"
    "  });\n\n"
    "  final String productoId;\n"
    "  final String nombre;\n"
    "  final String codigo;\n"
    "  final String marca;\n"
    "  final String unidadBase;\n",
    "    required this.pedidos,\n"
    "    this.presentacion = 'Presentación',\n"
    "  });\n\n"
    "  final String productoId;\n"
    "  final String nombre;\n"
    "  final String codigo;\n"
    "  final String marca;\n"
    "  final String unidadBase;\n"
    "  final String presentacion;\n",
    "agregar presentación a productos destacados",
)
domain = replace_once(
    domain,
    "    unidadBase,\n"
    "    cantidadRequerida,\n",
    "    unidadBase,\n"
    "    presentacion,\n"
    "    cantidadRequerida,\n",
    "incluir presentación en propiedades de producto",
)

domain = replace_once(
    domain,
    "    required this.pedidosAfectados,\n"
    "  });\n\n"
    "  final String productoId;\n"
    "  final String nombre;\n"
    "  final String codigo;\n"
    "  final String unidadBase;\n",
    "    required this.pedidosAfectados,\n"
    "    this.presentacion = 'Presentación',\n"
    "  });\n\n"
    "  final String productoId;\n"
    "  final String nombre;\n"
    "  final String codigo;\n"
    "  final String unidadBase;\n"
    "  final String presentacion;\n",
    "agregar presentación a faltantes",
)
domain = replace_once(
    domain,
    "    unidadBase,\n"
    "    cantidadPendiente,\n"
    "    pedidosAfectados,\n"
    "  ];\n}\n\nclass DashboardPedidoListo",
    "    unidadBase,\n"
    "    presentacion,\n"
    "    cantidadPendiente,\n"
    "    pedidosAfectados,\n"
    "  ];\n}\n\nclass DashboardPedidoListo",
    "incluir presentación en propiedades de faltante",
)
domain = replace_tail(
    domain,
    "class DashboardSincronizacion extends Equatable {",
    SYNC_DOMAIN,
    "detalle de sincronización",
)

# Datasource: preparación y faltantes por presentación.
datasource = replace_between(
    datasource,
    "    final preparacion = (await db.rawQuery(",
    "    final parcial =",
    PREPARATION_QUERY,
    "resumen de preparación por presentación",
)
datasource = replace_between(
    datasource,
    "    final parcial =",
    "    final estados =",
    PARTIAL_QUERY,
    "pedidos con preparación parcial",
)
datasource = replace_between(
    datasource,
    "    final productosTopRows = await db.rawQuery(",
    "    final cotizacionesRows = await db.rawQuery(",
    PRODUCTS_QUERY,
    "productos solicitados por presentación",
)
datasource = replace_between(
    datasource,
    "    final faltantesRows = await db.rawQuery(",
    "    final listosRows = await db.rawQuery(",
    MISSING_QUERY,
    "faltantes por presentación",
)
datasource = replace_between(
    datasource,
    "    final listosRows = await db.rawQuery(",
    "    final syncRow =",
    READY_QUERY,
    "pedidos listos según presentaciones",
)
datasource = replace_between(
    datasource,
    "    final syncRow =",
    "    return DashboardData(",
    SYNC_QUERIES,
    "detalle global de sincronización",
)

datasource = replace_once(
    datasource,
    "        unidadBase: row['unidad_base'] as String? ?? 'UND',\n"
    "        cantidadRequerida: _int(row['requerida']),\n",
    "        unidadBase: row['unidad_base'] as String? ?? 'UND',\n"
    "        presentacion: row['presentacion'] as String? ?? 'Presentación',\n"
    "        cantidadRequerida: _int(row['requerida']),\n",
    "mapear presentación de producto",
)
datasource = replace_once(
    datasource,
    "    unidadBase: row['unidad_base'] as String? ?? 'UND',\n"
    "    cantidadPendiente: _int(row['pendiente']),\n",
    "    unidadBase: row['unidad_base'] as String? ?? 'UND',\n"
    "    presentacion: row['presentacion'] as String? ?? 'Presentación',\n"
    "    cantidadPendiente: _int(row['pendiente']),\n",
    "mapear presentación faltante",
)
datasource = replace_once(
    datasource,
    "        ultimaSincronizacion: _dateOrNull(syncRow['ultima_sincronizacion']),\n"
    "      ),\n",
    "        ultimaSincronizacion: _dateOrNull(syncRow['ultima_sincronizacion']),\n"
    "        pendientes: syncPendientesRows.map(_syncPendiente).toList(),\n"
    "      ),\n",
    "agregar pendientes al resultado",
)

sync_mapper = """  DashboardSyncPendiente _syncPendiente(
    Map<String, Object?> row,
  ) => DashboardSyncPendiente(
    id: row['id'] as String? ?? '',
    tipo: row['tipo'] as String? ?? 'operacion',
    titulo: row['titulo'] as String? ?? '',
    detalle: row['detalle'] as String? ?? '',
    estado: row['estado'] as String? ?? 'pendiente',
    fecha: _date(row['fecha']),
    error: row['error'] as String? ?? '',
  );

"""
datasource = replace_once(
    datasource,
    "  DashboardPedidoListo _pedidoListo(Map<String, Object?> row) =>\n",
    sync_mapper
    + "  DashboardPedidoListo _pedidoListo(Map<String, Object?> row) =>\n",
    "mapear pendientes de sincronización",
)

# UI: import, calendario, gráficos y modal offline.
if "import 'dart:math' as math;" not in page:
    page = replace_once(
        page,
        "import 'package:flutter/material.dart';\n",
        "import 'dart:math' as math;\n\n"
        "import 'package:flutter/material.dart';\n",
        "importar funciones matemáticas",
    )

page = replace_between(
    page,
    "  Future<void> _seleccionarPeriodo(",
    "class _DashboardHeader extends StatelessWidget {",
    DATE_PICKER,
    "selector visual de periodo",
)

page = replace_once(
    page,
    "                  onSync: () => onNavigate?.call(4),\n",
    "                  onSync: () => _showSyncPending(context),\n",
    "abrir pendientes desde atención",
)
page = replace_once(
    page,
    "                onViewPending: () => onNavigate?.call(4),\n",
    "                onViewPending: () => _showSyncPending(context),\n",
    "abrir pendientes desde sincronización",
)

sync_method = """  Future<void> _showSyncPending(BuildContext context) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.58),
        builder: (_) => _SyncPendingDialog(sync: data.sincronizacion),
      );

"""
page = replace_once(
    page,
    "  Future<void> _registrarCarga(\n",
    sync_method + "  Future<void> _registrarCarga(\n",
    "agregar modal de sincronización",
)

page = replace_between(
    page,
    "class _PedidosEstadoCard extends StatelessWidget {",
    "class _ProgresoOperativoCard extends StatelessWidget {",
    ORDERS_STATE,
    "gráfico de pedidos por estado",
)
page = replace_between(
    page,
    "class _ProgresoOperativoCard extends StatelessWidget {",
    "class _AtencionCard extends StatelessWidget {",
    PROGRESS,
    "progreso operativo radial",
)
page = replace_between(
    page,
    "class _ProductosTopCard extends StatelessWidget {",
    "class _CotizacionesCard extends StatelessWidget {",
    PRODUCTS_TOP,
    "productos destacados sin barras lineales",
)
page = replace_between(
    page,
    "class _FaltantesCard extends StatelessWidget {",
    "class _SummaryBox extends StatelessWidget {",
    MISSING,
    "faltantes por presentación",
)
page = replace_between(
    page,
    "class _SyncCard extends StatelessWidget {",
    "class _StatusPill extends StatelessWidget {",
    SYNC_UI,
    "sincronización offline y modal",
)

page = page.replace(
    "'Preparación física'",
    "'Preparación de presentaciones'",
)

# Test de calendario y modal.
test_anchor = "  testWidgets('registra una carga desde un pedido completamente preparado', (\n"
if tests.count(test_anchor) != 1:
    fail("No se encontró dónde insertar la prueba de diseño del Dashboard.")
tests = tests.replace(test_anchor, TEST_BLOCK + test_anchor, 1)

updates = {
    DOMAIN: domain,
    DATASOURCE: datasource,
    PAGE: page,
    TEST: tests,
}

backup_dir = ROOT / (
    ".backup_dashboard_diseno_v2_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    destination = backup_dir / path.relative_to(ROOT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nRediseño estadístico del Dashboard aplicado.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/dashboard_page_test.dart")
print("  flutter analyze")
