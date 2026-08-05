part of '../main.dart';

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.body,
    required this.footer,
    required this.child,
    this.scope = false,
  });

  final String title;
  final String body;
  final String footer;
  final Widget child;
  final bool scope;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    Widget tile = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: text.tabLabelTextStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: text.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (scope) {
      tile = HitScope(debugLabel: 'tile-$title', child: tile);
    }
    return tile;
  }
}
