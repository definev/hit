// Microbenchmark: HitLink before vs after (identity set + split notifications).
//
// Pure Dart stand-ins of the pre-1.2 and current HitLink membership/notify
// paths — no Flutter dependency so `dart run` works.
//
//   dart run benchmark/hit_link_bench.dart

// ignore_for_file: avoid_print

import 'dart:collection';
import 'dart:math' as math;

void main() {
  const sizes = <int>[8, 32, 128, 512, 2048];
  const rounds = 9;
  const ops = 80000;

  print('HitLink benchmark — best of $rounds rounds × $ops ops');
  print('');

  final rows = <_Row>[];

  for (final n in sizes) {
    final targets = List<_Target>.generate(n, (_) => _Target());
    final probe = targets[n ~/ 2];

    final oldContains = _bestUs(rounds, () {
      final link = _OldHitLink()..seed(targets);
      var sink = 0;
      for (var i = 0; i < ops; i++) {
        if (link.contains(probe)) sink++;
      }
      return sink;
    });

    final newContains = _bestUs(rounds, () {
      final link = _NewHitLink()..seed(targets);
      var sink = 0;
      for (var i = 0; i < ops; i++) {
        if (link.contains(probe)) sink++;
      }
      return sink;
    });

    final oldAddDup = _bestUs(rounds, () {
      final link = _OldHitLink()..seed(targets);
      for (var i = 0; i < ops; i++) {
        link.add(probe);
      }
      return link.length;
    });

    final newAddDup = _bestUs(rounds, () {
      final link = _NewHitLink()..seed(targets);
      for (var i = 0; i < ops; i++) {
        link.add(probe);
      }
      return link.length;
    });

    var oldPaint = 0;
    final oldGeometry = _bestUs(rounds, () {
      final link = _OldHitLink()..seed(targets);
      var paint = 0;
      link.addListener(() => paint++);
      for (var i = 0; i < ops; i++) {
        link.markGeometryDirty();
      }
      oldPaint = paint;
      return paint;
    });

    var newPaint = 0;
    final newGeometry = _bestUs(rounds, () {
      final link = _NewHitLink()..seed(targets);
      var paint = 0;
      var geometry = 0;
      link.addPaintListener(() => paint++);
      link.addGeometryListener(() => geometry++);
      for (var i = 0; i < ops; i++) {
        link.markGeometryDirty();
      }
      newPaint = paint;
      return geometry;
    });

    rows.add(
      _Row(
        n: n,
        oldContainsUs: oldContains,
        newContainsUs: newContains,
        oldAddDupUs: oldAddDup,
        newAddDupUs: newAddDup,
        oldGeometryUs: oldGeometry,
        newGeometryUs: newGeometry,
        oldPaintNotifies: oldPaint,
        newPaintNotifies: newPaint,
      ),
    );
  }

  print(
    '${'n'.padLeft(5)}  '
    '${'contains·old'.padLeft(13)}  '
    '${'contains·new'.padLeft(13)}  '
    '${'×'.padLeft(7)}  '
    '${'addDup·old'.padLeft(13)}  '
    '${'addDup·new'.padLeft(13)}  '
    '${'×'.padLeft(7)}  '
    '${'geom→paint'.padLeft(14)}',
  );
  print('-' * 104);

  for (final r in rows) {
    print(
      '${r.n.toString().padLeft(5)}  '
      '${_fmt(r.oldContainsUs).padLeft(13)}  '
      '${_fmt(r.newContainsUs).padLeft(13)}  '
      '${_ratio(r.oldContainsUs, r.newContainsUs).padLeft(7)}  '
      '${_fmt(r.oldAddDupUs).padLeft(13)}  '
      '${_fmt(r.newAddDupUs).padLeft(13)}  '
      '${_ratio(r.oldAddDupUs, r.newAddDupUs).padLeft(7)}  '
      '${'${r.oldPaintNotifies}→${r.newPaintNotifies}'.padLeft(14)}',
    );
  }

  print('');
  print('markGeometryDirty cost (old also invokes paint listeners):');
  for (final r in rows) {
    print(
      '  n=${r.n.toString().padLeft(4)}  '
      'old ${_fmt(r.oldGeometryUs).padLeft(11)}  '
      'new ${_fmt(r.newGeometryUs).padLeft(11)}  '
      '${_ratio(r.oldGeometryUs, r.newGeometryUs)}',
    );
  }
}

class _Row {
  _Row({
    required this.n,
    required this.oldContainsUs,
    required this.newContainsUs,
    required this.oldAddDupUs,
    required this.newAddDupUs,
    required this.oldGeometryUs,
    required this.newGeometryUs,
    required this.oldPaintNotifies,
    required this.newPaintNotifies,
  });

  final int n;
  final double oldContainsUs;
  final double newContainsUs;
  final double oldAddDupUs;
  final double newAddDupUs;
  final double oldGeometryUs;
  final double newGeometryUs;
  final int oldPaintNotifies;
  final int newPaintNotifies;
}

double _bestUs(int rounds, int Function() body) {
  var best = double.infinity;
  for (var r = 0; r < rounds; r++) {
    body();
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    best = math.min(best, sw.elapsedMicroseconds.toDouble());
  }
  return best;
}

String _fmt(double us) {
  if (us >= 1000) return '${(us / 1000).toStringAsFixed(2)}ms';
  return '${us.toStringAsFixed(0)}µs';
}

String _ratio(double oldUs, double newUs) {
  if (newUs <= 0) return '∞';
  return '${(oldUs / newUs).toStringAsFixed(1)}×';
}

class _Target {}

/// Pre-1.2: List.contains + unified listener.
class _OldHitLink {
  final List<_Target> _targets = <_Target>[];
  final List<void Function()> _listeners = <void Function()>[];

  int get length => _targets.length;

  void seed(List<_Target> targets) {
    _targets
      ..clear()
      ..addAll(targets);
  }

  bool contains(_Target target) => _targets.contains(target);

  void addListener(void Function() listener) => _listeners.add(listener);

  void markGeometryDirty() {
    for (final l in _listeners) {
      l();
    }
  }

  void add(_Target target) {
    if (!_targets.contains(target)) {
      _targets.add(target);
      markGeometryDirty();
    }
  }
}

/// Current: identity HashSet + split paint/geometry signals.
class _NewHitLink {
  final List<_Target> _targets = <_Target>[];
  final Set<_Target> _targetSet = HashSet<_Target>(
    equals: identical,
    hashCode: identityHashCode,
  );
  final List<void Function()> _paint = <void Function()>[];
  final List<void Function()> _geometry = <void Function()>[];

  int get length => _targets.length;

  void seed(List<_Target> targets) {
    for (final t in targets) {
      _targetSet.add(t);
      _targets.add(t);
    }
  }

  bool contains(_Target target) => _targetSet.contains(target);

  void addPaintListener(void Function() listener) => _paint.add(listener);

  void addGeometryListener(void Function() listener) => _geometry.add(listener);

  void markGeometryDirty() {
    for (final l in _geometry) {
      l();
    }
  }

  void add(_Target target) {
    if (_targetSet.add(target)) {
      _targets.add(target);
      for (final l in _paint) {
        l();
      }
    }
  }
}
