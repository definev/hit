import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  testWidgets('Hit.before receives taps outside parent bounds', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                        child: ColoredBox(color: Colors.green)),
                    Positioned(
                      bottom: -30,
                      child: Hit.before(
                        behavior: HitTestBehavior.opaque,
                        child: GestureDetector(
                          key: const Key('before_btn'),
                          onTap: () => tapped = true,
                          child: const ColoredBox(
                            color: Colors.blue,
                            child: SizedBox(width: 60, height: 30),
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
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('before_btn')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('nested HitScope: nearest scope delivers deferred hit', (
    tester,
  ) async {
    final outerLink = HitLink();
    final innerLink = HitLink();
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: outerLink,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: HitScope(
              link: innerLink,
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Hit.defer(
                          behavior: HitTestBehavior.opaque,
                          child: GestureDetector(
                            key: const Key('nested_badge'),
                            onTap: () => tapped = true,
                            child: const ColoredBox(
                              color: Colors.red,
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
        ),
      ),
    );
    await tester.pump();

    expect(innerLink.targets, hasLength(1));
    expect(outerLink.targets, isEmpty);

    await tester.tap(find.byKey(const Key('nested_badge')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('explicit HitLink registers with outer scope past nearer one', (
    tester,
  ) async {
    final outerLink = HitLink();
    final innerLink = HitLink();
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: outerLink,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: HitScope(
              link: innerLink,
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Hit.defer(
                          link: outerLink,
                          behavior: HitTestBehavior.opaque,
                          child: GestureDetector(
                            key: const Key('outer_badge'),
                            onTap: () => tapped = true,
                            child: const ColoredBox(
                              color: Colors.red,
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
        ),
      ),
    );
    await tester.pump();

    expect(outerLink.targets, hasLength(1));
    expect(innerLink.targets, isEmpty);

    await tester.tap(find.byKey(const Key('outer_badge')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('deferred opaque hit skips scoped subtree sibling', (
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
                      behavior: HitTestBehavior.opaque,
                      child: Listener(
                        key: const Key('deferred_opaque'),
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
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('deferred_opaque'))),
    );
    await tester.pump();

    expect(deferredDown, isTrue);
    expect(panelDown, isFalse);
  });

  testWidgets('HitScope.of throws FlutterError without ancestor', (
    tester,
  ) async {
    Object? caught;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            try {
              HitScope.of(context);
            } catch (e) {
              caught = e;
            }
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(caught, isA<FlutterError>());
    expect(
      caught.toString(),
      contains('does not contain a HitScope'),
    );
  });

  testWidgets('HitScope.maybeOf returns null without ancestor', (tester) async {
    HitScopeState? state;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            state = HitScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(state, isNull);
  });

  testWidgets('HitScope.maybeOf returns nearest scope state', (tester) async {
    HitScopeState? state;
    final link = HitLink();

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          link: link,
          child: Builder(
            builder: (context) {
              state = HitScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(state, isNotNull);
    expect(identical(state!.link, link), isTrue);
  });

  testWidgets('ClipRect above scope blocks overflow taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ClipRect(
            child: SizedBox(
              width: 100,
              height: 100,
              child: HitScope(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -20,
                      top: 30,
                      child: Hit.defer(
                        behavior: HitTestBehavior.opaque,
                        child: GestureDetector(
                          key: const Key('clipped_badge'),
                          onTap: () => tapped = true,
                          child: const ColoredBox(
                            color: Colors.red,
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
      ),
    );
    await tester.pump();

    // Badge hangs past the right edge of the 100x100 clip; that point is
    // outside the ClipRect's hit box so the walk never reaches HitScope.
    final badgeTopLeft =
        tester.getTopLeft(find.byKey(const Key('clipped_badge')));
    await tester.tapAt(badgeTopLeft + const Offset(30, 20));
    await tester.pump();

    expect(tapped, isFalse);
  });

  testWidgets('Hit.defer remains tappable under Transform.translate', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: Transform.translate(
              offset: const Offset(40, 60),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Hit.defer(
                          behavior: HitTestBehavior.opaque,
                          child: GestureDetector(
                            key: const Key('transformed_badge'),
                            onTap: () => tapped = true,
                            child: const ColoredBox(
                              color: Colors.orange,
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
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('transformed_badge')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('overflow HitLayer remains tappable under Transform.translate', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HitScope(
          child: Center(
            child: Transform.translate(
              offset: const Offset(30, 50),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: HitLayer(
                  alignment: Alignment.center,
                  behavior: HitTestBehavior.deferToChild,
                  hitChild: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped = true,
                    child: const SizedBox(width: 48, height: 48),
                  ),
                  paintChild: const IgnorePointer(
                    child: SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final topLeft = tester.getTopLeft(find.byType(HitLayer));
    await tester.tapAt(topLeft + const Offset(-10, -10));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
