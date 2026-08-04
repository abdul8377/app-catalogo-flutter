part of '../imagenes_section.dart';

extension _Step6ImageCardAndPreview on _Step6ImagesPanelState {
  Widget _buildImageCard(Step6ProductImageDraft image, int index) {
    final belowRecommendation = _isBelowRecommendation(image.candidate);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: image.isPrimary ? _primary : _border,
          width: image.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImagePreview(image),
                Positioned(
                  top: 9,
                  left: 9,
                  child: image.isPrimary
                      ? _statusBadge(
                          icon: Icons.star,
                          label: 'Principal',
                          background: const Color(0xFFFFF3BF),
                          foreground: _ink,
                        )
                      : _statusBadge(
                          icon: Icons.drag_indicator,
                          label: 'Posición ${index + 1}',
                          background: Colors.white.withOpacity(0.94),
                          foreground: _ink,
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: PopupMenuButton<_Step6ImageAction>(
                    tooltip: 'Acciones de imagen',
                    constraints: const BoxConstraints(minWidth: 220),
                    onSelected: (action) => _handleImageAction(action, image),
                    itemBuilder: (context) => [
                      _imageMenuItem(
                        _Step6ImageAction.view,
                        Icons.open_in_full,
                        'Ver en tamaño completo',
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.makePrimary,
                        Icons.star_outline,
                        'Establecer como principal',
                        enabled: !image.isPrimary && image.isReady,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.editLabel,
                        Icons.label_outline,
                        'Editar etiqueta',
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.crop,
                        Icons.crop,
                        'Ajustar o recortar',
                        enabled: image.isReady,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.replace,
                        Icons.find_replace_outlined,
                        'Reemplazar',
                        enabled:
                            image.processState !=
                            Step6ImageProcessState.processing,
                      ),
                      _imageMenuItem(
                        _Step6ImageAction.delete,
                        Icons.delete_outline,
                        'Eliminar',
                        foreground: _danger,
                      ),
                    ],
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
                if (image.processState == Step6ImageProcessState.processing)
                  _buildProcessingOverlay(image),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                if (image.processState == Step6ImageProcessState.failed)
                  _buildFailedStatus(image)
                else
                  _buildSyncStatus(image),
                if (belowRecommendation &&
                    image.processState == Step6ImageProcessState.ready) ...[
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFF8A5A00),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Resolución menor a la recomendada',
                          style: TextStyle(
                            color: Color(0xFF8A5A00),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_Step6ImageAction> _imageMenuItem(
    _Step6ImageAction value,
    IconData icon,
    String label, {
    bool enabled = true,
    Color foreground = _ink,
  }) {
    return PopupMenuItem<_Step6ImageAction>(
      value: value,
      enabled: enabled,
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: enabled ? foreground : _muted, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? foreground : _muted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Step6ProductImageDraft image) {
    if (widget.previewBuilder != null) {
      return ClipRect(child: widget.previewBuilder!(context, image));
    }

    final bytes = image.candidate.previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }

    final url = image.candidate.remoteUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPreviewPlaceholder(image),
      );
    }

    return _buildPreviewPlaceholder(image);
  }

  Widget _buildPreviewPlaceholder(Step6ProductImageDraft image) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            (constraints.hasBoundedWidth && constraints.maxWidth < 100) ||
            (constraints.hasBoundedHeight && constraints.maxHeight < 100);
        return ColoredBox(
          color: const Color(0xFFEEF1F5),
          child: Center(
            child: compact
                ? const Icon(Icons.image_outlined, color: _muted, size: 28)
                : Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: _muted,
                          size: 38,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          image.candidate.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingOverlay(Step6ProductImageDraft image) {
    return ColoredBox(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Procesando ${(image.progress * 100).round()} %',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedStatus(Step6ProductImageDraft image) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: _danger, size: 19),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'No se pudo procesar',
            style: TextStyle(
              color: _danger,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _retryImage(image),
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(Step6ProductImageDraft image) {
    final synced = image.syncState == Step6ImageSyncState.synced;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: synced ? _success : _muted,
          size: 19,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            synced
                ? 'Sincronizada'
                : 'Guardada localmente · Pendiente de sincronizar',
            style: TextStyle(
              color: synced ? _success : _muted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
