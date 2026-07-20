import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/entities/nuevo_cliente.dart';
import '../../domain/repositories/clientes_repository.dart';

class ClienteFormPage extends StatefulWidget {
  const ClienteFormPage({this.clienteId, super.key});

  final String? clienteId;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFFFFC500);
  final Color darkColor = const Color(0xFF1F1F1F);

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _dniCtrl;
  late final TextEditingController _rucCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _observacionesCtrl;

  String _tipoCliente = 'Persona';
  bool _activo = true;
  DateTime _fechaCreacion = DateTime.now();
  DateTime? _ultimaActualizacion;
  String? _fotoRuta;

  bool _didLoad = false;
  bool _cargando = false;
  bool _guardando = false;
  Cliente? _clienteInicial;

  bool get _esEdicion => widget.clienteId != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _dniCtrl = TextEditingController();
    _rucCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _referenciaCtrl = TextEditingController();
    _observacionesCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _cargarCliente();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _dniCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
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
      _clienteInicial = cliente;
      _nombreCtrl.text = cliente.nombre;
      _telefonoCtrl.text = cliente.telefono;
      _dniCtrl.text = cliente.dni ?? '';
      _rucCtrl.text = cliente.ruc ?? '';
      _direccionCtrl.text = cliente.direccion ?? '';
      _referenciaCtrl.text = cliente.referencia ?? '';
      _observacionesCtrl.text = cliente.observaciones ?? '';
      _tipoCliente = cliente.tipo;
      _activo = cliente.activo;
      _fechaCreacion = cliente.fechaRegistro;
      _ultimaActualizacion = cliente.ultimaActualizacion;
      _fotoRuta = cliente.fotoUbicacionPath;
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo cargar el cliente.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCliente() async {
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return;
    setState(() => _guardando = true);
    final cliente = NuevoCliente(
      nombre: _nombreCtrl.text.trim(),
      tipo: _tipoCliente,
      telefono: _telefonoCtrl.text.trim(),
      dni: _dniCtrl.text.trim(),
      ruc: _rucCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
      fotoUbicacionPath: _fotoRuta,
      activo: _activo,
      observaciones: _observacionesCtrl.text.trim(),
    );

    try {
      final repository = context.read<ClientesRepository>();
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

  Future<void> _seleccionarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_fotoRuta != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fotoRuta = null);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null && mounted) {
        setState(() => _fotoRuta = image.path);
      }
    } catch (_) {
      if (mounted) _mensaje('No se pudo seleccionar la imagen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _appBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información principal'),
              const SizedBox(height: 16),
              Text(
                'Tipo de cliente',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleChip(
                      label: 'Persona',
                      icon: Icons.person_outline,
                      selected: _tipoCliente == 'Persona',
                      onTap: () => setState(() => _tipoCliente = 'Persona'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleChip(
                      label: 'Empresa',
                      icon: Icons.business_outlined,
                      selected: _tipoCliente == 'Empresa',
                      onTap: () => setState(() => _tipoCliente = 'Empresa'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDecoration(
                  'Nombre o razón social *',
                  Icons.badge_outlined,
                ),
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: _inputDecoration(
                  'Teléfono *',
                  Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Requerido';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7 || digits.length > 15) {
                    return 'Formato inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.toggle_on_outlined,
                    size: 20,
                    color: Color(0xFF757575),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  Switch(
                    value: _activo,
                    onChanged: (val) => setState(() => _activo = val),
                    activeThumbColor: primaryColor,
                  ),
                  Text(
                    _activo ? 'Activo' : 'Inactivo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: _activo ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Documentos'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dniCtrl,
                decoration: _inputDecoration('DNI', Icons.credit_card_outlined),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rucCtrl,
                decoration: _inputDecoration(
                  _tipoCliente == 'Empresa' ? 'RUC (recomendado)' : 'RUC',
                  Icons.business_center_outlined,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Entrega y ubicación'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: _inputDecoration(
                  'Dirección *',
                  Icons.location_on_outlined,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'La dirección es requerida' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenciaCtrl,
                decoration: _inputDecoration('Referencia', Icons.info_outline),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Foto de ubicación',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _seleccionarFoto,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fotoRuta != null
                          ? primaryColor
                          : const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFotoPreview(),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Información adicional'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesCtrl,
                decoration: _inputDecoration('Observaciones', Icons.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_esEdicion || _clienteInicial != null) ...[
                _buildReadOnlyRow(
                  'Fecha de creación',
                  _formatDateTime(_fechaCreacion),
                ),
                const SizedBox(height: 8),
                _buildReadOnlyRow(
                  'Última actualización',
                  _ultimaActualizacion != null
                      ? _formatDateTime(_ultimaActualizacion!)
                      : 'No disponible',
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 80),
            ],
          ),
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
  }

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

  Widget _buildFotoPreview() {
    final path = _fotoRuta;
    if (path == null || path.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para agregar foto',
            style: GoogleFonts.inter(color: const Color(0xFF9E9E9E)),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFE0E0E0),
              child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tocar para cambiar',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Row(
    children: [
      Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: darkColor,
        ),
      ),
    ],
  );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF757575)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected ? primaryColor.withValues(alpha: .15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? primaryColor : const Color(0xFFE0E0E0),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Colors.black : const Color(0xFF757575),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildReadOnlyRow(String label, String value) => Row(
    children: [
      Text(
        '$label: ',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF757575),
        ),
      ),
      Expanded(
        child: Text(value, style: GoogleFonts.inter(color: darkColor)),
      ),
    ],
  );

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  void _mensaje(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }
}
