import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets('HitDefer receives taps outside parent bounds', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -30,
                    child: HitDefer(
                      child: GestureDetector(
                        key: const Key('defer_btn'),
                        onTap: () => tapped = true,
                        child: const ColoredBox(
                          color: Colors.blue,
                          child: SizedBox(width: 60, height: 30),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: ColoredBox(color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('defer_btn')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HitLink clears registration after dispose', (tester) async {
    final link = HitLink();

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: HitDefer(
            link: link,
            child: const ColoredBox(
              color: Colors.blue,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(link.targets, hasLength(1));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(link.targets, isEmpty);
  });

  testWidgets(
    'HitLayer overflow hits survive scroll under HitScope',
    (tester) async {
      final taps = <int>[];
      final controller = ScrollController();

      Widget row(int index) {
        return SizedBox(
          height: 80,
          child: Align(
            alignment: Alignment.centerRight,
            child: HitLayer(
              key: Key('layer_$index'),
              alignment: Alignment.center,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps.add(index),
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const IgnorePointer(
                child: SizedBox(width: 16, height: 16),
              ),
            ),
          ),
        );
      }

      // Keep every row mounted so deferred AABBs are cached, then scroll moves
      // those transforms without laying out HitScope.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HitScope(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [for (var i = 0; i < 8; i++) row(i)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final layer0 = tester.getTopLeft(find.byKey(const Key('layer_0')));
      await tester.tapAt(layer0 + const Offset(-10, 8));
      await tester.pump();
      expect(taps, [0]);

      controller.jumpTo(400);
      await tester.pump();

      final layer6 = tester.getTopLeft(find.byKey(const Key('layer_6')));
      await tester.tapAt(layer6 + const Offset(-10, 8));
      await tester.pump();
      expect(taps, [0, 6]);
    },
  );

  testWidgets(
    'HitDefer paint onTop tracks scroll under HitScope',
    (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HitScope(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      const SizedBox(height: 120),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(
                              child: ColoredBox(color: Colors.grey),
                            ),
                            Positioned(
                              right: -10,
                              top: -10,
                              child: HitDefer(
                                paint: HitDeferPaint.onTop,
                                child: const ColoredBox(
                                  key: Key('paint_on_top'),
                                  color: Colors.red,
                                  child: SizedBox(width: 40, height: 40),
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 20,
                              child: ColoredBox(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final before = tester.getTopLeft(find.byKey(const Key('paint_on_top')));

      controller.jumpTo(80);
      await tester.pump();
      // Second paint must reuse the follower via LayerHandle (not a disposed layer).
      await tester.pump();

      final after = tester.getTopLeft(find.byKey(const Key('paint_on_top')));
      expect(after.dy, closeTo(before.dy - 80, 0.5));

      controller.jumpTo(40);
      await tester.pump();
      await tester.pump();
      final mid = tester.getTopLeft(find.byKey(const Key('paint_on_top')));
      expect(mid.dy, closeTo(before.dy - 40, 0.5));
    },
  );

  testWidgets('swapping HitScope.link migrates deferred targets', (
    tester,
  ) async {
    final linkA = HitLink();
    final linkB = HitLink();
    var useA = true;
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return HitScope(
              link: useA ? linkA : linkB,
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -30,
                        child: HitDefer(
                          child: GestureDetector(
                            key: const Key('defer_btn'),
                            onTap: () => tapped = true,
                            child: const ColoredBox(
                              color: Colors.blue,
                              child: SizedBox(width: 60, height: 30),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: TextButton(
                          key: const Key('swap'),
                          onPressed: () => setState(() => useA = !useA),
                          child: const Text('swap'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(linkA.targets, hasLength(1));
    expect(linkB.targets, isEmpty);

    await tester.tap(find.byKey(const Key('swap')));
    await tester.pump();

    expect(linkA.targets, isEmpty);
    expect(linkB.targets, hasLength(1));

    await tester.tap(find.byKey(const Key('defer_btn')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('HitScope reuses internal link when external link cleared', (
    tester,
  ) async {
    final external = HitLink();
    HitLink? provided = external;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return HitScope(
              link: provided,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HitDefer(
                      child: const ColoredBox(
                        color: Colors.blue,
                        child: SizedBox(width: 10, height: 10),
                      ),
                    ),
                    TextButton(
                      key: const Key('clear'),
                      onPressed: () => setState(() => provided = null),
                      child: const Text('clear'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(external.targets, hasLength(1));

    await tester.tap(find.byKey(const Key('clear')));
    await tester.pump();

    expect(external.targets, isEmpty);
    final internal = tester.state<HitScopeState>(find.byType(HitScope)).link;
    expect(identical(internal, external), isFalse);
    expect(internal.targets, hasLength(1));
  });
}
