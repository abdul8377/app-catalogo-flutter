part of '../../pages/dashboard_page.dart';

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.title,
    required this.value,
    required this.theme,
    required this.child,
  });

  final String title;
  final String value;
  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEAECF0)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Theme(data: theme, child: child),
      ],
    ),
  );
}

class _RangeQuickButton extends StatelessWidget {
  const _RangeQuickButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: const BorderSide(color: _yellow),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    child: Text(label),
  );
}
