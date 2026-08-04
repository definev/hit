part of 'main.dart';

const Color _highlightYellow = Color(0xFFFFD60A);
const Color _highlightGreen = Color(0xFF30D158);
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
