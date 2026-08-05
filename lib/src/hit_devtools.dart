import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'hit_debug.dart';
import 'hit_defer.dart';
import 'hit_layer.dart';
import 'hit_link.dart';
import 'hit_scope.dart';

/// Service extension method names used by the hit DevTools extension.
abstract final class HitDevToolsMethods {
  /// Prefix for all hit service extensions.
  static const String prefix = 'ext.hit.';

  /// Returns `{ enabled: bool }` for [debugPaintHitAreas].
  static const String getDebugPaint = '${prefix}getDebugPaint';

  /// Sets [debugPaintHitAreas]. Params: `enabled` = `"true"` / `"false"`.
  static const String setDebugPaint = '${prefix}setDebugPaint';

  /// Returns `{ enabled: bool }` for [debugHitSelectEnabled].
  static const String getSelectMode = '${prefix}getSelectMode';

  /// Sets [debugHitSelectEnabled]. Params: `enabled` = `"true"` / `"false"`.
  static const String setSelectMode = '${prefix}setSelectMode';

  /// Returns a JSON snapshot of hit layers, defers, and scopes.
  static const String getSnapshot = '${prefix}getSnapshot';

  /// Explains hit/miss at a global point. Params: `x`, `y` (logical pixels).
  static const String probe = '${prefix}probe';

  /// Highlights a target by `id` (identityHashCode). Empty `id` clears.
  static const String highlight = '${prefix}highlight';
}

/// Extension event kind posted when a hit target is selected in the app.
const String hitSelectedEventKind = 'Hit.selected';

bool _hitDevToolsInitialized = false;
bool _hitSelectRouteInstalled = false;

const Map<String, Object?> _emptyHitDevToolsSnapshot = <String, Object?>{
  'debugPaintHitAreas': false,
  'hitDebugPaintingEnabled': false,
  'selectMode': false,
  'highlightId': null,
  'layers': <Map<String, Object?>>[],
  'defers': <Map<String, Object?>>[],
  'scopes': <Map<String, Object?>>[],
  'tree': <Map<String, Object?>>[],
};

/// Registers VM service extensions used by the hit DevTools tab.
///
/// Safe to call multiple times. No-op in profile / release ([kDebugMode] is
/// false). Invoked automatically when a [HitScope], [HitLayer], or [HitDefer]
/// is created in debug mode.
void ensureHitDevToolsInitialized() {
  if (!kDebugMode) {
    return;
  }
  assert(() {
    if (_hitDevToolsInitialized) {
      return true;
    }
    _hitDevToolsInitialized = true;
    _ensureHitDebugSelectInstalled();
    _registerExtensions();
    return true;
  }());
}

void _ensureHitDebugSelectInstalled() {
  if (!kDebugMode) {
    return;
  }
  assert(() {
    if (_hitSelectRouteInstalled) {
      return true;
    }
    _hitSelectRouteInstalled = true;
    GestureBinding.instance.pointerRouter
        .addGlobalRoute(_onGlobalSelectPointer);
    return true;
  }());
}

void _onGlobalSelectPointer(PointerEvent event) {
  assert(() {
    if (!debugHitSelectEnabled) {
      return true;
    }
    if (event is! PointerDownEvent) {
      return true;
    }
    if (!hitDebugPaintingEnabled) {
      debugPaintHitAreas = true;
    }
    final int? id = selectHitTargetAt(event.position);
    if (id == null) {
      return true;
    }
    debugHighlightHitTargetId = id;
    postHitSelectedEvent(id);
    inspectHitTarget(id);
    final int pointer = event.pointer;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      GestureBinding.instance.cancelPointer(pointer);
    });
    return true;
  }());
}

