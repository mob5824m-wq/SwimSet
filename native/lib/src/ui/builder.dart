import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../templates.dart';
import '../theme.dart';
import 'common.dart';

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key, required this.state});

  final AppState state;

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  late final TextEditingController _title;
  late final TextEditingController _group;
  late final TextEditingController _focus;
  late final TextEditingController _notes;
  late String _draftId;

  @override
  void initState() {
    super.initState();
    _draftId = widget.state.draft.id;
    _title = TextEditingController(text: widget.state.draft.title);
    _group = TextEditingController(text: widget.state.draft.group);
    _focus = TextEditingController(text: widget.state.draft.focus);
    _notes = TextEditingController(text: widget.state.draft.notes);
  }

  @override
  void didUpdateWidget(BuilderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draftId != widget.state.draft.id) {
      _draftId = widget.state.draft.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _title.text = widget.state.draft.title;
        _group.text = widget.state.draft.group;
        _focus.text = widget.state.draft.focus;
        _notes.text = widget.state.draft.notes;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _group.dispose();
    _focus.dispose();
    _notes.dispose();
    super.dispose();
  }

  Practice get _practice => widget.state.draft;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseISODate(_practice.date),
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;
    widget.state.updateDraft((practice) => practice.date = todayISO(picked));
  }

  Future<void> _save() async {
    await widget.state.saveCurrent();
    if (!mounted) return;
    showSnack(context, 'Saved to library');
  }

  void _startPoolside() {
    if (_practice.sets.isEmpty) {
      showSnack(context, 'Add at least one set first.');
      return;
    }
    widget.state.startRun();
  }

  void _addSet() {
    widget.state.updateDraft((practice) {
      final last = practice.sets.isEmpty ? null : practice.sets.last;
      practice.sets.add(PracticeSet(
        id: uid('s'),
        type: SetType.main,
        reps: 4,
        distance: last?.distance ?? 100,
        stroke: last?.stroke ?? Stroke.free,
        rest: last?.rest ?? 20,
        intervalMode: IntervalMode.pace,
      ));
    });
  }

  void _openTemplates() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: SwimTheme.line(sheetContext)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start from a template', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            'Replaces the current practice — your saved practices stay put.',
                            style: TextStyle(color: SwimTheme.muted(sheetContext), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconAction(icon: Icons.close, tooltip: 'Close', onPressed: () => Navigator.of(sheetContext).pop()),
                  ],
                ),
              ),
              Divider(height: 1, color: SwimTheme.line(sheetContext)),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: practiceTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final template = practiceTemplates[index];
                    final totals = practiceTotals(templateToPractice(template));
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.state.useTemplate(template);
                          showSnack(this.context, 'Loaded “${template.name}”');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(template.name, style: theme.textTheme.titleMedium)),
                                  TinyPill('${template.course.code} · ${formatNumber(totals.distance)} ${template.course.unit}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: TextStyle(color: SwimTheme.muted(context), fontSize: 12.5, height: 1.35),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final tag in template.tags) TinyPill(tag),
                                  TinyPill('${totals.setCount} sets'),
                                  TinyPill('~${formatDuration(totals.seconds)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final draft = state.draft;
    final totals = state.totals;
    final issues = state.issues;

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1080;
      final compact = constraints.maxWidth < 560;

      final editor = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, compact),
          const SizedBox(height: 14),
          _metaCard(context, compact),
          const SizedBox(height: 14),
          _heatsCard(context, compact),
          const SizedBox(height: 14),
          if (!wide) ...[
            _totalsCard(context, totals, compact),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(child: Text('Sets', style: Theme.of(context).textTheme.titleLarge)),
              Text(
                '${draft.sets.length} set${draft.sets.length == 1 ? '' : 's'}',
                style: TextStyle(color: SwimTheme.muted(context), fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (draft.sets.isEmpty)
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add, size: 30, color: SwimTheme.muted(context)),
                    const SizedBox(height: 8),
                    Text('No sets yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('Add a set or start from a template.',
                        style: TextStyle(color: SwimTheme.muted(context), fontSize: 12.5)),
                  ],
                ),
              ),
            )
          else
            for (var index = 0; index < draft.sets.length; index++) ...[
              SetEditorCard(
                key: ValueKey(draft.sets[index].id),
                state: state,
                index: index,
                set: draft.sets[index],
                unit: draft.course.unit,
                totalSets: draft.sets.length,
              ),
              const SizedBox(height: 10),
            ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add set'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _openTemplates,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Templates'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Send-offs calculate from base pace and rest.',
            style: TextStyle(color: SwimTheme.muted(context), fontSize: 11.5),
          ),
          const SizedBox(height: 18),
          if (!wide) _checkCard(context, issues),
        ],
      );

      if (!wide) {
        return ListView(
          padding: EdgeInsets.fromLTRB(compact ? 14 : 22, 18, compact ? 14 : 22, 28),
          children: [editor],
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: editor),
                const SizedBox(width: 18),
                SizedBox(
                  width: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _totalsCard(context, totals, false),
                      const SizedBox(height: 14),
                      _checkCard(context, issues),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _header(BuildContext context, bool compact) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: compact ? 23 : 28),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Practice title',
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: compact ? 23 : 28,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.32),
                    ),
                  ),
                  onChanged: (value) => widget.state.updateDraft((practice) => practice.title = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
              ),
              OutlinedButton.icon(
                onPressed: _startPoolside,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Poolside'),
              ),
              OutlinedButton.icon(
                onPressed: _openTemplates,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Templates'),
              ),
              IconAction(
                icon: Icons.auto_awesome,
                tooltip: 'Start a blank practice',
                onPressed: widget.state.newPractice,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaCard(BuildContext context, bool compact) {
    final draft = _practice;
    final unit = draft.course.unit;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: compact ? double.infinity : 250,
                child: LabeledField(
                  label: 'Date',
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(formatDate(draft.date), overflow: TextOverflow.ellipsis),
                    ),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: compact ? (MediaQuery.sizeOf(context).width - 76) / 2 : 210,
                child: LabeledField(
                  label: 'Course',
                  child: DropdownButtonFormField<Course>(
                    value: draft.course,
                    isExpanded: true,
                    items: [
                      for (final course in Course.values)
                        DropdownMenuItem(
                          value: course,
                          child: Text('${course.code} — ${course.poolLabel}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.state.updateDraft((practice) => practice.course = value);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: compact ? (MediaQuery.sizeOf(context).width - 76) / 2 : 160,
                child: LabeledField(
                  label: 'Base pace / 100 $unit',
                  child: TimeField(
                    seconds: draft.basePace,
                    onChanged: (value) {
                      if (value != null) widget.state.updateDraft((practice) => practice.basePace = value);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: compact ? (MediaQuery.sizeOf(context).width - 76) / 2 : 160,
                child: LabeledField(
                  label: 'Round send-offs',
                  child: DropdownButtonFormField<int>(
                    value: draft.roundTo,
                    isExpanded: true,
                    items: [
                      for (final step in roundSteps)
                        DropdownMenuItem(value: step, child: Text('To $step sec')),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.state.updateDraft((practice) => practice.roundTo = value);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : 210,
                child: LabeledField(
                  label: 'Group',
                  child: TextField(
                    controller: _group,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Squad, lane 3…'),
                    onChanged: (value) => widget.state.updateDraft((practice) => practice.group = value),
                  ),
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : 220,
                child: LabeledField(
                  label: 'Focus',
                  child: TextField(
                    controller: _focus,
                    decoration: const InputDecoration(hintText: 'Speed, technique…'),
                    onChanged: (value) => widget.state.updateDraft((practice) => practice.focus = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Practice notes',
            child: TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Warm-up instructions, lane assignments, reminders…'),
              onChanged: (value) => widget.state.updateDraft((practice) => practice.notes = value),
            ),
          ),
        ],
      ),
    );
  }

  void _addHeat() {
    widget.state.updateDraft((practice) {
      if (practice.heats.length >= 8) return;
      practice.heats.add(Heat(
        id: uid('h'),
        name: 'Heat ${practice.heats.length + 1}',
      ));
      if (practice.heats.length > 1 && practice.heatInterval <= 0) {
        practice.heatInterval = 60;
      }
    });
  }

  void _removeHeat(Heat heat) {
    widget.state.updateDraft((practice) {
      practice.heats.removeWhere((item) => item.id == heat.id);
      if (practice.heats.length < 2) practice.heatInterval = 0;
    });
  }

  void _updateHeat(String heatId, void Function(Heat heat) change) {
    widget.state.updateDraft((practice) {
      for (final heat in practice.heats) {
        if (heat.id == heatId) change(heat);
      }
    });
  }

  Widget _heatsCard(BuildContext context, bool compact) {
    final scheme = Theme.of(context).colorScheme;
    final practice = _practice;
    final heats = practice.heats;
    final unit = practice.course.unit;

    final header = Row(
      children: [
        Icon(Icons.groups_2_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text('Heats', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        if (heats.isNotEmpty) TinyPill('${heats.length} heats'),
        const Spacer(),
        if (heats.isEmpty)
          OutlinedButton.icon(
            onPressed: _addHeat,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add heats'),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );

    final explain = Text(
      heats.isEmpty
          ? 'One group swims every set off the base pace above. Add heats when lanes swim at different paces or need staggered starts.'
          : 'Each heat gets its own send-offs. A start interval staggers the send-offs in the poolside timer.',
      style: TextStyle(fontSize: 12, height: 1.35, color: SwimTheme.muted(context)),
    );

    if (heats.isEmpty) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, const SizedBox(height: 6), explain],
        ),
      );
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 6),
          explain,
          const SizedBox(height: 12),
          for (var index = 0; index < heats.length; index++) ...[
            _heatRow(context, heats[index], practice, unit, compact),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: heats.length < 8 ? _addHeat : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add heat'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabeledField(
                  label: 'Start next heat every',
                  child: NumberField(
                    value: practice.heatInterval,
                    min: 0,
                    max: 1800,
                    suffix: 'sec',
                    onChanged: (value) =>
                        widget.state.updateDraft((draft) => draft.heatInterval = value),
                  ),
                ),
              ),
            ],
          ),
          if (practice.heatInterval <= 0 && heats.length > 1) ...[
            const SizedBox(height: 6),
            Text(
              'At 0 seconds all heats start together.',
              style: TextStyle(fontSize: 11, color: SwimTheme.muted(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heatRow(BuildContext context, Heat heat, Practice practice, String unit, bool compact) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, compact ? 6 : 8, 6, compact ? 6 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwimTheme.line(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('heat-name-${heat.id}'),
              initialValue: heat.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Heat 1', isDense: true),
              onChanged: (value) => _updateHeat(heat.id, (item) => item.name = value),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: compact ? 104 : 128,
            child: TimeField(
              key: ValueKey('heat-pace-${heat.id}'),
              seconds: heat.basePace,
              allowEmpty: true,
              hint: formatClock(practice.basePace),
              onChanged: (value) => _updateHeat(heat.id, (item) => item.basePace = value),
            ),
          ),
          IconAction(
            icon: Icons.delete_outline,
            tooltip: 'Remove heat',
            onPressed: () => _removeHeat(heat),
          ),
        ],
      ),
    );
  }

  Widget _totalsCard(BuildContext context, Totals totals, bool compact) {
    final scheme = Theme.of(context).colorScheme;
    final draft = _practice;
    final strokeEntries = totals.byStroke.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatNumber(totals.distance),
                  style: const TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(draft.course.unit,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SwimTheme.muted(context))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('TOTAL VOLUME',
              style: TextStyle(
                  fontSize: 10, letterSpacing: 0.9, fontWeight: FontWeight.w700, color: SwimTheme.muted(context))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatTile(label: 'Session', value: formatDuration(totals.seconds), accent: scheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Reps', value: '${totals.reps}')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Sets', value: '${totals.setCount}')),
            ],
          ),
          if (strokeEntries.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final entry in strokeEntries.take(4)) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      child: Text(entry.key.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: totals.distance == 0 ? 0 : entry.value / totals.distance,
                          minHeight: 7,
                          backgroundColor: scheme.primary.withOpacity(0.10),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(formatNumber(entry.value),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11.5, color: SwimTheme.muted(context))),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (draft.heats.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final heat in draft.heats)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.groups_2_outlined, size: 14, color: SwimTheme.muted(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(heat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      '~${formatDuration(practiceTotals(draft, heat: heat).seconds)}',
                      style: TextStyle(fontSize: 12, color: SwimTheme.muted(context)),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _startPoolside,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text('Start poolside'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
          const SizedBox(height: 6),
          Text('Everything stays on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: SwimTheme.muted(context))),
        ],
      ),
    );
  }

  Widget _checkCard(BuildContext context, List<PracticeIssue> issues) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Practice check', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          if (issues.isEmpty)
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 17, color: scheme.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('Looks good — ready to swim.',
                      style: TextStyle(fontSize: 12.5, color: SwimTheme.muted(context))),
                ),
              ],
            )
          else
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        switch (issue.level) {
                          IssueLevel.error => Icons.error_outline,
                          IssueLevel.warn => Icons.warning_amber_rounded,
                          IssueLevel.info => Icons.info_outline,
                        },
                        size: 16,
                        color: switch (issue.level) {
                          IssueLevel.error => scheme.error,
                          IssueLevel.warn => const Color(0xFFD97706),
                          IssueLevel.info => scheme.primary,
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(issue.message,
                          style: TextStyle(fontSize: 12.5, height: 1.35, color: SwimTheme.muted(context))),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class SetEditorCard extends StatefulWidget {
  const SetEditorCard({
    super.key,
    required this.state,
    required this.index,
    required this.set,
    required this.unit,
    required this.totalSets,
  });

  final AppState state;
  final int index;
  final PracticeSet set;
  final String unit;
  final int totalSets;

  @override
  State<SetEditorCard> createState() => _SetEditorCardState();
}

class _SetEditorCardState extends State<SetEditorCard> {
  bool _open = true;
  bool _more = false;

  PracticeSet get _set => widget.set;

  void _update(void Function(PracticeSet set) change) {
    widget.state.updateDraft((practice) {
      final live = practice.sets.firstWhere((item) => item.id == _set.id, orElse: () => _set);
      change(live);
    });
  }

  void _delete() {
    final removedIndex = widget.index;
    final removed = _set.copy();
    widget.state.updateDraft((practice) => practice.sets.removeWhere((item) => item.id == _set.id));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${removed.type.label.toLowerCase()}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.state.updateDraft((practice) {
              final insertAt = removedIndex < 0
                  ? 0
                  : removedIndex > practice.sets.length
                      ? practice.sets.length
                      : removedIndex;
              practice.sets.insert(insertAt, removed);
            });
          },
        ),
      ));
  }

  void _duplicate() {
    widget.state.updateDraft((practice) {
      final index = practice.sets.indexWhere((item) => item.id == _set.id);
      if (index >= 0) practice.sets.insert(index + 1, _set.copy(freshId: true));
    });
  }

  void _move(int delta) {
    widget.state.updateDraft((practice) {
      final index = practice.sets.indexWhere((item) => item.id == _set.id);
      final target = index + delta;
      if (index < 0 || target < 0 || target >= practice.sets.length) return;
      final item = practice.sets.removeAt(index);
      practice.sets.insert(target, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final set = _set;
    final sendOff = sendOffForSet(set, widget.state.draft);
    final perRep = swimPerRep(set, widget.state.draft);
    final heatSends = widget.state.draft.heats.map((heat) {
      final heatSend = sendOffForSet(set, widget.state.draft, heat: heat);
      return '${heat.name} ${heatSend == null ? 'swim' : formatClock(heatSend)}';
    }).toList();
    final typeColor = Color(set.type.color);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: typeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        TypePill(set.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SetType>(
                              value: set.type,
                              isDense: true,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              style: Theme.of(context).textTheme.titleMedium,
                              selectedItemBuilder: (context) => [
                                for (final type in SetType.values)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(type.label,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              items: [
                                for (final type in SetType.values)
                                  DropdownMenuItem(value: type, child: Text(type.label)),
                              ],
                              onChanged: (value) {
                                if (value != null) _update((item) => item.type = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconAction(
                          icon: _open ? Icons.expand_less : Icons.expand_more,
                          tooltip: _open ? 'Collapse set' : 'Expand set',
                          onPressed: () => setState(() => _open = !_open),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Set actions',
                          icon: Icon(Icons.more_vert, size: 20, color: SwimTheme.muted(context)),
                          onSelected: (action) {
                            switch (action) {
                              case 'up':
                                _move(-1);
                                break;
                              case 'down':
                                _move(1);
                                break;
                              case 'duplicate':
                                _duplicate();
                                break;
                              case 'delete':
                                _delete();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'up',
                              enabled: widget.index > 0,
                              child: const Row(children: [Icon(Icons.arrow_upward, size: 17), SizedBox(width: 10), Text('Move up')]),
                            ),
                            PopupMenuItem(
                              value: 'down',
                              enabled: widget.index < widget.totalSets - 1,
                              child: const Row(children: [Icon(Icons.arrow_downward, size: 17), SizedBox(width: 10), Text('Move down')]),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(children: [Icon(Icons.copy_all_outlined, size: 17), SizedBox(width: 10), Text('Duplicate')]),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline, size: 17, color: scheme.error),
                                const SizedBox(width: 10),
                                Text('Delete', style: TextStyle(color: scheme.error)),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_open) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: LabeledField(
                              label: 'Reps',
                              child: NumberField(
                                value: set.reps,
                                min: 1,
                                max: 999,
                                onChanged: (value) => _update((item) => item.reps = value),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                            child: Text('×', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                          Expanded(
                            child: LabeledField(
                              label: 'Distance',
                              child: NumberField(
                                value: set.distance,
                                min: 1,
                                max: 10000,
                                suffix: widget.unit,
                                onChanged: (value) => _update((item) => item.distance = value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 4,
                            child: LabeledField(
                              label: 'Stroke',
                              child: DropdownButtonFormField<Stroke>(
                                value: set.stroke,
                                isExpanded: true,
                                items: [
                                  for (final stroke in Stroke.values)
                                    DropdownMenuItem(
                                      value: stroke,
                                      child: Text(stroke.label),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) _update((item) => item.stroke = value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: LabeledField(
                              label: 'Send-off',
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: set.intervalMode == IntervalMode.none
                                      ? scheme.surface
                                      : scheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: set.intervalMode == IntervalMode.none
                                        ? SwimTheme.line(context)
                                        : scheme.primary.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      set.intervalMode == IntervalMode.none
                                          ? 'Continuous'
                                          : sendOff == null
                                              ? '—'
                                              : formatClock(sendOff),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: set.intervalMode == IntervalMode.none
                                            ? SwimTheme.muted(context)
                                            : scheme.primary,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      set.intervalMode == IntervalMode.none
                                          ? 'swim ${formatClock(perRep)}'
                                          : set.intervalMode == IntervalMode.pace
                                              ? 'AUTO'
                                              : 'MANUAL',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w700,
                                        color: SwimTheme.muted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: LabeledField(
                              label: 'Rest between reps',
                              child: NumberField(
                                value: set.rest,
                                min: 0,
                                max: 1800,
                                suffix: 'sec',
                                onChanged: (value) => _update((item) => item.rest = value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: LabeledField(
                              label: 'Interval mode',
                              child: SegmentedButton<IntervalMode>(
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  textStyle: WidgetStatePropertyAll(
                                    TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                segments: [
                                  for (final mode in IntervalMode.values)
                                    ButtonSegment(value: mode, label: Text(mode.label)),
                                ],
                                selected: {set.intervalMode},
                                onSelectionChanged: (value) {
                                  final mode = value.first;
                                  _update((item) {
                                    item.intervalMode = mode;
                                    if (mode == IntervalMode.manual && (item.interval ?? 0) <= 0) {
                                      item.interval = (sendOffForSet(item, widget.state.draft) ?? 90);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (set.intervalMode == IntervalMode.manual) ...[
                        const SizedBox(height: 10),
                        LabeledField(
                          label: 'Custom send-off',
                          child: TimeField(
                            seconds: set.interval,
                            allowEmpty: true,
                            hint: '1:30',
                            onChanged: (value) => _update((item) => item.interval = value),
                          ),
                        ),
                      ],
                      if (heatSends.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final label in heatSends) TinyPill(label)],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatNumber(set.volume)} ${widget.unit} · swim ${formatDuration(perRep)}'
                              '${set.intervalMode == IntervalMode.none ? '' : ' · rest ${set.rest}s'}',
                              style: TextStyle(fontSize: 11.5, color: SwimTheme.muted(context)),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _more = !_more),
                            icon: Icon(_more ? Icons.expand_less : Icons.tune, size: 16),
                            label: Text(_more ? 'Less' : 'More'),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      if (_more) ...[
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: LabeledField(
                                label: 'Target pace / 100 (optional)',
                                child: TimeField(
                                  seconds: set.pace100,
                                  allowEmpty: true,
                                  hint: 'Base ${formatClock(widget.state.draft.basePace)}',
                                  onChanged: (value) => _update((item) => item.pace100 = value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FieldLabel('Equipment'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in equipmentOptions)
                              FilterChip(
                                label: Text(item),
                                selected: set.equipment.contains(item),
                                onSelected: (selected) {
                                  _update((entry) {
                                    if (selected) {
                                      if (!entry.equipment.contains(item)) entry.equipment.add(item);
                                    } else {
                                      entry.equipment.remove(item);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Set notes',
                          child: TextFormField(
                            initialValue: set.notes,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Cue, drill focus, send-off notes…'),
                            onChanged: (value) => _update((entry) => entry.notes = value),
                          ),
                        ),
                      ] else if (set.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          set.notes,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: SwimTheme.muted(context),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
