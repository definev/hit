part of '../main.dart';

/// Amazon / Docs-style safe-triangle cascading menu via [HitDefer] + [MouseRegion].
///
/// The tip tracks the cursor; the base is the submenu edge. Crossing the
/// triangle does not immediately steal the open submenu — but lingering on
/// another ▶ (~380ms) switches. Leaving the menu into empty space does **not**
/// collapse depth (Docs keeps it open until click-away or another hover).
class _CascadingMenuDemo extends StatefulWidget {
  const _CascadingMenuDemo({
    required this.useHit,
    required this.showHitArea,
    required this.onPick,
  });

  final bool useHit;
  final bool showHitArea;
  final ValueChanged<String> onPick;

  @override
  State<_CascadingMenuDemo> createState() => _CascadingMenuDemoState();
}

class _MenuNode {
  const _MenuNode(this.label, [this.children]);

  final String label;
  final List<_MenuNode>? children;

  bool get isSubmenu => children != null && children!.isNotEmpty;
}

class _CascadingMenuDemoState extends State<_CascadingMenuDemo> {
  static const List<_MenuNode> _root = [
    _MenuNode('About'),
    _MenuNode('Show Message'),
    _MenuNode('Background Color', [
      _MenuNode('Red Background'),
      _MenuNode('Green Background'),
      _MenuNode('Blue Background'),
    ]),
    _MenuNode('More', [
      _MenuNode('Copy Link'),
      _MenuNode('Share', [_MenuNode('Messages'), _MenuNode('Mail')]),
      _MenuNode('Delete'),
    ]),
  ];

  final LayerLink _link = LayerLink();

  /// Keys for each open panel (root = 0, first submenu = 1, …).
  final List<GlobalKey> _panelKeys = [GlobalKey()];

  /// Keys for the open anchor row at each depth that has a submenu open.
  final List<GlobalKey> _anchorRowKeys = [];

  /// Full-screen overlay stack — triangle coordinate space.
  final GlobalKey _overlayStackKey = GlobalKey();

  OverlayEntry? _overlay;

  /// Open submenu index at each depth. Empty = root panel only.
  List<int> _path = [];

  /// Cursor position (global). Drives the triangle tip.
  final ValueNotifier<Offset?> _pointerGlobal = ValueNotifier<Offset?>(null);

  /// Previous pointer — apex for "still inside triangle?" steal checks.
  /// (Tip-at-cursor would make contains(cursor) always true.)
  Offset? _lastPointerGlobal;

  /// Expand the submenu base so grazing an expandable sibling while aiming
  /// at the submenu still counts as inside the safe zone.
  static const double _safePad = 12;

  /// Linger on another row inside the triangle before stealing (Docs-style).
  static const Duration _hoverIntentDelay = Duration(milliseconds: 380);

  Timer? _hoverIntentTimer;
  (int depth, int index)? _pendingHoverIntent;

  bool get _isOpen => _overlay != null;

