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

  /// Last state pushed to the Android notification, so we only update on change.
  int _notifiedSecond = -1;
  bool _notifiedRunning = false;

  /// One plan per heat when the practice defines several heats.
  List<_HeatPlan> _plans = const [];
  int _selectedHeat = 0;
  bool _notStarted = false;

  bool get _multiHeat => _plans.length > 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _powerChannel.setMethodCallHandler(_platformCall);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _powerChannel.setMethodCallHandler(null);
    _ticker?.cancel();
    _keepAwake(false);
    _stopTimerService();
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
    final practice = widget.state.draft;
    if (practice.heats.length > 1) {
      _plans = [
        for (var index = 0; index < practice.heats.length; index++)
          _HeatPlan(
            heat: practice.heats[index],
            steps: compileSteps(practice, heat: practice.heats[index]),
            offsetMs: heatStartFor(practice, index) * 1000,
            durationMs: heatDurationMs(practice, practice.heats[index]),
          ),
      ];
      if (_selectedHeat >= _plans.length) _selectedHeat = 0;
      _steps = _plans[_selectedHeat].steps;
    } else {
      _plans = const [];
      _selectedHeat = 0;
      _steps = compileSteps(
        practice,
        heat: practice.heats.isEmpty ? null : practice.heats.first,
      );
    }
    _index = 0;
    _notStarted = false;
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

    if (_multiHeat) {
      _tickHeats(delta);
      return;
    }

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
          _syncNotification();
          return;
        }
        _ticker?.cancel();
        _keepAwake(false);
        _stopTimerService();
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
      _stopTimerService();
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
    _syncNotification();
  }

  void _tickHeats(double delta) {
    final previousElapsed = _elapsedMs;
    final elapsed = _elapsedMs + delta.round();
    _elapsedMs = elapsed;

    // A send cue when another heat goes off the wall.
    for (var index = 1; index < _plans.length; index++) {
      final at = _plans[index].offsetMs;
      if (at > 0 && previousElapsed < at && elapsed >= at) _beep();
    }

    final plan = _plans[_selectedHeat];
    final position = _positionAt(plan, elapsed - plan.offsetMs);
    final previousIndex = _index;
    final previousRemaining = _remainingMs;

    _steps = plan.steps;
    _index = position.index;
    _remainingMs = position.remainingMs;
    _notStarted = position.notStarted;

    if (position.index != previousIndex) {
      _beeps.clear();
      if (!position.notStarted && position.index > 0) _beep();
    }
    if (!position.notStarted && !position.finished) {
      _checkBeeps(previousRemaining, position.remainingMs);
    }

    if (_plans.every((item) => elapsed >= item.offsetMs + item.durationMs)) {
      _ticker?.cancel();
      _keepAwake(false);
      _stopTimerService();
      setState(() {
        _elapsedMs = elapsed;
        _running = false;
        _finished = true;
        _index = math.max(0, _steps.length - 1);
        _remainingMs = 0;
        _notStarted = false;
      });
      _showFinished();
      return;
    }

    setState(() {});
    _syncNotification();
  }

  /// Where a heat is on its own timeline, given the shared clock.
  _HeatPosition _positionAt(_HeatPlan plan, int localMs) {
    if (localMs < 0) {
      return _HeatPosition(
        index: 0,
        remainingMs: (-localMs).toDouble(),
        notStarted: true,
        finished: false,
      );
    }
    var cursor = 0;
    for (var index = 0; index < plan.steps.length; index++) {
      final duration = plan.steps[index].durationMs;
      if (localMs < cursor + duration) {
        return _HeatPosition(
          index: index,
          remainingMs: (cursor + duration - localMs).toDouble(),
          notStarted: false,
          finished: false,
        );
      }
      cursor += duration;
    }
    return _HeatPosition(
      index: math.max(0, plan.steps.length - 1),
      remainingMs: 0,
      notStarted: false,
      finished: true,
    );
  }

  String _nextSendLine() {
    _HeatPlan? next;
    for (final plan in _plans) {
      if (_elapsedMs < plan.offsetMs && (next == null || plan.offsetMs < next.offsetMs)) {
        next = plan;
      }
    }
    if (next == null) return 'All heats are in the water.';
    final seconds = ((next.offsetMs - _elapsedMs) / 1000).ceil();
    return 'Next send: ${next.heat.name} in ${formatClock(seconds)}';
  }

  void _selectHeat(int index) {
    if (!_multiHeat || index < 0 || index >= _plans.length || index == _selectedHeat) return;
    setState(() {
      _selectedHeat = index;
      final plan = _plans[index];
      final position = _positionAt(plan, _elapsedMs - plan.offsetMs);
      _steps = plan.steps;
      _index = position.index;
      _remainingMs = position.remainingMs;
      _notStarted = position.notStarted;
      _beeps.clear();
    });
    _scrollToCurrent();
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

  /// Runs the timer as an Android foreground service so a locked screen or a
  /// background app does not stop the countdown; desktops ignore the call.
  void _startTimerService() {
    _notifiedSecond = (_remainingMs / 1000).ceil();
    _notifiedRunning = true;
    unawaited(_invoke('startTimer', {
      'title': _timerTitle,
      'text': _timerText(),
      'running': true,
    }));
  }

  /// Mirrors the countdown into the ongoing notification (and its Pause/Resume label).
  void _syncNotification({bool force = false}) {
    final second = (_remainingMs / 1000).ceil();
    if (!force && second == _notifiedSecond && _running == _notifiedRunning) return;
    _notifiedSecond = second;
    _notifiedRunning = _running;
    unawaited(_invoke('updateTimer', {
      'title': _timerTitle,
      'text': _timerText(),
      'running': _running,
    }));
  }

  void _stopTimerService() {
    _notifiedSecond = -1;
    unawaited(_invoke('stopTimer'));
  }

  /// Quietly calls the host; desktops and tests have no timer service.
  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _powerChannel.invokeMethod<void>(method, arguments);
    } catch (_) {
      // No native implementation on this platform.
    }
  }

  String get _timerTitle {
    final practice = widget.state.draft;
    if (!_multiHeat) return practice.title;
    return '${_plans[_selectedHeat].heat.name} · ${practice.title}';
  }

  String _timerText() {
    final left = _remainingMs > 0 ? formatClock((_remainingMs / 1000).ceil()) : '0:00';
    if (_notStarted) return '$left until the heat goes off';
    final state = _running ? '$left left' : 'Paused · $left left';
    if (!_multiHeat || _steps.isEmpty) return state;
    final step = _steps[math.min(_index, _steps.length - 1)];
    return '$state · ${step.label}';
  }

  Future<Object?> _platformCall(MethodCall call) async {
    if (call.method != 'timerAction') return null;
    switch (call.arguments) {
      case 'pause':
        if (_running) _pause();
      case 'resume':
        if (!_running) _start();
      case 'next':
        _skipNext();
    }
    return null;
  }

  /// Moves to the next rep from the notification without losing the clock.
  void _skipNext() {
    if (_index >= _steps.length - 1) return;
    final wasRunning = _running;
    _jumpTo(_index + 1);
    if (wasRunning) _start();
    _syncNotification(force: true);
  }

  void _start() {
    if (_steps.isEmpty) return;
    if (_finished) _reset();
    setState(() {
      _running = true;
      _finished = false;
    });
    _keepAwake(true);
    _startTimerService();
    _ensureTicker();
  }

  void _pause() {
    _ticker?.cancel();
    _keepAwake(false);
    if (!mounted) return;
    setState(() => _running = false);
    _syncNotification(force: true);
  }

  void _toggle() => _running ? _pause() : _start();

  void _reset() {
    _ticker?.cancel();
    _keepAwake(false);
    _stopTimerService();
    setState(() {
      _elapsedMs = 0;
      _running = false;
      _finished = false;
      _beeps.clear();
      if (_multiHeat) {
        final plan = _plans[_selectedHeat];
        _steps = plan.steps;
        _index = 0;
        _notStarted = plan.offsetMs > 0;
        _remainingMs = _steps.isEmpty
            ? 0
            : (plan.offsetMs > 0 ? plan.offsetMs.toDouble() : _steps.first.durationMs.toDouble());
      } else {
        _index = 0;
        _notStarted = false;
        _remainingMs = _steps.isEmpty ? 0 : _steps.first.durationMs.toDouble();
      }
    });
    _scrollToCurrent();
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    _ticker?.cancel();
    setState(() {
      _index = index;
      _notStarted = false;
      _remainingMs = _steps[index].durationMs.toDouble();
      _running = false;
      _finished = false;
      _beeps.clear();
      if (_multiHeat) {
        final plan = _plans[_selectedHeat];
        var local = 0;
        for (var step = 0; step < index; step++) {
          local += plan.steps[step].durationMs;
        }
        _steps = plan.steps;
        _elapsedMs = plan.offsetMs + local;
      }
    });
    _scrollToCurrent();
    _syncNotification(force: true);
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

  Widget _heatStrip(BuildContext context, ColorScheme scheme) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _plans.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final position = _positionAt(plan, _elapsedMs - plan.offsetMs);
        final selected = index == _selectedHeat;
        final seconds = (position.remainingMs / 1000).ceil();
        final sending = position.notStarted && seconds <= 5;
        final String status;
        if (position.notStarted) {
          status = sending ? 'send now' : 'in ${formatClock(seconds)}';
        } else if (position.finished) {
          status = 'done';
        } else {
          status = '${formatClock(seconds)} left';
        }
        return InkWell(
          onTap: () => _selectHeat(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? scheme.primary.withOpacity(0.10) : null,
              border: Border.all(
                color: sending
                    ? const Color(0xFFD97706)
                    : selected
                        ? scheme.primary.withOpacity(0.45)
                        : SwimTheme.line(context),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.heat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: sending ? FontWeight.w700 : FontWeight.w500,
                    color: sending ? const Color(0xFFD97706) : SwimTheme.muted(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final plan = _multiHeat ? _plans[_selectedHeat] : null;
    final progress = _notStarted
        ? (plan != null && plan.offsetMs > 0
            ? (1 - (_remainingMs / plan.offsetMs)).clamp(0.0, 1.0)
            : 1.0)
        : (step.durationMs <= 0 ? 0.0 : (_remainingMs / step.durationMs).clamp(0.0, 1.0));
    final timeUp = !_running && !_notStarted && _remainingMs <= 0 && !_finished;
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
                      if (plan != null) TinyPill(plan.heat.name),
                      TinyPill('Set ${step.setIndex + 1} of ${practice.sets.length}'),
                      if (step.rounds > 1) TinyPill('Round ${step.round}/${step.rounds}'),
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
            if (_multiHeat) ...[
              const SizedBox(height: 8),
              SizedBox(height: 52, child: _heatStrip(context, scheme)),
              const SizedBox(height: 4),
            ],
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
                            _notStarted
                                ? 'STARTS IN'
                                : timeUp
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
                if (!_multiHeat)
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
                if (!_multiHeat)
                  IconButton.filledTonal(
                    onPressed: _index < _steps.length - 1 ? () => _jumpTo(_index + 1) : null,
                    tooltip: 'Next rep',
                    icon: const Icon(Icons.skip_next_rounded, size: 22),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_multiHeat)
              Row(
                children: [
                  Icon(Icons.sync_rounded, size: 16, color: SwimTheme.muted(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'One clock runs every heat. Tap a heat to watch its countdown.',
                      style: TextStyle(fontSize: 11, color: SwimTheme.muted(context)),
                    ),
                  ),
                ],
              ),
            if (!_multiHeat)
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
              _multiHeat
                  ? _nextSendLine()
                  : _index == _steps.length - 1
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
                Expanded(
                  child: Text(
                    plan == null ? 'Practice plan' : 'Plan · ${plan.heat.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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
                                '${item.rounds > 1 ? 'Round ${item.round}/${item.rounds} · ' : ''}Rep ${item.rep} of ${item.reps}',
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

class _HeatPlan {
  _HeatPlan({
    required this.heat,
    required this.steps,
    required this.offsetMs,
    required this.durationMs,
  });

  final Heat heat;
  final List<RunStep> steps;
  final int offsetMs;
  final int durationMs;
}

class _HeatPosition {
  _HeatPosition({
    required this.index,
    required this.remainingMs,
    required this.notStarted,
    required this.finished,
  });

  final int index;
  final double remainingMs;
  final bool notStarted;
  final bool finished;
}
