import 'dart:math' as math;

/* ------------------------------------------------------------------ */
/* Reference data                                                      */
/* ------------------------------------------------------------------ */

enum Course {
  scy('SCY', '25 yd', 'yd', 25, 1.0),
  scm('SCM', '25 m', 'm', 25, 1.11),
  lcm('LCM', '50 m', 'm', 50, 1.13);

  const Course(this.code, this.poolLabel, this.unit, this.poolLength, this.factor);

  final String code;
  final String poolLabel;
  final String unit;
  final int poolLength;
  final double factor;

  String get title => switch (this) {
        Course.scy => 'Short course yards',
        Course.scm => 'Short course meters',
        Course.lcm => 'Long course meters',
      };

  static Course fromCode(Object? value) {
    final text = value?.toString().toUpperCase();
    return Course.values.firstWhere(
      (course) => course.code == text,
      orElse: () => Course.scm,
    );
  }
}

enum SetType {
  warmup('warmup', 'Warm-up', 'WU', 0xFF0EA5E9),
  preset('preset', 'Pre-set', 'PS', 0xFF8B5CF6),
  drill('drill', 'Drill', 'DR', 0xFF14B8A6),
  kick('kick', 'Kick', 'KK', 0xFFF59E0B),
  pull('pull', 'Pull', 'PL', 0xFF6366F1),
  main('main', 'Main set', 'MS', 0xFFEF4444),
  sprint('sprint', 'Sprint', 'SP', 0xFFEC4899),
  im('im', 'IM', 'IM', 0xFFA855F7),
  recovery('recovery', 'Recovery', 'RC', 0xFF22C55E),
  test('test', 'Test set', 'TT', 0xFFEAB308),
  cooldown('cooldown', 'Cool-down', 'CD', 0xFF64748B),
  other('other', 'Other', '••', 0xFF94A3B8);

  const SetType(this.id, this.label, this.short, this.color);

  final String id;
  final String label;
  final String short;
  final int color;

  static SetType fromId(Object? value) => SetType.values.firstWhere(
        (type) => type.id == value,
        orElse: () => SetType.main,
      );
}

enum Stroke {
  free('Free'),
  back('Back'),
  breast('Breast'),
  fly('Fly'),
  im('IM'),
  choice('Choice'),
  mixed('Mixed');

  const Stroke(this.label);
  final String label;

  static Stroke fromLabel(Object? value) => Stroke.values.firstWhere(
        (stroke) => stroke.label == value,
        orElse: () => Stroke.free,
      );
}

enum IntervalMode {
  pace('pace', 'Auto'),
  manual('manual', 'Manual'),
  none('none', 'None');

  const IntervalMode(this.id, this.label);
  final String id;
  final String label;

  static IntervalMode fromId(Object? value) => IntervalMode.values.firstWhere(
        (mode) => mode.id == value,
        orElse: () => IntervalMode.pace,
      );
}

const List<String> equipmentOptions = [
  'Fins',
  'Paddles',
  'Pull buoy',
  'Kickboard',
  'Snorkel',
  'Band',
  'Tempo trainer',
];

const List<int> roundSteps = [1, 5, 10];
const List<int> ladderDistances = [25, 50, 75, 100, 150, 200, 250, 300, 400, 500];

/* ------------------------------------------------------------------ */
/* Utilities                                                           */
/* ------------------------------------------------------------------ */

int _counter = 0;

String uid([String prefix = 'id']) {
  _counter++;
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = math.Random().nextInt(0x7fffffff).toRadixString(36);
  return '${prefix}_$stamp$rand$_counter';
}

int clampInt(int value, int min, int max) => math.min(max, math.max(min, value));

int roundUpTo(num value, int step) {
  final safeStep = step > 0 ? step : 1;
  final result = ((value - 1e-9) / safeStep).ceil() * safeStep;
  return result <= 0 ? 0 : result;
}

