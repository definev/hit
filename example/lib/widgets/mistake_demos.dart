part of '../main.dart';

class _MistakeCompare extends StatelessWidget {
  const _MistakeCompare({
    required this.title,
    required this.body,
    required this.wrong,
    required this.right,
    required this.wrongFooter,
    required this.rightFooter,
  });

  final String title;
  final String body;
  final Widget wrong;
  final Widget right;
  final String wrongFooter;
  final String rightFooter;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MistakeSide(
                  label: 'Wrong',
                  ok: false,
                  footer: wrongFooter,
                  child: wrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MistakeSide(
                  label: 'Right',
                  ok: true,
                  footer: rightFooter,
                  child: right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MistakeSide extends StatelessWidget {
  const _MistakeSide({
    required this.label,
    required this.ok,
    required this.footer,
    required this.child,
  });

  final String label;
  final bool ok;
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    final accent = ok
        ? CupertinoColors.activeGreen.resolveFrom(context)
        : CupertinoColors.destructiveRed.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.tabLabelTextStyle.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: child,
        ),
        const SizedBox(height: 8),
        Text(
          footer,
          style: text.textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Shared 24 paint / 48 hit icon used by mistake demos.
class _MistakeIconLayer extends StatelessWidget {
  const _MistakeIconLayer({
    required this.showHitArea,
    required this.onTap,
    this.debugLabel,
    this.link,
  });

  final bool showHitArea;
  final VoidCallback onTap;
  final String? debugLabel;
  final HitLink? link;

  @override
  Widget build(BuildContext context) {
    return HitLayer(
      debugLabel: debugLabel,
      link: link,
      alignment: Alignment.center,
      behavior: HitTestBehavior.deferToChild,
      hitChild: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(width: 48, height: 48),
      ),
      paintChild: const IgnorePointer(
        child: Icon(CupertinoIcons.add, size: 24),
      ),
    );
  }
}

class _TightScopeDemo extends StatelessWidget {
  const _TightScopeDemo({
    required this.padded,
    required this.showHitArea,
    required this.onTap,
  });

  final bool padded;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layer = _MistakeIconLayer(
      debugLabel: padded ? 'mistake-tight-ok' : 'mistake-tight-bad',
      showHitArea: showHitArea,
      onTap: onTap,
    );
    // Nested HitScope so the page-level scope does not rescue the tight case.
    return HitScope(
      debugLabel: padded ? 'mistake-tight-scope-ok' : 'mistake-tight-scope-bad',
      child: padded
          ? Padding(padding: const EdgeInsets.all(12), child: layer)
          : layer,
    );
  }
}

class _ClipScopeDemo extends StatelessWidget {
  const _ClipScopeDemo({
    required this.clipped,
    required this.showHitArea,
    required this.onTap,
  });

  final bool clipped;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Card', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
          Positioned(
            right: -14,
            top: -14,
            child: HitDefer(
              debugLabel: clipped
                  ? 'mistake-clip-badge-bad'
                  : 'mistake-clip-badge-ok',
              behavior: HitTestBehavior.opaque,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      size: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (clipped) {
      // Clip above HitScope — overflow never receives events.
      return ClipRect(
        child: SizedBox(
          width: 72,
          height: 72,
          child: HitScope(debugLabel: 'mistake-clip-scope-bad', child: card),
        ),
      );
    }

    // HitScope covers the hanging badge via padding; no clip above.
    return HitScope(
      debugLabel: 'mistake-clip-scope-ok',
      child: Padding(padding: const EdgeInsets.all(16), child: card),
    );
  }
}

class _MissingScopeDemo extends StatelessWidget {
  const _MissingScopeDemo({
    required this.link,
    required this.showHitArea,
    required this.onTap,
  });

  /// Non-null orphan link = Wrong (nothing walks it). Null = use HitScope.
  final HitLink? link;
  final bool showHitArea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layer = _MistakeIconLayer(
      debugLabel: link != null
          ? 'mistake-missing-scope-bad'
          : 'mistake-missing-scope-ok',
      link: link,
      showHitArea: showHitArea,
      onTap: onTap,
    );
    if (link != null) {
      // Deliberately no HitScope on this link — deferred hits never fire.
      return Padding(padding: const EdgeInsets.all(12), child: layer);
    }
    return HitScope(
      debugLabel: 'mistake-missing-scope-ok',
      child: Padding(padding: const EdgeInsets.all(12), child: layer),
    );
  }
}
