import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets('deferred translucent hit still reaches subtree sibling', (
    tester,
  ) async {
    var deferredDown = false;
    var panelDown = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: (_) => panelDown = true,
                      child: const ColoredBox(color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Hit.defer(
                      child: Listener(
                        key: const Key('deferred'),
                        onPointerDown: (_) => deferredDown = true,
                        child: const ColoredBox(
                          color: Colors.blue,
                          child: SizedBox(width: 40, height: 40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byKey(const Key('deferred'))));
    await tester.pump();

    expect(deferredDown, isTrue);
    expect(panelDown, isTrue);
  });
}
