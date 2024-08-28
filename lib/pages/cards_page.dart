import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/pages/test_page.dart';
import 'package:flash_your_memory/pages/editor_page.dart';
import 'package:flash_your_memory/util/card_tile.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CardsPage extends StatefulWidget {
  const CardsPage(
      {super.key,
      required this.database,
      this.deckID,
      required this.notifyParent,
      this.controller});

  final CardsDatabase database;
  final int? deckID;
  final Function() notifyParent;
  final ScrollController? controller;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  /// Cards list for selected deck
  ///
  /// [[FrontText, BackText, Diffculty, DeckID, CardIndex], ...]
  List? _cardsList;

  /// cards's index that can be referred to databse.
  /// To be used with [_cardsList]
  static const int _cardDbIndex = 4;
  AppBar? appBar;
  static const _emptyText = "😔 Nothing's here";

  /// Builds [_cardsList] based on [widget.deckID]
  /// if [widget.deckID] is not null
  void buildModifiedCardsList() {
    if (widget.deckID != null) {
      List databaseCardsList = widget.database.cardsList;
      _cardsList = [];

      _debugPrint(
          "buildCardsList(): deckID: ${widget.deckID}, building cardsList");

      for (int i = 0; i < widget.database.cardsList.length; i++) {
        if (widget.database.cardsList[i][CardsDatabase.cardDeckIDIndex] ==
            widget.deckID) {
          _cardsList!.add([
            databaseCardsList[i][CardsDatabase.frontIndex],
            databaseCardsList[i][CardsDatabase.backIndex],
            databaseCardsList[i][CardsDatabase.priorityIndex],
            databaseCardsList[i][CardsDatabase.cardDeckIDIndex],
            i // actual card's index to refer to the database
          ]);
        }
      }
    }
  }

  /// Generates a FloatingActionButton
  /// to start a test for the selected deck
  FloatingActionButton? buildFloatingActionButton(ThemeData theme) {
    if (widget.deckID != null &&
        ((_cardsList?.length ?? widget.database.cardsList.length) != 0)) {
      return FloatingActionButton.extended(
        onPressed: () {
          _debugPrint("buildFloatingActionButton(): Start test");
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TestPage(
                title: widget.database.getDeckTitle(widget.deckID!),
                deckID: widget.deckID!,
                database: widget.database,
              ),
            ),
          );
        },
        tooltip: "Start test",
        label: const Text("Start test"),
        icon: const Text(
          "🤔",
          semanticsLabel: "",
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    }

    return null;
  }

  @override
  void initState() {
    buildModifiedCardsList();
    super.initState();
  }

  /// for slidable action
  void modifyCard(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardEditorPage(
          deckID: -1,
          database: widget.database,
          notifyParent: () {
            buildModifiedCardsList();
            setState(() {});
          },
          cardIndex: _cardsList?[index][_cardDbIndex] ?? index,
        ),
      ),
    );
  }

  /// deletes a card from the list at [index].
  ///
  /// [index] is referred to either [_cardsList] (if not null)
  /// or [widget.database.deleteCard] method
  void deleteCard(int index, BuildContext context) {
    if (_cardsList != null) {
      // delete from modified cards list
      widget.database.deleteCard(_cardsList![index][_cardDbIndex]);
      buildModifiedCardsList();
    } else {
      widget.database.deleteCard(index);
    }
    // navigate out if list is empty
    if (_cardsList?.isEmpty ?? false) {
      Navigator.pop(context);
    }
    setState(() {});
  }

  /// builds a list of widgets
  /// 1. SliverAppBar if a deck is selected
  /// 2. List of slidable cards
  List<Widget> buildWidgetLists() {
    final theme = Theme.of(context);

    List<Widget> widgetsList = [];
    if (widget.deckID != null) {
      // build sliver appbar
      widgetsList.add(
        SliverAppBar.medium(
          title: Text(widget.database.getDeckTitle(widget.deckID!)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CardEditorPage(
                      deckID: widget.deckID!,
                      database: widget.database,
                      notifyParent: () {
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              child: const Text("Add new"),
            )
          ],
        ),
      );
    }

    if ((_cardsList?.length ?? widget.database.cardsList.length) == 0) {
      // database list is empty
      widgetsList.add(
          const SliverToBoxAdapter(child: Center(child: Text(_emptyText))));
    } else {
      // build cards
      widgetsList.addAll([
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Slidable(
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => modifyCard(context, index),
                      icon: Icons.edit,
                      foregroundColor: theme.colorScheme.onTertiary,
                      backgroundColor: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(22),
                    )
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => deleteCard(index, context),
                      icon: Icons.delete,
                      foregroundColor: theme.colorScheme.onTertiary,
                      backgroundColor: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(22),
                    )
                  ],
                ),
                child: CardTile(
                  controller: FlipCardController(),
                  frontText: getFrontText(index),
                  // widget.database.cardsList[index][0],
                  backText: getBackText(index),
                ),
              );
            },
            childCount: _cardsList?.length ?? widget.database.cardsList.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
          ),
        ),
      ]);
    }

    return widgetsList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: buildFloatingActionButton(theme),
      body: CustomScrollView(
        controller: widget.controller,
        slivers: buildWidgetLists(),
      ),
    );
  }

  /// Returns text either from modified cardsList or database
  String getFrontText(int index) {
    String frontText = "Something went wrong! 😔";
    String deck = "Something went wrong! 😔";
    int priority = -1;
    int deckID = -1;

    if (_cardsList != null) {
      // get texts from modified cards list
      frontText = _cardsList![index][0];
      priority = _cardsList![index][2];
      deckID = _cardsList![index][3];
      deck = widget.database.getDeckTitle(deckID);
    } else {
      // get texts from database
      frontText = widget.database.getFrontText(index) ?? frontText;
      priority = widget.database.cardsList[index][CardsDatabase.priorityIndex];

      deckID = widget.database.cardsList[index][CardsDatabase.cardDeckIDIndex];
      deck = widget.database.getDeckTitle(deckID);
    }

    return (kDebugMode)
        ? "$frontText\nPriority: $priority\nDeck_id: $deckID\nDeck: $deck"
        : frontText;
  }

  String getBackText(int index) {
    String back = "Something went wrong! 😔";
    // check if specific deck is selected
    if (_cardsList != null) {
      return _cardsList![index][CardsDatabase.backIndex];
    }
    // get back text
    back = widget.database.getBackText(index);
    return back;
  }

  void _debugPrint(String msg) {
    if (kDebugMode) print("----[CardsPage]---- $msg");
  }
}
