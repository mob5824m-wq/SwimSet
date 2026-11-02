import 'package:flutter_test/flutter_test.dart';
import 'package:swimset/src/models.dart';
import 'package:swimset/src/templates.dart';

void main() {
  group('time parsing', () {
    test('accepts coach-friendly formats', () {
      expect(parseTimeSeconds('1:40'), 100);
      expect(parseTimeSeconds('100'), 100);
      expect(parseTimeSeconds('90s'), 90);
      expect(parseTimeSeconds(':45'), 45);
      expect(parseTimeSeconds('1:40.5'), 100.5);
      expect(parseTimeSeconds('1.30'), 90);
      expect(parseTimeSeconds('1:02:03'), 3723);
      expect(parseTimeSeconds('later'), isNull);
      expect(parseTimeSeconds(''), isNull);
    });

    test('formats clocks and durations', () {
      expect(formatClock(100), '1:40');
      expect(formatClock(45), '0:45');
      expect(formatClock(3600), '1:00:00');
      expect(formatClock(3725), '1:02:05');
      expect(formatClockDecimal(180.18), '3:00.2');
      expect(formatClockDecimal(100), '1:40');
      expect(formatDuration(45), '45 sec');
      expect(formatDuration(1520), '25 min');
      expect(formatDuration(4320), '1 h 12 min');
    });

    test('formats dates and numbers', () {
      expect(formatDate('2026-10-31'), 'Sat, Oct 31, 2026');
      expect(formatNumber(1200), '1,200');
      expect(formatNumber(0), '0');
    });
  });

  group('send-off maths', () {
    final practice = Practice(
      id: 'p',
      title: 'Test',
      course: Course.scm,
      basePace: 100,
      roundTo: 5,
    );

    test('100s on 1:40 plus 20s rest rounds to 2:00', () {
      final set = PracticeSet(id: 's', reps: 4, distance: 100, rest: 20);
      expect(sendOffForSet(set, practice), 120);
      expect(durationForSet(set, practice), 480);
      expect(swimSecondsForSet(set, practice), 400);
    });

    test('50s on 1:40 plus 20s rest rounds to 1:10', () {
      final set = PracticeSet(id: 's', reps: 8, distance: 50, rest: 20);
      expect(sendOffForSet(set, practice), 70);
      expect(durationForSet(set, practice), 560);
    });

    test('rounds up to the practice step', () {
      final set = PracticeSet(id: 's', reps: 4, distance: 100, rest: 21);
      expect(sendOffForSet(set, practice), 125);
    });

    test('manual and continuous intervals', () {
      final manual = PracticeSet(
        id: 's',
        reps: 4,
        distance: 100,
        intervalMode: IntervalMode.manual,
        interval: 130,
      );
      expect(sendOffForSet(manual, practice), 130);
      expect(durationForSet(manual, practice), 520);

      final continuous = PracticeSet(
        id: 's',
        reps: 4,
        distance: 100,
        rest: 30,
        intervalMode: IntervalMode.none,
      );
      expect(sendOffForSet(continuous, practice), isNull);
      // 4 × 100s swim + 3 × 30s rest.
      expect(durationForSet(continuous, practice), 490);
    });

    test('per-set target pace wins over base pace', () {
      final set = PracticeSet(id: 's', reps: 4, distance: 100, pace100: 80, rest: 20);
      expect(paceForSet(set, practice), 80);
      expect(sendOffForSet(set, practice), 100);
    });
  });

  group('totals and steps', () {
    final practice = Practice(
      id: 'p',
      title: 'First practice',
      course: Course.scm,
      basePace: 100,
      roundTo: 5,
      sets: [
        PracticeSet(id: 'a', type: SetType.warmup, reps: 4, distance: 100, rest: 20),
        PracticeSet(id: 'b', type: SetType.main, reps: 8, distance: 50, rest: 20),
        PracticeSet(id: 'c', type: SetType.cooldown, reps: 4, distance: 100, stroke: Stroke.choice, rest: 20),
      ],
    );

    test('aggregates volume, reps and duration', () {
      final totals = practiceTotals(practice);
      expect(totals.distance, 1200);
      expect(totals.reps, 16);
      expect(totals.setCount, 3);
      expect(totals.seconds, 1520);
      expect(totals.byStroke[Stroke.free], 800);
      expect(totals.byStroke[Stroke.choice], 400);
    });

    test('compiles rep-by-rep steps', () {
      final steps = compileSteps(practice);
      expect(steps.length, 16);
      expect(steps.first.durationMs, 120000);
      expect(steps[4].setIndex, 1);
      expect(steps[4].rep, 1);
      expect(steps.last.rep, 4);
      expect(steps.last.label, contains('4 × 100 m Choice'));
    });

    test('validates', () {
      expect(validatePractice(practice), isEmpty);
      final empty = Practice(id: 'p2', title: 'Untitled practice');
      final issues = validatePractice(empty);
      expect(issues.any((issue) => issue.level == IssueLevel.error), isTrue);
    });
  });

  group('serialisation', () {
    test('round-trips JSON', () {
      final practice = Practice(
        id: 'p1',
        title: 'Morning set',
        course: Course.scy,
        basePace: 85,
        roundTo: 5,
        group: 'Squad',
        focus: 'Speed',
        sets: [
          PracticeSet(
            id: 's1',
            type: SetType.sprint,
            reps: 6,
            distance: 50,
            stroke: Stroke.fly,
            equipment: ['Fins'],
            pace100: 70,
            rest: 40,
            notes: 'Fast',
          ),
        ],
      );
      final restored = Practice.fromJson(practice.toJson());
      expect(restored.title, 'Morning set');
      expect(restored.course, Course.scy);
      expect(restored.sets.single.equipment, ['Fins']);
      expect(restored.sets.single.stroke, Stroke.fly);
      expect(restored.sets.single.pace100, 70);
      expect(restored.sets.single.notes, 'Fast');
    });

    test('clamps bad input', () {
      final restored = normalizePractice({
        'title': '  ',
        'course': 'nope',
        'basePace': 2,
        'roundTo': 7,
        'sets': [
          {'reps': -4, 'distance': 0, 'intervalMode': 'weird'},
        ],
      });
      expect(restored.title, 'Untitled practice');
      expect(restored.course, Course.scm);
      expect(restored.basePace, 20);
      expect(restored.roundTo, 5);
      expect(restored.sets.single.reps, 1);
      expect(restored.sets.single.distance, 1);
      expect(restored.sets.single.intervalMode, IntervalMode.pace);
    });
  });

  group('conversions', () {
    test('converts between courses', () {
      expect(convertTime(200, Course.scm, Course.scy), closeTo(180.18, 0.01));
      expect(convertPace(200, Course.scm, Course.scy), 180);
      expect(formatClockDecimal(convertTime(200, Course.scm, Course.scy)), '3:00.2');
    });

    test('builds a ladder', () {
      final rows = paceLadder(100, roundTo: 5, rest: 20);
      expect(rows.first.distance, 25);
      expect(rows.first.sendOff, 45);
      expect(rows[3].distance, 100);
      expect(rows[3].sendOff, 120);
      expect(rows.last.distance, 500);
      expect(rows.last.sendOff, 520);
    });
  });

  group('templates and text', () {
    test('ships seven templates', () {
      expect(practiceTemplates.length, 7);
      final practice = templateToPractice(practiceTemplates.first);
      expect(practice.title, 'Sprint Power');
      expect(practice.sets, isNotEmpty);
      expect(practiceTotals(practice).distance, greaterThan(0));
    });

    test('exports readable text', () {
      final practice = templateToPractice(practiceTemplates.first);
      final text = practiceToText(practice);
      expect(text, contains('SPRINT POWER'));
      expect(text, contains('TOTAL:'));
      expect(text, contains('Made with SwimSet'));
    });
  });

  group('heats', () {
    Practice build() => Practice(
          id: 'p1',
          title: 'Heats',
          course: Course.scm,
          basePace: 100,
          roundTo: 5,
          heatInterval: 90,
          heats: [
            Heat(id: 'h1', name: 'Heat 1', basePace: 110),
            Heat(id: 'h2', name: 'Heat 2'),
          ],
          sets: [
            PracticeSet(
              id: 's1',
              type: SetType.main,
              reps: 4,
              distance: 100,
              stroke: Stroke.free,
              rest: 20,
            ),
          ],
        );

    test('each heat swims off its own pace', () {
      final practice = build();
      final set = practice.sets.single;
      expect(sendOffForSet(set, practice), 120);
      expect(sendOffForSet(set, practice, heat: practice.heats[0]), 130);
      expect(sendOffForSet(set, practice, heat: practice.heats[1]), 120);
      expect(basePaceForHeat(practice, practice.heats[1]), 100);
    });

    test('totals and steps follow the heat', () {
      final practice = build();
      expect(practiceTotals(practice).seconds, 480);
      expect(practiceTotals(practice, heat: practice.heats[0]).seconds, 520);
      final steps = compileSteps(practice, heat: practice.heats[0]);
      expect(steps.length, 4);
      expect(steps.first.sendOff, 130);
      expect(steps.first.durationMs, 130000);
      expect(steps.first.label, contains('2:10'));
    });

    test('start offsets stagger the heats', () {
      final practice = build();
      expect(heatStartOffset(practice, 0), 0);
      expect(heatStartOffset(practice, 1), 90);
      expect(heatStartOffset(practice, 2), 180);
      expect(heatDurationMs(practice, practice.heats[0]), 520000);
    });

    test('heats survive JSON and text export', () {
      final practice = build();
      final restored = Practice.fromJson(practice.toJson());
      expect(restored.heats.length, 2);
      expect(restored.heats.first.name, 'Heat 1');
      expect(restored.heats.first.basePace, 110);
      expect(restored.heats[1].basePace, isNull);
      expect(restored.heatInterval, 90);
      final text = practiceToText(practice);
      expect(text, contains('Heats: Heat 1 1:50 · Heat 2 1:40'));
      expect(text, contains('Heat 1 2:10'));
      expect(text, contains('BY HEAT:'));
    });

    test('sparse heats are normalized', () {
      final restored = normalizePractice({
        'heats': [
          {'basePace': 5},
          {'name': '  ', 'basePace': 200},
        ],
        'heatInterval': -30,
      });
      expect(restored.heats.length, 2);
      expect(restored.heats.first.name, 'Heat 1');
      expect(restored.heats.first.basePace, isNull);
      expect(restored.heats[1].name, 'Heat 2');
      expect(restored.heats[1].basePace, 200);
      expect(restored.heatInterval, 0);
    });
  });

  group('blocks and heat overrides', () {
    Practice build() => Practice(
          id: 'pb',
          title: 'Blocks',
          basePace: 100,
          roundTo: 5,
          heats: [Heat(id: 'h1', name: 'Heat 1', basePace: 110)],
          sets: [
            PracticeSet(
              id: 's1',
              reps: 4,
              distance: 50,
              rest: 20,
              blockId: 'b1',
              blockRounds: 3,
            ),
            PracticeSet(
              id: 's2',
              reps: 2,
              distance: 200,
              rest: 20,
              blockId: 'b1',
              blockRounds: 3,
            ),
            PracticeSet(
              id: 's3',
              reps: 4,
              distance: 100,
              rest: 20,
              heatSendOffs: {'h1': 135},
            ),
          ],
        );

    test('blocks repeat their sets in order', () {
      final practice = build();
      final expanded = expandSets(practice);
      expect(expanded.length, 7);
      expect(expanded.first.set.id, 's1');
      expect(expanded.first.round, 1);
      expect(expanded[2].set.id, 's1');
      expect(expanded[2].round, 2);
      expect(expanded.last.set.id, 's3');
      expect(expanded.where((entry) => entry.rounds == 3).length, 6);
    });

    test('blocks expand into steps and totals', () {
      final practice = build();
      final steps = compileSteps(practice);
      expect(steps.length, 3 * (4 + 2) + 4);
      expect(steps.first.key, 's1:1:0');
      expect(steps.first.round, 1);
      expect(steps.first.rounds, 3);
      expect(practiceTotals(practice).distance, 2200);
      expect(practiceToText(practice), contains('Round 2/3'));
    });

    test('per-heat send-off overrides win over the heat pace', () {
      final practice = build();
      final set = practice.sets.last;
      final heat = practice.heats.first;
      expect(sendOffForSet(set, practice), 120);
      expect(autoSendOffForSet(set, practice, heat: heat), 130);
      expect(sendOffForSet(set, practice, heat: heat), 135);
      final restored = Practice.fromJson(practice.toJson());
      expect(restored.sets.last.heatSendOffs['h1'], 135);
      expect(restored.sets.first.blockId, 'b1');
      expect(restored.sets.first.blockRounds, 3);
    });

    test('explicit heat offsets win over the interval', () {
      final practice = Practice(
        id: 'po',
        heatInterval: 60,
        heats: [
          Heat(id: 'h1', name: 'H1'),
          Heat(id: 'h2', name: 'H2', startOffset: 150),
        ],
      );
      expect(heatStartFor(practice, 0), 0);
      expect(heatStartFor(practice, 1), 150);
      final restored = Practice.fromJson(practice.toJson());
      expect(restored.heats[1].startOffset, 150);
    });
  });

  group('lanes and volume balance', () {
    test('heat lanes survive JSON and the text export', () {
      final practice = Practice(
        id: 'pl',
        title: 'Lanes',
        heats: [Heat(id: 'h1', name: 'Heat 1', lanes: '3–5')],
        sets: [PracticeSet(id: 's1')],
      );
      final restored = Practice.fromJson(practice.toJson());
      expect(restored.heats.first.lanes, '3–5');
      expect(practiceToText(practice), contains('lanes 3–5'));
      expect(Practice.fromJson({'id': 'px', 'heats': [{'name': 'H', 'lanes': '  1-2  '}]})
          .heats
          .first
          .lanes, '1-2');
    });

    test('volume split follows the set types', () {
      final practice = Practice(
        id: 'pv',
        sets: [
          PracticeSet(id: 'w', type: SetType.warmup, reps: 4, distance: 100),
          PracticeSet(id: 'm', type: SetType.main, reps: 10, distance: 100),
          PracticeSet(id: 'c', type: SetType.cooldown, reps: 2, distance: 100),
        ],
      );
      final split = volumeSplit(practice);
      expect(split.total, 1600);
      expect(split.warmup, 400);
      expect(split.main, 1000);
      expect(split.cooldown, 200);
      expect(split.share(VolumeBucket.main), closeTo(0.625, 0.0001));
      expect(volumeNudge(practice), isNull);

      final mainOnly = Practice(
        id: 'pm',
        sets: [PracticeSet(id: 'm2', type: SetType.main, reps: 20, distance: 100)],
      );
      expect(volumeNudge(mainOnly), isNotNull);
      expect(validatePractice(mainOnly).any((issue) => issue.message.contains('Main work')), isTrue);
    });

    test('volume targets clamp and default', () {
      final practice = Practice.fromJson(
          {'id': 'pt', 'targetWarmup': 300, 'targetMain': -5, 'targetCooldown': 20});
      expect(practice.targetWarmup, 100);
      expect(practice.targetMain, 0);
      expect(practice.targetCooldown, 20);
      final defaults = Practice(id: 'pd');
      expect(defaults.targetWarmup, 25);
      expect(defaults.targetMain, 60);
      expect(defaults.targetCooldown, 15);
      expect(Practice.fromJson(defaults.toJson()).targetMain, 60);
    });

    test('reordering detaches a broken block', () {
      final practice = Practice(
        id: 'pb2',
        sets: [
          PracticeSet(id: 'a', blockId: 'b', blockRounds: 2),
          PracticeSet(id: 'b', blockId: 'b', blockRounds: 2),
          PracticeSet(id: 'c'),
        ],
      );
      expect(expandSets(practice).length, 5);
      practice.sets.insert(1, practice.sets.removeAt(2));
      normalizeBlocks(practice);
      expect(practice.sets.every((set) => set.blockId == null), isTrue);
      expect(expandSets(practice).length, 3);
    });
  });
}
