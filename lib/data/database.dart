import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Return codes of database operations
enum DbReturnCode {
  /// Operation completed successfully
  ok,

  /// Card does not exist
  noCard,

  /// Deck already exists
  deckExists,

  /// Deck does not exist
  noDeck,

  /// Deck is associated with a card
  deckLinked,
}

class CardsDatabase {
  /// example data to be put in the database
  static const bool _preCreateData = true;

  // Card's DB indexes
  static const int _defaultCardLevel = 5;
  static const int frontIndex = 0;
  static const int backIndex = 1;

  /// Priority level of the deck [1-10],
  ///
  /// Easiest to recall level: 1
  ///
  /// Hardest to recall level: 10
  static const int priorityIndex = 2;

  /// maximum value of card's priority
  static const int _maxPriority = 10;

  /// minimum value of card's priority
  static const int _minPriority = 1;

  /// priority to be increased/decreased by [_stepPriorityValue]
  static const int _stepPriorityValue = 1;

  /// Associated/linked Deck ID with the card
  /// [cardDeckIDIndex] = 3
  static const int cardDeckIDIndex = 3;

  // Decks's DB indexes
  /// deck's index in deck's DB
  static const int deckIdIndex = 0;

  /// [deckNameIndex] = 1
  static const int deckNameIndex = 1;

  static const String cardsDB = "cards";
  static const String decksDB = "decks";

  CardsDatabase() {
    initData();
  }

  /// [[FrontText, BackText, Diffculty, DeckID], ...]
  List cardsList = [];

  /// [[deckIdIndex, deckNameIndex], ...]
  List decksList = [];
  final _cards = Hive.box(cardsDB);
  final _decks = Hive.box(decksDB);
  final _cardsListName = "CARDSLIST";
  final _decksListName = "DECKSLIST";

  /// Adds a card and updates database
  ///
  /// Return values: [DbReturnCode.ok], [DbReturnCode.noDeck]
  DbReturnCode addCard(
      {required String frontText,
      required String backText,
      required int deckID}) {
    if (deckExists(deckID)) {
      cardsList.add([frontText, backText, _defaultCardLevel, deckID]);
      updateCardDatabase();
      return DbReturnCode.ok;
    }
    return DbReturnCode.noDeck;
  }

  /// Returns true if deck's id exists in the database
  bool deckExists(int deckID) {
    for (List deck in decksList) {
      if (deck[deckIdIndex] == deckID) {
        return true;
      }
    }
    return false;
  }

  /// Deletes a Card and updates database
  ///
  /// Also check for return values [DbReturnCode.ok] or [DbReturnCode.noCard]
  DbReturnCode deleteCard(int cardIndex) {
    if (cardIndex < cardsList.length) {
      debugPrint("deleteCard(): deleting card index: $cardIndex");
      cardsList.removeAt(cardIndex);
      updateCardDatabase();
      return DbReturnCode.ok;
    }
    debugPrint("deleteCard(): card index: $cardIndex not found");
    return DbReturnCode.noCard;
  }

  /// Modifies the card at [index] and updates database
  ///
  /// Return values: [DbReturnCode.ok], [DbReturnCode.noCard], [DbReturnCode.noDeck]
  DbReturnCode modifyCard(
      int index, String frontText, String backText, int deckID) {
    if (index >= cardsList.length) {
      return DbReturnCode.noCard;
    } else if (deckID >= decksList.length) {
      return DbReturnCode.noDeck;
    }
    cardsList[index] = [frontText, backText, _defaultCardLevel, deckID];
    updateCardDatabase();
    return DbReturnCode.ok;
  }

  /// Returns deck's id if [deckName] exists in the database
  ///
  /// Returns -1 if deck doesn't exist by [deckName]
  int deckWhere(String deckName) {
    for (int i = 0; i < decksList.length; i++) {
      if (decksList[i][deckNameIndex] == deckName) {
        //deck found, return deck's id
        return i;
      }
    }
    return -1;
  }

