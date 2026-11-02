import test from 'node:test';
import assert from 'node:assert/strict';
import * as core from '../js/core.js';
import { TEMPLATES, templateToPractice } from '../js/templates.js';

const practice = (overrides = {}) => core.createPractice({ basePace: 100, roundTo: 5, ...overrides });

test('parseTime accepts coach-friendly formats', () => {
  assert.equal(core.parseTime(90), 90);
  assert.equal(core.parseTime('90'), 90);
  assert.equal(core.parseTime('90s'), 90);
  assert.equal(core.parseTime('1:30'), 90);
  assert.equal(core.parseTime(':45'), 45);
  assert.equal(core.parseTime('1:05:00'), 3900);
  assert.equal(core.parseTime('1.30'), 90);
  assert.equal(core.parseTime('1:52.5'), 113);
  assert.equal(core.parseTime('2:00'), 120);
  assert.equal(core.parseTime('0'), 0);
  assert.equal(core.parseTime(''), null);
  assert.equal(core.parseTime('abc'), null);
  assert.equal(core.parseTime('1:99'), null);
  assert.equal(core.parseTime(null), null);
});

test('decimal time parsing keeps tenths for the pace tools', () => {
  assert.equal(core.parseTimeFloat('1:52.5'), 112.5);
  assert.equal(core.parseTimeFloat('112.5'), 112.5);
  assert.equal(core.parseTimeFloat('1.30'), 90);
  assert.equal(core.parseTimeFloat('90s'), 90);
  assert.equal(core.parseTimeFloat('nope'), null);
  assert.equal(core.parseTime('1:52.5'), 113);
  assert.equal(core.formatClockDecimal(112.96), '1:53');
  assert.equal(core.formatClockDecimal(59.96), '1:00');
  assert.equal(core.formatClockDecimal(45.5), ':45.5');
});

test('formatClock and formatDuration', () => {
  assert.equal(core.formatClock(90), '1:30');
  assert.equal(core.formatClock(45), ':45');
  assert.equal(core.formatClock(60), '1:00');
  assert.equal(core.formatClock(3900), '1:05:00');
  assert.equal(core.formatClock(0), ':00');
  assert.equal(core.formatDuration(45), '45 sec');
  assert.equal(core.formatDuration(600), '10 min');
  assert.equal(core.formatDuration(3600), '1 h');
  assert.equal(core.formatDuration(3900), '1 h 5 min');
  assert.equal(core.formatClockDecimal(112.4), '1:52.4');
  assert.equal(core.formatClockDecimal(112), '1:52');
});

test('roundUpTo respects the step and does not over-round exact values', () => {
  assert.equal(core.roundUpTo(90, 5), 90);
  assert.equal(core.roundUpTo(90.1, 5), 95);
  assert.equal(core.roundUpTo(91, 5), 95);
  assert.equal(core.roundUpTo(92, 10), 100);
  assert.equal(core.roundUpTo(45, 1), 45);
  assert.equal(core.roundUpTo(0, 5), 0);
});

test('auto send-off = swim target + rest, rounded up', () => {
  const p = practice();
  const set = core.createSet({ reps: 4, distance: 100, rest: 20 });
  assert.equal(core.sendoffForSet(set, p), 120);
  assert.equal(core.durationForSet(set, p), 480);
  assert.equal(core.swimSecondsForSet(set, p), 400);

  const p10 = practice({ roundTo: 10 });
  assert.equal(core.sendoffForSet(set, p10), 120);

  set.rest = 17;
  assert.equal(core.sendoffForSet(set, p), 120);
  assert.equal(core.sendoffForSet(set, p10), 120);

  const fifty = core.createSet({ distance: 50, rest: 20 });
  assert.equal(core.sendoffForSet(fifty, p), 70);

  const target = core.createSet({ distance: 100, rest: 10, pace100: 80 });
  assert.equal(core.sendoffForSet(target, p), 90);
});

test('manual and no-interval sets', () => {
  const p = practice();
  const manual = core.createSet({ reps: 4, distance: 100, intervalMode: 'manual', interval: 90 });
  assert.equal(core.sendoffForSet(manual, p), 90);
  assert.equal(core.durationForSet(manual, p), 360);

  const continuous = core.createSet({ reps: 4, distance: 100, intervalMode: 'none', rest: 20 });
  assert.equal(core.sendoffForSet(continuous, p), null);
  // 400 swim + 3 × 20 rest
  assert.equal(core.durationForSet(continuous, p), 460);
});

test('practice totals add up', () => {
  const p = practice();
  p.sets = [
    core.createSet({ type: 'warmup', reps: 4, distance: 100, rest: 20 }),
    core.createSet({ type: 'main', reps: 8, distance: 50, stroke: 'Back', rest: 20 }),
    core.createSet({ type: 'cooldown', reps: 1, distance: 400, intervalMode: 'none', rest: 0 }),
  ];
  const totals = core.practiceTotals(p);
  assert.equal(totals.distance, 400 + 400 + 400);
  assert.equal(totals.reps, 13);
  assert.equal(totals.setCount, 3);
  assert.equal(totals.unit, 'm');
  assert.equal(totals.seconds, 4 * 120 + 8 * 70 + 400);
  const back = totals.byStroke.find((row) => row.stroke === 'Back');
  assert.equal(back.distance, 400);
});

