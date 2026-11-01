import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimset/main.dart';
import 'package:swimset/src/state.dart';
import 'package:swimset/src/store.dart';

import 'font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('builder, navigation and saving work', (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await loadAppFonts();
    final store = await PracticeStore.open();
    final state = AppState.bootstrap(store);
    await tester.pumpWidget(SwimSetApp(state: state));
    await tester.pumpAndSettle();

    expect(state.draft.title, 'First practice');
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Warm-up'), findsWidgets);

    await tester.tap(find.text('Pace'));
    await tester.pumpAndSettle();
    expect(find.text('Send-off ladder'), findsOneWidget);
    expect(find.text('Course converter'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Practice library'), findsOneWidget);
    expect(find.text('No saved practices yet'), findsOneWidget);

    await tester.tap(find.text('Poolside'));
    await tester.pumpAndSettle();
    expect(find.text('Practice plan'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Builder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Morning set');
    await tester.pump();
    expect(state.draft.title, 'Morning set');

    await tester.ensureVisible(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    expect(state.draft.sets.length, 4);

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.practices.length, 1);
    expect(state.practices.single.title, 'Morning set');
  });

  testWidgets('saved practice opens from the library', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await loadAppFonts();
    final store = await PracticeStore.open();
    await store.savePractice(starterPractice()..title = 'Saved practice');
    final state = AppState.bootstrap(store);
    state.setTab(1);

    await tester.pumpWidget(SwimSetApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Saved practice'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(state.draft.title, 'Saved practice');
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('poolside timer asks the platform for a background service', (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final calls = <String>[];
    const channel = MethodChannel('swimset/power');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );

    await loadAppFonts();
    final store = await PracticeStore.open();
    final state = AppState.bootstrap(store);
    await tester.pumpWidget(SwimSetApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Poolside'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(calls, contains('startTimer'));

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(calls, contains('stopTimer'));
  });

  testWidgets('a block shows its rounds in the builder', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await loadAppFonts();
    final store = await PracticeStore.open();
    final state = AppState.bootstrap(store);
    final practice = starterPractice();
    practice.sets[0].blockId = 'b1';
    practice.sets[0].blockRounds = 3;
    practice.sets[1].blockId = 'b1';
    practice.sets[1].blockRounds = 3;
    state.replaceDraft(practice);

    await tester.pumpWidget(SwimSetApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Block'), findsOneWidget);
    expect(find.text('2 sets × 3'), findsOneWidget);
    expect(find.textContaining('with rounds'), findsOneWidget);
  });
}
