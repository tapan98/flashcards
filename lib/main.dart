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

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = CardsDatabase();
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        home: FirstPage(
          database: db,
        ),
        // TODO: Create switchable dark theme
        theme: ThemeData(
          // appBarTheme: AppBarTheme(
          //   backgroundColor:
          //       lightDynamic?.primaryContainer ?? Colors.blue.shade700,
          //   foregroundColor: lightDynamic?.onPrimaryContainer ?? Colors.white,
          // ),
          colorScheme: lightDynamic,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkDynamic,
          useMaterial3: true,
        ),
        // routes: {
        //   '/firstPage': (context) => FirstPage(database: db),
        // },
      );
    });
  }
}
