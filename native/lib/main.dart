import 'package:flutter/material.dart';

import 'src/state.dart';
import 'src/store.dart';
import 'src/theme.dart';
import 'src/ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PracticeStore.open();
  final state = AppState.bootstrap(store);
  runApp(SwimSetApp(state: state));
}

class SwimSetApp extends StatelessWidget {
  const SwimSetApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        title: 'SwimSet',
        debugShowCheckedModeBanner: false,
        theme: SwimTheme.light(),
        darkTheme: SwimTheme.dark(),
        themeMode: state.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 180),
        home: HomeShell(state: state),
      ),
    );
  }
}
