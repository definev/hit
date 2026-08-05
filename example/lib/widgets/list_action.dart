part of '../main.dart';

class _ListAction extends StatelessWidget {
  const _ListAction({
    required this.useHit,
    required this.showHitArea,
    required this.onTap,
  });

  final bool useHit;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Inbox message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ExpandHit(
            useHit: useHit,
            showHitArea: showHitArea,
            debugLabel: 'list-row-trash',
            onTap: onTap,
            hitSize: const Size(44, 44),
            paintChild: Icon(
              CupertinoIcons.trash,
              size: 18,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
