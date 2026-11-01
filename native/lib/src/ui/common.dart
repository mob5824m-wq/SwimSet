import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: SwimTheme.muted(context),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, trailing: trailing),
          child,
        ],
      );
}

class TypePill extends StatelessWidget {
  const TypePill(this.type, {super.key, this.showLabel = false});

  final SetType type;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = Color(type.color);
    final foreground = dark ? Color.lerp(base, Colors.white, 0.35)! : Color.lerp(base, Colors.black, 0.24)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.withOpacity(0.32)),
      ),
      child: Text(
        showLabel ? type.label : type.short,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: showLabel ? 0.2 : 0.8,
        ),
      ),
    );
  }
}

class TinyPill extends StatelessWidget {
  const TinyPill(this.text, {super.key, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? SwimTheme.muted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tint == SwimTheme.muted(context) ? scheme.onSurface : tint,
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.unit, this.accent});

  final String label;
  final String value;
  final String? unit;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (accent ?? scheme.primary).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (accent ?? scheme.primary).withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: SwimTheme.muted(context),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: accent ?? scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SwimTheme.muted(context),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class TimeField extends StatefulWidget {
  const TimeField({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.hint = '1:40',
    this.enabled = true,
    this.allowEmpty = false,
    this.textAlign = TextAlign.start,
  });

  final int? seconds;
  final ValueChanged<int?> onChanged;
  final String hint;
  final bool enabled;
  final bool allowEmpty;
  final TextAlign textAlign;

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.seconds == null ? '' : formatClock(widget.seconds!));
    _focus = FocusNode();
    _focus.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_focus.hasFocus || !mounted) return;
    if (_controller.text.trim().isEmpty && !widget.allowEmpty) {
      _controller.text = widget.seconds == null ? '' : formatClock(widget.seconds!);
      if (_invalid) setState(() => _invalid = false);
    }
  }

  @override
  void didUpdateWidget(TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds != oldWidget.seconds && !_focus.hasFocus) {
      final next = widget.seconds == null ? '' : formatClock(widget.seconds!);
      if (_controller.text != next) _controller.text = next;
      _invalid = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _invalid = false);
      if (widget.allowEmpty) widget.onChanged(null);
      return;
    }
    final parsed = parseTimeSeconds(trimmed);
    setState(() => _invalid = parsed == null);
    if (parsed != null) widget.onChanged(parsed.round());
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        textAlign: widget.textAlign,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:.]'))],
        style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _invalid ? 'Use 1:40' : null,
        ),
        onChanged: _handle,
      );
}

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.suffix,
    this.enabled = true,
    this.hint,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? suffix;
  final bool enabled;
  final String? hint;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handle(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    final clamped = clampInt(parsed, widget.min, widget.max);
    if (clamped != parsed) {
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(hintText: widget.hint, suffixText: widget.suffix),
        onChanged: _handle,
      );
}

class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: size),
        tooltip: tooltip,
        onPressed: onPressed,
        color: color ?? SwimTheme.muted(context),
        visualDensity: VisualDensity.compact,
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SwimTheme.muted(context), height: 1.4),
                ),
                if (action != null) ...[const SizedBox(height: 18), action!],
              ],
            ),
          ),
        ),
      );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

class TimerRingPainter extends CustomPainter {
  TimerRingPainter({
    required this.progress,
    required this.color,
    required this.track,
    this.strokeWidth = 16,
  });

  /// 1 = full interval remaining, 0 = time is up.
  final double progress;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.track != track;
}
