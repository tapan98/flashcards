import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/pages/cards_page.dart';
import 'package:flash_your_memory/pages/decks_page.dart';
import 'package:flutter/material.dart';

class FirstPage extends StatefulWidget {
  final CardsDatabase database;
  const FirstPage({super.key, required this.database});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _activePage = 0;
  final _decksScrollController = ScrollController();
  final _cardsScrollController = ScrollController();

  void refreshState() {
    setState(() {});
  }

  @override
  void dispose() {
    _decksScrollController.dispose();
    _cardsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> destinations = [
      DecksPage(
        database: widget.database,
        controller: _decksScrollController,
      ),
      CardsPage(
        database: widget.database,
        notifyParent: refreshState,
        controller: _cardsScrollController,
      ),
    ];
    List<ScrollController> scrollControllers = [
      _decksScrollController,
      _cardsScrollController
    ];
    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: 75,
        // leadingWidth: double.infinity,
        // title: const SearchBar(
        //   hintText: "Search",
        // ),
        title: const Text("Flash cards"),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _activePage,
          children: destinations,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.layers), label: "Decks"),
          NavigationDestination(icon: Icon(Icons.view_agenda), label: "Cards"),
        ],
        selectedIndex: _activePage,
        onDestinationSelected: (int index) {
          if (_activePage == index) {
            // scroll to the top
            scrollControllers[index].animateTo(0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.linear);
          }
          setState(
            () {
              _activePage = index;
            },
          );
        },
      ),
    );
  }
}
