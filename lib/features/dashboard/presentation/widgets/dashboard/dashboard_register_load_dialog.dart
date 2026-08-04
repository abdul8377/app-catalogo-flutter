part of '../../pages/dashboard_page.dart';

class _RegistrarCargaDialog extends StatefulWidget {
  const _RegistrarCargaDialog({required this.pedido});

  final DashboardPedidoListo pedido;

  @override
  State<_RegistrarCargaDialog> createState() => _RegistrarCargaDialogState();
}

class _RegistrarCargaDialogState extends State<_RegistrarCargaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paquetes = TextEditingController(text: '1');
  final _observacion = TextEditingController();

  @override
  void dispose() {
    _paquetes.dispose();
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    titlePadding: EdgeInsets.zero,
    contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
    actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    title: Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.local_shipping_outlined, color: _ink),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar carga',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.pedido.codigo,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB7BAC1),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    content: SizedBox(
      width: 430,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pedido.cliente,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              widget.pedido.direccion.isEmpty
                  ? 'Sin dirección registrada'
                  : widget.pedido.direccion,
              style: GoogleFonts.inter(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paquetes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de paquetes *',
                helperText: 'Debe representar la carga física del pedido.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final cantidad = int.tryParse(value?.trim() ?? '');
                if (cantidad == null || cantidad <= 0) {
                  return 'Ingresa una cantidad mayor que cero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _observacion,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación',
                hintText: 'Ej. Carga revisada y sellada',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _CargaInput(
              int.parse(_paquetes.text.trim()),
              _observacion.text.trim(),
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _ink,
        ),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Confirmar carga'),
      ),
    ],
  );
}

class _CargaInput {
  const _CargaInput(this.paquetes, this.observacion);

  final int paquetes;
  final String observacion;
}
