part of 'main.dart';

class _HitDetailsPanel extends StatelessWidget {
  const _HitDetailsPanel({
    required this.selected,
    required this.tree,
    required this.highlightId,
    required this.onOpenId,
  });

  final HitNodeData? selected;
  final List<TreeViewNode<HitNodeData>> tree;
  final int? highlightId;
  final ValueChanged<int> onOpenId;

  @override
  Widget build(BuildContext context) {
    final HitNodeData? node = selected;
    if (node == null) {
      return const _EmptyState(
        'Select a node in the tree, or enable Select and tap a '
        'debug-painted hit area in the app.',
      );
    }
    if (node.kind == 'group') {
      return _GroupDetails(node: node);
    }

    final Map<String, Object?> p = node.payload;
    final bool highlighted = highlightId != null && node.id == highlightId;
    final List<String> warnings = _warningsFor(node);
    final int? parentScopeId = (p['parentScopeId'] as num?)?.toInt();
    final HitNodeData? parentScope =
        parentScopeId == null ? null : _findDataById(tree, parentScopeId);
    final int? linkId = (p['linkId'] as num?)?.toInt();
    final Object? paintSize = p['paintSize'] ?? p['size'];
    final Object? hitSize =
        p['hitSize'] ?? (node.kind == 'scope' ? null : p['size']);
    final String? sizeInsight = _sizeInsight(paintSize, hitSize);
    final bool deferred = p['deferred'] == true;
    final bool outside = p['outsideScope'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      children: [
        _DetailsHeader(
          node: node,
          highlighted: highlighted,
          deferred: deferred,
          outside: outside,
          warningCount: warnings.length,
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...warnings.map(
            (String warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _WarningCard(message: warning),
            ),
          ),
        ],
        if (paintSize != null ||
            hitSize != null ||
            p['targetCount'] != null) ...[
          const SizedBox(height: 10),
          _SectionLabel('SIZE'),
          const SizedBox(height: 4),
          if (paintSize != null || hitSize != null)
            _KvRow(
              label: node.kind == 'scope' ? 'Scope' : 'Paint / hit',
              value: [
                if (paintSize != null) _sizeLabel(paintSize),
                if (hitSize != null) _sizeLabel(hitSize),
              ].join(' → '),
              subtitle: sizeInsight,
            ),
          if (p['targetCount'] != null)
            _KvRow(label: 'Targets', value: '${p['targetCount']}'),
        ],
        const SizedBox(height: 8),
        _SectionLabel('BOUNDS'),
        const SizedBox(height: 4),
        _KvRow(
          label: 'Global hit',
          value: _boundsLabel(p['globalHitBounds'] ?? p['globalBounds']),
        ),
        _KvRow(
          label: 'Local hit',
          value: _boundsLabel(p['hitBounds'] ?? p['inScopeBounds']),
        ),
        if (p['globalPaintBounds'] != null)
          _KvRow(
            label: 'Global paint',
            value: _boundsLabel(p['globalPaintBounds']),
          ),
        if (p['behavior'] != null ||
            p['paint'] != null ||
            parentScope != null ||
            parentScopeId != null ||
            linkId != null) ...[
          const SizedBox(height: 8),
          _SectionLabel('CONFIG'),
          const SizedBox(height: 4),
          if (p['behavior'] != null)
            _KvRow(label: 'Behavior', value: '${p['behavior']}'),
          if (p['paint'] != null)
            _KvRow(label: 'Defer paint', value: '${p['paint']}'),
          if (parentScope != null || parentScopeId != null)
            _KvRow(
              label: 'Parent',
              value: parentScope == null ? _idRef(parentScopeId) : null,
              child: parentScope != null
                  ? _LinkChip(
                      label: _nodePrimaryLabel(parentScope),
                      onTap: parentScope.id == null
                          ? null
                          : () => onOpenId(parentScope.id!),
                    )
                  : null,
            ),
          if (linkId != null) _KvRow(label: 'Link', value: _idRef(linkId)),
        ],
      ],
    );
  }
}

class _GroupDetails extends StatelessWidget {
  const _GroupDetails({required this.node});