String todayISO([DateTime? date]) {
  final d = date ?? DateTime.now();
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

String formatNumber(num value) {
  final negative = value < 0;
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/* ------------------------------------------------------------------ */
/* Time parsing and formatting                                         */
/* ------------------------------------------------------------------ */

/// Coach-friendly time input. Accepts 90, "90s", "1:30", ":45", "1:30.5",
/// "1.30" and "1:02:03". Returns null when the input cannot be understood.
double? parseTimeSeconds(String? input) {
  if (input == null) return null;
  var text = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'(sec|secs|seconds|s)$'), '');
  if (text.isEmpty) return null;

  final mmss = RegExp(r'^(\d+)[.,](\d{2})$').firstMatch(text);
  if (mmss != null) {
    return int.parse(mmss.group(1)!) * 60.0 + int.parse(mmss.group(2)!);
  }

  if (RegExp(r'^\d+(\.\d+)?$').hasMatch(text)) {
    final n = double.tryParse(text);
    return n == null ? null : math.max(0, n);
  }

  final hms = RegExp(r'^(\d+):([0-5]?\d):([0-5]?\d(?:\.\d+)?)$').firstMatch(text);
  if (hms != null) {
    return int.parse(hms.group(1)!) * 3600.0 +
        int.parse(hms.group(2)!) * 60.0 +
        double.parse(hms.group(3)!);
  }

  final colon = RegExp(r'^(\d+):([0-5]?\d(?:\.\d+)?)$').firstMatch(text);
  if (colon != null) {
    return int.parse(colon.group(1)!) * 60.0 + double.parse(colon.group(2)!);
  }

  final colonOnly = RegExp(r'^:([0-5]?\d(?:\.\d+)?)$').firstMatch(text);
  if (colonOnly != null) return double.parse(colonOnly.group(1)!);

  return null;
}

int? parseWholeSeconds(String? input) => parseTimeSeconds(input)?.round();

/// "0:45", "1:40", "1:02:03".
String formatClock(num totalSeconds) {
  final total = math.max(0, totalSeconds.round());
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Seconds with one decimal, e.g. 112.4 -> "1:52.4".
String formatClockDecimal(num totalSeconds) {
  final value = math.max(0, totalSeconds.toDouble());
  var whole = value.floor();
  var tenth = ((value - whole) * 10).round();
  if (tenth == 10) {
    whole += 1;
    tenth = 0;
  }
  final base = formatClock(whole);
  return tenth == 0 ? base : '$base.$tenth';
}

/// "45 sec", "44 min", "1 h 12 min".
String formatDuration(num totalSeconds) {
  final total = math.max(0, totalSeconds.round());
  if (total < 60) return '$total sec';
  final hours = total ~/ 3600;
  final minutes = ((total % 3600) / 60).round();
  if (hours > 0) return minutes > 0 ? '$hours h $minutes min' : '$hours h';
  return '$minutes min';
}

const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return iso;
  final date = DateTime(year, month, day);
  final weekday = _weekdays[date.weekday - 1];
  return '$weekday, ${_months[month - 1]} $day, $year';
}

DateTime parseISODate(String iso) {
  final parts = iso.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  return DateTime.now();
}

/* ------------------------------------------------------------------ */
/* Models                                                              */
/* ------------------------------------------------------------------ */

class PracticeSet {
  PracticeSet({
    required this.id,
    this.type = SetType.main,
    this.reps = 4,
    this.distance = 100,
    this.stroke = Stroke.free,
    List<String>? equipment,
    this.pace100,
    this.rest = 20,
    this.intervalMode = IntervalMode.pace,
    this.interval,
    this.notes = '',
    this.blockId,
    this.blockRounds = 1,
    Map<String, int>? heatSendOffs,
  })  : equipment = equipment ?? <String>[],
        heatSendOffs = heatSendOffs ?? <String, int>{};

  String id;
  SetType type;
  int reps;
  int distance;
  Stroke stroke;
  List<String> equipment;
  int? pace100;
  int rest;
  IntervalMode intervalMode;
  int? interval;
  String notes;

  /// Consecutive sets that share a block id repeat together.
  String? blockId;

  /// How many times the block repeats (1 when the set is not in a block).
  int blockRounds;

  /// Manual send-off per heat id; missing entries calculate from the heat pace.
  Map<String, int> heatSendOffs;

  int get volume => reps * distance;

