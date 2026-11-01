import 'dart:io';

import 'package:flutter/foundation.dart';
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

  final iconFont = _findIconFont();
  if (iconFont != null) {
    debugPrint('[fonts] MaterialIcons <- ${iconFont.path}');
    final bytes = iconFont.readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

/// The Material icon font lives in the Flutter SDK rather than in this package,
/// so tests have to find it next to the engine that is running them.
File? _findIconFont() {
  const relative = 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final candidates = <String>[];

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    candidates.add('$flutterRoot/$relative');
  }

  var dir = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 7; depth++) {
    candidates.add('${dir.path}/$relative');
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  candidates.add('test/assets/MaterialIcons-Regular.otf');
  candidates.add('test/assets/MaterialIcons-Regular.ttf');

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 1000) return file;
  }
  return null;
}
