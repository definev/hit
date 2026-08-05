part of '../main.dart';

/// [HitLayer] inside [Text.rich] / [WidgetSpan] — layout follows the chip;
/// overflow taps still land via the enclosing [HitScope].
class _RichTextHit extends StatelessWidget {
  const _RichTextHit({
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final baseStyle = CupertinoTheme.of(
      context,
    ).textTheme.textStyle.copyWith(fontSize: 15, height: 1.4, color: secondary);

    final mention = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '@hit',
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.2,
        ),
      ),
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'Ping '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _ExpandHit(
              useHit: useHit,
              showHitArea: showHitArea,
              debugLabel: 'rich-text-mention',
              onTap: onTap,
              hitSize: const Size(44, 44),
              paintChild: mention,
            ),
          ),
          const TextSpan(text: ' without growing the line box.'),
        ],
      ),
    );
  }
}
