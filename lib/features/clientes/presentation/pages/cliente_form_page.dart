import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/repositories/clientes_repository.dart';
import '../bloc/cliente_form/cliente_form_cubit.dart';
import '../bloc/cliente_form/cliente_form_state.dart';
import '../forms/cliente_formulario.dart';

class ClienteFormPage extends StatelessWidget {
  const ClienteFormPage({this.clienteId, super.key});

  final String? clienteId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ClienteFormCubit(
      context.read<ClientesRepository>(),
      clienteId: clienteId,
    )..load(),
    child: _ClienteFormView(clienteId: clienteId),
  );
}

class _ClienteFormView extends StatefulWidget {
  const _ClienteFormView({required this.clienteId});

  final String? clienteId;

  @override
  State<_ClienteFormView> createState() => _ClienteFormViewState();
}

class _ClienteFormViewState extends State<_ClienteFormView> {
  final _formularioKey = GlobalKey<ClienteFormularioState>();
  final Color primaryColor = const Color(0xFFFFC500);
  final Color darkColor = const Color(0xFF1F1F1F);

  bool get _esEdicion => widget.clienteId != null;

  void _guardarCliente() {
    final formulario = _formularioKey.currentState;
    if (formulario == null || !formulario.validate()) return;
    context.read<ClienteFormCubit>().save(formulario.toNuevoCliente());
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ClienteFormCubit, ClienteFormState>(
    listenWhen: (previous, current) =>
        previous.error != current.error ||
        previous.notFound != current.notFound ||
        previous.saved != current.saved,
    listener: (context, state) {
      if (state.error != null) _mensaje(state.error!);
      if (state.notFound) {
        Navigator.pop(context, false);
        return;
      }
      if (state.saved) Navigator.pop(context, true);
    },
    builder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _appBar(),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ClienteFormulario(
                key: _formularioKey,
                clienteInicial: state.cliente,
                mostrarAuditoria: _esEdicion,
                bottomSpacer: 80,
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkColor,
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('guardar_cliente'),
                  onPressed: state.saving ? null : _guardarCliente,
                  icon: state.saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    state.saving ? 'Guardando...' : 'Guardar cliente',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: .4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  AppBar _appBar() => AppBar(
    title: Text(
      _esEdicion ? 'Editar cliente' : 'Nuevo cliente',
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    backgroundColor: darkColor,
    foregroundColor: Colors.white,
    elevation: 0,
  );

  void _mensaje(String value) {
    AppNotice.info(context, value);
  }
}
