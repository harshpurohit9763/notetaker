import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_taker/home_screen.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:note_taker/reminder_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/utils/constant_manager.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:note_taker/utils/theme_manager.dart';
import 'note_model.dart';
import 'note_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(ReminderAdapter());
  await Hive.openBox<Note>('notes');
  await Hive.openBox<Reminder>('reminders');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NoteProvider()),
        ChangeNotifierProvider(create: (context) => ReminderProvider()),
      ],
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
      onGenerateRoute: RouteManager.generateRoute,
    );
  }
}
