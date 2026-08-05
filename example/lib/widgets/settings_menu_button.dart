part of '../main.dart';

/// Settings gear that opens a [CupertinoMenuAnchor] with toggle items.
class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
    required this.useHit,
    required this.showHitArea,
    required this.onUseHitChanged,
    required this.onShowHitAreaChanged,
  });

  final bool useHit;
  final bool showHitArea;
  final ValueChanged<bool> onUseHitChanged;
  final ValueChanged<bool> onShowHitAreaChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoMenuAnchor(
      consumeOutsideTaps: true,
      builder: (context, controller, child) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: const Icon(CupertinoIcons.settings),
        );
      },
      menuChildren: [
        CupertinoMenuItem(
          subtitle: Text(
            useHit
                ? 'HitLayer / HitDefer active'
                : 'Plain Flutter — no hit package',
          ),
          trailing: useHit
              ? const Icon(CupertinoIcons.check_mark)
              : const SizedBox.shrink(),
          requestCloseOnActivate: false,
          onPressed: () => onUseHitChanged(!useHit),
          child: const Text('Use hit'),
        ),
        const CupertinoMenuDivider(),
        CupertinoMenuItem(
          subtitle: Text(
            showHitArea
                ? 'Dashed overlay + DevTools labels (debugPaintHitAreas)'
                : 'Hit areas hidden',
          ),
          trailing: showHitArea
              ? const Icon(CupertinoIcons.check_mark)
              : const SizedBox.shrink(),
          requestCloseOnActivate: false,
          onPressed: () => onShowHitAreaChanged(!showHitArea),
          child: const Text('Show hit areas'),
        ),
      ],
    );
  }
}