  final HitNodeData node;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Object? children = node.payload['children'];
    final int count = children is List ? children.length : 0;
    final bool outside = node.groupKind == 'outside_scope';
    final List<String> warnings = _warningsFor(node);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      children: [
        Row(
          children: [
            Icon(
              _hitNodeIcon(kind: node.kind, groupKind: node.groupKind),
              size: 16,
              color: outside ? colors.tertiary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _nodePrimaryLabel(node),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'Roboto Mono, monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          outside
              ? 'Hit AABBs extend outside their HitScope layout box.'
              : 'Not registered under a HitScope.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.3,
          ),
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...warnings.map(
            (String warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _WarningCard(message: warning),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.node,
    required this.highlighted,
    required this.deferred,
    required this.outside,
    required this.warningCount,
  });

  final HitNodeData node;
  final bool highlighted;
  final bool deferred;
  final bool outside;
  final int warningCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String type = '${node.payload['type'] ?? node.kind}';
    final String primary = _nodePrimaryLabel(node);
    final String? id = node.id == null ? null : _idRef(node.id);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? _highlightYellow.withValues(alpha: 0.10)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted
              ? _highlightYellow.withValues(alpha: 0.5)
              : colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hitNodeIcon(kind: node.kind, groupKind: node.groupKind),
                  size: 15,
                  color: highlighted ? _highlightYellow : colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: primary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Roboto Mono, monospace',
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        if (id != null && primary != id)
                          TextSpan(
                            text: '  $id',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'Roboto Mono, monospace',
                              color: colors.onSurfaceVariant,
                              height: 1.15,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _Chip(label: type, emphasized: true),
                if (deferred) const _Chip(label: 'deferred'),
                if (outside) const _Chip(label: 'outside', danger: true),
                if (highlighted)
                  const _Chip(label: 'highlighted', highlight: true),
                if (warningCount > 0)
                  _Chip(
                    label: warningCount == 1 ? 'warn' : '$warningCount warns',
                    danger: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    this.value,
    this.subtitle,
    this.child,
  });

  final String label;
  final String? value;
  final String? subtitle;
  final Widget? child;

  static const double _labelWidth = 78;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child ??
                    Text(
                      value ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Roboto Mono, monospace',
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, size: 13, color: colors.error),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onErrorContainer,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            fontSize: 10,
          ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.emphasized = false,
    this.danger = false,
    this.highlight = false,
  });

  final String label;
  final bool emphasized;
  final bool danger;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (danger) {
      bg = colors.errorContainer;
      fg = colors.onErrorContainer;
    } else if (highlight) {
      bg = _highlightYellow.withValues(alpha: 0.22);
      fg = colors.onSurface;
    } else if (emphasized) {
      bg = colors.primaryContainer.withValues(alpha: 0.55);
      fg = colors.onPrimaryContainer;
    } else {
      bg = colors.surfaceContainerHighest;
      fg = colors.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              height: 1.2,
            ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'Roboto Mono, monospace',
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                      color: colors.onPrimaryContainer,
                    ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.open_in_new,
                  size: 10,
                  color: colors.onPrimaryContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _sizeInsight(Object? paintRaw, Object? hitRaw) {
  if (paintRaw is! Map || hitRaw is! Map) {
    return null;
  }
  final double? pw = (paintRaw['width'] as num?)?.toDouble();
  final double? ph = (paintRaw['height'] as num?)?.toDouble();
  final double? hw = (hitRaw['width'] as num?)?.toDouble();
  final double? hh = (hitRaw['height'] as num?)?.toDouble();
  if (pw == null ||
      ph == null ||
      hw == null ||
      hh == null ||
      pw <= 0 ||
      ph <= 0) {
    return null;
  }
  if ((hw - pw).abs() < 0.5 && (hh - ph).abs() < 0.5) {
    return 'No expanded hit target.';
  }
  final double areaRatio = (hw * hh) / (pw * ph);
  final String dx = hw > pw ? '+${_num(hw - pw)}' : _num(hw - pw);
  final String dy = hh > ph ? '+${_num(hh - ph)}' : _num(hh - ph);
  if (areaRatio >= 1.05) {
    return 'Expands $dx×$dy · ${areaRatio.toStringAsFixed(areaRatio >= 10 ? 0 : 1)}× area';
  }
  if (areaRatio <= 0.95) {
    return 'Smaller than paint ($dx×$dy)';
  }
  return 'Differs by $dx×$dy';
}
