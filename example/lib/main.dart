import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:hit/hit.dart';

part 'hit_home.dart';
part 'pages/hit_demo_page.dart';
part 'pages/sliver_hit_demo_page.dart';
part 'widgets/settings_menu_button.dart';
part 'widgets/demo_tile.dart';
part 'widgets/overflow_badge.dart';
part 'widgets/expand_hit.dart';
part 'widgets/chip_dismiss.dart';
part 'widgets/rich_text_hit.dart';
part 'widgets/resize_handle.dart';
part 'widgets/window_edge.dart';
part 'widgets/list_action.dart';
part 'widgets/hover_toolbar.dart';
part 'widgets/cascading_menu.dart';
part 'widgets/slider_thumb.dart';
part 'widgets/mistake_demos.dart';
part 'widgets/hit_ghost.dart';

const primaryColor = CupertinoColors.destructiveRed;

void main() => runApp(const HitExampleApp());

class HitExampleApp extends StatelessWidget {
  const HitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'hit example',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(primaryColor: primaryColor),
      home: HitHome(),
    );
  }
}