  @override
  void dispose() {
    _cancelHoverIntent();
    _overlay?.remove();
    _overlay = null;
    _pointerGlobal.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CascadingMenuDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useHit != widget.useHit ||
        oldWidget.showHitArea != widget.showHitArea) {
      _overlay?.markNeedsBuild();
    }
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _path = [];
    _pointerGlobal.value = null;
    _lastPointerGlobal = null;
    _syncKeys();
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _cancelHoverIntent();
    _overlay?.remove();
    _overlay = null;
    _path = [];
    _pointerGlobal.value = null;
    _lastPointerGlobal = null;
    if (mounted) setState(() {});
  }

  void _cancelHoverIntent() {
    _hoverIntentTimer?.cancel();
    _hoverIntentTimer = null;
    _pendingHoverIntent = null;
  }

  void _scheduleHoverIntent({
    required int depth,
    required int index,
    required VoidCallback apply,
  }) {
    final target = (depth, index);
    if (_pendingHoverIntent == target && _hoverIntentTimer != null) {
      return;
    }
    _cancelHoverIntent();
    _pendingHoverIntent = target;
    _hoverIntentTimer = Timer(_hoverIntentDelay, () {
      _hoverIntentTimer = null;
      _pendingHoverIntent = null;
      if (!mounted || !_isOpen) return;
      apply();
    });
  }

  void _syncKeys() {
    final panelsNeeded = _path.length + 1;
    while (_panelKeys.length < panelsNeeded) {
      _panelKeys.add(GlobalKey());
    }
    if (_panelKeys.length > panelsNeeded) {
      _panelKeys.removeRange(panelsNeeded, _panelKeys.length);
    }

    final rowsNeeded = _path.length;
    while (_anchorRowKeys.length < rowsNeeded) {
      _anchorRowKeys.add(GlobalKey());
    }
    if (_anchorRowKeys.length > rowsNeeded) {
      _anchorRowKeys.removeRange(rowsNeeded, _anchorRowKeys.length);
    }
  }

  void _setPath(List<int> path) {
    if (_listEquals(path, _path)) return;
    _cancelHoverIntent();
    _path = path;
    _syncKeys();
    _overlay?.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlay?.markNeedsBuild();
      _pointerGlobal.value = _pointerGlobal.value;
    });
  }

  void _pick(String label) {
    widget.onPick(label);
    _close();
  }

  void _onPointer(Offset global) {
    final previous = _pointerGlobal.value;
    _pointerGlobal.value = global;
    _lastPointerGlobal = previous ?? global;
  }

  /// Trapezoid in global coords: open-row right edge → submenu left edge.
  Path? _bridgePathGlobal(int depth) {
    if (depth < 0 || depth >= _anchorRowKeys.length) return null;
    if (depth + 1 >= _panelKeys.length) return null;

    final rowBox =
        _anchorRowKeys[depth].currentContext?.findRenderObject() as RenderBox?;
    final subBox =
        _panelKeys[depth + 1].currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null ||
        !rowBox.hasSize ||
        subBox == null ||
        !subBox.hasSize) {
      return null;
    }

    final rowTR = rowBox.localToGlobal(Offset(rowBox.size.width, 0));
    final rowBR = rowBox.localToGlobal(
      Offset(rowBox.size.width, rowBox.size.height),
    );
    final subTL = subBox.localToGlobal(Offset.zero);
    final subBL = subBox.localToGlobal(Offset(0, subBox.size.height));

    return Path()
      ..moveTo(rowTR.dx, rowTR.dy)
      ..lineTo(subTL.dx, subTL.dy)
      ..lineTo(subBL.dx, subBL.dy)
      ..lineTo(rowBR.dx, rowBR.dy)
      ..close();
  }

  /// Cursor→submenu triangle with a padded base (global coords).
  Path? _cursorTriangleGlobal(int depth, Offset apex) {
    if (depth + 1 >= _panelKeys.length) return null;
    final subBox =
        _panelKeys[depth + 1].currentContext?.findRenderObject() as RenderBox?;
    if (subBox == null || !subBox.hasSize) return null;

    final rawTL = subBox.localToGlobal(Offset.zero);
    final rawBL = subBox.localToGlobal(Offset(0, subBox.size.height));
    // Outset the base so the zone still covers while grazing siblings.
    final subTL = Offset(rawTL.dx - 4, rawTL.dy - _safePad);
    final subBL = Offset(rawBL.dx - 4, rawBL.dy + _safePad);

    return Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(subTL.dx, subTL.dy)
      ..lineTo(subBL.dx, subBL.dy)
      ..close();
  }

  /// True when [point] lies in the padded triangle from [apex] for [depth].
  bool _stillInSafeTriangle({
    required int depth,
    required Offset apex,
    required Offset point,
  }) {
    final triangle = _cursorTriangleGlobal(depth, apex);
    if (triangle != null && triangle.contains(point)) return true;
    final bridge = _bridgePathGlobal(depth);
    return bridge != null && bridge.contains(point);
  }

  /// Paint the triangle only for the deepest open level, and only while the
  /// cursor is still in that level's row / bridge / submenu neighborhood.
  bool _shouldShowDeepestTriangle(Offset? pointer) {
    if (pointer == null || _path.isEmpty) return false;
    final depth = _path.length - 1;
    if (depth < 0 ||
        depth >= _anchorRowKeys.length ||
        depth + 1 >= _panelKeys.length) {
      return false;
    }

    if (_overKeyBounds(_anchorRowKeys[depth], pointer, pad: _safePad)) {
      return true;
    }
    if (_overKeyBounds(_panelKeys[depth + 1], pointer, pad: _safePad)) {
      return true;
    }
    final bridge = _bridgePathGlobal(depth);
    if (bridge != null && bridge.contains(pointer)) return true;

    // Corridor AABB (row ∪ submenu), slightly inflated — outside → hide.
    final bounds = _deepestCorridorBounds(depth);
    return bounds != null && bounds.inflate(_safePad * 2).contains(pointer);
  }

  bool _overKeyBounds(GlobalKey key, Offset global, {double pad = 0}) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.inflate(pad).contains(global);
  }

  Rect? _deepestCorridorBounds(int depth) {
    final rowBox =
        _anchorRowKeys[depth].currentContext?.findRenderObject() as RenderBox?;
    final subBox =
        _panelKeys[depth + 1].currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null ||
        !rowBox.hasSize ||
        subBox == null ||
        !subBox.hasSize) {
      return null;
    }
    final row = rowBox.localToGlobal(Offset.zero) & rowBox.size;
    final sub = subBox.localToGlobal(Offset.zero) & subBox.size;
    return row.expandToInclude(sub);
  }

  List<_MenuNode> _itemsAtDepth(int depth) {
    var items = _root;
    for (var d = 0; d < depth; d++) {
      items = items[_path[d]].children!;
    }
    return items;
  }

  void _hoverRow({
    required int depth,
    required int index,
    required _MenuNode item,
  }) {
    final pointer = _pointerGlobal.value;
    final apex = _lastPointerGlobal ?? pointer;

    if (item.isSubmenu) {
      final switching = depth < _path.length && _path[depth] != index;
      // Cutting through the triangle: delay steal until linger (Docs-style).
      if (widget.useHit &&
          switching &&
          pointer != null &&
          apex != null &&
          _stillInSafeTriangle(depth: depth, apex: apex, point: pointer)) {
        _scheduleHoverIntent(
          depth: depth,
          index: index,
          apply: () => _setPath([..._path.take(depth), index]),
        );
        return;
      }
      _cancelHoverIntent();
      _setPath([..._path.take(depth), index]);
      return;
    }

    // Leaf under an open path → dismiss deeper depths (delayed if in triangle).
    if (depth < _path.length) {
      if (widget.useHit &&
          pointer != null &&
          apex != null &&
          _stillInSafeTriangle(depth: depth, apex: apex, point: pointer)) {
        _scheduleHoverIntent(
          depth: depth,
          index: index,
          apply: () {
            if (depth < _path.length) {
              _setPath(_path.sublist(0, depth));
            }
          },
        );
        return;
      }
      _cancelHoverIntent();
      _setPath(_path.sublist(0, depth));
    }
  }

  void _hoverRowExit({required int depth, required int index}) {
    if (_pendingHoverIntent == (depth, index)) {
      _cancelHoverIntent();
    }
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final themeContext = context;
    final bg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      themeContext,
    );
    final border = CupertinoColors.separator.resolveFrom(themeContext);
    final label = CupertinoColors.label.resolveFrom(themeContext);
    final primary = CupertinoTheme.of(themeContext).primaryColor;

    const scopePad = 24.0;

    final panels = <Widget>[];
    for (var depth = 0; ; depth++) {
      final items = _itemsAtDepth(depth);
      panels.add(
        KeyedSubtree(
          key: _panelKeys[depth],
          child: _CascadingMenuPanel(
            items: items,
            openIndex: depth < _path.length ? _path[depth] : null,
            anchorRowKey: depth < _path.length ? _anchorRowKeys[depth] : null,
            background: bg,
            border: border,
            labelColor: label,
            primary: primary,
            onPointer: _onPointer,
            onHoverRow: (index, item) =>
                _hoverRow(depth: depth, index: index, item: item),
            onHoverRowExit: (index) =>
                _hoverRowExit(depth: depth, index: index),
            onPick: _pick,
          ),
        ),
      );
      if (depth >= _path.length) break;
      final open = _path[depth];
      if (!items[open].isSubmenu) break;
      panels.add(const SizedBox(width: 10));
    }

    return Listener(
      onPointerHover: (event) => _onPointer(event.position),
      onPointerMove: (event) => _onPointer(event.position),
      child: HitScope(
        debugLabel: 'safe-triangle-menu',
        child: Stack(
          key: _overlayStackKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Padding(
                padding: const EdgeInsets.all(scopePad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: panels,
                ),
              ),
            ),
            if (widget.useHit && _path.isNotEmpty)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _pointerGlobal,
                  builder: (context, _) {
                    final depth = _path.length - 1;
                    final pointer = _pointerGlobal.value;
                    if (!_shouldShowDeepestTriangle(pointer)) {
                      return const SizedBox.shrink();
                    }
                    return _SafeTriangleLayer(
                      coordKey: _overlayStackKey,
                      rowKey: _anchorRowKeys[depth],
                      submenuKey: _panelKeys[depth + 1],
                      pointerGlobal: pointer,
                      color: primary.withValues(alpha: 0.28),
                      showOutline: widget.showHitArea,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: CompositedTransformTarget(
        link: _link,
        child: _ExpandHit(
          useHit: widget.useHit,
          showHitArea: widget.showHitArea,
          debugLabel: 'menu-open',
          hitSize: const Size(88, 44),
          onTap: _toggle,
          paintChild: Text(
            _isOpen ? 'CLOSE' : 'OPEN MENU',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Safe triangle: tip tracks the live cursor; base is the submenu edge with
/// [_CascadingMenuDemoState._safePad] so grazing expandable siblings stays covered.
class _SafeTriangleLayer extends StatelessWidget {
  const _SafeTriangleLayer({
    required this.coordKey,
    required this.rowKey,
    required this.submenuKey,
    required this.pointerGlobal,
    required this.color,
    required this.showOutline,
  });

  final GlobalKey coordKey;
  final GlobalKey rowKey;
  final GlobalKey submenuKey;
  final Offset? pointerGlobal;
  final Color color;
  final bool showOutline;

  static const double _pad = _CascadingMenuDemoState._safePad;

  @override
  Widget build(BuildContext context) {
    final pointer = pointerGlobal;
    final coordBox = coordKey.currentContext?.findRenderObject() as RenderBox?;
    final rowBox = rowKey.currentContext?.findRenderObject() as RenderBox?;
    final subBox = submenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (pointer == null ||
        coordBox == null ||
        !coordBox.hasSize ||
        rowBox == null ||
        !rowBox.hasSize ||
        subBox == null ||
        !subBox.hasSize) {
      return const SizedBox.shrink();
    }

    Offset local(Offset global) => coordBox.globalToLocal(global);

    final apex = local(pointer);
    final rowTR = local(rowBox.localToGlobal(Offset(rowBox.size.width, 0)));
    final rowBR = local(
      rowBox.localToGlobal(Offset(rowBox.size.width, rowBox.size.height)),
    );
    final rawTL = local(subBox.localToGlobal(Offset.zero));
    final rawBL = local(subBox.localToGlobal(Offset(0, subBox.size.height)));
    final subTL = Offset(rawTL.dx - 4, rawTL.dy - _pad);
    final subBL = Offset(rawBL.dx - 4, rawBL.dy + _pad);

    final triangle = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(subTL.dx, subTL.dy)
      ..lineTo(subBL.dx, subBL.dy)
      ..close();
    final bridge = Path()
      ..moveTo(rowTR.dx, rowTR.dy)
      ..lineTo(rawTL.dx, rawTL.dy)
      ..lineTo(rawBL.dx, rawBL.dy)
      ..lineTo(rowBR.dx, rowBR.dy)
      ..close();
    final hitPath = Path.combine(PathOperation.union, triangle, bridge);

    return HitDefer(
      debugLabel: 'safe-triangle',
      paint: HitDeferPaint.none,
      behavior: HitTestBehavior.translucent,
      child: CustomPaint(
        painter: _SafeTrianglePainter(
          paintPath: triangle,
          hitPath: hitPath,
          color: color,
          showOutline: showOutline,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SafeTrianglePainter extends CustomPainter {
  const _SafeTrianglePainter({
    required this.paintPath,
    required this.hitPath,
    required this.color,
    required this.showOutline,
  });

  final Path paintPath;
  final Path hitPath;
  final Color color;
  final bool showOutline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      paintPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (showOutline) {
      canvas.drawPath(
        paintPath,
        Paint()
          ..color = color.withValues(alpha: 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool? hitTest(Offset position) => hitPath.contains(position);

  @override
  bool shouldRepaint(covariant _SafeTrianglePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showOutline != showOutline ||
        oldDelegate.paintPath != paintPath ||
        oldDelegate.hitPath != hitPath;
  }
}

class _CascadingMenuPanel extends StatelessWidget {
  const _CascadingMenuPanel({
    required this.items,
    required this.openIndex,
    required this.anchorRowKey,
    required this.background,
    required this.border,
    required this.labelColor,
    required this.primary,
    required this.onPointer,
    required this.onHoverRow,
    required this.onHoverRowExit,
    required this.onPick,
  });

  final List<_MenuNode> items;
  final int? openIndex;
  final GlobalKey? anchorRowKey;
  final Color background;
  final Color border;
  final Color labelColor;
  final Color primary;
  final ValueChanged<Offset> onPointer;
  final void Function(int index, _MenuNode item) onHoverRow;
  final ValueChanged<int> onHoverRowExit;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              _CascadingMenuRow(
                key: openIndex == i ? anchorRowKey : null,
                item: items[i],
                open: openIndex == i,
                labelColor: labelColor,
                primary: primary,
                onPointer: onPointer,
                onHover: () => onHoverRow(i, items[i]),
                onHoverExit: () => onHoverRowExit(i),
                onPick: () => onPick(items[i].label),
              ),
          ],
        ),
      ),
    );
  }
}

class _CascadingMenuRow extends StatelessWidget {
  const _CascadingMenuRow({
    super.key,
    required this.item,
    required this.open,
    required this.labelColor,
    required this.primary,
    required this.onPointer,
    required this.onHover,
    required this.onHoverExit,
    required this.onPick,
  });

  final _MenuNode item;
  final bool open;
  final Color labelColor;
  final Color primary;
  final ValueChanged<Offset> onPointer;
  final VoidCallback onHover;
  final VoidCallback onHoverExit;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final highlight = open
        ? primary.withValues(alpha: 0.12)
        : const Color(0x00000000);

    return MouseRegion(
      onHover: (event) => onPointer(event.position),
      onEnter: (_) => onHover(),
      onExit: (_) => onHoverExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => onPointer(details.globalPosition),
        onTap: item.isSubmenu ? onHover : onPick,
        child: ColoredBox(
          color: highlight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: labelColor,
                      fontWeight: open ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (item.isSubmenu)
                  CustomPaint(
                    size: const Size(8, 10),
                    painter: _ChevronPainter(
                      color: open ? primary : labelColor,
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.08)
      ..lineTo(size.width * 0.15, size.height * 0.92)
      ..lineTo(size.width * 0.95, size.height * 0.5)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