  PracticeSet copy({bool freshId = false}) => PracticeSet(
        id: freshId ? uid('s') : id,
        type: type,
        reps: reps,
        distance: distance,
        stroke: stroke,
        equipment: List<String>.from(equipment),
        pace100: pace100,
        rest: rest,
        intervalMode: intervalMode,
        interval: interval,
        notes: notes,
        blockId: blockId,
        blockRounds: blockRounds,
        heatSendOffs: Map<String, int>.from(heatSendOffs),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'reps': reps,
        'distance': distance,
        'stroke': stroke.label,
        'equipment': equipment,
        'pace100': pace100,
        'rest': rest,
        'intervalMode': intervalMode.id,
        'interval': interval,
        'notes': notes,
        'blockId': blockId,
        'blockRounds': blockRounds,
        'heatSendOffs': heatSendOffs,
      };

  factory PracticeSet.fromJson(Map<String, dynamic> raw) => normalizeSet(raw);

  static PracticeSet create([Map<String, dynamic>? overrides]) => normalizeSet(overrides ?? const {});
}

/// A group of swimmers that shares a lane and a pace. Heats are optional:
/// a practice without heats is timed off [Practice.basePace].
class Heat {
  Heat({
    required this.id,
    required this.name,
    this.basePace,
    this.startOffset,
  });

  String id;
  String name;

  /// Seconds per 100; null means "use the practice base pace".
  int? basePace;

  /// Seconds after the first heat when this heat is sent. Null means
  /// "index × practice.heatInterval".
  int? startOffset;

  Heat copy({bool freshId = false}) => Heat(
        id: freshId ? uid('h') : id,
        name: name,
        basePace: basePace,
        startOffset: startOffset,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'basePace': basePace,
        'startOffset': startOffset,
      };

  factory Heat.fromJson(Map<String, dynamic> raw) => normalizeHeat(raw, 0);
}

Heat normalizeHeat(Map<String, dynamic> raw, int index) {
  final name = raw['name'];
  final pace = raw['basePace'];
  final offset = raw['startOffset'];
  final clean = name is String ? name.trim() : '';
  return Heat(
    id: raw['id'] is String && (raw['id'] as String).isNotEmpty ? raw['id'] as String : uid('h'),
    name: clean.isNotEmpty ? clean.substring(0, math.min(40, clean.length)) : 'Heat ${index + 1}',
    basePace: pace is num && pace >= 20 && pace <= 1800 ? pace.round() : null,
    startOffset: offset is num && offset >= 0 && offset <= 7200 ? offset.round() : null,
  );
}

class Practice {
  Practice({
    required this.id,
    this.title = 'Untitled practice',
    String? date,
    this.course = Course.scm,
    this.basePace = 100,
    this.roundTo = 5,
    this.group = '',
    this.focus = '',
    this.notes = '',
    List<PracticeSet>? sets,
    List<Heat>? heats,
    this.heatInterval = 0,
    String? createdAt,
    String? updatedAt,
  })  : date = date ?? todayISO(),
        sets = sets ?? <PracticeSet>[],
        heats = heats ?? <Heat>[],
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  String id;
  String title;
  String date;
  Course course;
  int basePace;
  int roundTo;
  String group;
  String focus;
  String notes;
  List<PracticeSet> sets;

  /// Optional pace groups. Empty means one implicit heat using [basePace].
  List<Heat> heats;

  /// Seconds between consecutive heat send-offs (0 = all heats start together).
  int heatInterval;

  String createdAt;
  String updatedAt;