void _registerExtensions() {
  // Belt-and-suspenders: never register service extensions outside debug,
  // even if this private helper is somehow reached.
  if (!kDebugMode) {
    return;
  }
  developer.registerExtension(
    HitDevToolsMethods.getDebugPaint,
    (String method, Map<String, String> params) async {
      return _ok(<String, Object?>{'enabled': debugPaintHitAreas});
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.setDebugPaint,
    (String method, Map<String, String> params) async {
      final String? raw = params['enabled'];
      if (raw == null) {
        return _invalid('Missing parameter: enabled');
      }
      debugPaintHitAreas = raw == 'true';
      return _ok(<String, Object?>{'enabled': debugPaintHitAreas});
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.getSelectMode,
    (String method, Map<String, String> params) async {
      return _ok(<String, Object?>{'enabled': debugHitSelectEnabled});
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.setSelectMode,
    (String method, Map<String, String> params) async {
      final String? raw = params['enabled'];
      if (raw == null) {
        return _invalid('Missing parameter: enabled');
      }
      debugHitSelectEnabled = raw == 'true';
      if (debugHitSelectEnabled) {
        debugPaintHitAreas = true;
      }
      return _ok(<String, Object?>{
        'enabled': debugHitSelectEnabled,
        'debugPaint': debugPaintHitAreas,
      });
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.getSnapshot,
    (String method, Map<String, String> params) async {
      return _ok(collectHitDevToolsSnapshot());
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.probe,
    (String method, Map<String, String> params) async {
      final double? x = double.tryParse(params['x'] ?? '');
      final double? y = double.tryParse(params['y'] ?? '');
      if (x == null || y == null) {
        return _invalid('Missing or invalid parameters: x, y');
      }
      return _ok(probeHitAt(Offset(x, y)));
    },
  );

  developer.registerExtension(
    HitDevToolsMethods.highlight,
    (String method, Map<String, String> params) async {
      final String? raw = params['id'];
      if (raw == null || raw.isEmpty) {
        debugHighlightHitTargetId = null;
      } else {
        debugHighlightHitTargetId = int.tryParse(raw);
      }
      // Force overlays on so the highlight is visible.
      if (debugHighlightHitTargetId != null) {
        debugPaintHitAreas = true;
      }
      postHitSelectedEvent(debugHighlightHitTargetId);
      inspectHitTarget(debugHighlightHitTargetId);
      return _ok(<String, Object?>{
        'id': debugHighlightHitTargetId,
        'enabled': debugPaintHitAreas,
      });
    },
  );
}

/// Posts a VM extension event so DevTools can jump to [id] in the tree.
@visibleForTesting
void postHitSelectedEvent(int? id) {
  assert(() {
    developer.postEvent(hitSelectedEventKind, <String, Object?>{'id': id});
    return true;
  }());
}

/// Finds the live [RenderObject] for a DevTools hit target [id], if any.
///
/// Returns `null` outside [kDebugMode] (profile / release).
@visibleForTesting
RenderObject? findHitRenderObjectById(int id) {
  if (!kDebugMode) {
    return null;
  }
  RenderObject? found;

  void visit(RenderObject node) {
    if (found != null) {
      return;
    }
    final bool isHitNode = node is RenderHitLayer ||
        node is RenderHitDefer ||
        node is RenderHitScope ||
        node is RenderSliverHitScope;
    if (isHitNode && hitDebugIdOf(node) == id) {
      found = node;
      return;
    }
    node.visitChildren(visit);
  }

  for (final RenderView view in RendererBinding.instance.renderViews) {
    visit(view);
    if (found != null) {
      break;
    }
  }
  return found;
}

/// Selects [id] in Flutter's Widget Inspector so the IDE can jump to source.
///
/// Uses [WidgetInspectorService.setSelection], which posts a `navigate`
/// [ToolEvent] with the widget creation location (the `HitLayer` /
/// `HitDefer` / `HitScope` call site) when creation tracking is enabled.
///
/// Returns whether the inspector selection changed. No-op in release builds.
@visibleForTesting
bool inspectHitTarget(int? id) {
  var didSelect = false;
  assert(() {
    if (id == null) {
      return true;
    }
    final RenderObject? target = findHitRenderObjectById(id);
    if (target == null) {
      return true;
    }
    final Object? creator = target.debugCreator;
    final Object inspectee = creator is DebugCreator ? creator.element : target;
    // Posts ToolEvent navigate for IDE jump-to-source (same path as
    // Flutter's on-device Widget Inspector).
    // ignore: invalid_use_of_protected_member
    didSelect = WidgetInspectorService.instance.setSelection(inspectee);
    return true;
  }());
  return didSelect;
}

/// Picks the most specific HitLayer / HitDefer under [globalPosition].
///
/// Prefer the smallest containing hit area (most specific target). Returns
/// `null` when nothing is under the point, or outside [kDebugMode].
@visibleForTesting
int? selectHitTargetAt(Offset globalPosition) {
  if (!kDebugMode) {
    return null;
  }
  final Map<String, Object?> snapshot = collectHitDevToolsSnapshot();
  int? bestId;
  var bestArea = double.infinity;

  void consider(Map<String, Object?> item) {
    final Object? raw = item['globalHitBounds'] ?? item['globalBounds'];
    if (raw is! Map) {
      return;
    }
    final Rect? rect = _rectFromJson(raw.cast<String, Object?>());
    if (rect == null || !rect.contains(globalPosition)) {
      return;
    }
    final double area = math.max(rect.width, 0) * math.max(rect.height, 0);
    final int? id = (item['id'] as num?)?.toInt();
    if (id == null) {
      return;
    }
    if (area < bestArea) {
      bestArea = area;
      bestId = id;
    }
  }

  for (final Object? item in snapshot['layers']! as List<Object?>) {
    consider(item! as Map<String, Object?>);
  }
  for (final Object? item in snapshot['defers']! as List<Object?>) {
    consider(item! as Map<String, Object?>);
  }
  for (final Object? item in snapshot['scopes']! as List<Object?>) {
    final Map<String, Object?> scope = item! as Map<String, Object?>;
    final Object? targets = scope['targets'];
    if (targets is! List) {
      continue;
    }
    for (final Object? t in targets) {
      if (t is Map) {
        consider(t.cast<String, Object?>());
      }
    }
  }
  return bestId;
}

developer.ServiceExtensionResponse _ok(Map<String, Object?> data) {
  return developer.ServiceExtensionResponse.result(jsonEncode(data));
}

developer.ServiceExtensionResponse _invalid(String message) {
  return developer.ServiceExtensionResponse.error(
    developer.ServiceExtensionResponse.invalidParams,
    message,
  );
}

/// Identity used in DevTools snapshots / highlight.
int hitDebugIdOf(Object object) => identityHashCode(object);

/// Collects hit-related render objects from the live tree.
///
/// Returns an empty snapshot outside [kDebugMode] so profile / release builds
/// never walk the render tree for DevTools.
@visibleForTesting
Map<String, Object?> collectHitDevToolsSnapshot() {
  if (!kDebugMode) {
    return _emptyHitDevToolsSnapshot;
  }
  final List<Map<String, Object?>> layers = <Map<String, Object?>>[];
  final List<Map<String, Object?>> defers = <Map<String, Object?>>[];
  final List<Map<String, Object?>> scopes = <Map<String, Object?>>[];

  void visit(RenderObject node) {
    if (node is RenderHitLayer && node.hasSize) {
      layers.add(_describeHitLayer(node));
    } else if (node is RenderHitDefer && node.hasSize) {
      defers.add(_describeHitDefer(node));
    } else if (node is RenderHitScope && node.hasSize) {
      scopes.add(_describeHitScope(node));
    } else if (node is RenderSliverHitScope) {
      scopes.add(_describeSliverHitScope(node));
    }
    node.visitChildren(visit);
  }

  // Prefer render views — covers multi-view and avoids depending on element
  // tree shape.
  for (final RenderView view in RendererBinding.instance.renderViews) {
    visit(view);
  }

  final List<Map<String, Object?>> tree = _buildHitTree(
    layers: layers,
    defers: defers,
    scopes: scopes,
  );

  layers.sort(_compareByScreenPosition);
  defers.sort(_compareByScreenPosition);
  scopes.sort(_compareByScreenPosition);

  return <String, Object?>{
    'debugPaintHitAreas': debugPaintHitAreas,
    'hitDebugPaintingEnabled': hitDebugPaintingEnabled,
    'selectMode': debugHitSelectEnabled,
    'highlightId': debugHighlightHitTargetId,
    'layers': layers,
    'defers': defers,
    'scopes': scopes,
    'tree': tree,
  };
}

/// Builds a hierarchical tree for the DevTools [TreeView].
///
/// Root → top-level scopes (nested scopes as children by render ancestry;
/// in-scope targets as children; out-of-scope targets under a collapsed
/// `Outside scope` group) → unscoped targets.
///
/// Sibling lists are ordered by screen position (top→bottom, then left→right),
/// except `Outside scope` / `Unscoped` groups stay first / last.
List<Map<String, Object?>> _buildHitTree({
  required List<Map<String, Object?>> layers,
  required List<Map<String, Object?>> defers,
  required List<Map<String, Object?>> scopes,
}) {
  final Map<int, Map<String, Object?>> byId = <int, Map<String, Object?>>{};
  for (final Map<String, Object?> layer in layers) {
    final int? id = (layer['id'] as num?)?.toInt();
    if (id != null) {
      byId[id] = layer;
    }
  }
  for (final Map<String, Object?> defer in defers) {
    final int? id = (defer['id'] as num?)?.toInt();
    if (id != null) {
      byId[id] = defer;
    }
  }

  final Set<int> claimed = <int>{};
  final Map<int, Map<String, Object?>> scopeById =
      <int, Map<String, Object?>>{};

  for (final Map<String, Object?> scope in scopes) {
    final int? scopeId = (scope['id'] as num?)?.toInt();
    if (scopeId == null) {
      continue;
    }
    final List<Map<String, Object?>> inScope = <Map<String, Object?>>[];
    final List<Map<String, Object?>> outside = <Map<String, Object?>>[];
    final Object? targets = scope['targets'];
    if (targets is List) {
      for (final Object? raw in targets) {
        if (raw is! Map) {
          continue;
        }
        final Map<String, Object?> target = raw.cast<String, Object?>();
        final int? id = (target['id'] as num?)?.toInt();
        if (id == null) {
          continue;
        }
        claimed.add(id);
        final Map<String, Object?> full = byId[id] ?? target;
        final bool outsideScope = target['outsideScope'] == true;
        final Map<String, Object?> node = <String, Object?>{
          ...full,
          if (target['globalHitBounds'] != null)
            'globalHitBounds': target['globalHitBounds'],
          if (target['inScopeBounds'] != null)
            'inScopeBounds': target['inScopeBounds'],
          'kind': full['type'] == 'HitDefer' ? 'defer' : 'layer',
          'outsideScope': outsideScope,
          'warnings': <String>[
            ...(((full['warnings'] as List?) ?? const [])
                .map((Object? e) => '$e')
                .where((String w) => w != 'target_outside_scope')),
          ],
        };
        if (outsideScope) {
          outside.add(node);
        } else {
          inScope.add(node);
        }
      }
    }

    inScope.sort(_compareByScreenPosition);
    outside.sort(_compareByScreenPosition);

    final List<Map<String, Object?>> children = <Map<String, Object?>>[
      if (outside.isNotEmpty)
        <String, Object?>{
          'kind': 'group',
          'groupKind': 'outside_scope',
          'scopeId': scopeId,
          'label': 'Outside scope (${outside.length})',
          'children': outside,
        },
      ...inScope,
    ];

    scopeById[scopeId] = <String, Object?>{
      ...scope,
      'kind': 'scope',
      'warnings': <String>[
        for (final Object? w in (scope['warnings'] as List?) ?? const [])
          if (!'$w'.startsWith('target_outside_scope')) '$w',
      ],
      'children': children,
    };
  }

  final List<Map<String, Object?>> rootScopes = <Map<String, Object?>>[];
  for (final Map<String, Object?> scopeNode in scopeById.values) {
    final int? parentId = (scopeNode['parentScopeId'] as num?)?.toInt();
    final Map<String, Object?>? parent =
        parentId == null ? null : scopeById[parentId];
    if (parent != null) {
      (parent['children']! as List<Map<String, Object?>>).add(scopeNode);
    } else {
      rootScopes.add(scopeNode);
    }
  }

  for (final Map<String, Object?> scopeNode in scopeById.values) {
    _sortScopeChildren(scopeNode['children']! as List<Map<String, Object?>>);
  }
  rootScopes.sort(_compareByScreenPosition);

  final List<Map<String, Object?>> orphans = <Map<String, Object?>>[
    for (final Map<String, Object?> layer in layers)
      if (!claimed.contains((layer['id'] as num?)?.toInt()))
        <String, Object?>{...layer, 'kind': 'layer'},
    for (final Map<String, Object?> defer in defers)
      if (!claimed.contains((defer['id'] as num?)?.toInt()))
        <String, Object?>{...defer, 'kind': 'defer'},
  ]..sort(_compareByScreenPosition);

  final List<Map<String, Object?>> rootChildren = <Map<String, Object?>>[
    ...rootScopes,
    if (orphans.isNotEmpty)
      <String, Object?>{
        'kind': 'group',
        'groupKind': 'unscoped',
        'scopeId': 'root',
        'label': 'Unscoped targets (${orphans.length})',
        'children': orphans,
      },
  ];

  return <Map<String, Object?>>[
    <String, Object?>{
      'kind': 'root',
      'label': 'Hit-Test Areas',
      'children': rootChildren,
    },
  ];
}

/// Keeps `Outside scope` groups first; sorts remaining siblings by position.
void _sortScopeChildren(List<Map<String, Object?>> children) {
  final List<Map<String, Object?>> groups = <Map<String, Object?>>[];
  final List<Map<String, Object?>> rest = <Map<String, Object?>>[];
  for (final Map<String, Object?> child in children) {
    if (child['kind'] == 'group') {
      groups.add(child);
    } else {
      rest.add(child);
    }
  }
  rest.sort(_compareByScreenPosition);
  children
    ..clear()
    ..addAll(groups)
    ..addAll(rest);
}

/// Top→bottom, then left→right. No registration / z-order.
int _compareByScreenPosition(Map<String, Object?> a, Map<String, Object?> b) {
  final Rect? ra = _screenRectOf(a);
  final Rect? rb = _screenRectOf(b);
  if (ra == null && rb == null) {
    return _idOf(a).compareTo(_idOf(b));
  }
  if (ra == null) {
    return 1;
  }
  if (rb == null) {
    return -1;
  }
  final int byTop = ra.top.compareTo(rb.top);
  if (byTop != 0) {
    return byTop;
  }
  final int byLeft = ra.left.compareTo(rb.left);
  if (byLeft != 0) {
    return byLeft;
  }
  return _idOf(a).compareTo(_idOf(b));
}

Rect? _screenRectOf(Map<String, Object?> item) {
  final Object? raw = item['globalHitBounds'] ??
      item['globalBounds'] ??
      item['globalPaintBounds'] ??
      item['inScopeBounds'];
  if (raw is! Map) {
    return null;
  }
  return _rectFromJson(raw.cast<String, Object?>());
}

int _idOf(Map<String, Object?> item) => (item['id'] as num?)?.toInt() ?? 0;

Map<String, Object?> _describeHitLayer(RenderHitLayer layer) {
  final Size paintSize = layer.paintRenderChild?.size ?? layer.size;
  final Size? hitSize = layer.hitRenderChild?.size;
  final Rect hitBounds = layer.deferredHitBounds;
  final Rect? globalHit = _globalRect(layer, hitBounds);
  final Rect? globalPaint = _globalRect(layer, Offset.zero & paintSize);
  final bool deferred = layer.link != null && layer.link!.contains(layer);
  final List<String> warnings = <String>[];
  if (layer.link == null &&
      hitSize != null &&
      (hitBounds.left < 0 ||
          hitBounds.top < 0 ||
          hitBounds.right > layer.size.width ||
          hitBounds.bottom > layer.size.height)) {
    warnings.add('overflow_without_scope');
  }
  return <String, Object?>{
    'id': hitDebugIdOf(layer),
    'type': 'HitLayer',
    'debugLabel': layer.debugLabel,
    'deferred': deferred,
    'behavior': layer.hitBehavior.name,
    'paintSize': _sizeJson(paintSize),
    'hitSize': hitSize == null ? null : _sizeJson(hitSize),
    'hitBounds': _rectJson(hitBounds),
    'globalHitBounds': globalHit == null ? null : _rectJson(globalHit),
    'globalPaintBounds': globalPaint == null ? null : _rectJson(globalPaint),
    'linkId': layer.link == null ? null : hitDebugIdOf(layer.link!),
    'warnings': warnings,
  };
}

Map<String, Object?> _describeHitDefer(RenderHitDefer defer) {
  final Rect hitBounds = defer.deferredHitBounds;
  final Rect? globalHit = _globalRect(defer, hitBounds);
  return <String, Object?>{
    'id': hitDebugIdOf(defer),
    'type': 'HitDefer',
    'debugLabel': defer.debugLabel,
    'deferred': true,
    'behavior': defer.hitBehavior.name,
    'paint': defer.deferPaint.name,
    'size': _sizeJson(defer.size),
    'hitBounds': _rectJson(hitBounds),
    'globalHitBounds': globalHit == null ? null : _rectJson(globalHit),
    'linkId': hitDebugIdOf(defer.link),
    'warnings': const <String>[],
  };
}

Map<String, Object?> _describeHitScope(RenderHitScope scope) {
  final Rect global = _globalRect(scope, Offset.zero & scope.size) ??
      (Offset.zero & scope.size);
  final List<Map<String, Object?>> targets = <Map<String, Object?>>[];
  final List<String> warnings = <String>[];
  scope.link.forEach((HitDeferRegistration target) {
    final Rect local = target.deferredHitBounds;
    final Matrix4 transform = target.hitTestBox.getTransformTo(scope);
    final Rect inScope = MatrixUtils.transformRect(transform, local);
    final Rect? globalHit = _globalRect(scope, inScope);
    final bool outside = inScope.left < 0 ||
        inScope.top < 0 ||
        inScope.right > scope.size.width ||
        inScope.bottom > scope.size.height;
    final String targetRef = _debugRef(target.debugLabel, hitDebugIdOf(target));
    if (outside) {
      warnings.add('target_outside_scope:$targetRef');
    }
    targets.add(<String, Object?>{
      'id': hitDebugIdOf(target),
      'debugLabel': target.debugLabel,
      'inScopeBounds': _rectJson(inScope),
      'globalHitBounds': globalHit == null ? null : _rectJson(globalHit),
      'outsideScope': outside,
      'behavior': target.hitBehavior.name,
      'deferPaint': target.deferPaint.name,
    });
  });
  return <String, Object?>{
    'id': hitDebugIdOf(scope),
    'type': 'HitScope',
    'debugLabel': scope.debugLabel,
    'parentScopeId': _parentScopeIdOf(scope),
    'size': _sizeJson(scope.size),
    'globalBounds': _rectJson(global),
    'linkId': hitDebugIdOf(scope.link),
    'targetCount': targets.length,
    'targets': targets,
    'warnings': warnings,
  };
}

Map<String, Object?> _describeSliverHitScope(RenderSliverHitScope scope) {
  final List<Map<String, Object?>> targets = <Map<String, Object?>>[];
  scope.link.forEach((HitDeferRegistration target) {
    targets.add(<String, Object?>{
      'id': hitDebugIdOf(target),
      'debugLabel': target.debugLabel,
      'behavior': target.hitBehavior.name,
      'deferPaint': target.deferPaint.name,
    });
  });
  return <String, Object?>{
    'id': hitDebugIdOf(scope),
    'type': 'SliverHitScope',
    'debugLabel': scope.debugLabel,
    'parentScopeId': _parentScopeIdOf(scope),
    'linkId': hitDebugIdOf(scope.link),
    'targetCount': targets.length,
    'targets': targets,
    'geometryPaintExtent': scope.geometry?.paintExtent,
    'geometryHitTestExtent': scope.geometry?.hitTestExtent,
    'warnings': const <String>[],
  };
}

/// Nearest enclosing [RenderHitScope] / [RenderSliverHitScope], if any.
int? _parentScopeIdOf(RenderObject node) {
  RenderObject? parent = node.parent;
  while (parent != null) {
    if (parent is RenderHitScope || parent is RenderSliverHitScope) {
      return hitDebugIdOf(parent);
    }
    parent = parent.parent;
  }
  return null;
}

String _debugRef(String? label, int id) {
  if (label == null || label.isEmpty) {
    return '#$id';
  }
  return '$label (#$id)';
}

/// Explains what would happen for a pointer at [globalPosition].
///
/// Returns an empty probe result outside [kDebugMode].
@visibleForTesting
Map<String, Object?> probeHitAt(Offset globalPosition) {
  if (!kDebugMode) {
    return <String, Object?>{
      'x': globalPosition.dx,
      'y': globalPosition.dy,
      'hits': const <Map<String, Object?>>[],
      'notes': const <String>[],
    };
  }
  final Map<String, Object?> snapshot = collectHitDevToolsSnapshot();
  final List<Map<String, Object?>> hits = <Map<String, Object?>>[];
  final List<String> notes = <String>[];

  void consider(Map<String, Object?> item, String kind) {
    final Object? raw = item['globalHitBounds'] ?? item['globalBounds'];
    if (raw is! Map) {
      return;
    }
    final Rect? rect = _rectFromJson(raw.cast<String, Object?>());
    if (rect == null || !rect.contains(globalPosition)) {
      return;
    }
    hits.add(<String, Object?>{
      'kind': kind,
      'id': item['id'],
      'type': item['type'],
      'debugLabel': item['debugLabel'],
      'deferred': item['deferred'],
      'warnings': item['warnings'],
    });
  }

  for (final Object? item in snapshot['layers']! as List<Object?>) {
    consider(item! as Map<String, Object?>, 'layer');
  }
  for (final Object? item in snapshot['defers']! as List<Object?>) {
    consider(item! as Map<String, Object?>, 'defer');
  }
  for (final Object? item in snapshot['scopes']! as List<Object?>) {
    final Map<String, Object?> scope = item! as Map<String, Object?>;
    consider(scope, 'scope');
    final Object? targets = scope['targets'];
    if (targets is List) {
      for (final Object? t in targets) {
        if (t is! Map) {
          continue;
        }
        final Map<String, Object?> target = t.cast<String, Object?>();
        final Object? raw = target['globalHitBounds'];
        if (raw is! Map) {
          continue;
        }
        final Rect? rect = _rectFromJson(raw.cast<String, Object?>());
        if (rect != null && rect.contains(globalPosition)) {
          hits.add(<String, Object?>{
            'kind': 'deferredTarget',
            'id': target['id'],
            'debugLabel': target['debugLabel'],
            'scopeId': scope['id'],
            'scopeDebugLabel': scope['debugLabel'],
            'outsideScope': target['outsideScope'],
            'behavior': target['behavior'],
          });
          if (target['outsideScope'] == true) {
            final String targetRef = _debugRef(
              target['debugLabel'] as String?,
              (target['id'] as num).toInt(),
            );
            final String scopeRef = _debugRef(
              scope['debugLabel'] as String?,
              (scope['id'] as num).toInt(),
            );
            notes.add(
              'Deferred target $targetRef contains the point but its '
              'AABB extends outside scope $scopeRef — taps may miss if '
              'the pointer never enters the scope layout box.',
            );
          }
        }
      }
    }
  }

  // Common miss diagnoses when nothing hittable claimed the point.
  if (hits.isEmpty) {
    notes.add(
      'No HitLayer / HitDefer / HitScope hit area contains this point.',
    );
  } else {
    final bool onlyScope =
        hits.every((Map<String, Object?> h) => h['kind'] == 'scope');
    if (onlyScope) {
      notes.add(
        'Point is inside a HitScope layout box but not inside any registered '
        'deferred hit area.',
      );
    }
    for (final Map<String, Object?> h in hits) {
      final Object? warnings = h['warnings'];
      if (warnings is List && warnings.contains('overflow_without_scope')) {
        final String ref = _debugRef(
          h['debugLabel'] as String?,
          (h['id'] as num).toInt(),
        );
        notes.add(
          'HitLayer $ref overflows without a HitScope/link — overflow '
          'regions are not hittable.',
        );
      }
    }
  }

  return <String, Object?>{
    'x': globalPosition.dx,
    'y': globalPosition.dy,
    'hits': hits,
    'notes': notes,
  };
}

Rect? _globalRect(RenderObject box, Rect local) {
  if (box is! RenderBox || !box.hasSize || !box.attached) {
    return null;
  }
  try {
    final Offset topLeft = box.localToGlobal(local.topLeft);
    final Offset bottomRight = box.localToGlobal(local.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  } catch (_) {
    return null;
  }
}

Map<String, Object?> _sizeJson(Size size) => <String, Object?>{
      'width': size.width,
      'height': size.height,
    };

Map<String, Object?> _rectJson(Rect rect) => <String, Object?>{
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
      'width': rect.width,
      'height': rect.height,
    };

Rect? _rectFromJson(Map<String, Object?> json) {
  final double? left = (json['left'] as num?)?.toDouble();
  final double? top = (json['top'] as num?)?.toDouble();
  final double? right = (json['right'] as num?)?.toDouble();
  final double? bottom = (json['bottom'] as num?)?.toDouble();
  if (left == null || top == null || right == null || bottom == null) {
    return null;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}
