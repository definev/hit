part of 'main.dart';

IconData _hitNodeIcon({required String kind, String? groupKind}) {
  if (groupKind == 'outside_scope') {
    return Icons.crop_din_outlined;
  }
  if (groupKind == 'unscoped') {
    return Icons.folder_off_outlined;
  }
  return switch (kind) {
    'root' => Icons.account_tree_outlined,
    'scope' => Icons.crop_free,
    'group' => Icons.folder_outlined,
    'defer' || 'deferredTarget' => Icons.low_priority,
    'layer' => Icons.layers_outlined,
    _ => Icons.touch_app_outlined,
  };
}

/// Primary label for tree rows (id shown separately as a muted suffix).
String _nodePrimaryLabel(HitNodeData data) {
  final String? label = data.label;
  if (label != null && label.isNotEmpty) {
    return label;
  }
  if (data.kind == 'root' || data.kind == 'group') {
    return '${data.payload['type'] ?? data.kind}';
  }
  if (data.id != null) {
    return _idRef(data.id);
  }
  return '${data.payload['type'] ?? data.kind}';
}

bool _isQuietGroup(HitNodeData data) {
  final Object? groupKind = data.payload['groupKind'];
  return groupKind == 'outside_scope' || groupKind == 'unscoped';
}

List<TreeViewNode<HitNodeData>> _buildTree(
  Map<String, Object?> snapshot, {
  Set<String> openQuietGroups = const <String>{},
}) {
  final Object? rawTree = snapshot['tree'];
  if (rawTree is! List || rawTree.isEmpty) {
    return const <TreeViewNode<HitNodeData>>[];
  }
  List<Map> entries = rawTree.whereType<Map>().toList();
  // Snapshot wraps scopes under a synthetic root — unwrap for the UI.
  if (entries.length == 1) {
    final Map<String, Object?> root = entries.first.cast<String, Object?>();
    if (root['kind'] == 'root') {
      final Object? children = root['children'];
      entries =
          children is List ? children.whereType<Map>().toList() : const <Map>[];
    }
  }
  return entries
      .map(
        (Map raw) => _nodeFromJson(
          raw.cast<String, Object?>(),
          expanded: true,
          openQuietGroups: openQuietGroups,
        ),
      )
      .toList();
}

TreeViewNode<HitNodeData> _nodeFromJson(
  Map<String, Object?> json, {
  bool expanded = false,
  Set<String> openQuietGroups = const <String>{},
  Object? ancestorId,
}) {
  final Object? id = (json['id'] as num?)?.toInt() ?? ancestorId;
  final Object? childrenRaw = json['children'];
  final List<TreeViewNode<HitNodeData>> children =
      <TreeViewNode<HitNodeData>>[];
  if (childrenRaw is List) {
    for (final Object? child in childrenRaw) {
      if (child is Map) {
        children.add(
          _nodeFromJson(
            child.cast<String, Object?>(),
            openQuietGroups: openQuietGroups,
            ancestorId: id,
          ),
        );
      }
    }
  }
  final String? groupKind = json['groupKind'] as String?;
  // Quiet buckets default closed; stay open without animation if the user
  // already expanded them (baked into the node, not controller.expandNode).
  final Object quietOwner = json['scopeId'] ?? ancestorId ?? 'root';
  final bool shouldExpand = switch (groupKind) {
    'outside_scope' ||
    'unscoped' =>
      openQuietGroups.contains('$quietOwner:$groupKind'),
    _ => expanded || children.isNotEmpty,
  };
  return TreeViewNode<HitNodeData>(
    HitNodeData.fromJson(json),
    expanded: shouldExpand,
    children: children,
  );
}

HitNodeData? _findDataById(List<TreeViewNode<HitNodeData>> tree, int? id) {
  return _findNodeById(tree, id)?.content;
}

TreeViewNode<HitNodeData>? _findNodeById(
  List<TreeViewNode<HitNodeData>> tree,
  int? id,
) {
  if (id == null) {
    return null;
  }
  final List<TreeViewNode<HitNodeData>> queue =
      List<TreeViewNode<HitNodeData>>.of(tree);
  while (queue.isNotEmpty) {
    final TreeViewNode<HitNodeData> node = queue.removeAt(0);
    if (node.content.id == id) {
      return node;
    }
    queue.addAll(node.children);
  }
  return null;
}

/// Case-insensitive match on label, kind, groupKind, debugLabel, or id.
bool _nodeMatchesQuery(HitNodeData data, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  if (_nodePrimaryLabel(data).toLowerCase().contains(q)) {
    return true;
  }
  if (data.kind.toLowerCase().contains(q)) {
    return true;
  }
  final String? groupKind = data.groupKind;
  if (groupKind != null && groupKind.toLowerCase().contains(q)) {
    return true;
  }
  final Object? debugLabel = data.payload['debugLabel'];
  if (debugLabel is String && debugLabel.toLowerCase().contains(q)) {
    return true;
  }
  final int? id = data.id;
  if (id != null) {
    final String idDec = '$id';
    final String idHex = id.toRadixString(16);
    final String idRef = _idRef(id).toLowerCase();
    final String bare = q.startsWith('#') ? q.substring(1) : q;
    if (idDec.contains(q) ||
        idHex.contains(bare) ||
        idRef.contains(q) ||
        _shortId(id).contains(bare)) {
      return true;
    }
  }
  return false;
}

/// Keeps matches and their ancestors; expands matching branches.
List<TreeViewNode<HitNodeData>> _filterTree(
  List<TreeViewNode<HitNodeData>> tree,
  String query,
) {
  if (query.trim().isEmpty) {
    return tree;
  }

  List<TreeViewNode<HitNodeData>> filterNodes(
    List<TreeViewNode<HitNodeData>> nodes,
  ) {
    final List<TreeViewNode<HitNodeData>> out = <TreeViewNode<HitNodeData>>[];
    for (final TreeViewNode<HitNodeData> node in nodes) {
      final List<TreeViewNode<HitNodeData>> children =
          filterNodes(node.children);
      if (_nodeMatchesQuery(node.content, query) || children.isNotEmpty) {
        out.add(
          TreeViewNode<HitNodeData>(
            node.content,
            expanded: true,
            children: children,
          ),
        );
      }
    }
    return out;
  }

  return filterNodes(tree);
}

List<String> _warningsFor(HitNodeData? selected) {
  if (selected == null) {
    return const <String>[];
  }
  final Map<String, Object?> p = selected.payload;
  final List<String> out = <String>[];
  if (p['groupKind'] == 'outside_scope') {
    out.add('Outside HitScope — taps may miss.');
  }
  if (p['outsideScope'] == true) {
    out.add('Outside HitScope — taps may miss.');
  }
  final List warnings = (p['warnings'] as List?) ?? const [];
  for (final Object? w in warnings) {
    final String warning = '$w';
    if (warning == 'overflow_without_scope') {
      out.add('Overflow without HitScope or HitLink.');
    } else if (warning.startsWith('target_outside_scope:')) {
      out.add('Deferred target outside HitScope — taps may miss.');
    } else if (warning.isNotEmpty) {
      out.add(warning);
    }
  }
  return out;
}
