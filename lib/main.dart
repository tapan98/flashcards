import 'package:dynamic_color/dynamic_color.dart';
import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/pages/first_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // debugPaintSizeEnabled = true;

  // init database
  await Hive.initFlutter();
  await Hive.openBox(CardsDatabase.cardsDB);
  await Hive.openBox(CardsDatabase.decksDB);

  runApp(
    DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        home: const MainApp(),
        theme: ThemeData(
          colorScheme: lightDynamic,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkDynamic,
          useMaterial3: true,
        ),
      );
    }),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = CardsDatabase();
    return FirstPage(
      database: db,
    );
  }
}