test('compileSteps expands every rep', () => {
  const p = practice();
  p.sets = [
    core.createSet({ reps: 2, distance: 100 }),
    core.createSet({ reps: 3, distance: 50 }),
  ];
  const steps = core.compileSteps(p);
  assert.equal(steps.length, 5);
  assert.equal(new Set(steps.map((s) => s.key)).size, 5);
  assert.equal(steps[2].setIndex, 1);
  assert.equal(steps[2].rep, 1);
  assert.equal(steps[4].reps, 3);
});

test('normalisation clamps and repairs imported data', () => {
  const messy = core.normalizePractice({
    title: '  Test  ',
    course: 'XXL',
    basePace: -5,
    roundTo: 7,
    date: 'nope',
    sets: [
      { reps: '0', distance: '-25', type: 'bogus', intervalMode: 'manual', interval: 0 },
      { reps: 4, distance: 100, stroke: 'Dolphin', equipment: ['Fins', 42] },
    ],
  });
  assert.equal(messy.title, 'Test');
  assert.equal(messy.course, 'SCM');
  assert.equal(messy.basePace, 20);
  assert.equal(messy.roundTo, 5);
  assert.match(messy.date, /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(messy.sets[0].reps, 1);
  assert.equal(messy.sets[0].distance, 1);
  assert.equal(messy.sets[0].type, 'main');
  assert.equal(messy.sets[0].intervalMode, 'pace');
  assert.equal(messy.sets[1].stroke, 'Free');
  assert.deepEqual(messy.sets[1].equipment, ['Fins']);
});

test('validation flags missing warm-up and impossible intervals', () => {
  const p = practice();
  p.sets = [
    core.createSet({ type: 'main', reps: 4, distance: 100, intervalMode: 'manual', interval: 60 }),
  ];
  const issues = core.validatePractice(p);
  const messages = issues.map((i) => i.message).join(' | ');
  assert.match(messages, /warm-up/i);
  assert.match(messages, /cool-down/i);
  assert.match(messages, /shorter than/i);
  assert.ok(issues.some((i) => i.level === 'error'));

  const empty = core.validatePractice(practice());
  assert.ok(empty.some((i) => i.level === 'error' && /at least one set/i.test(i.message)));
});

test('course conversions and pace ladders', () => {
  assert.equal(core.convertTime(100, 'SCY', 'SCM'), 111);
  assert.equal(core.convertTime(111, 'SCM', 'SCY'), 100);
  assert.equal(core.convertPace(100, 'SCY', 'LCM'), 113);
  const ladder = core.paceLadder(100, { roundTo: 5, rest: 0 });
  assert.deepEqual(ladder.slice(0, 4).map((r) => r.sendoff), [25, 50, 75, 100]);
  const withRest = core.paceLadder(100, { roundTo: 5, rest: 20, distances: [100] });
  assert.equal(withRest[0].sendoff, 120);
});

test('clonePractice creates fresh ids and keeps content', () => {
  const p = practice({ title: 'Speed' });
  p.sets = [core.createSet({ reps: 3, distance: 200 })];
  const copy = core.clonePractice(p);
  assert.notEqual(copy.id, p.id);
  assert.notEqual(copy.sets[0].id, p.sets[0].id);
  assert.equal(copy.sets[0].reps, 3);
  assert.equal(copy.title, 'Speed (copy)');
});

test('practiceToText produces a printable text sheet', () => {
  const p = practice({ title: 'Morning speed', group: 'Senior' });
  p.sets = [
    core.createSet({ type: 'warmup', reps: 4, distance: 100, rest: 20 }),
    core.createSet({ type: 'cooldown', reps: 1, distance: 200, intervalMode: 'none', rest: 0 }),
  ];
  const text = core.practiceToText(p);
  assert.match(text, /MORNING SPEED/);
  assert.match(text, /SCM/);
  assert.match(text, /Warm-up/);
  assert.match(text, /TOTAL: 600 m/);
  assert.match(text, /Made with SwimSet/);
});

test('every built-in template is complete and valid', () => {
  assert.ok(TEMPLATES.length >= 6);
  for (const template of TEMPLATES) {
    const p = templateToPractice(template);
    assert.ok(p.sets.length > 0, `${template.id} has sets`);
    assert.ok(core.practiceTotals(p).distance > 0, `${template.id} has distance`);
    assert.ok(core.practiceTotals(p).seconds > 0, `${template.id} has duration`);
    assert.ok(p.basePace > 0, `${template.id} has a base pace`);
    const errors = core.validatePractice(p).filter((i) => i.level === 'error');
    assert.deepEqual(errors, [], `${template.id} has no errors`);
    for (const set of p.sets) {
      assert.ok(set.reps >= 1 && set.distance >= 1, `${template.id} set is valid`);
      const sendoff = core.sendoffForSet(set, p);
      if (sendoff) {
        const perRep = (set.distance / 100) * core.paceForSet(set, p);
        assert.ok(sendoff >= perRep, `${template.id} send-off fits the swim`);
      }
    }
  }
});
