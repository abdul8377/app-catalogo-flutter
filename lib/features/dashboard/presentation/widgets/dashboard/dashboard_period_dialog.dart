part of '../../pages/dashboard_page.dart';

class _DashboardRangeDialog extends StatefulWidget {
  const _DashboardRangeDialog({
    required this.firstDate,
    required this.lastDate,
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_DashboardRangeDialog> createState() => _DashboardRangeDialogState();
}

class _DashboardRangeDialogState extends State<_DashboardRangeDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = DateUtils.dateOnly(widget.initialStart);
    _end = DateUtils.dateOnly(widget.initialEnd);
    if (_end.isBefore(_start)) _end = _start;
  }

  void _setQuickRange(int days) {
    final end = DateUtils.dateOnly(widget.lastDate);
    final start = end.subtract(Duration(days: days - 1));
    setState(() {
      _start = start.isBefore(widget.firstDate) ? widget.firstDate : start;
      _end = end;
    });
  }

  void _setCurrentMonth() {
    final end = DateUtils.dateOnly(widget.lastDate);
    setState(() {
      _start = DateTime(end.year, end.month);
      _end = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    final calendarTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: _yellow,
        onPrimary: Colors.black,
        secondary: _yellow,
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: _ink,
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 760),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                color: _ink,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar periodo',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Elige una fecha inicial y una fecha final.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB7BAC1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RangeQuickButton(
                            label: 'Últimos 7 días',
                            onPressed: () => _setQuickRange(7),
                          ),
                          _RangeQuickButton(
                            label: 'Últimos 30 días',
                            onPressed: () => _setQuickRange(30),
                          ),
                          _RangeQuickButton(
                            label: 'Este mes',
                            onPressed: _setCurrentMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final startCalendar = _CalendarPanel(
                            title: 'Desde',
                            value: format.format(_start),
                            theme: calendarTheme,
                            child: CalendarDatePicker(
                              key: ValueKey('dashboard-start-$_start'),
                              initialDate: _start,
                              firstDate: widget.firstDate,
                              lastDate: widget.lastDate,
                              onDateChanged: (value) {
                                final date = DateUtils.dateOnly(value);
                                setState(() {
                                  _start = date;
                                  if (_end.isBefore(date)) _end = date;
                                });
                              },
                            ),
                          );
                          final endCalendar = _CalendarPanel(
                            title: 'Hasta',
                            value: format.format(_end),
                            theme: calendarTheme,
                            child: CalendarDatePicker(
                              key: ValueKey('dashboard-end-$_end'),
                              initialDate: _end,
                              firstDate: widget.firstDate,
                              lastDate: widget.lastDate,
                              onDateChanged: (value) {
                                final date = DateUtils.dateOnly(value);
                                setState(() {
                                  _end = date;
                                  if (_start.isAfter(date)) _start = date;
                                });
                              },
                            ),
                          );

                          if (constraints.maxWidth >= 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: startCalendar),
                                const SizedBox(width: 14),
                                Expanded(child: endCalendar),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              startCalendar,
                              const SizedBox(height: 14),
                              endCalendar,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        DateTimeRange(start: _start, end: _end),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: _ink,
                        minimumSize: const Size(140, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Aplicar periodo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
