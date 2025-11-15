import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_taker/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/utils/constant_manager.dart';
import 'package:note_taker/utils/route_manager.dart';
import 'package:note_taker/utils/theme_manager.dart';
import 'note_model.dart';
import 'note_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes');

  runApp(
    ChangeNotifierProvider(
      create: (context) => NoteProvider(),
      child: const NoteTakerApp(),
    ),
  );
}

class NoteTakerApp extends StatelessWidget {
  const NoteTakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: ConstantManager.appName,
      theme: ThemeManager.darkTheme,
      initialRoute: RouteManager.homeScreen,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RouteManager.homeScreen:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
