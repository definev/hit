part of 'main.dart';

const Color _highlightYellow = Color(0xFFFFD60A);
const Color _selectionBlue = Color(0xFF0A84FF);

/// Short hex suffix for identity hashes in UI (selection still uses full id).
String _shortId(int id) {
  final int short = id & 0xFFFFF;
  return short.toRadixString(16).padLeft(5, '0');
}

String _idRef(int? id) => id == null ? '' : '#${_shortId(id)}';

Map<String, Object?> _jsonMap(Map<String, dynamic>? json) {
  if (json == null) {
    return <String, Object?>{};
  }
  return Map<String, Object?>.from(json);
}

/// VM extension payloads sometimes stringify values — coerce carefully.
bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value == 'true';
  }
  return false;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

/// Deep-normalize a [Hit.probed] extension payload for the Probe panel.
Map<String, Object?> _normalizeProbeResult(Map<String, Object?> raw) {
  final Object? hitsRaw = raw['hits'];
  final List<Map<String, Object?>> hits = <Map<String, Object?>>[];
  if (hitsRaw is List) {
    for (final Object? item in hitsRaw) {
      if (item is Map) {
        final Map<String, Object?> hit = Map<String, Object?>.from(item);
        hits.add(<String, Object?>{
          ...hit,
          'id': _asInt(hit['id']),
          'winner': _asBool(hit['winner']),
          'inHitPath': _asBool(hit['inHitPath']),
          'deferred': _asBool(hit['deferred']),
          'outsideScope': _asBool(hit['outsideScope']),
        });
      }
    }
  }
  return <String, Object?>{
    ...raw,
    'x': _asDouble(raw['x']),
    'y': _asDouble(raw['y']),
    'winnerId': _asInt(raw['winnerId']),
    'hits': hits,
    'notes': raw['notes'] is List
        ? <String>[for (final Object? n in raw['notes']! as List) '$n']
        : const <String>[],
  };
}

String _num(Object value) {
  if (value is num) {
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(1);
  }
  return '$value';
}

String _sizeLabel(Object? raw) {
  if (raw is! Map) {
    return '—';
  }
  final Object? w = raw['width'];
  final Object? h = raw['height'];
  if (w == null || h == null) {
    return '—';
  }
  return '${_num(w)}×${_num(h)}';
}

String _boundsLabel(Object? raw) {
  if (raw is! Map) {
    return '—';
  }
  final double? left = (raw['left'] as num?)?.toDouble();
  final double? top = (raw['top'] as num?)?.toDouble();
  final double? width = (raw['width'] as num?)?.toDouble();
  final double? height = (raw['height'] as num?)?.toDouble();
  if (left == null || top == null || width == null || height == null) {
    return '—';
  }
  return 'x: ${_num(left)}, y: ${_num(top)}, w: ${_num(width)}, h: ${_num(height)}';
}
