import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/util/card_tile.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TestPage extends StatefulWidget {
  const TestPage(
      {super.key,
      required this.title,
      required this.deckID,
      required this.database});

  final String title;
  final int deckID;
  final CardsDatabase database;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _controllerFlipCard = FlipCardController();
  bool _isFront = true;
  CardsList? _cardsList;
  static const _emptyCardValue = "Nothing to test 😔";

  @override
  void initState() {
    _cardsList = CardsList(database: widget.database, deckID: widget.deckID);
    _cardsList!.selectCard();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds a list of widgets that the user can interact with
  List<Widget> buildListWidget(ThemeData theme) {
    List<Widget> widgets = [
      // CardTile Causes exception
      SizedBox(
        height: 300,
        child: CardTile(
          frontText: _cardsList?.getFrontText() ?? _emptyCardValue,
          backText: _cardsList?.getBackText() ?? _emptyCardValue,
          testMode: true,
          controller: _controllerFlipCard,
          backgroundColorFront: theme.colorScheme.primaryContainer,
          foregroundColorFront: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      // const Expanded(child: SizedBox())
    ];

    int? currentIndex = _cardsList?.getCardIndex();
    if (currentIndex != null) {
      _debugPrint(// priority level of the current card
          "${_cardsList?.getFrontText()} priority: ${widget.database.cardsList[currentIndex][CardsDatabase.priorityIndex]}");
      if (_isFront) {
        // tap to reveal button
        widgets.add(
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    _debugPrint("build(): Tap to reveal button pressed");
                    if (_controllerFlipCard.state?.isFront ?? false) {
                      _controllerFlipCard.toggleCardWithoutAnimation();
                      setState(() {});
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Tap to reveal"),
                  ),
                ),
              ],
            ),
          ),
        );
        _isFront = !_isFront;
      } else {
        // user tapped reveal button
        widgets.addAll([
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Did you get it right?",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      // Yes button
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () =>
                          onAssessmentButtonPressed(isCorrect: true),
                      icon: const Icon(Icons.check),
                      label: const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Yes"),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FilledButton.icon(
                      // No button
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                      onPressed: () =>
                          onAssessmentButtonPressed(isCorrect: false),
                      icon: const Icon(Icons.close),
                      label: const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text("No"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                FilledButton.icon(
                  onPressed: () {
                    onAssessmentButtonPressed(isCorrect: true, skip: true);
                  },
                  icon: const Icon(Icons.check),
                  label: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Yes and don't ask again"),
                  ),
                )
              ],
            ),
          )
        ]);
      }
    }
    return widgets;
  }

  /// Increases/decreases card priority, gets the next card and flips the test card
  void onAssessmentButtonPressed({required bool isCorrect, bool skip = false}) {
    if (_cardsList != null && _cardsList!.getCardIndex() != null) {
      if (isCorrect) {
        _debugPrint("✅ button pressed\nDecreasing priority...");
        if ((widget.database.decreasePriority(_cardsList!.getCardIndex()!)) ==
            DbReturnCode.noCard) {
          _debugPrint("No Card");
        }
        if (skip) {
          _debugPrint('Skipping card "${_cardsList!.getFrontText()}"');
          _cardsList!.skipCard();
        }
      } else {
        _debugPrint("❌ button pressed\nIncreasing priority...");
        if ((widget.database.increasePriority(_cardsList!.getCardIndex()!)) ==
            DbReturnCode.noCard) {
          _debugPrint("No Card");
        }
      }
    }

    // get next card
    if (_cardsList != null) {
      _cardsList!.updateDistribution();
      _cardsList!.selectCard();
    }

    // flip the card
    if (!_isFront) _isFront = !_isFront;
    _controllerFlipCard.toggleCardWithoutAnimation();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text("Test: ${widget.title}"),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 8.0, right: 8.0, bottom: 50),
              child: Column(
                children: buildListWidget(Theme.of(context)),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// for debugging purposes
  void _debugPrint(String msg) {
    if (kDebugMode) {
      print("[TestPage] $msg");
    }
  }
}

/// 1. Extracts a list of cards for the specified deck
///
/// 2. Provides an interface to select a random card
/// based on probability distribution
class CardsList {
  CardsList({required this.database, required this.deckID}) {
    buildCardsList();
  }

  static const int frontIndex = 0;
  static const int backIndex = 1;
  static const int distributionValueIndex = 2;
  static const int cardIndex = 3;
  static const int countIndex = 4;
  static const int skipIndex = 5;

  static const String cardsDebugHelper =
      "cardsList[ [ frontText, backText, distributionValue, card's DB index, count, skip], ...]";

