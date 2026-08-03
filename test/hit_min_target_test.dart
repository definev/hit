import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets('paint layout 24; hit 48 corners tappable via HitScope', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              alignment: Alignment.center,
              behavior: HitTestBehavior.deferToChild,
              hitChild: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 48, height: 48),
              ),
              paintChild: const IgnorePointer(
                child: ColoredBox(
                  color: Colors.orange,
                  child: SizedBox(width: 24, height: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final layer = find.byType(HitLayer);
    expect(tester.getSize(layer), const Size(24, 24));

    final topLeft = tester.getTopLeft(layer);
    for (final Offset delta in <Offset>[
      const Offset(-11, -11),
      const Offset(35, -11),
      const Offset(-11, 35),
      const Offset(35, 35),
      const Offset(12, 12),
    ]) {
      await tester.tapAt(topLeft + delta);
      await tester.pump();
    }

    expect(taps, 5);
  });

  testWidgets('Text sits next to paint size, not hit size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HitLayer(
                  alignment: Alignment.center,
                  hitChild: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: const SizedBox(width: 48, height: 48),
                  ),
                  paintChild: const SizedBox(width: 24, height: 24),
                ),
                const Text('nearby'),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final layerRight = tester.getTopRight(find.byType(HitLayer)).dx;
    final textLeft = tester.getTopLeft(find.text('nearby')).dx;
    expect(textLeft - layerRight, lessThan(1));
    expect(tester.getSize(find.byType(HitLayer)), const Size(24, 24));
  });

  testWidgets('paintChild aligns topLeft inside larger hitChild', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: HitLayer(
              alignment: Alignment.topLeft,
              hitChild: const SizedBox(width: 48, height: 48),
              paintChild: const ColoredBox(
                key: Key('paint'),
                color: Colors.orange,
                child: SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // topLeft alignment: hit offset is (0,0), paint at origin of layout.
    final layerTopLeft = tester.getTopLeft(find.byType(HitLayer));
    final paintTopLeft = tester.getTopLeft(find.byKey(const Key('paint')));
    expect(paintTopLeft, layerTopLeft);
  });
}
