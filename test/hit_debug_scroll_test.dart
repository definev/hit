import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';
import 'package:hit/src/hit_layer.dart';

void main() {
  tearDown(() {
    debugPaintHitAreas = false;
  });

  testWidgets(
    'deferred hit debug leader tracks scroll without scope scroll listeners',
    (tester) async {
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
                      // Larger than paint so the layer defers and uses a
                      // debug LeaderLayer (Follower lives on HitScope).
                      hitChild: const SizedBox(width: 120, height: 60),
                      paintChild: const SizedBox(width: 24, height: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final RenderHitLayer layer = tester.renderObject(
        find.byWidgetPredicate(
          (Widget w) => w is HitLayer && w.debugLabel == 'row-0',
        ),
      );
      expect(layer.hitDebugLeaderLink, isNotNull);

      final Map<String, Object?> before = collectHitDevToolsSnapshot();
      final Map<String, Object?> firstBefore = _layerNamed(before, 'row-0');
      final Map<String, Object?> boundsBefore =
          firstBefore['globalHitBounds']! as Map<String, Object?>;
      final double topBefore = (boundsBefore['top'] as num).toDouble();

      controller.jumpTo(120);
      await tester.pump();

      // Live transforms update on scroll; Leader/Follower keep overlays glued
      // without HitScope scroll NotificationListener / ScrollPosition hooks.
      expect(layer.attached, isTrue);
      expect(layer.hitDebugLeaderLink, isNotNull);
      final Map<String, Object?> after = collectHitDevToolsSnapshot();
      final Map<String, Object?> firstAfter = _layerNamed(after, 'row-0');
      final Map<String, Object?> boundsAfter =
          firstAfter['globalHitBounds']! as Map<String, Object?>;
      final double topAfter = (boundsAfter['top'] as num).toDouble();

      expect(topAfter, isNot(equals(topBefore)));
      expect(tester.takeException(), isNull);
    },
  );
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
