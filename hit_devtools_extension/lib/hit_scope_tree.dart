part of 'main.dart';

/// Compact tree row height — keep in sync with jump-to-scroll math.
const double _kTreeRowExtent = 26.0;
const double _kTreeIndent = 12.0;
const double _kTreeChevronSize = 16.0;

class _HitScopeTree extends StatelessWidget {
  const _HitScopeTree({
    required this.tree,
    required this.controller,
    required this.verticalController,
    required this.horizontalController,
    required this.selected,
    required this.highlightId,
    required this.onNodeTap,
    required this.onNodeToggle,
  });

  final List<TreeViewNode<HitNodeData>> tree;
  final TreeViewController controller;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final HitNodeData? selected;
  final int? highlightId;
  final ValueChanged<TreeViewNode<HitNodeData>> onNodeTap;
  final ValueChanged<TreeViewNode<HitNodeData>> onNodeToggle;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        child: Scrollbar(
          controller: verticalController,
          thumbVisibility: true,
          child: TreeView<HitNodeData>(
            controller: controller,
            tree: tree,
            onNodeToggle: onNodeToggle,
            // Keep expand/collapse instant so snapshot refreshes (e.g. HitLayer
            // list changes) do not replay open animations on already-open
            // Outside scope groups.
            toggleAnimationStyle: AnimationStyle.noAnimation,
            verticalDetails: ScrollableDetails.vertical(
              controller: verticalController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: horizontalController,
            ),
            indentation: TreeViewIndentationType.custom(_kTreeIndent),
            treeNodeBuilder: (
              BuildContext context,
              TreeViewNode<HitNodeData> node,
              AnimationStyle toggleAnimationStyle,
            ) {
              return _TreeRowContent(
                node: node,
                highlightId: highlightId,
                selected: selected == node.content,
              );
            },
            treeRowBuilder: (TreeViewNode<HitNodeData> node) {
              final bool isSelected = selected == node.content;
              final bool isHighlighted =
                  highlightId != null && node.content.id == highlightId;
              return TreeRow(
                extent: const FixedTreeRowExtent(_kTreeRowExtent),
                recognizerFactories: <Type, GestureRecognizerFactory>{
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                      TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (TapGestureRecognizer t) {
                      t.onTap = () => onNodeTap(node);
                    },
                  ),
                },
                backgroundDecoration: TreeRowDecoration(
                  color: isSelected
                      ? _selectionBlue.withValues(alpha: 0.18)
                      : isHighlighted
                          ? _highlightYellow.withValues(alpha: 0.10)
                          : null,
                ),
                foregroundDecoration: TreeRowDecoration(
                  border: TreeRowBorder(
                    left: isSelected
                        ? const BorderSide(color: _selectionBlue, width: 2)
                        : isHighlighted
                            ? const BorderSide(
                                color: _highlightYellow,
                                width: 2,
                              )
                            : BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TreeRowContent extends StatelessWidget {
  const _TreeRowContent({
    required this.node,
    required this.highlightId,
    required this.selected,
  });

  final TreeViewNode<HitNodeData> node;
  final int? highlightId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final HitNodeData data = node.content;
    final bool isParent = node.children.isNotEmpty;
    final bool isHighlighted = highlightId != null && data.id == highlightId;
    final String? groupKind = data.groupKind;
    final bool isOutsideGroup = groupKind == 'outside_scope';
    final bool isGroup = data.kind == 'group' || data.kind == 'root';
    final String primary = _nodePrimaryLabel(data);
    final String? idSuffix =
        data.id != null && !isGroup ? _idRef(data.id) : null;
    final Color iconColor = isHighlighted
        ? _highlightYellow
        : selected
            ? _selectionBlue
            : _iconColorFor(data, colors);

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 6),
      child: Row(
        children: [
          SizedBox(
            width: _kTreeChevronSize,
            height: _kTreeChevronSize,
            child: isParent
                ? TreeView.wrapChildToToggleNode(
                    node: node,
                    child: Icon(
                      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 14,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 2),
          Icon(
            _hitNodeIcon(kind: data.kind, groupKind: groupKind),
            size: 13,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: primary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Roboto Mono, monospace',
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: isHighlighted ||
                              selected ||
                              data.kind == 'scope' ||
                              isOutsideGroup
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isOutsideGroup && !isHighlighted && !selected
                          ? colors.onSurfaceVariant
                          : null,
                      fontStyle: isOutsideGroup ? FontStyle.italic : null,
                    ),
                  ),
                  if (idSuffix != null &&
                      primary != idSuffix &&
                      !primary.endsWith(idSuffix))
                    TextSpan(
                      text: ' $idSuffix',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'Roboto Mono, monospace',
                        fontSize: 10.5,
                        height: 1.15,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isHighlighted) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _highlightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _iconColorFor(HitNodeData data, ColorScheme colors) {
    final String? groupKind = data.groupKind;
    if (groupKind == 'outside_scope') {
      return colors.tertiary;
    }
    if (groupKind == 'unscoped') {
      return colors.onSurfaceVariant;
    }
    return switch (data.kind) {
      'scope' => colors.primary,
      'defer' => colors.tertiary,
      'root' => colors.onSurfaceVariant,
      _ => colors.onSurfaceVariant.withValues(alpha: 0.85),
    };
  }
}
