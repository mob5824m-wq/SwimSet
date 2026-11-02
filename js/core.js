/*
 * SwimSet — core logic
 * Pure, DOM-free functions so they can be unit tested in Node and shared by
 * the web app, the offline service worker and any future native shell.
 */

/* ------------------------------------------------------------------ */
/* Reference data                                                      */
/* ------------------------------------------------------------------ */

export const COURSES = {
  SCY: { id: 'SCY', label: 'SCY', name: 'Short course yards', unit: 'yd', length: 25 },
  SCM: { id: 'SCM', label: 'SCM', name: 'Short course meters', unit: 'm', length: 25 },
  LCM: { id: 'LCM', label: 'LCM', name: 'Long course meters', unit: 'm', length: 50 },
};

export const COURSE_IDS = Object.keys(COURSES);

/** Approximate training conversions relative to short course yards. */
export const COURSE_FACTORS = { SCY: 1, SCM: 1.11, LCM: 1.13 };

export const SET_TYPES = [
  { id: 'warmup', label: 'Warm-up', short: 'WU', color: '#0ea5e9' },
  { id: 'preset', label: 'Pre-set', short: 'PS', color: '#8b5cf6' },
  { id: 'drill', label: 'Drill', short: 'DR', color: '#14b8a6' },
  { id: 'kick', label: 'Kick', short: 'KK', color: '#f59e0b' },
  { id: 'pull', label: 'Pull', short: 'PL', color: '#6366f1' },
  { id: 'main', label: 'Main set', short: 'MS', color: '#ef4444' },
  { id: 'sprint', label: 'Sprint', short: 'SP', color: '#ec4899' },
  { id: 'im', label: 'IM', short: 'IM', color: '#a855f7' },
  { id: 'recovery', label: 'Recovery', short: 'RC', color: '#22c55e' },
  { id: 'test', label: 'Test set', short: 'TT', color: '#eab308' },
  { id: 'cooldown', label: 'Cool-down', short: 'CD', color: '#64748b' },
  { id: 'other', label: 'Other', short: '••', color: '#94a3b8' },
];

export const SET_TYPE_IDS = SET_TYPES.map((t) => t.id);
export const STROKES = ['Free', 'Back', 'Breast', 'Fly', 'IM', 'Choice', 'Mixed'];
export const EQUIPMENT = ['Fins', 'Paddles', 'Pull buoy', 'Kickboard', 'Snorkel', 'Band', 'Tempo trainer'];
export const ROUND_STEPS = [1, 5, 10];
export const LADDER_DISTANCES = [25, 50, 75, 100, 150, 200, 250, 300, 400, 500];

/* ------------------------------------------------------------------ */
/* Small utilities                                                     */
/* ------------------------------------------------------------------ */

