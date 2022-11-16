import 'package:flutter/material.dart';
import 'package:flutter_dashcast/episodes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int navIndex = 0;

  final pages = List<Widget>.unmodifiable([
    const EpisodesPage(),
    const DummyPage(),
  ]);

  final iconList = List<IconData>.unmodifiable(
    [
      Icons.hot_tub,
      Icons.timelapse,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavBar(
        icons: iconList,
      ),
    );
  }
}

class MyNavBar extends StatefulWidget {
  final List<IconData> icons;
  const MyNavBar({super.key, required this.icons}) : assert(icons != null);
  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (var icon in widget.icons) Icon(icon)],
        ));
  }
}

class DummyPage extends StatelessWidget {
  const DummyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dummy Page'),
    );
  }
}
