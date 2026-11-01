import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

class RunPage extends StatefulWidget {
  const RunPage({super.key, required this.state});

  final AppState state;

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> with WidgetsBindingObserver {
  AudioPlayer? _player;
  final ScrollController _planScroll = ScrollController();

  List<RunStep> _steps = const [];
  int _index = 0;
  double _remainingMs = 0;
  int _elapsedMs = 0;
  bool _running = false;
  bool _auto = true;
  bool _muted = false;
  bool _finished = false;
  bool _immersive = false;
  Timer? _ticker;
  DateTime _lastTick = DateTime.now();
  final Set<int> _beeps = {};
  late int _seenToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seenToken = widget.state.runToken;
    _loadSteps(notify: false);
  }

  @override
  void didUpdateWidget(RunPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.runToken != _seenToken) {
      _seenToken = widget.state.runToken;
      _loadSteps(notify: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _running) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    final player = _player;
    if (player != null) {
      unawaited(player.dispose().catchError((Object _) {}));
    }
    if (_immersive) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    _planScroll.dispose();
    super.dispose();
  }

  void _loadSteps({bool notify = true}) {
    _ticker?.cancel();
    _steps = compileSteps(widget.state.draft);
    _index = 0;
    _remainingMs = _steps.isEmpty ? 0 : _steps.first.durationMs.toDouble();
    _elapsedMs = 0;
    _running = false;
    _finished = false;
    _beeps.clear();
    if (notify && mounted) setState(() {});
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_planScroll.hasClients) return;
      final max = _planScroll.position.maxScrollExtent;
      final target = (_index * 66.0 - 110).clamp(0.0, max);
      _planScroll.animateTo(target, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    });
  }

  void _ensureTicker() {
    _ticker?.cancel();
    _lastTick = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (!_running) return;
    final now = DateTime.now();
    final delta = now.difference(_lastTick).inMilliseconds.toDouble();
    _lastTick = now;
    if (delta <= 0) return;

    final previous = _remainingMs;
    var remaining = _remainingMs - delta;
    var elapsed = _elapsedMs + delta.round();

    if (remaining <= 0) {
      _beep();
      if (_auto) {
        if (_index < _steps.length - 1) {
          _index++;
          _remainingMs = _steps[_index].durationMs.toDouble();
          _elapsedMs = elapsed;
          _beeps.clear();
          _lastTick = DateTime.now();
          setState(() {});
          _scrollToCurrent();
          return;
        }
        _ticker?.cancel();
        _keepAwake(false);
        setState(() {
          _remainingMs = 0;
          _elapsedMs = elapsed;
          _running = false;
          _finished = true;
        });
        _showFinished();
        return;
      }
      remaining = 0;
      _ticker?.cancel();
      _keepAwake(false);
      setState(() {
        _remainingMs = 0;
        _elapsedMs = elapsed;
        _running = false;
      });
      return;
    }

    _checkBeeps(previous, remaining);
    setState(() {
      _remainingMs = remaining;
      _elapsedMs = elapsed;
    });
  }

  void _checkBeeps(double previous, double remaining) {
    for (final threshold in const [3, 2, 1]) {
      if (previous > threshold * 1000 &&
          remaining <= threshold * 1000 &&
          !_beeps.contains(threshold)) {
        _beeps.add(threshold);
        _beep();
      }
    }
  }

  void _beep() {
    if (_muted) return;
    try {
      final player = _player ??= AudioPlayer();
      unawaited(player.play(AssetSource('audio/beep.wav')).catchError((Object _) {}));
    } catch (_) {
      // Audio is unavailable (for example in tests); timing still works.
    }
  }

  static const MethodChannel _powerChannel = MethodChannel('swimset/power');

  /// Asks the host platform to hold the screen awake while the timer runs.
  /// Android implements this in MainActivity; desktops simply ignore it.
  void _keepAwake(bool awake) {
    unawaited(_powerChannel
        .invokeMethod<bool>('keepAwake', awake)
        .catchError((Object _) => false));
  }

  void _start() {
    if (_steps.isEmpty) return;
    if (_finished) _reset();
    setState(() {
      _running = true;
      _finished = false;
    });
    _keepAwake(true);
    _ensureTicker();
  }

  void _pause() {
    _ticker?.cancel();
    _keepAwake(false);
    if (!mounted) return;
    setState(() => _running = false);
  }

  void _toggle() => _running ? _pause() : _start();

  void _reset() {
    _ticker?.cancel();
    _keepAwake(false);
    setState(() {
      _index = 0;
      _remainingMs = _steps.isEmpty ? 0 : _steps.first.durationMs.toDouble();
      _elapsedMs = 0;
      _running = false;
      _finished = false;
      _beeps.clear();
    });
    _scrollToCurrent();
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    _ticker?.cancel();
    setState(() {
      _index = index;
      _remainingMs = _steps[index].durationMs.toDouble();
      _running = false;
      _finished = false;
      _beeps.clear();
    });
    _scrollToCurrent();
  }

  Future<void> _showFinished() async {
    if (!mounted) return;
    final practice = widget.state.draft;
    final totals = practiceTotals(practice);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Practice complete'),
        content: Text(
          '${practice.title}\n'
          '${formatNumber(totals.distance)} ${practice.course.unit} · ${totals.reps} reps · ~${formatDuration(totals.seconds)}',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reset();
              _start();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    final next = !_immersive;
    setState(() => _immersive = next);
    try {
      await SystemChrome.setEnabledSystemUIMode(
        next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final practice = widget.state.draft;
    if (_steps.isEmpty) {
      return EmptyState(
        icon: Icons.timer_outlined,
        title: 'Nothing to run yet',
        message: 'Build a practice with at least one set, then start it from the Builder.',
        action: FilledButton.icon(
          onPressed: () => widget.state.setTab(0),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Open the builder'),
        ),
      );
    }

    final step = _steps[_index];
    final scheme = Theme.of(context).colorScheme;
    final progress = step.durationMs <= 0 ? 0.0 : (_remainingMs / step.durationMs).clamp(0.0, 1.0);
    final timeUp = !_running && _remainingMs <= 0 && !_finished;
    final accent = timeUp ? scheme.error : scheme.primary;
    final ringSize = math.min(MediaQuery.sizeOf(context).width - 110, 310.0).toDouble();

    final timerCard = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TypePill(step.type),
                      TinyPill('Set ${step.setIndex + 1} of ${practice.sets.length}'),
                      TinyPill('Rep ${step.rep} of ${step.reps}'),
                    ],
                  ),
                ),
                IconAction(
                  icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  tooltip: _muted ? 'Unmute beeps' : 'Mute beeps',
                  onPressed: () => setState(() => _muted = !_muted),
                ),
                IconAction(
                  icon: _immersive ? Icons.fullscreen_exit : Icons.fullscreen,
                  tooltip: _immersive ? 'Exit full screen' : 'Full screen',
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
            ),
            if (step.notes.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                step.notes,
                textAlign: TextAlign.center,
                style: TextStyle(color: SwimTheme.muted(context), fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: TimerRingPainter(
                        progress: progress,
                        color: accent,
                        track: SwimTheme.line(context),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatClock((_remainingMs / 1000).ceil()),
                            style: TextStyle(
                              fontSize: 56,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeUp
                                ? 'TIME UP'
                                : step.sendOff != null
                                    ? 'ON THE SEND-OFF'
                                    : 'SWIM THIS REP',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                              color: SwimTheme.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Rep ${step.rep} of ${step.reps}',
                    style: TextStyle(fontSize: 12, color: SwimTheme.muted(context))),
                const Spacer(),
                Text('Elapsed ${formatClock(_elapsedMs / 1000)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: SwimTheme.muted(context),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: step.rep / step.reps,
                minHeight: 5,
                backgroundColor: scheme.primary.withOpacity(0.10),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                IconButton.filledTonal(
                  onPressed: _reset,
                  tooltip: 'Reset practice',
                  icon: const Icon(Icons.replay_rounded, size: 20),
                ),
                IconButton.filledTonal(
                  onPressed: _index > 0 ? () => _jumpTo(_index - 1) : null,
                  tooltip: 'Previous rep',
                  icon: const Icon(Icons.skip_previous_rounded, size: 22),
                ),
                FilledButton.icon(
                  onPressed: _finished ? () {
                    _reset();
                    _start();
                  } : _toggle,
                  icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
                  label: Text(
                    _running
                        ? 'Pause'
                        : _finished
                            ? 'Restart'
                            : (_remainingMs < step.durationMs ? 'Resume' : 'Start'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(132, 56),
                    backgroundColor: _running ? const Color(0xFFD97706) : null,
                    textStyle: const TextStyle(fontFamily: 'Lato', fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _index < _steps.length - 1 ? () => _jumpTo(_index + 1) : null,
                  tooltip: 'Next rep',
                  icon: const Icon(Icons.skip_next_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _auto ? scheme.primary.withOpacity(0.05) : null,
              ),
              child: Row(
                children: [
                  Switch(
                    value: _auto,
                    onChanged: (value) => setState(() => _auto = value),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Auto-advance', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Text(
                          'Beeps at 3-2-1 and at the end of each send-off.',
                          style: TextStyle(fontSize: 10.5, color: SwimTheme.muted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _index == _steps.length - 1
                  ? 'Last rep — finish strong.'
                  : 'Up next: ${_steps[_index + 1].label} · rep ${_steps[_index + 1].rep}/${_steps[_index + 1].reps}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: SwimTheme.muted(context)),
            ),
          ],
        ),
      ),
    );

    final planCard = Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Practice plan', style: Theme.of(context).textTheme.titleMedium)),
                Text('${practice.sets.length} sets',
                    style: TextStyle(fontSize: 11.5, color: SwimTheme.muted(context))),
              ],
            ),
          ),
          Divider(height: 1, color: SwimTheme.line(context)),
          SizedBox(
            height: 372,
            child: ListView.builder(
              controller: _planScroll,
              itemExtent: 66,
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final item = _steps[index];
                final current = index == _index;
                final done = index < _index;
                return InkWell(
                  onTap: () => _jumpTo(index),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 3, 8, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: current ? scheme.primary.withOpacity(0.10) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: current ? scheme.primary.withOpacity(0.35) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: current
                                ? scheme.primary
                                : done
                                    ? scheme.primary.withOpacity(0.14)
                                    : SwimTheme.line(context).withOpacity(0.55),
                          ),
                          child: done && !current
                              ? Icon(Icons.check, size: 14, color: scheme.primary)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: current ? scheme.onPrimary : scheme.onSurface,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Rep ${item.rep} of ${item.reps}',
                                style: TextStyle(fontSize: 10.5, color: SwimTheme.muted(context)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.sendOff == null ? 'swim' : formatClock(item.sendOff!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SwimTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      if (wide) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: timerCard),
              const SizedBox(width: 16),
              SizedBox(width: 350, child: planCard),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
        children: [timerCard, const SizedBox(height: 12), planCard],
      );
    });
  }
}
