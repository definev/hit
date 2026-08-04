import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';
import 'package:hit/src/hit_layer.dart';

void main() {
  tearDown(() {
    debugPaintHitAreas = false;
    debugPaintSizeEnabled = false;
  });

  testWidgets('debugPaintHitAreas notifies and enables painting flag', (
    tester,
  ) async {
    var notified = 0;
    void listener() => notified++;

    addHitDebugPaintListener(listener);
    addTearDown(() => removeHitDebugPaintListener(listener));

    expect(hitDebugPaintingEnabled, isFalse);
    debugPaintHitAreas = true;
    expect(hitDebugPaintingEnabled, isTrue);
    expect(notified, 1);

    debugPaintHitAreas = true;
    expect(notified, 1);

    debugPaintHitAreas = false;
    expect(hitDebugPaintingEnabled, isFalse);
    expect(notified, 2);
  });

  testWidgets('deferred debug leader is absent when painting disabled', (
    tester,
  ) async {
    expect(hitDebugPaintingEnabled, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const SizedBox(width: 24, height: 24),
            ),
          ),
        ),
      ),
    );

    final RenderHitLayer layer = tester.renderObject(find.byType(HitLayer));
    expect(layer.link?.contains(layer), isTrue);
    expect(layer.hitDebugLeaderLink, isNull);
    expect(layer.alwaysNeedsCompositing, isFalse);
  });

  testWidgets('debugPaintSizeEnabled also enables hit debug painting', (
    tester,
  ) async {
    expect(hitDebugPaintingEnabled, isFalse);
    debugPaintSizeEnabled = true;
    expect(hitDebugPaintingEnabled, isTrue);
    debugPaintSizeEnabled = false;
  });

  testWidgets('HitLayer with debugPaintHitAreas paints without throwing', (
    tester,
  ) async {
    debugPaintHitAreas = true;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const SizedBox(width: 24, height: 24),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final RenderHitLayer layer = tester.renderObject(find.byType(HitLayer));
    // Overflowing hitChild is deferred; debug uses a composited leader so the
    // overlay tracks paintChild through scroll / transforms.
    expect(layer.size, const Size(24, 24));
    expect(layer.link?.contains(layer), isTrue);
    expect(layer.hitDebugLeaderLink, isNotNull);

    debugPaintHitAreas = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(layer.hitDebugLeaderLink, isNull);
  });
}
