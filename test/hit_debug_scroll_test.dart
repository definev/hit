import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  tearDown(() {
    debugPaintHitAreas = false;
  });

  testWidgets('deferred hit debug overlay repaints when list scrolls', (
    tester,
  ) async {
    debugPaintHitAreas = true;
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          debugLabel: 'scroll-scope',
          child: ListView.builder(
            controller: controller,
            itemCount: 40,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 80,
                child: Center(
                  child: HitLayer(
                    debugLabel: 'row-$index',
                    alignment: Alignment.center,
                    behavior: HitTestBehavior.deferToChild,
                    hitChild: const SizedBox(width: 48, height: 48),
                    paintChild: Text('$index'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final Map<String, Object?> before = collectHitDevToolsSnapshot();
    final Map<String, Object?> firstBefore = _layerNamed(before, 'row-0');
    final Map<String, Object?> boundsBefore =
        firstBefore['globalHitBounds']! as Map<String, Object?>;
    final double topBefore = (boundsBefore['top'] as num).toDouble();

    controller.jumpTo(120);
    await tester.pump();

    final Map<String, Object?> after = collectHitDevToolsSnapshot();
    final Map<String, Object?> firstAfter = _layerNamed(after, 'row-0');
    final Map<String, Object?> boundsAfter =
        firstAfter['globalHitBounds']! as Map<String, Object?>;
    final double topAfter = (boundsAfter['top'] as num).toDouble();

    expect(topAfter, isNot(equals(topBefore)));
    // Snapshot uses live transforms; also ensure the scope still paints
    // after scroll (no exception / stale-only path).
    expect(tester.takeException(), isNull);
  });
}

Map<String, Object?> _layerNamed(Map<String, Object?> snap, String label) {
  final List<Map<String, Object?>> layers = (snap['layers']! as List)
      .whereType<Map>()
      .map((Map raw) => raw.cast<String, Object?>())
      .toList();
  return layers.firstWhere(
    (Map<String, Object?> item) => item['debugLabel'] == label,
  );
}
