part of '../main.dart';

class _ChipDismiss extends StatelessWidget {
  const _ChipDismiss({
    required this.useHit,
    required this.showHitArea,
    required this.onDismiss,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Design',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            _ExpandHit(
              useHit: useHit,
              showHitArea: showHitArea,
              debugLabel: 'chip-dismiss',
              onTap: onDismiss,
              hitSize: const Size(44, 44),
              paintChild: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 18,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
