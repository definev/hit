import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared chrome for every before/after demo page.
class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        actions: actions,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              subtitle,
              style: TextStyle(
                color: HitExampleTheme.ink.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Side-by-side Before / After panels with a shared tap counter.
class BeforeAfterSplit extends StatelessWidget {
  const BeforeAfterSplit({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After · hit',
    this.footer,
  });

  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final panels = [
          _Panel(label: beforeLabel, tone: _PanelTone.before, child: before),
          _Panel(label: afterLabel, tone: _PanelTone.after, child: after),
        ];

        return Column(
          children: [
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: panels[0]),
                        Container(width: 1, color: HitExampleTheme.mist),
                        Expanded(child: panels[1]),
                      ],
                    )
                  : ListView(
                      children: [
                        SizedBox(height: 280, child: panels[0]),
                        Container(height: 1, color: HitExampleTheme.mist),
                        SizedBox(height: 280, child: panels[1]),
                      ],
                    ),
            ),
            if (footer != null) ...[const Divider(height: 1), footer!],
          ],
        );
      },
    );
  }
}

enum _PanelTone { before, after }

class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.tone, required this.child});

  final String label;
  final _PanelTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = tone == _PanelTone.before
        ? HitExampleTheme.warn
        : HitExampleTheme.accent;
    final soft = tone == _PanelTone.before
        ? HitExampleTheme.warnSoft
        : HitExampleTheme.accentSoft;

    return ColoredBox(
      color: HitExampleTheme.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: soft,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(padding: const EdgeInsets.all(20), child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend + live tap count strip.
class TapStatsBar extends StatelessWidget {
  const TapStatsBar({
    super.key,
    required this.beforeTaps,
    required this.afterTaps,
    this.hint = 'Tap near the control — green shows expanded hit area.',
  });

  final int beforeTaps;
  final int afterTaps;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint,
            style: TextStyle(
              color: HitExampleTheme.ink.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                label: 'Before taps',
                value: beforeTaps,
                color: HitExampleTheme.warn,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'After taps',
                value: afterTaps,
                color: HitExampleTheme.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: HitExampleTheme.mist),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: HitExampleTheme.ink.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flash feedback when a control is activated.
class TapFlash extends StatefulWidget {
  const TapFlash({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<TapFlash> createState() => _TapFlashState();
}

class _TapFlashState extends State<TapFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.94,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant TapFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
