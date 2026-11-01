import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimset/src/models.dart';
import 'package:swimset/src/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves, lists and deletes practices', () async {
    final store = await PracticeStore.open();
    final practice = Practice(id: 'p1', title: 'Morning set');
    await store.savePractice(practice);

    final loaded = store.listPractices();
    expect(loaded.length, 1);
    expect(loaded.single.title, 'Morning set');

    practice.title = 'Morning set v2';
    await store.savePractice(practice);
    expect(store.listPractices().single.title, 'Morning set v2');
    expect(store.listPractices().length, 1);

    await store.deletePractice('p1');
    expect(store.listPractices(), isEmpty);
  });

  test('stores the working draft and theme', () async {
    final store = await PracticeStore.open();
    final practice = Practice(id: 'draft', title: 'Draft', sets: [
      PracticeSet(id: 's', reps: 4, distance: 100),
    ]);
    await store.saveDraft(practice);
    final draft = store.loadDraft();
    expect(draft, isNotNull);
    expect(draft!.title, 'Draft');
    expect(draft.sets.single.reps, 4);

    expect(store.loadTheme(), ThemeMode.system);
    await store.saveTheme(ThemeMode.dark);
    expect(store.loadTheme(), ThemeMode.dark);
  });

  test('exports and imports the library', () async {
    final store = await PracticeStore.open();
    await store.savePractice(Practice(id: 'p1', title: 'One'));
    await store.savePractice(Practice(id: 'p2', title: 'Two'));

    final exported = store.exportAllJson();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    expect(decoded['app'], 'SwimSet');
    expect((decoded['practices'] as List).length, 2);

    final count = await store.importJson(exported);
    expect(count, 2);
    expect(store.listPractices().length, 2);
  });

  test('imports a single practice and a bare list', () async {
    final store = await PracticeStore.open();
    final single = Practice(id: 'p9', title: 'Single');
    expect(await store.importJson(jsonEncode(single.toJson())), 1);
    expect(store.listPractices().single.title, 'Single');

    final list = jsonEncode([
      Practice(id: 'p10', title: 'List A').toJson(),
      Practice(id: 'p11', title: 'List B').toJson(),
    ]);
    expect(await store.importJson(list), 2);
    expect(store.listPractices().length, 3);
  });

  test('rejects files without practices', () async {
    final store = await PracticeStore.open();
    expect(() => store.importJson('{"hello":"world"}'), throwsFormatException);
  });
}
