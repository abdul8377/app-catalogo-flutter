import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_destination.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

part '../widgets/dashboard/dashboard_active_sheet_overview.dart';
part '../widgets/dashboard/dashboard_activity_overview.dart';
part '../widgets/dashboard/dashboard_attention_overview.dart';
part '../widgets/dashboard/dashboard_body.dart';
part '../widgets/dashboard/dashboard_calendar_widgets.dart';
part '../widgets/dashboard/dashboard_clients_overview.dart';
part '../widgets/dashboard/dashboard_delivery_overview.dart';
part '../widgets/dashboard/dashboard_feedback_states.dart';
part '../widgets/dashboard/dashboard_header.dart';
part '../widgets/dashboard/dashboard_kpi_widgets.dart';
part '../widgets/dashboard/dashboard_operations_overview.dart';
part '../widgets/dashboard/dashboard_order_status_overview.dart';
part '../widgets/dashboard/dashboard_period_dialog.dart';
part '../widgets/dashboard/dashboard_products_overview.dart';
part '../widgets/dashboard/dashboard_quotes_orders_overview.dart';
part '../widgets/dashboard/dashboard_register_load_dialog.dart';
part '../widgets/dashboard/dashboard_sync_overview.dart';
part '../widgets/dashboard/dashboard_sync_pending_dialog.dart';

const _yellow = Color(0xFFFFC500);
const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF667085);
const _background = Color(0xFFF5F6F8);

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
    super.key,
  });

  final ValueChanged<AppDestination>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final ValueChanged<String>? onOpenHoja;
  final ValueChanged<String>? onOpenCliente;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DashboardBloc(context.read<DashboardRepository>())
          ..add(const DashboardStarted()),
    child: _DashboardView(
      onNavigate: onNavigate,
      onOpenPedidos: onOpenPedidos,
      onOpenHoja: onOpenHoja,
      onOpenCliente: onOpenCliente,
    ),
  );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    this.onNavigate,
    this.onOpenPedidos,
    this.onOpenHoja,
    this.onOpenCliente,
  });

  final ValueChanged<AppDestination>? onNavigate;
  final void Function(int tab, String hojaCodigo)? onOpenPedidos;
  final ValueChanged<String>? onOpenHoja;
  final ValueChanged<String>? onOpenCliente;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.message != current.message,
      listener: (context, state) {
        final initialLoadFailed =
            state.error != null && state.data == const DashboardData.empty();
        if (initialLoadFailed) return;

        final text = state.error ?? state.message;
        if (text == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: state.error == null
                  ? const Color(0xFF16794B)
                  : const Color(0xFFB42318),
            ),
          );
      },
      builder: (context, state) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _DashboardHeader(
                state: state,
                onRefresh: () => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
                onPeriodo: (periodo) =>
                    _seleccionarPeriodo(context, state, periodo),
              ),
              if (state.actualizando)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: _yellow,
                  backgroundColor: Color(0xFFFFE899),
                ),
              Expanded(
                child: state.loading
                    ? const _DashboardSkeleton()
                    : state.error != null &&
                          state.data == const DashboardData.empty()
                    ? _ErrorState(
                        message: state.error!,
                        onRetry: () => context.read<DashboardBloc>().add(
                          const DashboardStarted(),
                        ),
                      )
                    : RefreshIndicator(
                        color: _ink,
                        backgroundColor: _yellow,
                        onRefresh: () async {
                          context.read<DashboardBloc>().add(
                            const DashboardRefreshed(),
                          );
                          await context.read<DashboardBloc>().stream.firstWhere(
                            (value) => !value.actualizando,
                          );
                        },
                        child: _DashboardBody(
                          state: state,
                          onNavigate: onNavigate,
                          onOpenPedidos: onOpenPedidos,
                          onOpenHoja: onOpenHoja,
                          onOpenCliente: onOpenCliente,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarPeriodo(
    BuildContext context,
    DashboardState state,
    DashboardPeriodoTipo periodo,
  ) async {
    if (periodo != DashboardPeriodoTipo.personalizado) {
      context.read<DashboardBloc>().add(
        DashboardPeriodoCambiado(DashboardFiltro(periodo: periodo)),
      );
      return;
    }

    final now = DateTime.now();
    final initialStart =
        state.filtro.fechaInicio ?? now.subtract(const Duration(days: 6));
    final initialEnd = state.filtro.fechaFin ?? now;

    final range = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _DashboardRangeDialog(
        firstDate: DateTime(2020),
        lastDate: now,
        initialStart: initialStart.isAfter(now) ? now : initialStart,
        initialEnd: initialEnd.isAfter(now) ? now : initialEnd,
      ),
    );

    if (!context.mounted || range == null) return;
    context.read<DashboardBloc>().add(
      DashboardPeriodoCambiado(
        DashboardFiltro(
          periodo: periodo,
          fechaInicio: range.start,
          fechaFin: range.end,
        ),
      ),
    );
  }
}
