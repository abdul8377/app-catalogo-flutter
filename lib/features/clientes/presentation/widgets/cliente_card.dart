import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/cliente.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({
    required this.cliente,
    this.onVer,
    this.onEditar,
    this.onActivarDesactivar,
    super.key,
  });

  final Cliente cliente;
  final VoidCallback? onVer;
  final VoidCallback? onEditar;
  final VoidCallback? onActivarDesactivar;

  @override
  Widget build(BuildContext context) {
    const darkColor = Color(0xFF1F1F1F);
    const primaryColor = Color(0xFFFFC500);
    final ruc = cliente.ruc;
    final dni = cliente.dni;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cliente.activo
                        ? primaryColor.withValues(alpha: .2)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      cliente.iniciales,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: cliente.activo ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cliente.tipo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cliente.activo
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cliente.activo ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cliente.activo
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, cliente.telefono),
            if (ruc != null && ruc.isNotEmpty)
              _buildInfoRow(Icons.badge, 'RUC: $ruc'),
            if ((dni ?? '').isNotEmpty && (ruc ?? '').isEmpty)
              _buildInfoRow(Icons.badge, 'DNI: $dni'),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Dirección: $_direccionResumen',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${cliente.pedidosCount} pedidos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cliente.ultimoPedido != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• Último: ${_formatDate(cliente.ultimoPedido!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onVer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkColor,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    child: const Text('Ver'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEditar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkColor,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, size: 16),
                  ),
                  onSelected: (val) {
                    if (val == 'editar') onEditar?.call();
                    if (val == 'activar') onActivarDesactivar?.call();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: const [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'activar',
                      child: Row(
                        children: [
                          Icon(
                            cliente.activo ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: cliente.activo
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(cliente.activo ? 'Desactivar' : 'Activar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _direccionResumen {
    final direccion = cliente.direccion?.trim();
    if (direccion == null || direccion.isEmpty) return 'Sin dirección';
    return direccion;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF616161),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