  Practice copy({bool freshId = false}) => Practice(
        id: freshId ? uid('p') : id,
        title: title,
        date: date,
        course: course,
        basePace: basePace,
        roundTo: roundTo,
        group: group,
        focus: focus,
        notes: notes,
        sets: sets.map((set) => set.copy(freshId: freshId)).toList(),
        heats: heats.map((heat) => heat.copy(freshId: freshId)).toList(),
        heatInterval: heatInterval,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'course': course.code,
        'basePace': basePace,
        'roundTo': roundTo,
        'group': group,
        'focus': focus,
        'notes': notes,
        'sets': sets.map((set) => set.toJson()).toList(),
        'heats': heats.map((heat) => heat.toJson()).toList(),
        'heatInterval': heatInterval,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Practice.fromJson(Map<String, dynamic> raw) => normalizePractice(raw);

  static Practice create([Map<String, dynamic>? overrides]) => normalizePractice(overrides ?? const {});
}

PracticeSet normalizeSet(Map<String, dynamic> raw) {
  final base = PracticeSet(id: uid('s'));
  final reps = raw['reps'];
  final distance = raw['distance'];
  final rest = raw['rest'];
  final pace = raw['pace100'];
  final interval = raw['interval'];
  final equipment = raw['equipment'];
  final blockId = raw['blockId'];
  final blockRounds = raw['blockRounds'];
  final heatSendOffs = raw['heatSendOffs'];

  return PracticeSet(
    id: raw['id'] is String && (raw['id'] as String).isNotEmpty ? raw['id'] as String : base.id,
    type: SetType.fromId(raw['type']),
    reps: clampInt((reps is num ? reps.round() : 4), 1, 999),
    distance: clampInt((distance is num ? distance.round() : 100), 1, 10000),
    stroke: Stroke.fromLabel(raw['stroke']),
    equipment: equipment is List
        ? equipment.whereType<String>().take(8).toList()
        : <String>[],
    pace100: pace is num && pace > 0 ? pace.round() : null,
    rest: clampInt((rest is num ? rest.round() : 20), 0, 3600),
    intervalMode: IntervalMode.fromId(raw['intervalMode']),
    interval: interval is num && interval > 0 ? interval.round() : null,
    notes: raw['notes'] is String ? (raw['notes'] as String).substring(0, math.min(500, (raw['notes'] as String).length)) : '',
    blockId: blockId is String && blockId.isNotEmpty ? blockId : null,
    blockRounds: clampInt(blockRounds is num ? blockRounds.round() : 1, 1, 20),
    heatSendOffs: heatSendOffs is Map
        ? {
            for (final entry in heatSendOffs.entries)
              if (entry.value is num && (entry.value as num) > 0 && (entry.value as num) <= 3600)
                '${entry.key}': (entry.value as num).round(),
          }
        : <String, int>{},
  );
}

Practice normalizePractice(Map<String, dynamic> raw) {
  final now = DateTime.now().toIso8601String();
  final title = raw['title'];
  final date = raw['date'];
  final basePace = raw['basePace'];
  final roundTo = raw['roundTo'];
  final sets = raw['sets'];
  final heats = raw['heats'];
  final heatInterval = raw['heatInterval'];
  final step = roundTo is num ? roundTo.round() : 5;
  return Practice(
    id: raw['id'] is String && (raw['id'] as String).isNotEmpty ? raw['id'] as String : uid('p'),
    title: title is String && title.trim().isNotEmpty ? title.trim() : 'Untitled practice',
    date: date is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ? date : todayISO(),
    course: Course.fromCode(raw['course']),
    basePace: clampInt(basePace is num ? basePace.round() : 100, 20, 1800),
    roundTo: roundSteps.contains(step) ? step : 5,
    group: raw['group'] is String ? raw['group'] as String : '',
    focus: raw['focus'] is String ? raw['focus'] as String : '',
    notes: raw['notes'] is String ? raw['notes'] as String : '',
    sets: sets is List
        ? sets
            .whereType<Map>()
            .take(80)
            .map((entry) => normalizeSet(Map<String, dynamic>.from(entry)))
            .toList()
        : <PracticeSet>[],
    heats: heats is List
        ? heats
            .whereType<Map>()
            .take(8)
            .toList()
            .asMap()
            .entries
            .map((entry) => normalizeHeat(Map<String, dynamic>.from(entry.value), entry.key))
            .toList()
        : <Heat>[],
    heatInterval: clampInt(heatInterval is num ? heatInterval.round() : 0, 0, 1800),
    createdAt: raw['createdAt'] is String ? raw['createdAt'] as String : now,
    updatedAt: raw['updatedAt'] is String ? raw['updatedAt'] as String : now,
  );
}

Practice clonePractice(Practice source, {bool keepId = false}) {
  final clone = source.copy(freshId: !keepId);
  if (!keepId) {
    clone.title = '${source.title} (copy)';
    clone.createdAt = DateTime.now().toIso8601String();
  }
  clone.updatedAt = DateTime.now().toIso8601String();
  return clone;
}

/* ------------------------------------------------------------------ */
/* Interval / pace maths                                               */
/* ------------------------------------------------------------------ */

/// The pace a heat swims at; heats without their own pace inherit the practice.
int basePaceForHeat(Practice practice, Heat? heat) => heat?.basePace ?? practice.basePace;

int paceForSet(PracticeSet set, Practice practice, {Heat? heat}) {
  final target = set.pace100;
  return target != null && target > 0 ? target : basePaceForHeat(practice, heat);
}

double swimPerRep(PracticeSet set, Practice practice, {Heat? heat}) =>
    (set.distance / 100) * paceForSet(set, practice, heat: heat);

double swimSecondsForSet(PracticeSet set, Practice practice, {Heat? heat}) =>
    swimPerRep(set, practice, heat: heat) * set.reps;

/// The calculated send-off, ignoring any per-heat manual override.
int? autoSendOffForSet(PracticeSet set, Practice practice, {Heat? heat}) {
  if (set.intervalMode == IntervalMode.none) return null;
  if (set.intervalMode == IntervalMode.manual) {
    return set.interval != null && set.interval! > 0 ? set.interval : null;
  }
  return roundUpTo(swimPerRep(set, practice, heat: heat) + set.rest, practice.roundTo);
}

int? sendOffForSet(PracticeSet set, Practice practice, {Heat? heat}) {
  if (set.intervalMode == IntervalMode.none) return null;
  if (heat != null) {
    final override = set.heatSendOffs[heat.id];
    if (override != null && override > 0) return override;
  }
  return autoSendOffForSet(set, practice, heat: heat);
}

int durationForSet(PracticeSet set, Practice practice, {Heat? heat}) {
  final sendOff = sendOffForSet(set, practice, heat: heat);
  if (sendOff != null) return sendOff * set.reps;
  final swim = swimSecondsForSet(set, practice, heat: heat);
  return (swim + set.rest * math.max(0, set.reps - 1)).round();
}

int minSendOffForSet(PracticeSet set, Practice practice, {Heat? heat}) =>
    roundUpTo(swimPerRep(set, practice, heat: heat), practice.roundTo);

/// Seconds after the first heat when heat [index] is sent out.
int heatStartOffset(Practice practice, int index) => math.max(0, index) * practice.heatInterval;

/// Explicit heat offset when set, otherwise the practice stagger for [index].
int heatStartFor(Practice practice, int index) {
  if (index < 0 || index >= practice.heats.length) return 0;
  final explicit = practice.heats[index].startOffset;
  if (explicit != null) return math.max(0, explicit);
  return heatStartOffset(practice, index);
}

/// Number of milliseconds one heat spends in the pool.
int heatDurationMs(Practice practice, Heat heat) =>
    compileSteps(practice, heat: heat).fold<int>(0, (sum, step) => sum + step.durationMs);

/// A set as it appears on deck: blocks repeat their sets [round] times.
class ExpandedSet {
  ExpandedSet(this.set, this.index, this.round, this.rounds);

