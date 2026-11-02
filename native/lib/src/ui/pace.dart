import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class PacePage extends StatefulWidget {
  const PacePage({super.key});

  @override
  State<PacePage> createState() => _PacePageState();
}

class _PacePageState extends State<PacePage> {
  int _ladderPace = 100;
  int _ladderRest = 0;
  int _ladderRound = 5;

  int _convertSeconds = 200;
  Course _from = Course.scm;
  Course _to = Course.scy;

  int _swimSeconds = 500;
  int _swimDistance = 500;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1120;
      final cards = [
        _ladderCard(context),
        _converterCard(context),
        _paceCard(context),
      ];
      return ListView(
        padding: EdgeInsets.fromLTRB(constraints.maxWidth >= 760 ? 28 : 16, 22,
            constraints.maxWidth >= 760 ? 28 : 16, 30),
        children: [
          Text('Pace & send-off tools',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            'Turn a target pace into send-offs, convert between courses, or work out a pace from a swim time.',
            style: TextStyle(color: SwimTheme.muted(context), fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  cards[i],
                ],
              ],
            ),
        ],
      );
    });
  }

  Widget _cardHeader(BuildContext context, IconData icon, String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17))),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: SwimTheme.muted(context))),
        ],
      );

  Widget _ladderCard(BuildContext context) {
    final rows = paceLadder(_ladderPace, roundTo: _ladderRound, rest: _ladderRest);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(context, Icons.straighten, 'Send-off ladder', 'Every distance from one base pace.'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Pace / 100',
                  child: TimeField(
                    seconds: _ladderPace,
                    onChanged: (value) {
                      if (value != null) setState(() => _ladderPace = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Rest (sec)',
                  child: NumberField(
                    value: _ladderRest,
                    min: 0,
                    max: 600,
                    onChanged: (value) => setState(() => _ladderRest = value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Round',
                  child: DropdownButtonFormField<int>(
                    value: _ladderRound,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 sec')),
                      DropdownMenuItem(value: 5, child: Text('5 sec')),
                      DropdownMenuItem(value: 10, child: Text('10 sec')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _ladderRound = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _headCell(context, 'DIST')),
                Expanded(child: _headCell(context, 'SWIM', align: TextAlign.right)),
                Expanded(child: _headCell(context, 'SEND-OFF', align: TextAlign.right)),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: SwimTheme.line(context), width: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${row.distance}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(
                      formatClock(row.swim),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: SwimTheme.muted(context),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatClock(row.sendOff),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _note(context, 'Send-off = swim target + rest, rounded up. The same maths powers the builder.'),
        ],
      ),
    );
  }

  Widget _converterCard(BuildContext context) {
    final converted = convertTime(_convertSeconds.toDouble(), _from, _to);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(context, Icons.swap_horiz, 'Course converter', 'Approximate training equivalents.'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: LabeledField(
                  label: 'Swim time',
                  child: TimeField(
                    seconds: _convertSeconds,
                    onChanged: (value) {
                      if (value != null) setState(() => _convertSeconds = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: LabeledField(
                  label: 'From',
                  child: DropdownButtonFormField<Course>(
                    value: _from,
                    isExpanded: true,
                    items: [
                      for (final course in Course.values)
                        DropdownMenuItem(value: course, child: Text(course.code)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _from = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: LabeledField(
                  label: 'To',
                  child: DropdownButtonFormField<Course>(
                    value: _to,
                    isExpanded: true,
                    items: [
                      for (final course in Course.values)
                        DropdownMenuItem(value: course, child: Text(course.code)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _to = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_from.code} → ${_to.code}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: SwimTheme.muted(context),
                    ),
                  ),
                ),
                Text(
                  formatClockDecimal(converted),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final course in Course.values)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: course == _to ? Theme.of(context).colorScheme.primary.withOpacity(0.06) : null,
                borderRadius: BorderRadius.circular(8),
                border: Border(bottom: BorderSide(color: SwimTheme.line(context), width: 0.6)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(course.code,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: course == _to ? Theme.of(context).colorScheme.primary : null,
                        )),
                  ),
                  Expanded(
                    child: Text(course.poolLabel,
                        style: TextStyle(fontSize: 12, color: SwimTheme.muted(context))),
                  ),
                  Text(
                    formatClockDecimal(convertTime(_convertSeconds.toDouble(), _from, course)),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _note(context, 'Estimates use SCY → SCM ×1.11 and SCY → LCM ×1.13. Not an official conversion.'),
        ],
      ),
    );
  }

  Widget _paceCard(BuildContext context) {
    final pacePer100 = _swimDistance <= 0 ? 0.0 : (_swimSeconds / _swimDistance) * 100;
    final rows = [50, 100, 200].map((distance) {
      final target = pacePer100 * distance / 100;
      return (distance: distance, target: target, sendOff: roundUpTo(target, 5));
    }).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(context, Icons.speed, 'Pace from a swim', 'Turn a known time into a training pace.'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Time swam',
                  child: TimeField(
                    seconds: _swimSeconds,
                    onChanged: (value) {
                      if (value != null) setState(() => _swimSeconds = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Distance',
                  child: NumberField(
                    value: _swimDistance,
                    min: 25,
                    max: 10000,
                    onChanged: (value) => setState(() => _swimDistance = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('PACE PER 100',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.9,
                        color: SwimTheme.muted(context),
                      )),
                ),
                Text(
                  pacePer100 <= 0 ? '—' : formatClockDecimal(pacePer100),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SwimTheme.line(context)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final row in rows)
                  Text(
                    '${formatClock(row.sendOff)} /${row.distance} send-off',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _note(context, 'Gives the pace per 100 for that swim. Use it as a base pace or a per-set target.'),
        ],
      ),
    );
  }

  Widget _headCell(BuildContext context, String text, {TextAlign align = TextAlign.left}) => Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: SwimTheme.muted(context),
        ),
      );

  Widget _note(BuildContext context, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 14, color: SwimTheme.muted(context)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, height: 1.35, color: SwimTheme.muted(context)),
            ),
          ),
        ],
      );
}