  /// Randomly selects a card based on their probability distribution
  void selectCard() {
    if (_cardsList.isEmpty) return;
    // random number between 0 to maximum distribution value
    int randomNumber = _rng.nextInt(_cardsList.last[distributionValueIndex]);
    _debugPrint("Random number: $randomNumber");

    // select card
    for (int i = 0; i < _cardsList.length; i++) {
      if (randomNumber < _cardsList[i][distributionValueIndex]) {
        _debugPrint("lucky card: ${_cardsList[i][frontIndex]}");
        _index = i;
        _cardsList[i][countIndex]++;
        break;
      }
    }
  }

  /// updates probability distribution
  /// based on the priority of the card
  void updateDistribution() {
    int totalCount = 0;

    if (_cardsList.isEmpty) {
      _index == null;
      return;
    }

    for (int i = 0; i < _cardsList.length; i++) {
      int dbIndex = _cardsList[i][cardIndex];
      int priority = database.cardsList[dbIndex][CardsDatabase.priorityIndex];
      if (i == 0) {
        _cardsList[i][distributionValueIndex] = priority;
      } else {
        int previousDistribution = _cardsList[i - 1][distributionValueIndex];
        _cardsList[i][distributionValueIndex] = previousDistribution +
            database.cardsList[dbIndex][CardsDatabase.priorityIndex];
      }
      totalCount += _cardsList[i][countIndex] as int;
    }
    _debugPrint("---Card's details---");
    for (List card in _cardsList) {
      String percentage =
          ((card[countIndex] / totalCount * 100) as double).toStringAsFixed(2);
      int dbIndex = card[cardIndex];
      _debugPrint(
          "Card: ${card[frontIndex]}\ndistribution value: ${card[distributionValueIndex]}\tcount: ${card[countIndex]}\tpriority: ${database.cardsList[dbIndex][CardsDatabase.priorityIndex]}\toccurence percentage: $percentage%");
      _debugPrint("Total count: $totalCount");
    }
  }

  /// Returns front text of the card
  /// based on selected card
  String getFrontText() {
    if (_index != null && _cardsList.isNotEmpty) {
      return _cardsList[_index!][frontIndex];
    }
    return "No card!";
  }

  /// Returns back text of the card
  /// based on selected card
  String getBackText() {
    if (_index != null && _cardsList.isNotEmpty) {
      return _cardsList[_index!][backIndex];
    }
    return "No card!";
  }

  /// Returns index of database's cardsList
  /// based on selected card
  int? getCardIndex() {
    if (_index != null && _cardsList.isNotEmpty) {
      return _cardsList[_index!][cardIndex];
    }
    return null;
  }

  /// Skips/Prevents the card from selecting
  void skipCard() {
    if (_index != null) {
      _cardsList.removeAt(_index!);
      updateDistribution();
    }
  }

  /// builds [_cardsList] for selected Deck,
  ///
  /// also distributes probability based on their priority value
  void buildCardsList() {
    _debugPrint("building _cardsList...");
    for (int i = 0; i < database.cardsList.length; i++) {
      if (database.cardsList[i][CardsDatabase.cardDeckIDIndex] == deckID) {
        if (_cardsList.isEmpty) {
          // distribute probability value for the first card = card's priority
          _cardsList.add([
            database.cardsList[i][CardsDatabase.frontIndex],
            database.cardsList[i][CardsDatabase.backIndex],
            database.cardsList[i][CardsDatabase.priorityIndex],
            i, // original index of the card
            0,
            false
          ]);
        } else {
          // distribute probability value based on the
          // sum of previous and priority values
          int valueToDistribute = _cardsList.last[distributionValueIndex] +
              database.cardsList[i][CardsDatabase.priorityIndex];

          _cardsList.add([
            database.cardsList[i][CardsDatabase.frontIndex],
            database.cardsList[i][CardsDatabase.backIndex],
            valueToDistribute,
            i, // original index of the card
            0,
            false
          ]);
        }
        _debugPrint("Card: ${database.cardsList[i][CardsDatabase.frontIndex]}");
        _debugPrint(
            "Priority: ${database.cardsList[i][CardsDatabase.priorityIndex]}");
      }
    }
    _debugPrint(
        "buildCardsList():\n${CardsList.cardsDebugHelper}\n_cardsList: $_cardsList");
    _debugPrint(
        "Last distribution value (Sum): ${_cardsList.last[distributionValueIndex]}");
  }

  /// cardsList[ [ frontText, backText, distributionValue, card's DB index, count, skip], ...]
  List _cardsList = [];
  final _rng = Random();

  /// index of currenty selected card from [_cardsList]
  ///
  /// value of -1 == uninitialized
  int? _index;

  final CardsDatabase database;
  final int deckID;

  /// -1 = uninitialized
  double ratioFactor = -1;

  _debugPrint(String msg) {
    if (kDebugMode) {
      print("[TestPage/CardsList] $msg");
    }
  }
}