  final PracticeSet set;
  final int index;
  final int round;
  final int rounds;
}

/// Walks the practice and repeats blocks, in order.
List<ExpandedSet> expandSets(Practice practice) {
  final out = <ExpandedSet>[];
  var index = 0;
  while (index < practice.sets.length) {
    final set = practice.sets[index];
    final blockId = set.blockId;
    if (blockId == null) {
      out.add(ExpandedSet(set, index, 1, 1));
      index++;
      continue;
    }
    final start = index;
    final members = <int>[];
    while (index < practice.sets.length && practice.sets[index].blockId == blockId) {
      members.add(index);
      index++;
    }
    final rounds = math.max(1, practice.sets[start].blockRounds);
    for (var round = 1; round <= rounds; round++) {
      for (final member in members) {
        out.add(ExpandedSet(practice.sets[member], member, round, rounds));
      }
    }
  }
  return out;
}

class Totals {
  Totals({
    required this.distance,
    required this.reps,
    required this.setCount,
    required this.seconds,
    required this.swimSeconds,
    required this.byStroke,
  });

  final int distance;
  final int reps;
  final int setCount;
  final int seconds;
  final int swimSeconds;
  final Map<Stroke, int> byStroke;

  int get restSeconds => math.max(0, seconds - swimSeconds);
}

Totals practiceTotals(Practice practice, {Heat? heat}) {
  var distance = 0;
  var reps = 0;
  var seconds = 0;
  var swim = 0.0;
  final byStroke = <Stroke, int>{};
  for (final expanded in expandSets(practice)) {
    final set = expanded.set;
    final volume = set.reps * set.distance;
    distance += volume;
    reps += set.reps;
    seconds += durationForSet(set, practice, heat: heat);
    swim += swimSecondsForSet(set, practice, heat: heat);
    byStroke[set.stroke] = (byStroke[set.stroke] ?? 0) + volume;
  }
  return Totals(
    distance: distance,
    reps: reps,
    setCount: practice.sets.length,
    seconds: seconds,
    swimSeconds: swim.round(),
    byStroke: byStroke,
  );
}

String setLabel(PracticeSet set, Practice practice, {Heat? heat}) {
  final unit = practice.course.unit;
  var label = '${formatNumber(set.reps)} × ${formatNumber(set.distance)} $unit ${set.stroke.label}';
  final sendOff = sendOffForSet(set, practice, heat: heat);
  if (sendOff != null) label += ' on ${formatClock(sendOff)}';
  return label;
}

class RunStep {
  RunStep({
    required this.key,
    required this.setIndex,
    required this.rep,
    required this.reps,
    required this.type,
    required this.label,
    required this.sendOff,
    required this.durationMs,
    required this.notes,
    required this.equipment,
    this.round = 1,
    this.rounds = 1,
  });