  /// Adds a deck
  ///
  /// Also check for return values [DbReturnCode.ok] or [DbReturnCode.noCard]
  DbReturnCode addDeck(String deckName) {
    if (deckWhere(deckName) != -1) return DbReturnCode.deckExists;
    int newDeckId = decksList.isNotEmpty ? decksList.last[deckIdIndex] + 1 : 0;
    decksList.add([newDeckId, deckName]);
    updateDatabase();
    return DbReturnCode.ok;
  }

  /// Deletes a deck (only if there is no existing card associated with it) and updates deck database
  ///
  /// return values: [DbReturnCode.ok], [DbReturnCode.noDeck], [DbReturnCode.deckLinked]
  DbReturnCode deleteDeck(int deckID) {
    // check if deck id exists in database
    for (int i = 0; i < decksList.length; i++) {
      if (decksList[i][deckIdIndex] == deckID) {
        // check if deck is associated/linked with a card
        for (List card in cardsList) {
          if (card[cardDeckIDIndex] == deckID) {
            // [deckID] is associated with an existing card
            debugPrint(
                "deleteDeck(): deck id: $deckID is associated with a card");
            return DbReturnCode.deckLinked;
          }
        }
        // deck is not associated/linked, delete deck
        decksList.removeAt(i);
        updateDeckDatabase();
        return DbReturnCode.ok;
      }
    }
    return DbReturnCode.noDeck;
  }

  /// Deletes all the cards associated with [deckID] and also deletes deck at [deckID]
  ///
  /// Return values: [DbReturnCode.ok], [DbReturnCode.noDeck]
  DbReturnCode deleteAllFromDeck(int deckID) {
    if (deckExists(deckID)) {
      String deckTitle = getDeckTitle(deckID);
      debugPrint(
          "deleteAllFromDeck(): Removing cards from deck: $deckTitle...");
      for (int i = cardsList.length - 1; i >= 0; i--) {
        if (cardsList[i][cardDeckIDIndex] == deckID) {
          // remove card
          cardsList.removeAt(i);
        }
      }
      debugPrint("deleteAllFromDeck(): Removing deck: $deckTitle...");
      // remove deck itself
      for (int i = 0; i < decksList.length; i++) {
        if (decksList[i][deckIdIndex] == deckID) {
          decksList.removeAt(i);
          break;
        }
      }
      updateDatabase();
      return DbReturnCode.ok;
    }

    return DbReturnCode.noDeck;
  }

  /// Modifies the value of the specified [deckID]'s name with [text] and updates database
  ///
  /// return values: [DbReturnCode.ok], [DbReturnCode.noDeck]
  DbReturnCode modifyDeck(int deckID, String text) {
    for (int i = 0; i < decksList.length; i++) {
      if (decksList[i][deckIdIndex] == deckID) {
        decksList[i][deckNameIndex] = text;
        updateDeckDatabase();
        return DbReturnCode.ok;
      }
    }
    return DbReturnCode.noDeck;
  }

  /// Increases difficulty level of the card
  ///
  /// return values: [DbReturnCode.noCard], [DbReturnCode.ok]
  DbReturnCode increasePriority(int cardIndex) {
    if (cardIndex >= cardsList.length) return DbReturnCode.noCard;

    if (cardsList[cardIndex][priorityIndex] < _maxPriority) {
      debugPrint("Increasing priortiy...");
      cardsList[cardIndex][priorityIndex] += _stepPriorityValue;
      updateCardDatabase();
    } else {
      debugPrint("Did not increase priority");
    }
    return DbReturnCode.ok;
  }

  /// Decreases priority level of the card
  ///
  /// return values: [DbReturnCode.noCard], [DbReturnCode.ok]
  DbReturnCode decreasePriority(int cardIndex) {
    if (cardIndex >= cardsList.length) DbReturnCode.noCard;

    if (cardsList[cardIndex][priorityIndex] > _minPriority) {
      cardsList[cardIndex][priorityIndex] -= _stepPriorityValue;
      updateCardDatabase();
    }

    return DbReturnCode.ok;
  }

