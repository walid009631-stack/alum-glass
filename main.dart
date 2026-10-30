import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'calc_screen.dart';
import 'cutting_screen.dart';
import 'settings_screen.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const AlumApp());
}

class AlumApp extends StatelessWidget {
  const AlumApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Alum Glass',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0B6E99),
          inputDecorationTheme: const InputDecorationTheme(isDense: true),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, Widget)>[
      ('الشبابيك', Icons.window, const CalcScreen(kind: 'window')),
      ('الأبواب', Icons.door_front_door, const CalcScreen(kind: 'door')),
      ('الطرف', Icons.view_sidebar, const CalcScreen(kind: 'side')),
      ('البلور', Icons.crop_square, const CalcScreen(kind: 'glass')),
      ('تقطيع القطاعات', Icons.content_cut, const CuttingScreen()),
      ('إعدادات القطاعات', Icons.settings, const SettingsScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Alum Glass'), centerTitle: true),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(14),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          for (final it in items)
            Card(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => it.$3)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(it.$2, size: 46, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(it.$1,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
