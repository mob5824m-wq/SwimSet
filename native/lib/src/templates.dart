import 'models.dart';

class PracticeTemplate {
  PracticeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.course,
    required this.basePace,
    required this.group,
    required this.focus,
    required this.sets,
  });

  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final Course course;
  final int basePace;
  final String group;
  final String focus;
  final List<PracticeSet> sets;
}

PracticeSet _set({
  required SetType type,
  required int reps,
  required int distance,
  required Stroke stroke,
  List<String>? equipment,
  int? pace100,
  int rest = 20,
  IntervalMode intervalMode = IntervalMode.pace,
  String notes = '',
}) =>
    PracticeSet(
      id: uid('s'),
      type: type,
      reps: reps,
      distance: distance,
      stroke: stroke,
      equipment: equipment,
      pace100: pace100,
      rest: rest,
      intervalMode: intervalMode,
      notes: notes,
    );

final List<PracticeTemplate> practiceTemplates = [
  PracticeTemplate(
    id: 'sprint-power',
    name: 'Sprint Power',
    description:
        'Short, sharp speed work with plenty of recovery. Great for a 60-minute senior or masters session.',
    tags: ['sprint', 'senior', '60 min'],
    course: Course.scm,
    basePace: 95,
    group: 'Senior',
    focus: 'Speed & power',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 400, stroke: Stroke.free, rest: 30, intervalMode: IntervalMode.none, notes: 'Smooth, long strokes.'),
      _set(type: SetType.drill, reps: 8, distance: 50, stroke: Stroke.choice, rest: 15, notes: 'Alternate catch-up and fingertip drag.'),
      _set(type: SetType.kick, reps: 6, distance: 100, stroke: Stroke.free, equipment: ['Kickboard'], rest: 20, notes: 'Steady kick, good streamline off the wall.'),
      _set(type: SetType.preset, reps: 4, distance: 50, stroke: Stroke.free, rest: 20, notes: 'Descend 1–4 to fast.'),
      _set(type: SetType.sprint, reps: 8, distance: 50, stroke: Stroke.free, pace100: 75, rest: 45, notes: 'Max effort. Full recovery between reps.'),
      _set(type: SetType.main, reps: 4, distance: 100, stroke: Stroke.free, pace100: 85, rest: 30, notes: 'Hold goal 200 pace.'),
      _set(type: SetType.cooldown, reps: 4, distance: 100, stroke: Stroke.choice, rest: 20, notes: 'Easy, breathe every 3–5.'),
    ],
  ),
  PracticeTemplate(
    id: 'distance-base',
    name: 'Distance Base',
    description:
        'Aerobic bulk with a long main set. Built for long course but works in any pool.',
    tags: ['distance', 'aerobic', '90 min'],
    course: Course.lcm,
    basePace: 105,
    group: 'Senior',
    focus: 'Aerobic endurance',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 800, stroke: Stroke.free, rest: 60, intervalMode: IntervalMode.none, notes: 'Build to steady aerobic pace.'),
      _set(type: SetType.drill, reps: 8, distance: 50, stroke: Stroke.choice, rest: 15),
      _set(type: SetType.kick, reps: 6, distance: 100, stroke: Stroke.free, equipment: ['Kickboard'], rest: 20),
      _set(type: SetType.main, reps: 5, distance: 400, stroke: Stroke.free, pace100: 100, rest: 30, notes: 'Even splits. Negative-split the last one.'),
      _set(type: SetType.pull, reps: 4, distance: 200, stroke: Stroke.free, equipment: ['Pull buoy', 'Paddles'], rest: 20, notes: 'Long, strong pull. No paddles if shoulders are sore.'),
      _set(type: SetType.cooldown, reps: 1, distance: 400, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none, notes: 'Easy choice.'),
    ],
  ),
  PracticeTemplate(
    id: 'im-technique',
    name: 'IM Technique',
    description: 'Stroke-by-stroke IM work with drills, kick and a controlled main set.',
    tags: ['im', 'technique', '75 min'],
    course: Course.scm,
    basePace: 110,
    group: 'Age group',
    focus: 'IM technique',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 300, stroke: Stroke.im, rest: 30, intervalMode: IntervalMode.none, notes: 'Free / back / breast by 100.'),
      _set(type: SetType.drill, reps: 8, distance: 50, stroke: Stroke.im, rest: 15, notes: 'One length drill, one length swim. IM order.'),
      _set(type: SetType.kick, reps: 8, distance: 75, stroke: Stroke.im, equipment: ['Kickboard'], rest: 15, notes: '25 fly, 25 back, 25 breast kick.'),
      _set(type: SetType.main, reps: 4, distance: 200, stroke: Stroke.im, pace100: 125, rest: 30, notes: 'Build each 50. Strong turns.'),
      _set(type: SetType.im, reps: 8, distance: 50, stroke: Stroke.im, rest: 20, notes: 'IM transitions: fly/back, back/breast, breast/free.'),
      _set(type: SetType.cooldown, reps: 1, distance: 200, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none, notes: 'Easy choice.'),
    ],
  ),
  PracticeTemplate(
    id: 'age-group-fun',
    name: 'Age Group Skills',
    description:
        'Short, playful session with fins, boards and sprints. Ideal for younger swimmers.',
    tags: ['age group', 'beginner', '45 min'],
    course: Course.scm,
    basePace: 120,
    group: 'Age group',
    focus: 'Skills & fun',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 200, stroke: Stroke.free, rest: 30, intervalMode: IntervalMode.none, notes: 'Swim, float, breathe.'),
      _set(type: SetType.drill, reps: 6, distance: 50, stroke: Stroke.choice, equipment: ['Fins'], rest: 20, notes: 'Streamline push-offs with fins.'),
      _set(type: SetType.kick, reps: 4, distance: 50, stroke: Stroke.free, equipment: ['Kickboard'], rest: 20),
      _set(type: SetType.sprint, reps: 8, distance: 25, stroke: Stroke.free, rest: 30, notes: 'Race a partner. Big finishes!'),
      _set(type: SetType.main, reps: 4, distance: 100, stroke: Stroke.free, rest: 30, notes: 'Count strokes per length, try to hold it.'),
      _set(type: SetType.cooldown, reps: 1, distance: 200, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none, notes: 'Easy choice with buddies.'),
    ],
  ),
  PracticeTemplate(
    id: 'threshold-scy',
    name: 'Threshold 75',
    description: 'Yard-based threshold work with a descending pre-set and short sprints.',
    tags: ['threshold', 'scy', '75 min'],
    course: Course.scy,
    basePace: 80,
    group: 'Senior',
    focus: 'Threshold',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 500, stroke: Stroke.free, rest: 45, intervalMode: IntervalMode.none),
      _set(type: SetType.preset, reps: 10, distance: 50, stroke: Stroke.free, rest: 15, notes: 'Descend 1–5, 6–10.'),
      _set(type: SetType.kick, reps: 6, distance: 100, stroke: Stroke.free, equipment: ['Kickboard'], rest: 15),
      _set(type: SetType.main, reps: 5, distance: 200, stroke: Stroke.free, pace100: 85, rest: 20, notes: 'Threshold pace. Hold 1:00 per 100 or better.'),
      _set(type: SetType.pull, reps: 4, distance: 100, stroke: Stroke.free, equipment: ['Pull buoy'], rest: 15),
      _set(type: SetType.sprint, reps: 8, distance: 50, stroke: Stroke.free, pace100: 70, rest: 40, notes: 'Fast but relaxed.'),
      _set(type: SetType.cooldown, reps: 1, distance: 300, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none),
    ],
  ),
  PracticeTemplate(
    id: 'adult-beginner',
    name: 'Adult Beginner',
    description: 'Gentle introduction: short repeats, generous rest and lots of choice.',
    tags: ['beginner', 'adult', '40 min'],
    course: Course.scm,
    basePace: 150,
    group: 'Masters',
    focus: 'Comfort in the water',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 200, stroke: Stroke.choice, rest: 45, intervalMode: IntervalMode.none, notes: 'Anything comfortable. Stop and reset as needed.'),
      _set(type: SetType.drill, reps: 4, distance: 50, stroke: Stroke.free, equipment: ['Kickboard'], rest: 30, notes: 'Kick on the board, face in when ready.'),
      _set(type: SetType.main, reps: 6, distance: 50, stroke: Stroke.free, rest: 30, notes: 'Easy breathing every 3.'),
      _set(type: SetType.main, reps: 4, distance: 100, stroke: Stroke.choice, rest: 45, notes: 'Break at the 50 if you need to.'),
      _set(type: SetType.cooldown, reps: 1, distance: 100, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none),
    ],
  ),
  PracticeTemplate(
    id: 'test-set',
    name: 'Test Set Day',
    description: 'Warm-up, build, a timed 400 and an easy finish. A simple fitness check.',
    tags: ['test', 'fitness', '60 min'],
    course: Course.scm,
    basePace: 100,
    group: 'Masters',
    focus: 'Testing',
    sets: [
      _set(type: SetType.warmup, reps: 1, distance: 400, stroke: Stroke.free, rest: 45, intervalMode: IntervalMode.none),
      _set(type: SetType.preset, reps: 4, distance: 100, stroke: Stroke.free, rest: 20, notes: 'Build each 25.'),
      _set(type: SetType.test, reps: 1, distance: 400, stroke: Stroke.free, rest: 120, intervalMode: IntervalMode.none, notes: 'Timed 400. Record your time.'),
      _set(type: SetType.recovery, reps: 4, distance: 100, stroke: Stroke.choice, rest: 30, notes: 'Very easy.'),
      _set(type: SetType.cooldown, reps: 1, distance: 200, stroke: Stroke.choice, rest: 0, intervalMode: IntervalMode.none),
    ],
  ),
];

Practice templateToPractice(PracticeTemplate template) => Practice(
      id: uid('p'),
      title: template.name,
      date: todayISO(),
      course: template.course,
      basePace: template.basePace,
      roundTo: 5,
      group: template.group,
      focus: template.focus,
      notes: template.description,
      sets: template.sets.map((set) => set.copy(freshId: true)).toList(),
    );
