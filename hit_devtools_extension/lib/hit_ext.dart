/// Protocol shared with `package:hit` service extensions.
///
/// Kept as string constants so this web app does not depend on `package:hit`.
abstract final class HitExt {
  static const String getDebugPaint = 'ext.hit.getDebugPaint';
  static const String setDebugPaint = 'ext.hit.setDebugPaint';
  static const String getSelectMode = 'ext.hit.getSelectMode';
  static const String setSelectMode = 'ext.hit.setSelectMode';
  static const String getProbeMode = 'ext.hit.getProbeMode';
  static const String setProbeMode = 'ext.hit.setProbeMode';
  static const String getSnapshot = 'ext.hit.getSnapshot';
  static const String highlight = 'ext.hit.highlight';

  /// VM extension event posted when the app selects a hit target.
  static const String selectedEvent = 'Hit.selected';

  /// VM extension event posted when the app probes a point.
  static const String probedEvent = 'Hit.probed';
}
