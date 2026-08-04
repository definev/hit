import 'dart:async';
import 'dart:math' as math;

import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hit/hit.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:vm_service/vm_service.dart';

import 'hit_ext.dart';

part 'hit_chrome.dart';
part 'hit_details.dart';
part 'hit_format.dart';
part 'hit_home.dart';
part 'hit_node_data.dart';
part 'hit_scope_tree.dart';
part 'hit_tree_model.dart';

void main() {
  runApp(const HitDevToolsExtension());
}

class HitDevToolsExtension extends StatelessWidget {
  const HitDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: HitExtensionHome());
  }
}
