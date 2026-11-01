import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';
import 'templates.dart';

Practice starterPractice() => Practice(
      id: uid('p'),
      title: 'First practice',
      date: todayISO(),
      course: Course.scm,
      basePace: 100,
      roundTo: 5,
      group: 'Squad',
      focus: 'Getting going',
      sets: [
        PracticeSet(
          id: uid('s'),
          type: SetType.warmup,
          reps: 4,
          distance: 100,
          stroke: Stroke.free,
          rest: 20,
          notes: 'Easy, long strokes.',
        ),
        PracticeSet(
          id: uid('s'),
          type: SetType.main,
          reps: 8,
          distance: 50,
          stroke: Stroke.free,
          rest: 20,
          notes: 'Steady pace, hold your form.',
        ),
        PracticeSet(
          id: uid('s'),
          type: SetType.cooldown,
          reps: 4,
          distance: 100,
          stroke: Stroke.choice,
          rest: 20,
          notes: 'Easy choice.',
        ),
      ],
    );

class AppState extends ChangeNotifier {
  AppState._(this.store);

  factory AppState.bootstrap(PracticeStore store) {
    final state = AppState._(store);
    state.practices = store.listPractices();
    state.themeMode = store.loadTheme();
    state.draft = store.loadDraft() ?? starterPractice();
    return state;
  }

  final PracticeStore store;
  late Practice draft;
  late List<Practice> practices;
  late ThemeMode themeMode;

  int tab = 0;
  int runToken = 0;

  Totals get totals => practiceTotals(draft);
  List<PracticeIssue> get issues => validatePractice(draft);
  int get storageBytes => store.storageBytes();

  void setTab(int index) {
    if (tab == index) return;
    tab = index;
    notifyListeners();
  }

  void startRun() {
    runToken++;
    tab = 3;
    notifyListeners();
  }

  void updateDraft(void Function(Practice practice) change) {
    change(draft);
    draft.updatedAt = DateTime.now().toIso8601String();
    store.saveDraft(draft);
    notifyListeners();
  }

  void replaceDraft(Practice practice) {
    draft = practice;
    draft.updatedAt = DateTime.now().toIso8601String();
    store.saveDraft(draft);
    notifyListeners();
  }

  Future<void> saveCurrent() async {
    await store.savePractice(draft);
    practices = store.listPractices();
    notifyListeners();
  }

  void newPractice() {
    replaceDraft(Practice(id: uid('p'), title: 'Untitled practice', date: todayISO()));
    tab = 0;
    notifyListeners();
  }

  void useTemplate(PracticeTemplate template) {
    replaceDraft(templateToPractice(template));
    tab = 0;
    notifyListeners();
  }

  void openPractice(Practice practice) {
    replaceDraft(clonePractice(practice, keepId: true));
    tab = 0;
    notifyListeners();
  }

  Future<void> duplicatePractice(Practice practice) async {
    final copy = clonePractice(practice);
    await store.savePractice(copy);
    practices = store.listPractices();
    notifyListeners();
  }

  Future<void> deletePractice(String id) async {
    await store.deletePractice(id);
    practices = store.listPractices();
    notifyListeners();
  }

  Future<int> importJson(String text) async {
    final count = await store.importJson(text);
    practices = store.listPractices();
    notifyListeners();
    return count;
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    await store.saveTheme(mode);
    notifyListeners();
  }

  void cycleTheme() {
    final next = switch (themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setTheme(next);
  }
}
