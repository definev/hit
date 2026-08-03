import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';
import 'package:hit/src/hit_layer.dart';

void main() {
  testWidgets('non-overflow HitLayer is not registered on HitLink', (
    tester,
  ) async {
    final link = HitLink();

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: Center(
            child: HitLayer(
              link: link,
              hitChild: const SizedBox(width: 20, height: 20),
              paintChild: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(link.targets, isEmpty);
  });

  testWidgets('overflow HitLayer registers; corners still tappable', (
    tester,
  ) async {
    final link = HitLink();
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: Center(
            child: HitLayer(
              link: link,
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const IgnorePointer(
                child: SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(link.targets, hasLength(1));
    expect(link.targets.single, isA<RenderHitLayer>());

    final topLeft = tester.getTopLeft(find.byType(HitLayer));
    await tester.tapAt(topLeft + const Offset(-11, -11));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('overflow HitLayer skips local hitTest (no double path)', (
    tester,
  ) async {
    final link = HitLink();

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: Center(
            child: HitLayer(
              link: link,
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {},
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const IgnorePointer(
                child: SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(link.targets, hasLength(1));
    final RenderHitLayer layer = tester.renderObject(find.byType(HitLayer));

    // Deferred delivery only — local hitTest must not also claim the point.
    expect(
      layer.hitTest(BoxHitTestResult(), position: const Offset(12, 12)),
      isFalse,
    );

    final BoxHitTestResult deferred = BoxHitTestResult();
    expect(layer.hitTestDeferred(deferred, const Offset(12, 12)), isTrue);
    expect(
      deferred.path.where((HitTestEntry e) => e.target is RenderHitLayer),
      hasLength(1),
    );
  });

  testWidgets('unregisters when hitChild no longer overflows', (tester) async {
    final link = HitLink();
    var hitSize = 48.0;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HitLayer(
                      link: link,
                      alignment: Alignment.center,
                      hitChild: SizedBox(width: hitSize, height: hitSize),
                      paintChild: const SizedBox(width: 24, height: 24),
                    ),
                    TextButton(
                      onPressed: () => setState(() => hitSize = 20),
                      child: const Text('shrink'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(link.targets, hasLength(1));

    await tester.tap(find.text('shrink'));
    await tester.pump();
    expect(link.targets, isEmpty);
  });
}
