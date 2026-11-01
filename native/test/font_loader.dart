import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the fonts the app ships with so widget tests and screenshots render
/// real text instead of the solid "Ahem" blocks Flutter uses by default.
Future<void> loadAppFonts() async {
  final lato = FontLoader('Lato');
  for (final asset in const [
    'assets/fonts/Lato-Regular.ttf',
    'assets/fonts/Lato-Italic.ttf',
    'assets/fonts/Lato-Bold.ttf',
    'assets/fonts/Lato-BoldItalic.ttf',
  ]) {
    lato.addFont(rootBundle.load(asset));
  }
  await lato.load();

  // Material icons are bundled by the Flutter SDK at build time; tests need the
  // same font registered under the family Icon widgets ask for.
  final icons = File('test/assets/MaterialIcons-Regular.ttf');
  if (icons.existsSync()) {
    final bytes = icons.readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}
