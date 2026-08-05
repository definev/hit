part of 'main.dart';

/// Tab shell: Basics demos + SliverHitScope list/grid demos. Shared settings.
class HitHome extends StatefulWidget {
  const HitHome({super.key});

  @override
  State<HitHome> createState() => _HitHomeState();
}

class _HitHomeState extends State<HitHome> {
  bool _showHitArea = true;
  bool _useHit = true;

  @override
  void initState() {
    super.initState();
    debugPaintHitAreas = _showHitArea;
  }

  void _setShowHitArea(bool value) {
    setState(() {
      _showHitArea = value;
      debugPaintHitAreas = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            label: 'Basics',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Slivers',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => HitDemoPage(
                useHit: _useHit,
                showHitArea: _showHitArea,
                onUseHitChanged: (v) => setState(() => _useHit = v),
                onShowHitAreaChanged: _setShowHitArea,
              ),
              _ => SliverHitDemoPage(
                useHit: _useHit,
                showHitArea: _showHitArea,
                onUseHitChanged: (v) => setState(() => _useHit = v),
                onShowHitAreaChanged: _setShowHitArea,
              ),
            };
          },
        );
      },
    );
  }
}
