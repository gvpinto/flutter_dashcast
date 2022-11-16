import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dashcast/notifiers.dart';

import 'episodes_page.dart';
import 'home_page.dart';

void main() {
  Logger.root.level = Level.FINE; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.loggerName} - ${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Uri url = Uri.parse("https://itsallwidgets.com/podcast/feed");
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => PodCast()..parse(url),
      child: const MaterialApp(
        title: 'The Boring Show',
        home: HomePage(),
      ),
    );
  }
}