export function uid(prefix = 'id') {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return `${prefix}_${crypto.randomUUID().slice(0, 8)}`;
  }
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}${Date.now().toString(36).slice(-4)}`;
}

export function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

export function roundUpTo(value, step = 5) {
  const s = Number(step) > 0 ? Number(step) : 1;
  const result = Math.ceil((Number(value) - 1e-9) / s) * s;
  return result === 0 ? 0 : Math.max(0, result);
}

export function roundToTenth(value) {
  return Math.round(Number(value) * 10) / 10;
}

/** Local (not UTC) ISO date, e.g. 2026-10-31. */
export function todayISO(date = new Date()) {
  const d = date instanceof Date ? date : new Date(date);
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
}

export function slugify(text, fallback = 'swimset') {
  const slug = String(text || '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
  return slug || fallback;
}

/* ------------------------------------------------------------------ */
/* Time parsing and formatting                                         */
/* ------------------------------------------------------------------ */

/**
 * Parse coach-friendly time input into seconds, keeping tenths.
 * Accepts 90, "90s", "1:30", ":45", "1:30.5", "1.30" (mm.ss).
 * Returns null when the input cannot be understood.
 */
export function parseTimeFloat(input) {
  if (typeof input === 'number' && Number.isFinite(input)) return Math.max(0, input);
  if (input == null) return null;
  let s = String(input).trim().toLowerCase().replace(/\s+/g, '');
  if (!s) return null;
  s = s.replace(/sec|secs|seconds|s$/, '');

  const mmss = s.match(/^(\d+)[.,](\d{2})$/);
  if (mmss) return Number(mmss[1]) * 60 + Number(mmss[2]);

  if (/^\d+(\.\d+)?$/.test(s)) {
    const n = Number(s);
    return Number.isFinite(n) ? Math.max(0, n) : null;
  }

  const hms = s.match(/^(\d+):([0-5]?\d):([0-5]?\d(?:\.\d+)?)$/);
  if (hms) {
    return Number(hms[1]) * 3600 + Number(hms[2]) * 60 + Number(hms[3]);
  }

  const colon = s.match(/^(\d+):([0-5]?\d(?:\.\d+)?)$/);
  if (colon) return Number(colon[1]) * 60 + Number(colon[2]);

  const colonOnly = s.match(/^:([0-5]?\d(?:\.\d+)?)$/);
  if (colonOnly) return Number(colonOnly[1]);

  return null;
}

/** Whole-second variant used for send-offs and practice inputs. */
export function parseTime(input) {
  const value = parseTimeFloat(input);
  return value == null ? null : Math.round(value);
}

/** "1:30" / ":45" / "1:05:00" */
export function formatClock(totalSeconds) {
  const sec = Math.max(0, Math.round(Number(totalSeconds) || 0));
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  if (m > 0) return `${m}:${String(s).padStart(2, '0')}`;
  return `:${String(s).padStart(2, '0')}`;
}

/** Compact human duration: "45 sec", "44 min", "1 h 12 min". */
export function formatDuration(totalSeconds) {
  const sec = Math.max(0, Math.round(Number(totalSeconds) || 0));
  if (sec < 60) return `${sec} sec`;
  const h = Math.floor(sec / 3600);
  const m = Math.round((sec % 3600) / 60);
  if (h > 0) return m > 0 ? `${h} h ${m} min` : `${h} h`;
  return `${m} min`;
}

/** Seconds -> decimal display with one decimal, e.g. 112.4 -> "1:52.4". */
export function formatClockDecimal(totalSeconds) {
  const sec = Math.max(0, Number(totalSeconds) || 0);
  let whole = Math.floor(sec);
  let tenth = Math.round((sec - whole) * 10);
  if (tenth === 10) {
    whole += 1;
    tenth = 0;
  }
  const base = formatClock(whole);
  return tenth === 0 ? base : `${base}.${tenth}`;
}

export function formatNumber(n) {
  return new Intl.NumberFormat('en-US').format(Math.round(Number(n) || 0));
}

export function formatDate(iso) {
  if (!iso) return '';
  const match = String(iso).match(/^(\d{4})-(\d{2})-(\d{2})/);
  const d = match
    ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
    : new Date(iso);
  if (Number.isNaN(d.getTime())) return String(iso);
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
}

/* ------------------------------------------------------------------ */
/* Model factories and normalisation                                   */
/* ------------------------------------------------------------------ */

export function createPractice(overrides = {}) {
  const now = new Date().toISOString();
  return {
    id: uid('p'),
    title: 'Untitled practice',
    date: todayISO(),
    course: 'SCM',
    basePace: 100, // seconds per 100 in course units
    roundTo: 5,
    group: '',
    focus: '',
    notes: '',
    sets: [],
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

export function createSet(overrides = {}) {
  return {
    id: uid('s'),
    type: 'main',
    reps: 4,
    distance: 100,
    stroke: 'Free',
    equipment: [],
    pace100: null,
    rest: 20,
    intervalMode: 'pace', // pace | manual | none
    interval: null,
    notes: '',
    ...overrides,
  };
}

function finiteNumber(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

export function normalizeSet(raw = {}) {
  const set = createSet();
  set.id = typeof raw.id === 'string' && raw.id ? raw.id : set.id;
  set.type = SET_TYPE_IDS.includes(raw.type) ? raw.type : 'main';
  set.reps = clamp(Math.round(finiteNumber(raw.reps, 4)), 1, 999);
  set.distance = clamp(Math.round(finiteNumber(raw.distance, 100)), 1, 10000);
  set.stroke = STROKES.includes(raw.stroke) ? raw.stroke : 'Free';
  set.equipment = Array.isArray(raw.equipment)
    ? raw.equipment.filter((e) => typeof e === 'string').slice(0, 8)
    : [];
  set.pace100 = Number.isFinite(Number(raw.pace100)) && Number(raw.pace100) > 0
    ? Math.round(Number(raw.pace100))
    : null;
  set.rest = clamp(Math.round(finiteNumber(raw.rest, 20)), 0, 3600);
  set.intervalMode = ['pace', 'manual', 'none'].includes(raw.intervalMode)
    ? raw.intervalMode
    : 'pace';
  set.interval =
    Number.isFinite(Number(raw.interval)) && Number(raw.interval) > 0
      ? Math.round(Number(raw.interval))
      : null;
  if (set.intervalMode === 'manual' && !set.interval) set.intervalMode = 'pace';
  set.notes = typeof raw.notes === 'string' ? raw.notes.slice(0, 500) : '';
  return set;
}

export function normalizePractice(raw = {}) {
  const practice = createPractice();
  const now = new Date().toISOString();
  practice.id = typeof raw.id === 'string' && raw.id ? raw.id : practice.id;
  practice.title = typeof raw.title === 'string' && raw.title.trim()
    ? raw.title.trim().slice(0, 120)
    : 'Untitled practice';
  practice.date = /^\d{4}-\d{2}-\d{2}$/.test(raw.date || '') ? raw.date : todayISO();
  practice.course = COURSE_IDS.includes(raw.course) ? raw.course : 'SCM';
  practice.basePace = clamp(Math.round(finiteNumber(raw.basePace, 100)), 20, 1800);
  practice.roundTo = ROUND_STEPS.includes(Number(raw.roundTo)) ? Number(raw.roundTo) : 5;
  practice.group = typeof raw.group === 'string' ? raw.group.slice(0, 80) : '';
  practice.focus = typeof raw.focus === 'string' ? raw.focus.slice(0, 120) : '';
  practice.notes = typeof raw.notes === 'string' ? raw.notes.slice(0, 2000) : '';
  practice.sets = Array.isArray(raw.sets) ? raw.sets.slice(0, 80).map(normalizeSet) : [];
  practice.createdAt = typeof raw.createdAt === 'string' ? raw.createdAt : now;
  practice.updatedAt = typeof raw.updatedAt === 'string' ? raw.updatedAt : now;
  return practice;
}

export function cloneSet(set) {
  return { ...set, id: uid('s'), equipment: [...(set.equipment || [])] };
}

export function clonePractice(practice, { keepId = false } = {}) {
  const clone = normalizePractice(JSON.parse(JSON.stringify(practice)));
  if (!keepId) {
    clone.id = uid('p');
    clone.title = `${practice.title} (copy)`;
    clone.createdAt = new Date().toISOString();
  }
  clone.updatedAt = new Date().toISOString();
  clone.sets = (practice.sets || []).map((set) => ({
    ...normalizeSet(JSON.parse(JSON.stringify(set))),
    id: uid('s'),
  }));
  return clone;
}

/* ------------------------------------------------------------------ */
/* Interval / pace maths                                               */
/* ------------------------------------------------------------------ */

export function unitFor(practice) {
  return COURSES[practice.course]?.unit || 'm';
}

export function poolLengthFor(practice) {
  return COURSES[practice.course]?.length || 25;
}

export function paceForSet(set, practice) {
  const target = Number(set.pace100);
  return Number.isFinite(target) && target > 0 ? target : practice.basePace;
}

/** Swim time for the whole set (no rest), in seconds. */
export function swimSecondsForSet(set, practice) {
  return ((Number(set.reps) || 0) * (Number(set.distance) || 0) / 100) * paceForSet(set, practice);
}

/**
 * Send-off (interval) for one repetition, or null when the set is untimed.
 * Auto mode: target swim time per rep + rest, rounded up to the practice step.
 */
export function sendoffForSet(set, practice) {
  if (set.intervalMode === 'none') return null;
  if (set.intervalMode === 'manual') return Number(set.interval) > 0 ? Number(set.interval) : null;
  const perRep = ((Number(set.distance) || 0) / 100) * paceForSet(set, practice);
  const rest = Number(set.rest) || 0;
  return roundUpTo(perRep + rest, practice.roundTo || 5);
}

/** Estimated time the set occupies in the workout, in seconds. */
export function durationForSet(set, practice) {
  const reps = Math.max(1, Number(set.reps) || 1);
  const sendoff = sendoffForSet(set, practice);
  if (sendoff) return sendoff * reps;
  const swim = swimSecondsForSet(set, practice);
  const rest = Number(set.rest) || 0;
  return swim + rest * Math.max(0, reps - 1);
}

/** Fastest possible send-off that still fits the swim time (used for warnings). */
export function minSendoffForSet(set, practice) {
  const perRep = ((Number(set.distance) || 0) / 100) * paceForSet(set, practice);
  return roundUpTo(perRep, practice.roundTo || 5);
}

export function practiceTotals(practice) {
  const sets = Array.isArray(practice.sets) ? practice.sets : [];
  let distance = 0;
  let reps = 0;
  let seconds = 0;
  let swimSeconds = 0;
  const byStroke = new Map();
  const byType = new Map();

  for (const set of sets) {
    const setDistance = (Number(set.reps) || 0) * (Number(set.distance) || 0);
    distance += setDistance;
    reps += Number(set.reps) || 0;
    seconds += durationForSet(set, practice);
    swimSeconds += swimSecondsForSet(set, practice);
    byStroke.set(set.stroke, (byStroke.get(set.stroke) || 0) + setDistance);
    byType.set(set.type, (byType.get(set.type) || 0) + setDistance);
  }

  return {
    distance,
    reps,
    setCount: sets.length,
    seconds: Math.round(seconds),
    swimSeconds: Math.round(swimSeconds),
    restSeconds: Math.max(0, Math.round(seconds - swimSeconds)),
    unit: unitFor(practice),
    byStroke: [...byStroke.entries()]
      .map(([stroke, dist]) => ({ stroke, distance: dist }))
      .sort((a, b) => b.distance - a.distance),
    byType: [...byType.entries()]
      .map(([type, dist]) => ({ type, distance: dist }))
      .sort((a, b) => b.distance - a.distance),
  };
}

/**
 * A set-by-set, rep-by-rep plan for the poolside runner.
 */
export function compileSteps(practice) {
  const steps = [];
  (practice.sets || []).forEach((set, setIndex) => {
    const sendoff = sendoffForSet(set, practice);
    const swim = swimSecondsForSet(set, practice) / Math.max(1, set.reps);
    for (let rep = 0; rep < set.reps; rep += 1) {
      steps.push({
        key: `${set.id}:${rep}`,
        setIndex,
        rep: rep + 1,
        reps: set.reps,
        set,
        type: set.type,
        label: setLabel(set, practice),
        sendoff,
        swim,
        notes: set.notes,
        equipment: set.equipment || [],
      });
    }
  });
  return steps;
}

export function setLabel(set, practice) {
  const unit = unitFor(practice);
  let label = `${formatNumber(set.reps)} × ${formatNumber(set.distance)} ${unit} ${set.stroke}`;
  if (set.intervalMode === 'pace' || set.intervalMode === 'manual') {
    const sendoff = sendoffForSet(set, practice);
    if (sendoff) label += ` on ${formatClock(sendoff)}`;
  }
  return label;
}

/* ------------------------------------------------------------------ */
/* Course conversion                                                   */
/* ------------------------------------------------------------------ */

export function convertTime(seconds, fromCourse, toCourse) {
  const from = COURSE_FACTORS[fromCourse];
  const to = COURSE_FACTORS[toCourse];
  if (!from || !to) return Number(seconds) || 0;
  const converted = (Number(seconds) || 0) * (to / from);
  // Keep float noise from leaking into displayed times.
  return Math.round(converted * 1000) / 1000;
}

export function convertPace(secPer100, fromCourse, toCourse) {
  return Math.round(convertTime(secPer100, fromCourse, toCourse));
}

export function paceLadder(secPer100, { roundTo = 5, rest = 0, distances = LADDER_DISTANCES } = {}) {
  return distances.map((distance) => ({
    distance,
    swim: (distance / 100) * Number(secPer100),
    sendoff: roundUpTo((distance / 100) * Number(secPer100) + Number(rest || 0), roundTo),
  }));
}

/* ------------------------------------------------------------------ */
/* Validation                                                          */
/* ------------------------------------------------------------------ */

export function validatePractice(practice) {
  const issues = [];
  const sets = practice.sets || [];
  const totals = practiceTotals(practice);

  if (!practice.title || /^untitled practice$/i.test(practice.title.trim())) {
    issues.push({ level: 'info', message: 'Give the practice a title so it is easy to find later.' });
  }
  if (!sets.length) {
    issues.push({ level: 'error', message: 'Add at least one set to build the practice.' });
  }
  if (sets.length && !sets.some((s) => s.type === 'warmup')) {
    issues.push({ level: 'warn', message: 'No warm-up set — consider adding one.' });
  }
  if (sets.length && !sets.some((s) => s.type === 'cooldown')) {
    issues.push({ level: 'warn', message: 'No cool-down set — consider adding one.' });
  }
  if (!(practice.basePace > 0)) {
    issues.push({ level: 'error', message: 'Set a base pace per 100 for automatic send-offs.' });
  }
  if (totals.distance > 8000) {
    issues.push({ level: 'warn', message: `That is a big session (${formatNumber(totals.distance)} ${totals.unit}). Double-check the volume.` });
  }
  sets.forEach((set, index) => {
    const sendoff = sendoffForSet(set, practice);
    const perRep = ((Number(set.distance) || 0) / 100) * paceForSet(set, practice);
    if (sendoff && perRep > 0 && sendoff < perRep) {
      issues.push({
        level: 'error',
        message: `Set ${index + 1}: send-off ${formatClock(sendoff)} is shorter than the ${formatClock(perRep)} target swim time.`,
      });
    }
    if (!(Number(set.reps) >= 1) || !(Number(set.distance) >= 1)) {
      issues.push({ level: 'error', message: `Set ${index + 1} needs at least 1 rep and some distance.` });
    }
  });
  return issues;
}

/* ------------------------------------------------------------------ */
/* Text export                                                         */
/* ------------------------------------------------------------------ */

export function practiceToText(practice) {
  const totals = practiceTotals(practice);
  const course = COURSES[practice.course] || COURSES.SCM;
  const lines = [];
  lines.push(practice.title.toUpperCase());
  const meta = [formatDate(practice.date), course.label];
  if (practice.group) meta.push(practice.group);
  lines.push(meta.filter(Boolean).join(' · '));
  if (practice.focus) lines.push(`Focus: ${practice.focus}`);
  lines.push(
    `Base pace: ${formatClock(practice.basePace)} / 100 ${course.unit} · ` +
    `${formatNumber(totals.distance)} ${totals.unit} · ~${formatDuration(totals.seconds)}`
  );
  lines.push('');
  (practice.sets || []).forEach((set, i) => {
    const type = SET_TYPES.find((t) => t.id === set.type)?.label || 'Set';
    const sendoff = sendoffForSet(set, practice);
    const timing = sendoff
      ? ` on ${formatClock(sendoff)}`
      : set.intervalMode === 'none'
        ? ' (continuous)'
        : '';
    let line = `${String(i + 1).padStart(2, ' ')}. ${type}: ${set.reps} × ${set.distance} ${course.unit} ${set.stroke}${timing}`;
    if (set.equipment?.length) line += ` w/ ${set.equipment.join(' + ')}`;
    lines.push(line);
    if (set.notes) lines.push(`    ${set.notes}`);
  });
  lines.push('');
  lines.push(`TOTAL: ${formatNumber(totals.distance)} ${totals.unit} · ${totals.reps} reps · ~${formatDuration(totals.seconds)}`);
  if (practice.notes) {
    lines.push('');
    lines.push('NOTES');
    lines.push(practice.notes);
  }
  lines.push('');
  lines.push('Made with SwimSet');
  return lines.join('\n');
}
