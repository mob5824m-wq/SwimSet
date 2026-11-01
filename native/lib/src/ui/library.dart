import 'dart:convert';

import 'package:flutter/material.dart';

import '../export.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.state});

  final AppState state;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _search = TextEditingController();
  String _sort = 'recent';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Practice> get _visible {
    final query = _search.text.trim().toLowerCase();
    var items = widget.state.practices.where((practice) {
      if (query.isEmpty) return true;
      final haystack = [
        practice.title,
        practice.group,
        practice.focus,
        practice.notes,
        practice.course.code,
        ...practice.sets.map((set) => '${set.stroke.label} ${set.type.label}'),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    switch (_sort) {
      case 'title':
        items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'distance':
        items.sort((a, b) => practiceTotals(b).distance.compareTo(practiceTotals(a).distance));
        break;
      case 'date':
        items.sort((a, b) => b.date.compareTo(a.date));
        break;
      default:
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return items;
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final text = await pickJsonFile();
      if (text == null) return;
      final count = await widget.state.importJson(text);
      if (!mounted) return;
      showSnack(context, 'Imported $count practice${count == 1 ? '' : 's'}');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'Import failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportAll() async {
    try {
      final path = await saveBytes(
        'swimset-practices.json',
        utf8.encode(widget.state.store.exportAllJson()),
      );
      if (!mounted) return;
      showSnack(context, 'Saved to $path');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'Export failed: $error');
    }
  }

  Future<void> _exportPractice(Practice practice, String format) async {
    try {
      if (format == 'json') {
        final path = await saveBytes(
          '${slugify(practice.title)}.json',
          utf8.encode(practiceJson(practice)),
        );
        if (!mounted) return;
        showSnack(context, 'Saved to $path');
      } else if (format == 'text') {
        final path = await saveBytes(
          '${slugify(practice.title)}.txt',
          utf8.encode(practiceToText(practice)),
        );
        if (!mounted) return;
        showSnack(context, 'Saved to $path');
      } else {
        final bytes = await buildPracticePdf(practice);
        final path = await saveBytes('${slugify(practice.title)}.pdf', bytes);
        if (!mounted) return;
        showSnack(context, 'Saved to $path');
      }
    } catch (error) {
      if (!mounted) return;
      showSnack(context, 'Export failed: $error');
    }
  }

  Future<void> _delete(Practice practice) async {
    final ok = await confirmAction(
      context,
      title: 'Delete “${practice.title}”?',
      message: 'This removes the practice from this device. Export a backup first if you want to keep it.',
    );
    if (!ok) return;
    await widget.state.deletePractice(practice.id);
    if (!mounted) return;
    showSnack(context, 'Deleted “${practice.title}”');
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final total = widget.state.practices.length;

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final columns = constraints.maxWidth >= 1180 ? 3 : (constraints.maxWidth >= 760 ? 2 : 1);

      return ListView(
        padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 22, wide ? 28 : 16, 30),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practice library',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: wide ? 32 : 27)),
                    const SizedBox(height: 3),
                    Text(
                      total == 1
                          ? '1 saved practice · stored privately on this device'
                          : '$total saved practices · stored privately on this device',
                      style: TextStyle(color: SwimTheme.muted(context), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Import'),
              ),
              OutlinedButton.icon(
                onPressed: total == 0 ? null : _exportAll,
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Export all'),
              ),
              FilledButton.icon(
                onPressed: widget.state.newPractice,
                icon: const Icon(Icons.add, size: 19),
                label: const Text('New practice'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Search title, group, focus…',
                        prefixIcon: const Icon(Icons.search, size: 19),
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sort,
                      borderRadius: BorderRadius.circular(14),
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SwimTheme.muted(context),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'recent', child: Text('Recently updated')),
                        DropdownMenuItem(value: 'title', child: Text('Title')),
                        DropdownMenuItem(value: 'distance', child: Text('Distance')),
                        DropdownMenuItem(value: 'date', child: Text('Practice date')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _sort = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(total == 0 ? Icons.pool : Icons.search_off,
                        size: 34, color: SwimTheme.muted(context)),
                    const SizedBox(height: 10),
                    Text(total == 0 ? 'No saved practices yet' : 'No matches',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Build one from the Builder tab, or start from a template there.'
                          : 'Try a different search or clear the filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SwimTheme.muted(context), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(builder: (context, grid) {
              final cardWidth = (grid.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final practice in items)
                    SizedBox(
                      width: cardWidth,
                      child: _PracticeCard(
                        practice: practice,
                        onOpen: () => widget.state.openPractice(practice),
                        onDuplicate: () => widget.state.duplicatePractice(practice),
                        onDelete: () => _delete(practice),
                        onExport: (format) => _exportPractice(practice, format),
                      ),
                    ),
                ],
              );
            }),
          const SizedBox(height: 18),
          Text(
            'Library uses about ${(widget.state.storageBytes / 1024).ceil()} KB of app storage. '
            'Export a backup before clearing app data.',
            style: TextStyle(color: SwimTheme.muted(context), fontSize: 11.5),
          ),
        ],
      );
    });
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.practice,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
  });

  final Practice practice;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    final totals = practiceTotals(practice);
    final unit = practice.course.unit;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      practice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TinyPill(practice.course.code),
                  if (practice.heats.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    TinyPill('${practice.heats.length} heats'),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [
                  formatDate(practice.date),
                  if (practice.group.isNotEmpty) practice.group,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: SwimTheme.muted(context), fontSize: 12),
              ),
              if (practice.focus.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  practice.focus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SwimTheme.line(context)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _miniStat(context, '${formatNumber(totals.distance)} $unit', 'volume'),
                    _miniStat(context, formatDuration(totals.seconds), 'est.'),
                    _miniStat(context, '${totals.setCount} sets', 'structure'),
                    _miniStat(context, '${totals.reps} reps', 'total'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.play_arrow_rounded, size: 19),
                    label: const Text('Open'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Export',
                    icon: Icon(Icons.ios_share, size: 19, color: SwimTheme.muted(context)),
                    onSelected: onExport,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'pdf', child: Text('Save deck sheet (PDF)')),
                      PopupMenuItem(value: 'json', child: Text('Export JSON')),
                      PopupMenuItem(value: 'text', child: Text('Export text')),
                    ],
                  ),
                  IconAction(
                    icon: Icons.copy_all_outlined,
                    tooltip: 'Duplicate',
                    onPressed: onDuplicate,
                    size: 18,
                  ),
                  IconAction(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              )),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: SwimTheme.muted(context)),
          ),
        ],
      );
}
