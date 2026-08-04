import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';
import 'package:hit/src/hit_layer.dart';

void main() {
  tearDown(() async {
    debugPaintHitAreas = false;
    debugPaintSizeEnabled = false;
    debugHighlightHitTargetId = null;
    debugHitSelectEnabled = false;
    WidgetInspectorService.instance.selection.clear();
  });

  testWidgets('snapshot lists HitLayer and HitScope with tree', (tester) async {
    ensureHitDevToolsInitialized();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HitScope(
              debugLabel: 'devtools-test-scope',
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: HitLayer(
                  debugLabel: 'devtools-test-layer',
                  alignment: Alignment.center,
                  behavior: HitTestBehavior.deferToChild,
                  hitChild: const SizedBox(width: 48, height: 48),
                  paintChild: const SizedBox(width: 24, height: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final Map<String, Object?> snap = collectHitDevToolsSnapshot();
    final List<Map<String, Object?>> layers = (snap['layers']! as List)
        .whereType<Map>()
        .map((Map raw) => raw.cast<String, Object?>())
        .toList();
    final List<Map<String, Object?>> scopes = (snap['scopes']! as List)
        .whereType<Map>()
        .map((Map raw) => raw.cast<String, Object?>())
        .toList();
    expect(layers, isNotEmpty);
    expect(scopes, isNotEmpty);

    final Map<String, Object?> layer = layers.firstWhere(
      (Map<String, Object?> item) {
        final num? paintW = (item['paintSize'] as Map?)?['width'] as num?;
        final num? hitW = (item['hitSize'] as Map?)?['width'] as num?;
        return paintW == 24 && hitW == 48;
      },
    );
    expect(layer['type'], 'HitLayer');
    expect(layer['debugLabel'], 'devtools-test-layer');
    expect(layer['deferred'], isTrue);
    expect(layer['linkId'], isNotNull);
    expect(
      scopes.any(
        (Map<String, Object?> s) => s['debugLabel'] == 'devtools-test-scope',
      ),
      isTrue,
    );

    final List tree = snap['tree']! as List;
    expect(tree, isNotEmpty);
    final Map<String, Object?> root =
        (tree.first as Map).cast<String, Object?>();
    expect(root['kind'], 'root');
    expect(root['label'], 'Hit-Test Areas');
    expect((root['children'] as List), isNotEmpty);
  });

  testWidgets('nested HitScopes appear under parent in tree', (tester) async {
    ensureHitDevToolsInitialized();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitScope(
            debugLabel: 'outer-scope',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: HitScope(
                debugLabel: 'inner-scope',
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HitLayer(
                    debugLabel: 'inner-layer',
                    alignment: Alignment.center,
                    behavior: HitTestBehavior.deferToChild,
                    hitChild: const SizedBox(width: 48, height: 48),
                    paintChild: const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final Map<String, Object?> snap = collectHitDevToolsSnapshot();
    final List<Map<String, Object?>> scopes = (snap['scopes']! as List)
        .whereType<Map>()
        .map((Map raw) => raw.cast<String, Object?>())
        .toList();

    final Map<String, Object?> outer = scopes.firstWhere(
      (Map<String, Object?> s) => s['debugLabel'] == 'outer-scope',
    );
    final Map<String, Object?> inner = scopes.firstWhere(
      (Map<String, Object?> s) => s['debugLabel'] == 'inner-scope',
    );
    expect(outer['parentScopeId'], isNull);
    expect(inner['parentScopeId'], (outer['id'] as num).toInt());

    final Map<String, Object?> root =
        ((snap['tree']! as List).first as Map).cast<String, Object?>();
    final List rootChildren = root['children']! as List;
    expect(rootChildren, hasLength(1));
    final Map<String, Object?> outerNode =
        (rootChildren.first as Map).cast<String, Object?>();
    expect(outerNode['debugLabel'], 'outer-scope');
    expect(outerNode['kind'], 'scope');

    final List outerChildren = outerNode['children']! as List;
    final Map<String, Object?> innerNode = outerChildren
        .whereType<Map>()
        .map((Map raw) => raw.cast<String, Object?>())
        .firstWhere((Map<String, Object?> c) => c['kind'] == 'scope');
    expect(innerNode['debugLabel'], 'inner-scope');

    final List innerChildren = innerNode['children']! as List;
    expect(
      innerChildren.whereType<Map>().any(
            (Map c) => c['debugLabel'] == 'inner-layer',
          ),
      isTrue,
    );
  });

  testWidgets('selectHitTargetAt picks the layer under the point', (
    tester,
  ) async {
    ensureHitDevToolsInitialized();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitScope(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: HitLayer(
                  debugLabel: 'select-me',
                  alignment: Alignment.center,
                  behavior: HitTestBehavior.deferToChild,
                  hitChild: const SizedBox(width: 48, height: 48),
                  paintChild: const SizedBox(width: 24, height: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final Map<String, Object?> snap = collectHitDevToolsSnapshot();
    final Map<String, Object?> layer =
        (snap['layers']! as List).first as Map<String, Object?>;
    final Map<String, Object?> global =
        layer['globalHitBounds']! as Map<String, Object?>;
    final double x = ((global['left'] as num) + (global['right'] as num)) / 2;
    final double y = ((global['top'] as num) + (global['bottom'] as num)) / 2;

    final int? id = selectHitTargetAt(Offset(x, y));
    expect(id, (layer['id'] as num).toInt());
  });

  testWidgets('inspectHitTarget selects HitLayer in Widget Inspector', (
    tester,
  ) async {
    ensureHitDevToolsInitialized();
    WidgetInspectorService.instance.selection.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitScope(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: HitLayer(
                debugLabel: 'inspect-me',
                alignment: Alignment.center,
                behavior: HitTestBehavior.deferToChild,
                hitChild: const SizedBox(width: 48, height: 48),
                paintChild: const SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );

    final RenderHitLayer layer = tester.renderObject(find.byType(HitLayer));
    final int id = identityHashCode(layer);

    expect(findHitRenderObjectById(id), same(layer));
    expect(inspectHitTarget(id), isTrue);

    final Element? selected =
        WidgetInspectorService.instance.selection.currentElement;
    expect(selected, isNotNull);
    expect(selected!.widget, isA<HitLayer>());
    expect((selected.widget as HitLayer).debugLabel, 'inspect-me');
    expect(
      WidgetInspectorService.instance.selection.current,
      same(layer),
    );
  });

  testWidgets('probe reports deferred hit inside expanded area',
      (tester) async {
    ensureHitDevToolsInitialized();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HitScope(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: HitLayer(
                  alignment: Alignment.center,
                  behavior: HitTestBehavior.deferToChild,
                  hitChild: const SizedBox(width: 48, height: 48),
                  paintChild: const SizedBox(width: 24, height: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final Map<String, Object?> snap = collectHitDevToolsSnapshot();
    final Map<String, Object?> layer =
        (snap['layers']! as List).first as Map<String, Object?>;
    final Map<String, Object?> global =
        layer['globalHitBounds']! as Map<String, Object?>;
    final double x = ((global['left'] as num) + (global['right'] as num)) / 2;
    final double y = ((global['top'] as num) + (global['bottom'] as num)) / 2;

    final Map<String, Object?> probe = probeHitAt(Offset(x, y));
    final hits = probe['hits']! as List<Object?>;
    expect(hits, isNotEmpty);
  });

  testWidgets('probe notes empty space', (tester) async {
    ensureHitDevToolsInitialized();

    await tester.pumpWidget(
      const MaterialApp(
        home: HitScope(child: SizedBox(width: 100, height: 100)),
      ),
    );

    final Map<String, Object?> probe = probeHitAt(const Offset(-1000, -1000));
    expect(probe['hits'], isEmpty);
    expect((probe['notes'] as List), isNotEmpty);
  });
}
