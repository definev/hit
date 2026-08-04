part of 'main.dart';

/// Content identity for [TreeViewNode]s (equality by [id] / [kind]).
@immutable
class HitNodeData {
  const HitNodeData({
    required this.kind,
    this.id,
    this.label,
    this.payload = const <String, Object?>{},
  });

  factory HitNodeData.fromJson(Map<String, Object?> json) {
    return HitNodeData(
      kind: '${json['kind'] ?? json['type'] ?? 'node'}',
      id: (json['id'] as num?)?.toInt(),
      label: json['label'] as String? ?? json['debugLabel'] as String?,
      payload: json,
    );
  }

  final String kind;
  final int? id;
  final String? label;
  final Map<String, Object?> payload;

  bool get isSelectable =>
      kind == 'layer' || kind == 'defer' || kind == 'scope';

  String? get groupKind => payload['groupKind'] as String?;

  Object? get scopeId => payload['scopeId'];

  @override
  bool operator ==(Object other) {
    if (other is! HitNodeData) {
      return false;
    }
    if (kind != other.kind || id != other.id) {
      return false;
    }
    // Groups have no id — identity is groupKind + owning scope.
    if (kind == 'group') {
      return groupKind == other.groupKind && scopeId == other.scopeId;
    }
    if (kind == 'root') {
      return true;
    }
    return true;
  }

  @override
  int get hashCode {
    if (kind == 'group') {
      return Object.hash(kind, groupKind, scopeId);
    }
    return Object.hash(kind, id);
  }
}