  final String key;
  final int setIndex;
  final int rep;
  final int reps;
  final SetType type;
  final String label;
  final int? sendOff;
  final int durationMs;
  final String notes;
  final List<String> equipment;
  final int round;
  final int rounds;
}

List<RunStep> compileSteps(Practice practice, {Heat? heat}) {
  final steps = <RunStep>[];
  for (final expanded in expandSets(practice)) {
    final set = expanded.set;
    final sendOff = sendOffForSet(set, practice, heat: heat);
    final perRep = swimPerRep(set, practice, heat: heat);
    for (var rep = 0; rep < set.reps; rep++) {
      steps.add(RunStep(
        key: '${set.id}:${expanded.round}:$rep',
        setIndex: expanded.index,
        rep: rep + 1,
        reps: set.reps,
        type: set.type,
        label: setLabel(set, practice, heat: heat),
        sendOff: sendOff,
        durationMs: ((sendOff ?? perRep) * 1000).round(),
        notes: set.notes,
        equipment: List<String>.from(set.equipment),
        round: expanded.round,
        rounds: expanded.rounds,
      ));
    }
  }
  return steps;
}

/* ------------------------------------------------------------------ */
/* Course conversion                                                   */
/* ------------------------------------------------------------------ */

double convertTime(double seconds, Course from, Course to) =>
    (seconds * (to.factor / from.factor) * 1000).round() / 1000;

int convertPace(int secondsPer100, Course from, Course to) =>
    convertTime(secondsPer100.toDouble(), from, to).round();

class LadderRow {
  LadderRow(this.distance, this.swim, this.sendOff);
  final int distance;
  final double swim;
  final int sendOff;
}

List<LadderRow> paceLadder(
  int secondsPer100, {
  int roundTo = 5,
  int rest = 0,
  List<int> distances = ladderDistances,
}) =>
    distances
        .map((distance) {
          final swim = (distance / 100) * secondsPer100;
          return LadderRow(
            distance,
            swim,
            roundUpTo(swim + rest, roundTo),
          );
        })
        .toList();

/* ------------------------------------------------------------------ */
/* Validation                                                          */
/* ------------------------------------------------------------------ */

enum IssueLevel { info, warn, error }

class PracticeIssue {
  PracticeIssue(this.level, this.message);
  final IssueLevel level;
  final String message;
}

List<PracticeIssue> validatePractice(Practice practice) {
  final issues = <PracticeIssue>[];
  final sets = practice.sets;
  final totals = practiceTotals(practice);

  if (practice.title.trim().isEmpty ||
      practice.title.trim().toLowerCase() == 'untitled practice') {
    issues.add(PracticeIssue(
        IssueLevel.info, 'Give the practice a title so it is easy to find later.'));
  }
  if (sets.isEmpty) {
    issues.add(PracticeIssue(IssueLevel.error, 'Add at least one set to build the practice.'));
  }
  if (sets.isNotEmpty && !sets.any((set) => set.type == SetType.warmup)) {
    issues.add(PracticeIssue(IssueLevel.warn, 'No warm-up set — consider adding one.'));
  }
  if (sets.isNotEmpty && !sets.any((set) => set.type == SetType.cooldown)) {
    issues.add(PracticeIssue(IssueLevel.warn, 'No cool-down set — consider adding one.'));
  }
  if (practice.heats.length > 1 && practice.heatInterval <= 0) {
    issues.add(PracticeIssue(IssueLevel.info,
        'Heats start together — add a heat interval to stagger them.'));
  }
  if (practice.basePace <= 0) {
    issues.add(PracticeIssue(
        IssueLevel.error, 'Set a base pace per 100 for automatic send-offs.'));
  }
  if (totals.distance > 8000) {
    issues.add(PracticeIssue(IssueLevel.warn,
        'That is a big session (${formatNumber(totals.distance)} ${practice.course.unit}). Double-check the volume.'));
  }
  for (var i = 0; i < sets.length; i++) {
    final set = sets[i];
    final sendOff = sendOffForSet(set, practice);
    final perRep = swimPerRep(set, practice);
    if (sendOff != null && perRep > 0 && sendOff < perRep) {
      issues.add(PracticeIssue(IssueLevel.error,
          'Set ${i + 1}: send-off ${formatClock(sendOff)} is shorter than the ${formatClock(perRep)} target swim time.'));
    }
    if (set.reps < 1 || set.distance < 1) {
      issues.add(PracticeIssue(
          IssueLevel.error, 'Set ${i + 1} needs at least 1 rep and some distance.'));
    }
  }
  return issues;
}

/* ------------------------------------------------------------------ */
/* Text export                                                         */
/* ------------------------------------------------------------------ */

String practiceToText(Practice practice) {
  final totals = practiceTotals(practice);
  final unit = practice.course.unit;
  final lines = <String>[];
  lines.add(practice.title.toUpperCase());
  final meta = [formatDate(practice.date), practice.course.code];
  if (practice.group.isNotEmpty) meta.add(practice.group);
  lines.add(meta.join(' · '));
  if (practice.focus.isNotEmpty) lines.add('Focus: ${practice.focus}');
  lines.add('Base pace: ${formatClock(practice.basePace)} / 100 $unit · '
      '${formatNumber(totals.distance)} $unit · ~${formatDuration(totals.seconds)}');
  if (practice.heats.isNotEmpty) {
    final paceList = practice.heats
        .map((heat) => '${heat.name} ${formatClock(basePaceForHeat(practice, heat))}')
        .join(' · ');
    final stagger = practice.heatInterval > 0
        ? ' · starts every ${formatClock(practice.heatInterval)}'
        : '';
    lines.add('Heats: $paceList$stagger');
  }
  lines.add('');
  final expanded = expandSets(practice);
  for (var i = 0; i < expanded.length; i++) {
    final entry = expanded[i];
    final set = entry.set;
    final sendOff = sendOffForSet(set, practice);
    final timing = sendOff != null
        ? ' on ${formatClock(sendOff)}'
        : set.intervalMode == IntervalMode.none
            ? ' (continuous)'
            : '';
    final round = entry.rounds > 1 ? 'Round ${entry.round}/${entry.rounds} · ' : '';
    var line =
        '${(i + 1).toString().padLeft(2)}. $round${set.type.label}: ${set.reps} × ${set.distance} $unit ${set.stroke.label}$timing';
    if (set.equipment.isNotEmpty) line += ' w/ ${set.equipment.join(' + ')}';
    lines.add(line);
    if (practice.heats.isNotEmpty) {
      final sends = practice.heats.map((heat) {
        final sendOff = sendOffForSet(set, practice, heat: heat);
        return '${heat.name} ${sendOff == null ? 'swim' : formatClock(sendOff)}';
      }).join(' · ');
      lines.add('    $sends');
    }
    if (set.notes.isNotEmpty) lines.add('    ${set.notes}');
  }
  lines.add('');
  lines.add(
      'TOTAL: ${formatNumber(totals.distance)} $unit · ${totals.reps} reps · ~${formatDuration(totals.seconds)}');
  if (practice.heats.isNotEmpty) {
    final byHeat = practice.heats
        .map((heat) => '${heat.name} ~${formatDuration(practiceTotals(practice, heat: heat).seconds)}')
        .join(' · ');
    lines.add('BY HEAT: $byHeat');
  }
  if (practice.notes.isNotEmpty) {
    lines.add('');
    lines.add('NOTES');
    lines.add(practice.notes);
  }
  lines.add('');
  lines.add('Made with SwimSet');
  return lines.join('\n');
}
