import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets('SliverHitScope delivers Hit.defer taps outside parent bounds', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverHitScope(
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: -30,
                              child: Hit.defer(
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
                            const Positioned.fill(
                              child: ColoredBox(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('defer_btn')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets(
    'HitLayer overflow hits survive scroll under SliverHitScope',
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverHitScope(
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (var i = 0; i < 8; i++) row(i),
                      ]),
                    ),
                  ),
                ],
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

  testWidgets('HitScope.of resolves SliverHitScope', (tester) async {
    HitScopeHandle? handle;
    final link = HitLink();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: [
            SliverHitScope(
              link: link,
              sliver: SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    handle = HitScope.maybeOf(context);
                    return const SizedBox(height: 10);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(handle, isA<SliverHitScopeState>());
    expect(identical(handle!.link, link), isTrue);
  });

  testWidgets(
    'Hit.defer paintOnTop tracks scroll under SliverHitScope',
    (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverHitScope(
                    sliver: SliverToBoxAdapter(
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
                                  child: Hit.defer(
                                    paintOnTop: true,
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
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final before = tester.getTopLeft(find.byKey(const Key('paint_on_top')));

      controller.jumpTo(80);
      await tester.pump();
      await tester.pump();

      final after = tester.getTopLeft(find.byKey(const Key('paint_on_top')));
      expect(after.dy, closeTo(before.dy - 80, 0.5));
    },
  );
}
