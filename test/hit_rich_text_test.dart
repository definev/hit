import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets(
    'HitLayer inside Text.rich WidgetSpan keeps tight layout; overflow taps',
    (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HitScope(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Ping '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
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
                        const TextSpan(text: ' inline.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final layer = find.byType(HitLayer);
      expect(layer, findsOneWidget);
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
    },
  );
}
