part of 'main.dart';

class HitExtensionHome extends StatefulWidget {
  const HitExtensionHome({super.key});

  @override
  State<HitExtensionHome> createState() => _HitExtensionHomeState();
}

class _HitExtensionHomeState extends State<HitExtensionHome>
    with AutoDisposeMixin {
  bool _loading = false;
  String? _error;
  Map<String, Object?>? _snapshot;
  bool _debugPaint = false;
  bool _selectMode = false;
  int? _highlightId;
  HitNodeData? _selected;

  final TreeViewController _treeController = TreeViewController();
  final ScrollController _treeVertical = ScrollController();
  final ScrollController _treeHorizontal = ScrollController();
  List<TreeViewNode<HitNodeData>> _tree = <TreeViewNode<HitNodeData>>[];

  /// Quiet groups (Outside scope / Unscoped) the user has expanded — kept
  /// across snapshot refreshes so clicking a child does not collapse them.
  final Set<String> _openQuietGroups = <String>{};
  StreamSubscription<Event>? _extensionSub;

  /// Width of the tree pane in horizontal layout; null uses the default fraction.
  double? _treeWidth;

  /// Height of the tree pane in vertical layout; null uses the default fraction.
  double? _treeHeight;

  static const double _minPaneWidth = 220.0;
  static const double _minPaneHeight = 160.0;
  static const double _defaultTreeFraction = 5 / 9;

  /// Below this width, stack tree above details instead of side-by-side.
  static const double _verticalBreakpoint = _minPaneWidth * 2;

  @override
  void initState() {
    super.initState();
    cancelListeners();
    addAutoDisposeListener(serviceManager.connectedState, _onConnectionChanged);
    _listenToExtensionEvents();
    if (serviceManager.connectedState.value.connected) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _extensionSub?.cancel();
    _treeVertical.dispose();
    _treeHorizontal.dispose();
    super.dispose();
  }

  void _listenToExtensionEvents() {
    _extensionSub?.cancel();
    final VmService? service = serviceManager.service;
    if (service == null) {
      return;
    }
    _extensionSub = service.onExtensionEvent.listen((Event event) {
      if (event.extensionKind != HitExt.selectedEvent) {
        return;
      }
      final Object? raw = event.extensionData?.data['id'];
      final int? id = raw is num ? raw.toInt() : int.tryParse('$raw');
      if (!mounted) {
        return;
      }
      setState(() {
        _highlightId = id;
      });
      _jumpToId(id);
      // Refresh so details stay current.
      unawaited(_refresh(quiet: true));
    });
  }

  void _onConnectionChanged() {
    if (serviceManager.connectedState.value.connected) {
      _listenToExtensionEvents();
      _refresh();
    } else {
      setState(() {
        _snapshot = null;
        _tree = <TreeViewNode<HitNodeData>>[];
        _selected = null;
        _error = 'Connect a Flutter app that depends on package:hit.';
      });
    }
  }

  Future<Response> _call(
    String method, {
    Map<String, dynamic>? args,
  }) {
    return serviceManager.callServiceExtensionOnMainIsolate(
      method,
      args: args,
    );
  }

  Future<void> _refresh({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final Response paint = await _call(HitExt.getDebugPaint);
      final Response select = await _call(HitExt.getSelectMode);
      final Response snap = await _call(HitExt.getSnapshot);
      final Map<String, Object?> paintJson = _jsonMap(paint.json);
      final Map<String, Object?> selectJson = _jsonMap(select.json);
      final Map<String, Object?> snapJson = _jsonMap(snap.json);
      final int? highlightId = (snapJson['highlightId'] as num?)?.toInt();
      _captureQuietExpansion();
      final List<TreeViewNode<HitNodeData>> tree = _buildTree(
        snapJson,
        openQuietGroups: _openQuietGroups,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _debugPaint = paintJson['enabled'] == true;
        _selectMode = selectJson['enabled'] == true;
        _snapshot = snapJson;
        _highlightId = highlightId;
        _tree = tree;
        _loading = false;
        if (_selected != null) {
          _selected = _findDataById(tree, _selected!.id) ?? _selected;
        } else if (highlightId != null) {
          _selected = _findDataById(tree, highlightId);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (highlightId != null) {
          _jumpToId(highlightId);
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        if (!quiet) {
          _error = 'Failed to talk to package:hit service extensions.\n'
              'Is the app running in debug/profile with HitScope/HitLayer?\n\n$e';
        }
      });
    }
  }

  Future<void> _setDebugPaint(bool enabled) async {
    try {
      await _call(HitExt.setDebugPaint, args: {'enabled': '$enabled'});
      setState(() => _debugPaint = enabled);
      await _refresh(quiet: true);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _setSelectMode(bool enabled) async {
    try {
      final Response response = await _call(
        HitExt.setSelectMode,
        args: {'enabled': '$enabled'},
      );
      final Map<String, Object?> json = _jsonMap(response.json);
      setState(() {
        _selectMode = json['enabled'] == true;
        if (json['debugPaint'] == true) {
          _debugPaint = true;
        }
      });
      await _refresh(quiet: true);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _highlight(int? id) async {
    try {
      await _call(
        HitExt.highlight,
        args: {'id': id == null ? '' : '$id'},
      );
      setState(() {
        _highlightId = id;
        _debugPaint = true;
      });
      await _refresh(quiet: true);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _selectById(int? id) async {
    setState(() {
      _highlightId = id;
      _selected = id == null ? null : _findDataById(_tree, id);
    });
    await _highlight(id);
    _jumpToId(id);
  }

  void _onNodeTap(TreeViewNode<HitNodeData> node) {
    final HitNodeData data = node.content;
    if (!data.isSelectable && data.id == null) {
      setState(() => _selected = data);
      return;
    }
    setState(() => _selected = data);
    unawaited(_selectById(data.id));
  }

  void _onQuietGroupToggle(TreeViewNode<HitNodeData> node) {
    final String? key = _quietGroupKey(node);
    if (key == null) {
      return;
    }
    // onNodeToggle fires after the expansion state has flipped.
    if (node.isExpanded) {
      _openQuietGroups.add(key);
    } else {
      _openQuietGroups.remove(key);
    }
  }

  void _jumpToId(int? id) {
    if (id == null || _tree.isEmpty) {
      return;
    }
    final TreeViewNode<HitNodeData>? node = _findNodeById(_tree, id);
    if (node == null) {
      return;
    }
    // Expand normal ancestors. Quiet groups stay as the user left them —
    // if still collapsed, scroll to the group row instead of auto-opening.
    TreeViewNode<HitNodeData> scrollTarget = node;
    TreeViewNode<HitNodeData>? parent = node.parent;
    while (parent != null) {
      if (_isQuietGroup(parent.content)) {
        if (!parent.isExpanded) {
          scrollTarget = parent;
        }
      } else if (!parent.isExpanded) {
        _treeController.expandNode(parent);
      }
      parent = parent.parent;
    }
    setState(() {
      _selected = node.content;
      _highlightId = id;
    });
    final TreeViewNode<HitNodeData> target = scrollTarget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int? index = _treeController.getActiveIndexFor(target);
      if (index == null || !_treeVertical.hasClients) {
        return;
      }
      final double offsetY = index * _kTreeRowExtent;
      final double view = _treeVertical.position.viewportDimension;
      final double offset = (offsetY - view / 3).clamp(
        0.0,
        _treeVertical.position.maxScrollExtent,
      );
      _treeVertical.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _captureQuietExpansion() {
    _openQuietGroups.clear();
    void walk(List<TreeViewNode<HitNodeData>> nodes) {
      for (final TreeViewNode<HitNodeData> node in nodes) {
        final String? key = _quietGroupKey(node);
        if (key != null && node.isExpanded) {
          _openQuietGroups.add(key);
        }
        walk(node.children);
      }
    }

    walk(_tree);
  }

  /// Stable key for a quiet group under its owning scope (or root).
  String? _quietGroupKey(TreeViewNode<HitNodeData> node) {
    if (!_isQuietGroup(node.content)) {
      return null;
    }
    final Object? kind = node.content.groupKind;
    final Object? scopeId = node.content.scopeId;
    if (scopeId != null) {
      return '$scopeId:$kind';
    }
    TreeViewNode<HitNodeData>? parent = node.parent;
    while (parent != null) {
      if (parent.content.id != null) {
        return '${parent.content.id}:$kind';
      }
      parent = parent.parent;
    }
    return 'root:$kind';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: _loading && _snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Material(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(denseSpacing),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ),
                Expanded(
                  child: HitScope(
                    debugLabel: 'devtools-split',
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final bool vertical =
                            constraints.maxWidth < _verticalBreakpoint;
                        final Widget treePane = _Panel(
                          title: 'HIT SCOPE TREE',
                          actions: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ToolbarToggle(
                                tooltip:
                                    'Debug paint — show hit-area overlays in the '
                                    'connected app',
                                icon: Icons.border_outer,
                                value: _debugPaint,
                                onChanged: _setDebugPaint,
                              ),
                              const SizedBox(width: denseSpacing),
                              _ToolbarToggle(
                                tooltip:
                                    'Select — tap a debug-painted hit area in '
                                    'the app to jump here and open its call '
                                    'site in the IDE',
                                icon: Icons.near_me_outlined,
                                value: _selectMode,
                                activeColor: _highlightYellow,
                                onChanged: _setSelectMode,
                              ),
                              const SizedBox(width: denseSpacing),
                              DevToolsTooltip(
                                message: 'Refresh snapshot',
                                child: IconButton(
                                  onPressed: _loading ? null : () => _refresh(),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          child: _tree.isEmpty
                              ? const _EmptyState(
                                  'No HitScope / HitLayer found.\n'
                                  'Open a screen that uses package:hit.',
                                )
                              : _HitScopeTree(
                                  tree: _tree,
                                  controller: _treeController,
                                  verticalController: _treeVertical,
                                  horizontalController: _treeHorizontal,
                                  selected: _selected,
                                  highlightId: _highlightId,
                                  onNodeTap: _onNodeTap,
                                  onNodeToggle: _onQuietGroupToggle,
                                ),
                        );
                        final Widget detailsPane = _Panel(
                          title: 'DETAILS',
                          child: _HitDetailsPanel(
                            selected: _selected,
                            tree: _tree,
                            highlightId: _highlightId,
                            onOpenId: (int id) {
                              unawaited(_selectById(id));
                            },
                          ),
                        );

                        if (vertical) {
                          final double maxH = constraints.maxHeight;
                          final double maxTree = math.max(
                            _minPaneHeight,
                            maxH - _minPaneHeight,
                          );
                          final double treeH =
                              (_treeHeight ?? maxH * _defaultTreeFraction)
                                  .clamp(_minPaneHeight, maxTree);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: treeH, child: treePane),
                              _PaneResizeHandle(
                                axis: Axis.vertical,
                                onDrag: (double dy) {
                                  setState(() {
                                    _treeHeight = (treeH + dy).clamp(
                                      _minPaneHeight,
                                      maxTree,
                                    );
                                  });
                                },
                              ),
                              Expanded(child: detailsPane),
                            ],
                          );
                        }

                        final double maxW = constraints.maxWidth;
                        final double maxTree =
                            math.max(_minPaneWidth, maxW - _minPaneWidth);
                        final double treeW =
                            (_treeWidth ?? maxW * _defaultTreeFraction)
                                .clamp(_minPaneWidth, maxTree);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: treeW, child: treePane),
                            _PaneResizeHandle(
                              onDrag: (double dx) {
                                setState(() {
                                  _treeWidth = (treeW + dx).clamp(
                                    _minPaneWidth,
                                    maxTree,
                                  );
                                });
                              },
                            ),
                            Expanded(child: detailsPane),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
