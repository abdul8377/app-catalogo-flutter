import 'dart:async';

import 'package:flutter/material.dart';

enum AppNoticeType { success, info, warning, error }

class AppNotice {
  AppNotice._();

  static OverlayEntry? _current;

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    context,
    message: message,
    type: AppNoticeType.success,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    context,
    message: message,
    type: AppNoticeType.info,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppNoticeType.warning);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppNoticeType.error);

  static void show(
    BuildContext context, {
    required String message,
    AppNoticeType type = AppNoticeType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppNoticeOverlay(
        message: message,
        type: type,
        onClose: dismiss,
        actionLabel: actionLabel,
        onAction: onAction,
        duration:
            duration ??
            (type == AppNoticeType.success
                ? const Duration(seconds: 2)
                : type == AppNoticeType.error
                ? const Duration(seconds: 6)
                : const Duration(seconds: 4)),
        onDisposed: () {
          if (identical(_current, entry)) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _AppNoticeOverlay extends StatefulWidget {
  const _AppNoticeOverlay({
    required this.message,
    required this.type,
    required this.onClose,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDisposed,
  });

  final String message;
  final AppNoticeType type;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDisposed;

  @override
  State<_AppNoticeOverlay> createState() => _AppNoticeOverlayState();
}

class _AppNoticeOverlayState extends State<_AppNoticeOverlay> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onClose);
  }

  @override
  void dispose() {
    _timer.cancel();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual(widget.type);
    final closable =
        widget.type == AppNoticeType.warning ||
        widget.type == AppNoticeType.error;
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: visual.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: visual.foreground.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          visual.icon,
                          color: visual.foreground,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: visual.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            widget.onClose();
                            widget.onAction!();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: visual.foreground,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(widget.actionLabel!),
                        ),
                      ],
                      if (closable) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Cerrar aviso',
                          onPressed: widget.onClose,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            color: visual.foreground,
                            size: 19,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _NoticeVisual _visual(AppNoticeType value) {
    switch (value) {
      case AppNoticeType.success:
        return const _NoticeVisual(
          background: Color(0xFFE8F5E9),
          border: Color(0xFFA5D6A7),
          foreground: Color(0xFF1B5E20),
          icon: Icons.check_circle_outline,
        );
      case AppNoticeType.info:
        return const _NoticeVisual(
          background: Color(0xFFFFF8D6),
          border: Color(0xFFFFC500),
          foreground: Color(0xFF302600),
          icon: Icons.info_outline,
        );
      case AppNoticeType.warning:
        return const _NoticeVisual(
          background: Color(0xFFFFF3E0),
          border: Color(0xFFFFB74D),
          foreground: Color(0xFFE65100),
          icon: Icons.warning_amber_rounded,
        );
      case AppNoticeType.error:
        return const _NoticeVisual(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFEF9A9A),
          foreground: Color(0xFFB71C1C),
          icon: Icons.error_outline,
        );
    }
  }
}

class _NoticeVisual {
  const _NoticeVisual({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
