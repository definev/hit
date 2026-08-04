import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit/hit.dart';

void main() {
  test('HitLink paint vs geometry notifications are separate', () {
    final link = HitLink();
    var paint = 0;
    var geometry = 0;
    link.addPaintListener(() => paint++);
    link.addGeometryListener(() => geometry++);

    link.markGeometryDirty();
    expect(paint, 0);
    expect(geometry, 1);

    link.descendantNeedsPaint();
    expect(paint, 1);
    expect(geometry, 1);

    link.dispose();
  });

  test('HitLink contains/add are identity-based', () {
    final link = HitLink();
    final a = _FakeTarget();
    final b = _FakeTarget();

    link.add(a);
    expect(link.contains(a), isTrue);
    expect(link.contains(b), isFalse);
    expect(link.targets, <HitDeferRegistration>[a]);

    link.add(a); // no-op
    expect(link.targets, <HitDeferRegistration>[a]);

    link.add(b);
    expect(link.targets, <HitDeferRegistration>[a, b]);

    link.remove(a);
    expect(link.contains(a), isFalse);
    expect(link.targets, <HitDeferRegistration>[b]);

    link.dispose();
  });
}

class _FakeTarget implements HitDeferRegistration {
  @override
  String? get debugLabel => null;

  @override
  RenderBox? get registeredChild => null;

  @override
  RenderBox get hitTestBox => throw UnimplementedError();

  @override
  Rect get deferredHitBounds => Rect.zero;

  @override
  bool hitTestDeferred(BoxHitTestResult result, Offset position) => false;

  @override
  HitTestBehavior get hitBehavior => HitTestBehavior.translucent;

  @override
  HitDeferPaint get deferPaint => HitDeferPaint.none;

  @override
  LayerLink? get deferredPaintLink => null;

  @override
  LayerLink? get hitDebugLeaderLink => null;
}