  /// returns deck's title if exists, else empty string [""]
  String getDeckTitle(int index) {
    for (List deck in decksList) {
      if (deck[deckIdIndex] == index) {
        return deck[deckNameIndex];
      }
    }
    return "DB: Something went wrong! 😔";
  }

  /// returns card's front text from Cards List at [index]
  ///
  /// returns null if no card is associated with [index]
  String? getFrontText(int index) {
    if (index < cardsList.length) {
      return cardsList[index][frontIndex];
    }
    return null;
  }

  /// returns card's back text from Cards List at [index]
  ///
  /// returns null if no card is associated with [index]
  String getBackText(int index) {
    String backText = "DB: Something went wrong! 😔";
    if (index < cardsList.length) {
      return cardsList[index][backIndex];
    }
    return backText;
  }

  /// creates/loads data
  void initData() {
    if (_cards.get(_cardsListName) == null ||
        _decks.get(_decksListName) == null) {
      if (kDebugMode) {
        print("[Database/createInitData()] Creating init data");
      }

      if (_preCreateData) {
        cardsList = [
          [
            "Scaffold class",
            "Implements the basic Material Design visual layout structure",
            _defaultCardLevel,
            0,
          ],
          [
            "11\u00B2",
            "121",
            _defaultCardLevel,
            1,
          ],
          [
            "12\u00B2",
            "144",
            _defaultCardLevel,
            1,
          ],
          [
            "13\u00B2",
            "169",
            _defaultCardLevel,
            1,
          ],
          [
            "14\u00B2",
            "196",
            _defaultCardLevel,
            1,
          ],
          [
            "15\u00B2",
            "225",
            _defaultCardLevel,
            1,
          ],
          [
            "16\u00B2",
            "256",
            _defaultCardLevel,
            1,
          ],
          [
            "17\u00B2",
            "289",
            _defaultCardLevel,
            1,
          ],
          [
            "18\u00B2",
            "324",
            _defaultCardLevel,
            1,
          ],
          [
            "19\u00B2",
            "361",
            _defaultCardLevel,
            1,
          ],
          [
            "20\u00B2",
            "400",
            _defaultCardLevel,
            1,
          ],
          [
            "Andhra Pradesh",
            "Amaravati",
            _defaultCardLevel,
            2,
          ],
          [
            "Jharkhand",
            "Ranchi",
            _defaultCardLevel,
            2,
          ],
          [
            "Kerala",
            "Thiruvananthapuram",
            _defaultCardLevel,
            2,
          ],
          [
            "Madhya Pradesh",
            "Bhopal",
            _defaultCardLevel,
            2,
          ],
          [
            "Mizoram",
            "Aizawl",
            _defaultCardLevel,
            2,
          ],
          [
            "Tripura",
            "Agartala",
            _defaultCardLevel,
            2,
          ],
          [
            "Arunachal Pradesh",
            "Itanagar",
            _defaultCardLevel,
            2,
          ],
          [
            "Assam",
            "Dispur",
            _defaultCardLevel,
            2,
          ],
          [
            "Bihar",
            "Patna",
            _defaultCardLevel,
            2,
          ],
          [
            "Haryana",
            "Chandigarh",
            _defaultCardLevel,
            2,
          ],
          [
            "Maharashtra",
            "Mumbai",
            _defaultCardLevel,
            2,
          ],
          [
            "Meghalaya",
            "Shillong",
            _defaultCardLevel,
            2,
          ],
          [
            "Rajasthan",
            "Jaipur",
            _defaultCardLevel,
            2,
          ],
          [
            "Tamil Nadu",
            "Chennai",
            _defaultCardLevel,
            2,
          ],
        ];
        decksList = [
          [0, "Flutter"],
          [1, "x\u00B2"],
          [2, "Capitals of Indian States"],
        ];
      }
    } else {
      loadData();
    }
  }

