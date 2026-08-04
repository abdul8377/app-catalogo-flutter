part of '../imagenes_section.dart';

extension _Step6GallerySection on _Step6ImagesPanelState {
  Widget _buildHeader() {
    final primaryCount = _familyImages.where((image) => image.isPrimary).length;
    return Wrap(
      spacing: 18,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso 5 · Imágenes',
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Administra la galería compartida y las excepciones visuales.',
              style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Familia: ${widget.familyName} · '
              '${widget.variants.length} '
              '${widget.variants.length == 1 ? 'variante' : 'variantes'}',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryBadge(
              '${_familyImages.length} imágenes de familia · '
              '$primaryCount principal · '
              '${_exceptions.length} '
              '${_exceptions.length == 1 ? 'excepción' : 'excepciones'}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5CC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE58A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFamilyGallery() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galería de la familia',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todas las variantes heredan estas imágenes.',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _hasProcessing ? null : _addFamilyImages,
                style: _outlinedStyle(),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('+ Agregar imágenes'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildImageRequirements(),
          if (_hasProcessing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 4,
              color: _selection,
              backgroundColor: Color(0xFFDCE6F4),
            ),
          ],
          const SizedBox(height: 18),
          if (_familyImages.isEmpty)
            _buildEmptyGallery()
          else
            _buildReorderableGrid(),
        ],
      ),
    );
  }

  Widget _buildImageRequirements() {
    final maxMb = widget.maxImageBytes / (1024 * 1024);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'JPG, PNG o WebP · máximo ${_plainNumber(maxMb)} MB · '
              'recomendado ${widget.recommendedMinWidth} × '
              '${widget.recommendedMinHeight} px · recorte '
              '${_ratioLabel(widget.cropAspectRatio)}.',
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.photo_library_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay imágenes en la galería.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes guardar el producto como borrador. Para activarlo en el '
            'paso 7 deberá existir una imagen principal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _addFamilyImages,
            style: _outlinedStyle(),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Agregar imágenes'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780
            ? 3
            : constraints.maxWidth >= 510
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _familyImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final image = _familyImages[index];
            return LongPressDraggable<String>(
              data: image.id,
              maxSimultaneousDrags: image.isReady ? 1 : 0,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 240,
                  height: 280,
                  child: _buildImageCard(image, index),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _buildImageCard(image, index),
              ),
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) => details.data != image.id,
                onAcceptWithDetails: (details) {
                  _moveFamilyImage(details.data, image.id);
                },
                builder: (context, candidates, rejected) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: candidates.isEmpty
                          ? null
                          : Border.all(color: _selection, width: 2),
                    ),
                    child: _buildImageCard(image, index),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
