import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
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
