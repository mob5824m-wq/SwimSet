/*
 * SwimSet — built-in workout templates.
 * Each template is a complete practice that can be used as-is, inserted into
 * the current practice, or customised.
 */
import { createPractice, createSet, todayISO, uid } from './core.js';

const t = (overrides) => createSet(overrides);

export const TEMPLATES = [
  {
    id: 'sprint-power',
    name: 'Sprint Power',
    description: 'Short, sharp speed work with plenty of recovery. Great for a 60-minute senior or masters session.',
    tags: ['sprint', 'senior', '60 min'],
    course: 'SCM',
    basePace: 95,
    group: 'Senior',
    focus: 'Speed & power',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 400, stroke: 'Free', intervalMode: 'none', rest: 30, notes: 'Smooth, long strokes.' }),
      t({ type: 'drill', reps: 8, distance: 50, stroke: 'Choice', rest: 15, notes: 'Alternate catch-up and fingertip drag.' }),
      t({ type: 'kick', reps: 6, distance: 100, stroke: 'Free', equipment: ['Kickboard'], rest: 20, notes: 'Steady kick, good streamline off the wall.' }),
      t({ type: 'preset', reps: 4, distance: 50, stroke: 'Free', rest: 20, notes: 'Descend 1–4 to fast.' }),
      t({ type: 'sprint', reps: 8, distance: 50, stroke: 'Free', pace100: 75, rest: 45, notes: 'Max effort. Full recovery between reps.' }),
      t({ type: 'main', reps: 4, distance: 100, stroke: 'Free', pace100: 85, rest: 30, notes: 'Hold goal 200 pace.' }),
      t({ type: 'cooldown', reps: 4, distance: 100, stroke: 'Choice', rest: 20, notes: 'Easy, breathe every 3–5.' }),
    ],
  },
  {
    id: 'distance-base',
    name: 'Distance Base',
    description: 'Aerobic bulk with a long main set. Built for long course but works in any pool.',
    tags: ['distance', 'aerobic', '90 min'],
    course: 'LCM',
    basePace: 105,
    group: 'Senior',
    focus: 'Aerobic endurance',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 800, stroke: 'Free', intervalMode: 'none', rest: 60, notes: 'Build to steady aerobic pace.' }),
      t({ type: 'drill', reps: 8, distance: 50, stroke: 'Choice', rest: 15 }),
      t({ type: 'kick', reps: 6, distance: 100, stroke: 'Free', equipment: ['Kickboard'], rest: 20 }),
      t({ type: 'main', reps: 5, distance: 400, stroke: 'Free', pace100: 100, rest: 30, notes: 'Even splits. Negative-split the last one.' }),
      t({ type: 'pull', reps: 4, distance: 200, stroke: 'Free', equipment: ['Pull buoy', 'Paddles'], rest: 20, notes: 'Long, strong pull. No paddles if shoulders are sore.' }),
      t({ type: 'cooldown', reps: 1, distance: 400, stroke: 'Choice', intervalMode: 'none', rest: 0, notes: 'Easy choice.' }),
    ],
  },
  {
    id: 'im-technique',
    name: 'IM Technique',
    description: 'Stroke-by-stroke IM work with drills, kick and a controlled main set.',
    tags: ['im', 'technique', '75 min'],
    course: 'SCM',
    basePace: 110,
    group: 'Age group',
    focus: 'IM technique',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 300, stroke: 'IM', intervalMode: 'none', rest: 30, notes: 'Free / back / breast by 100.' }),
      t({ type: 'drill', reps: 8, distance: 50, stroke: 'IM', rest: 15, notes: 'One length drill, one length swim. IM order.' }),
      t({ type: 'kick', reps: 8, distance: 75, stroke: 'IM', equipment: ['Kickboard'], rest: 15, notes: '25 fly, 25 back, 25 breast kick.' }),
      t({ type: 'main', reps: 4, distance: 200, stroke: 'IM', pace100: 125, rest: 30, notes: 'Build each 50. Strong turns.' }),
      t({ type: 'im', reps: 8, distance: 50, stroke: 'IM', rest: 20, notes: 'IM transitions: fly/back, back/breast, breast/free.' }),
      t({ type: 'cooldown', reps: 1, distance: 200, stroke: 'Choice', intervalMode: 'none', rest: 0, notes: 'Easy choice.' }),
    ],
  },
  {
    id: 'age-group-fun',
    name: 'Age Group Skills',
    description: 'Short, playful session with fins, boards and sprints. Ideal for younger swimmers.',
    tags: ['age group', 'beginner', '45 min'],
    course: 'SCM',
    basePace: 120,
    group: 'Age group',
    focus: 'Skills & fun',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 200, stroke: 'Free', intervalMode: 'none', rest: 30, notes: 'Swim, float, breathe.' }),
      t({ type: 'drill', reps: 6, distance: 50, stroke: 'Choice', equipment: ['Fins'], rest: 20, notes: 'Streamline push-offs with fins.' }),
      t({ type: 'kick', reps: 4, distance: 50, stroke: 'Free', equipment: ['Kickboard'], rest: 20 }),
      t({ type: 'sprint', reps: 8, distance: 25, stroke: 'Free', rest: 30, notes: 'Race a partner. Big finishes!' }),
      t({ type: 'main', reps: 4, distance: 100, stroke: 'Free', rest: 30, notes: 'Count strokes per length, try to hold it.' }),
      t({ type: 'cooldown', reps: 1, distance: 200, stroke: 'Choice', intervalMode: 'none', rest: 0, notes: 'Easy choice with buddies.' }),
    ],
  },
  {
    id: 'threshold-scy',
    name: 'Threshold 75',
    description: 'Yard-based threshold work with a descending pre-set and short sprints.',
    tags: ['threshold', 'scy', '75 min'],
    course: 'SCY',
    basePace: 80,
    group: 'Senior',
    focus: 'Threshold',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 500, stroke: 'Free', intervalMode: 'none', rest: 45 }),
      t({ type: 'preset', reps: 10, distance: 50, stroke: 'Free', rest: 15, notes: 'Descend 1–5, 6–10.' }),
      t({ type: 'kick', reps: 6, distance: 100, stroke: 'Free', equipment: ['Kickboard'], rest: 15 }),
      t({ type: 'main', reps: 5, distance: 200, stroke: 'Free', pace100: 85, rest: 20, notes: 'Threshold pace. Hold 1:00 per 100 or better.' }),
      t({ type: 'pull', reps: 4, distance: 100, stroke: 'Free', equipment: ['Pull buoy'], rest: 15 }),
      t({ type: 'sprint', reps: 8, distance: 50, stroke: 'Free', pace100: 70, rest: 40, notes: 'Fast but relaxed.' }),
      t({ type: 'cooldown', reps: 1, distance: 300, stroke: 'Choice', intervalMode: 'none', rest: 0 }),
    ],
  },
  {
    id: 'adult-beginner',
    name: 'Adult Beginner',
    description: 'Gentle introduction: short repeats, generous rest and lots of choice.',
    tags: ['beginner', 'adult', '40 min'],
    course: 'SCM',
    basePace: 150,
    group: 'Masters',
    focus: 'Comfort in the water',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 200, stroke: 'Choice', intervalMode: 'none', rest: 45, notes: 'Anything comfortable. Stop and reset as needed.' }),
      t({ type: 'drill', reps: 4, distance: 50, stroke: 'Free', equipment: ['Kickboard'], rest: 30, notes: 'Kick on the board, face in when ready.' }),
      t({ type: 'main', reps: 6, distance: 50, stroke: 'Free', rest: 30, notes: 'Easy breathing every 3.' }),
      t({ type: 'main', reps: 4, distance: 100, stroke: 'Choice', rest: 45, notes: 'Break at the 50 if you need to.' }),
      t({ type: 'cooldown', reps: 1, distance: 100, stroke: 'Choice', intervalMode: 'none', rest: 0 }),
    ],
  },
  {
    id: 'test-set',
    name: 'Test Set Day',
    description: 'Warm-up, build, a timed 400 and an easy finish. A simple fitness check.',
    tags: ['test', 'fitness', '60 min'],
    course: 'SCM',
    basePace: 100,
    group: 'Masters',
    focus: 'Testing',
    sets: [
      t({ type: 'warmup', reps: 1, distance: 400, stroke: 'Free', intervalMode: 'none', rest: 45 }),
      t({ type: 'preset', reps: 4, distance: 100, stroke: 'Free', rest: 20, notes: 'Build each 25.' }),
      t({ type: 'test', reps: 1, distance: 400, stroke: 'Free', intervalMode: 'none', rest: 120, notes: 'Timed 400. Record your time.' }),
      t({ type: 'recovery', reps: 4, distance: 100, stroke: 'Choice', rest: 30, notes: 'Very easy.' }),
      t({ type: 'cooldown', reps: 1, distance: 200, stroke: 'Choice', intervalMode: 'none', rest: 0 }),
    ],
  },
];

export function templateToPractice(template, overrides = {}) {
  const practice = createPractice({
    title: template.name,
    date: todayISO(),
    course: template.course,
    basePace: template.basePace,
    group: template.group || '',
    focus: template.focus || '',
    notes: template.description || '',
    ...overrides,
  });
  practice.sets = template.sets.map((set) =>
    createSet({ ...JSON.parse(JSON.stringify(set)), id: uid('s') })
  );
  return practice;
}

export function instantiateTemplateSets(template) {
  return template.sets.map((set) => createSet({ ...JSON.parse(JSON.stringify(set)), id: uid('s') }));
}
