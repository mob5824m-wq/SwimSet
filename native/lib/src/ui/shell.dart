import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'builder.dart';
import 'library.dart';
import 'pace.dart';
import 'run.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final pages = <Widget>[
          BuilderPage(state: state),
          LibraryPage(state: state),
          const PacePage(),
          RunPage(state: state),
        ];
        final body = IndexedStack(index: state.tab, children: pages);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(state: state),
                VerticalDivider(width: 1, color: SwimTheme.line(context)),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 14,
            title: Row(
              children: [
                const _Mark(size: 30),
                const SizedBox(width: 9),
                Text('SwimSet',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 19, letterSpacing: -0.2)),
              ],
            ),
            actions: [
              IconAction(
                icon: _themeIcon(state.themeMode),
                tooltip: _themeLabel(state.themeMode),
                onPressed: state.cycleTheme,
              ),
              IconAction(
                icon: Icons.help_outline,
                tooltip: 'About & help',
                onPressed: () => showHelp(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.tab,
            onDestinationSelected: state.setTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: 'Builder',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_copy_outlined),
                selectedIcon: Icon(Icons.folder_copy),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.speed_outlined),
                selectedIcon: Icon(Icons.speed),
                label: 'Pace',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: 'Poolside',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = <(int, IconData, IconData, String)>[
      (0, Icons.edit_note_outlined, Icons.edit_note, 'Builder'),
      (1, Icons.folder_copy_outlined, Icons.folder_copy, 'Library'),
      (2, Icons.speed_outlined, Icons.speed, 'Pace'),
      (3, Icons.timer_outlined, Icons.timer, 'Poolside'),
    ];
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 232,
      color: Theme.of(context).cardTheme.color,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 22),
              child: Row(
                children: [
                  const _Mark(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SwimSet',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: scheme.onSurface,
                            )),
                        Text(
                          'PRACTICE MAKER',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 1.5,
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    _NavTile(
                      icon: state.tab == item.$1 ? item.$3 : item.$2,
                      label: item.$4,
                      selected: state.tab == item.$1,
                      onTap: () => state.setTab(item.$1),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: SwimTheme.line(context)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _NavTile(
                    icon: _themeIcon(state.themeMode),
                    label: _themeLabel(state.themeMode),
                    selected: false,
                    onTap: state.cycleTheme,
                    compact: true,
                  ),
                  _NavTile(
                    icon: Icons.help_outline,
                    label: 'About & help',
                    selected: false,
                    onTap: () => showHelp(context),
                    compact: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'SwimSet 2.0 · offline',
                style: TextStyle(fontSize: 10, color: SwimTheme.muted(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 9 : 11),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(0.10) : null,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 18 : 20, color: selected ? scheme.primary : SwimTheme.muted(context)),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? scheme.onSurface : SwimTheme.muted(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12A5C4), Color(0xFF0B5F75)],
          ),
        ),
        child: Icon(Icons.pool, color: Colors.white, size: size * 0.58),
      );
}

IconData _themeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

String _themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Follow system theme',
      ThemeMode.light => 'Light theme',
      ThemeMode.dark => 'Dark theme',
    };

Future<void> showHelp(BuildContext context) => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('SwimSet 2.0'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A native swim practice maker for Android, Chromebooks and Debian. '
                'No browser, no accounts and no network calls — practices live in app storage.',
                style: TextStyle(height: 1.45, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _helpSection('Builder', 'Add sets, set a base pace and let send-offs calculate. Open More on a set for target pace, equipment and notes.'),
              _helpSection('Poolside', 'Start a practice for a rep-by-rep timer with a beep at 3-2-1 and the send-off. Auto-advance keeps the session moving.'),
              _helpSection('Library', 'Save, search and duplicate practices. Export JSON for a backup and a PDF deck sheet for printing.'),
              const SizedBox(height: 14),
              Text('Made with Flutter · MIT licensed',
                  style: TextStyle(fontSize: 11, color: SwimTheme.muted(dialogContext))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
        ],
      ),
    );

Widget _helpSection(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(height: 1.4, fontSize: 12.5)),
        ],
      ),
    );
