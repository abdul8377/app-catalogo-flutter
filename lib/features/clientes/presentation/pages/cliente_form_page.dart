import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/app_notice.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/clientes_repository.dart';
import '../widgets/cliente_formulario.dart';

class ClienteFormPage extends StatefulWidget {
  const ClienteFormPage({this.clienteId, super.key});

  final String? clienteId;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formularioKey = GlobalKey<ClienteFormularioState>();
  final Color primaryColor = const Color(0xFFFFC500);
  final Color darkColor = const Color(0xFF1F1F1F);

  bool _didLoad = false;
  bool _cargando = false;
  bool _guardando = false;
  Cliente? _clienteInicial;

  bool get _esEdicion => widget.clienteId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _cargarCliente();
    }
  }

  Future<void> _cargarCliente() async {
    if (!_esEdicion) return;
    setState(() => _cargando = true);
    try {
      final cliente = await context.read<ClientesRepository>().obtenerCliente(
        widget.clienteId!,
      );
      if (!mounted) return;
      if (cliente == null) {
        _mensaje('No se encontró el cliente seleccionado.');
        Navigator.pop(context, false);
        return;
      }
      setState(() => _clienteInicial = cliente);
    } catch (_) {
      if (mounted) _mensaje('No se pudo cargar el cliente.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCliente() async {
    final formulario = _formularioKey.currentState;
    if (formulario == null || !formulario.validate()) return;

    setState(() => _guardando = true);
    try {
      final repository = context.read<ClientesRepository>();
      final cliente = formulario.toNuevoCliente();
      if (_esEdicion) {
        await repository.actualizarCliente(widget.clienteId!, cliente);
      } else {
        await repository.guardarCliente(cliente);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje(
        _esEdicion
            ? 'No se pudo actualizar el cliente.'
            : 'No se pudo guardar el cliente.',
      );
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    appBar: _appBar(),
    body: _cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: ClienteFormulario(
              key: _formularioKey,
              clienteInicial: _clienteInicial,
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
                onPressed: _guardando ? null : () => Navigator.pop(context),
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
                onPressed: _guardando ? null : _guardarCliente,
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_guardando ? 'Guardando...' : 'Guardar cliente'),
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
