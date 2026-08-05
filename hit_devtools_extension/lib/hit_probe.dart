part of 'main.dart';

class _HitProbePanel extends StatelessWidget {
  const _HitProbePanel({
    required this.result,
    required this.highlightId,
    required this.onOpenId,
    required this.onClear,
  });

  final Map<String, Object?> result;
  final int? highlightId;
  final ValueChanged<int> onOpenId;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final double? x = _asDouble(result['x']);
    final double? y = _asDouble(result['y']);
    final List<Object?> rawHits =
        (result['hits'] as List?) ?? const <Object?>[];
    final List<Object?> notes = (result['notes'] as List?) ?? const <Object?>[];
    final String? pointText =
        x == null || y == null ? null : '${_num(x)}, ${_num(y)}';

    final List<Map<String, Object?>> pathHits = <Map<String, Object?>>[];
    final List<Map<String, Object?>> overlapHits = <Map<String, Object?>>[];
    for (final Object? raw in rawHits) {
      if (raw is! Map) {
        continue;
      }
      final Map<String, Object?> hit = raw.cast<String, Object?>();
      final bool onPath = _asBool(hit['winner']) || _asBool(hit['inHitPath']);
      if (onPath) {
        pathHits.add(hit);
      } else {
        overlapHits.add(hit);
      }
    }

    Widget hitRows(List<Map<String, Object?>> hits, {required bool muted}) {
      if (hits.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 6),
          child: Text(
            'None',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final Map<String, Object?> hit in hits)
            _ProbeHitRow(
              hit: hit,
              muted: muted,
              highlighted:
                  highlightId != null && _asInt(hit['id']) == highlightId,
              onTap: () {
                final int? id = _asInt(hit['id']);
                if (id != null) {
                  onOpenId(id);
                }
              },
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      children: [
        if (notes.isNotEmpty) ...[
          ...notes.map(
            (Object? note) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _WarningCard(message: '$note'),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _SectionLabel(
                    pathHits.isEmpty
                        ? 'HITS (NONE)'
                        : 'HITS (${pathHits.length})',
                  ),
                  if (pointText != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              colors.onSurfaceVariant.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.gps_fixed,
                      size: 11,
                      color: colors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        pointText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'Roboto Mono, monospace',
                          fontSize: 10.5,
                          height: 1.2,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            DevToolsTooltip(
              message: 'Clear',
              child: InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        hitRows(pathHits, muted: false),
        if (overlapHits.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SectionLabel('OVERLAP ONLY (${overlapHits.length})'),
          const SizedBox(height: 2),
          hitRows(overlapHits, muted: true),
        ],
      ],
    );
  }
}

class _ProbeHitRow extends StatelessWidget {
  const _ProbeHitRow({
    required this.hit,
    required this.highlighted,
    required this.onTap,
    this.muted = false,
  });

  final Map<String, Object?> hit;
  final bool highlighted;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String kind = '${hit['kind'] ?? 'hit'}';
    final String? debugLabel = hit['debugLabel'] as String?;
    final String? type = hit['type'] as String?;
    final int? id = _asInt(hit['id']);
    final bool outside = _asBool(hit['outsideScope']);
    final bool deferred = _asBool(hit['deferred']);
    final Object? warningsRaw = hit['warnings'];
    final int warningCount = warningsRaw is List ? warningsRaw.length : 0;
    final String primary = (debugLabel != null && debugLabel.isNotEmpty)
        ? debugLabel
        : (type ?? kind);
    final String? idLabel = id == null ? null : _idRef(id);

    final List<String> trailing = <String>[
      if (deferred) 'deferred',
      if (outside) 'outside',
      if (warningCount == 1) 'warn',
      if (warningCount > 1) '$warningCount warns',
    ];

    final Color baseColor = muted
        ? colors.onSurfaceVariant.withValues(alpha: 0.7)
        : colors.onSurfaceVariant;

    return Material(
      color: highlighted
          ? _highlightYellow.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: id == null ? null : onTap,
        child: SizedBox(
          height: _kTreeRowExtent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(
                  _probeKindIcon(kind),
                  size: 13,
                  color: highlighted
                      ? _highlightYellow
                      : muted
                          ? colors.tertiary.withValues(alpha: 0.85)
                          : outside
                              ? colors.tertiary
                              : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: primary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Roboto Mono, monospace',
                            fontSize: 12,
                            height: 1.15,
                            fontWeight: highlighted || kind == 'scope'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: muted && !highlighted ? baseColor : null,
                            fontStyle: muted ? FontStyle.italic : null,
                          ),
                        ),
                        if (idLabel != null && primary != idLabel)
                          TextSpan(
                            text: ' $idLabel',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'Roboto Mono, monospace',
                              fontSize: 10.5,
                              height: 1.15,
                              color: colors.onSurfaceVariant
                                  .withValues(alpha: muted ? 0.55 : 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (trailing.isNotEmpty)
                          TextSpan(
                            text: '  ·  ${trailing.join(' · ')}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              height: 1.15,
                              color: outside || warningCount > 0
                                  ? colors.error
                                  : colors.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                              fontWeight: FontWeight.w400,
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
          ),
        ),
      ),
    );
  }
}

IconData _probeKindIcon(String kind) {
  switch (kind) {
    case 'scope':
      return Icons.crop_free;
    case 'defer':
    case 'deferredTarget':
      return Icons.subdirectory_arrow_right;
    case 'layer':
      return Icons.layers_outlined;
    default:
      return Icons.touch_app_outlined;
  }
}
