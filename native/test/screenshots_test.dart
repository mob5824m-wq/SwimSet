import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimset/main.dart';
import 'package:swimset/src/state.dart';
import 'package:swimset/src/store.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Lato');
  for (final asset in const [
    'assets/fonts/Lato-Regular.ttf',
    'assets/fonts/Lato-Italic.ttf',
    'assets/fonts/Lato-Bold.ttf',
    'assets/fonts/Lato-BoldItalic.ttf',
  ]) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/screens')..createSync(recursive: true);
    File('${directory.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render native screens', (tester) async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues({});
    final store = await PracticeStore.open();
    await store.savePractice(starterPractice());
    final state = AppState.bootstrap(store);
    final key = GlobalKey();

    final errors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
      originalOnError?.call(details);
    };

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2150);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });

    await tester.pumpWidget(RepaintBoundary(key: key, child: SwimSetApp(state: state)));
    await tester.pumpAndSettle();
    await _capture(tester, key, '01-builder-light');

    await state.setTheme(ThemeMode.dark);
    await tester.pumpAndSettle();
    await _capture(tester, key, '02-builder-dark');

    await state.setTheme(ThemeMode.light);
    tester.view.physicalSize = const Size(1440, 1050);
    state.setTab(1);
    await tester.pumpAndSettle();
    await _capture(tester, key, '03-library');

    tester.view.physicalSize = const Size(1440, 1250);
    state.setTab(2);
    await tester.pumpAndSettle();
    await _capture(tester, key, '04-pace');

    tester.view.physicalSize = const Size(1440, 1150);
    state.setTab(3);
    await tester.pumpAndSettle();
    await _capture(tester, key, '05-poolside');

    tester.view.physicalSize = const Size(1440, 1050);
    state.setTab(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates').first);
    await tester.pumpAndSettle();
    await _capture(tester, key, '06-templates');
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 1850);
    state.setTab(0);
    await tester.pumpAndSettle();
    await _capture(tester, key, '07-mobile-builder');

    tester.view.physicalSize = const Size(390, 1650);
    state.setTab(3);
    await tester.pumpAndSettle();
    await _capture(tester, key, '08-mobile-poolside');

    if (errors.isNotEmpty) {
      final directory = Directory('build/screens')..createSync(recursive: true);
      File('${directory.path}/layout-errors.txt').writeAsStringSync(errors.join('\n\n'));
    }
    expect(errors, isEmpty, reason: 'Layout errors were reported while rendering.');
  });
}