  void loadData() {
    cardsList = _cards.get(_cardsListName);
    decksList = _decks.get(_decksListName);
  }

  void updateDatabase() {
    _cards.put(_cardsListName, cardsList);
    _decks.put(_decksListName, decksList);
  }

  void updateCardDatabase() {
    _cards.put(_cardsListName, cardsList);
  }

  void updateDeckDatabase() {
    _decks.put(_decksListName, decksList);
  }

  /// appends [deckIdIndex, "deckName"] to [decksList]
  /// and returns true if deckID is unique
  ///
  /// else returns false
  bool appendDeck(List deckToAppend) {
    debugPrint("appendDeck(): appending $deckToAppend...");
    for (List deck in decksList) {
      if (deck[deckIdIndex] == deckToAppend[deckIdIndex]) {
        debugPrint(
            "appendDeck(): deckID: ${deckToAppend[deckIdIndex]} exists. Returning...");
        return false;
      }
    }
    decksList.add(deckToAppend);
    debugPrint("appendDeck(): decksList after appending: $decksList");
    return true;
  }

  /// appends [FrontText, BackText, Diffculty, DeckID]
  /// to the [cardsList]
  /// and returns true if frontText is unique
  ///
  /// else returns false
  bool appendCard(List cardToAppend) {
    debugPrint("appendCard(): appending $cardToAppend...");
    for (List card in cardsList) {
      if (card[frontIndex] == cardToAppend[frontIndex]) {
        debugPrint(
            "appendDeck(): frontText: ${cardToAppend[frontIndex]} exists. Returning...");
        return false;
      }
    }
    cardsList.add(cardToAppend);
    debugPrint("appendCard(): cardsList after appending: $cardsList");
    return true;
  }

  /// exports [cardsList] and [decksList] to a JSON file
  void export() async {
    debugPrint("export function called");
    String fileName = "flashcards.json";
    String? result = await FilePicker.platform.saveFile(
      dialogTitle: "Export flashcards",
      fileName: fileName,
      bytes: utf8.encode(serialize()),
      allowedExtensions: <String>[".json"],
    );
    if (result != null) {
      debugPrint("export(): exported to: $result");
    } else {
      debugPrint("export(): Couldn't export file");
    }
  }

  /// imports [cardsList] and [decksList] from a JSON file
  void import(VoidCallback notifyParent) async {
    debugPrint("import function called");
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        String json = utf8.decode(file.readAsBytesSync());
        debugPrint("import(): imported file contents: $json");
        if (deserializeAndAppend(json)) {
          notifyParent;
        }
      } else {
        debugPrint("import(): User cancelled file import");
      }
    } catch (e) {
      debugPrint("Exception in import(): $e");
    }
  }

  /// Serializes data to:
  ///
  /// {
  ///   "cardsList": [[cardData], ...],
  ///   "decksList": [[deckData], ...]
  /// }
  String serialize() {
    return jsonEncode(
        <String, dynamic>{"cardsList": cardsList, "decksList": decksList});
  }

  /// 1. De-seralizes data to:
  ///
  /// {
  ///   cardsList: [[<cardData>],...],
  ///   decksList: [[<deckData>],...]
  /// }
  ///
  /// 2. Appends data to existing lists
  bool deserializeAndAppend(String json) {
    bool appended = false;
    Map<String, dynamic> list = jsonDecode(json);
    List cards = list["cardsList"];
    List decks = list["decksList"];
    debugPrint("deserializeAndAppend():\nCards: $cards\nDecks: $decks");

    debugPrint("deserializeAndAppend(): appending decks:\n$decks");
    for (List deck in decks) {
      if (appendDeck(deck)) {
        appended = true;
      }
    }

    debugPrint("deserializeAndAppend(): appending cards:$cards");
    for (List card in cards) {
      if (appendCard(card)) {
        appended = true;
      }
    }
    return appended;
  }

  void debugPrint(String msg) {
    if (kDebugMode) {
      print("[Database] $msg");
    }
  }
}
