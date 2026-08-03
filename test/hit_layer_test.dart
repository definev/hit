import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';
import 'package:hit/src/hit_layer.dart';

Widget _box({double w = 40, double h = 40, Color color = Colors.blue}) {
  return ColoredBox(
    color: color,
    child: SizedBox(width: w, height: h),
  );
}

void main() {
  testWidgets('HitLayer translucent puts hitChild and paintChild on hit path', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              behavior: HitTestBehavior.translucent,
              hitChild: Listener(
                key: const Key('hit'),
                onPointerDown: (_) {},
                child: _box(w: 40, h: 40, color: Colors.red),
              ),
              paintChild: Listener(
                key: const Key('paint'),
                onPointerDown: (_) {},
                child: _box(w: 20, h: 20),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    final RenderHitLayer layer = tester.renderObject(find.byType(HitLayer));
    expect(layer.size, const Size(20, 20));

    final BoxHitTestResult result = BoxHitTestResult();
    expect(layer.hitTestDeferred(result, const Offset(10, 10)), isTrue);

    final targets = result.path.map((e) => e.target).toList();
    expect(targets.whereType<RenderPointerListener>().length, 2);
  });

  testWidgets('layout follows paintChild; hitChild can be larger', (
    tester,
  ) async {
    var hitTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              alignment: Alignment.center,
              hitChild: GestureDetector(
                onTap: () => hitTapped = true,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(width: 48, height: 48),
              ),
              behavior: HitTestBehavior.deferToChild,
              paintChild: const IgnorePointer(
                child: ColoredBox(
                  color: Colors.blue,
                  child: SizedBox(width: 24, height: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.getSize(find.byType(HitLayer)), const Size(24, 24));

    final topLeft = tester.getTopLeft(find.byType(HitLayer));
    await tester.tapAt(topLeft + const Offset(-10, 12));
    await tester.pump();
    expect(hitTapped, isTrue);
  });

  testWidgets('paintChild gesture wins when both have onTap', (tester) async {
    var hitTapped = false;
    var paintTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              hitChild: GestureDetector(
                onTap: () => hitTapped = true,
                behavior: HitTestBehavior.translucent,
                child: _box(w: 80, h: 80, color: Colors.red),
              ),
              paintChild: GestureDetector(
                onTap: () => paintTapped = true,
                child: _box(w: 40, h: 40),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(HitLayer));
    await tester.pump();

    expect(paintTapped, isTrue);
    expect(hitTapped, isFalse);
  });
}
