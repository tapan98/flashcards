import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/pages/cards_page.dart';
import 'package:flash_your_memory/util/dialog_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class DecksPage extends StatefulWidget {
  const DecksPage(
      {super.key, required this.database, required this.controller});
  final CardsDatabase database;
  final ScrollController controller;

  @override
  State<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends State<DecksPage> {
  final deckEditKey = GlobalKey<FormState>();
  static const _emptyListText = "😔 Nothing's here";

  void refreshState() {
    setState(() {});
  }

  /// Edit action for slidable deck widget at [index]
  ActionPane startActionPane(BuildContext context, int index) {
    final theme = Theme.of(context);
    return ActionPane(
      motion: const BehindMotion(),
      children: [
        SlidableAction(
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(22),
          onPressed: (context) {
            showDialog(
              context: context,
              builder: (context) {
                return EditDeckDialog(
                  formKey: deckEditKey,
                  deckID: widget.database.decksList[index]
                      [CardsDatabase.deckIdIndex],
                  notifyParent: () => setState(() {}),
                  database: widget.database,
                );
              },
            );
          },
          icon: Icons.edit,
        )
      ],
    );
  }

  /// Delete action for slidable deck widget at [index]
  ActionPane endActionPane(BuildContext context, int index) {
    final theme = Theme.of(context);
    return ActionPane(
      motion: const BehindMotion(),
      children: [
        SlidableAction(
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          borderRadius: BorderRadius.circular(22),
          onPressed: (context) {
            // asks user to confirm to delete all of the cards
            showDialog(
                context: context,
                builder: (context) {
                  return RemoveDeckDialog(
                    deckID: widget.database.decksList[index]
                        [CardsDatabase.deckIdIndex],
                    database: widget.database,
                    notifyParent: () {
                      refreshState();
                    },
                  );
                });
          },
          icon: Icons.delete,
        )
      ],
    );
  }

  /// builds a slidable deck at [index]
  Widget sliverChildDelegateBuilder(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Slidable(
        startActionPane: startActionPane(context, index),
        endActionPane: endActionPane(context, index),
        child: DecoratedDeck(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CardsPage(
                  notifyParent: refreshState,
                  database: widget.database,
                  deckID: widget.database.decksList[index]
                      [CardsDatabase.deckIdIndex],
                ),
              ),
            );
          },
          text: widget.database.decksList[index][CardsDatabase.deckNameIndex],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Widget> slivers = <Widget>[
      SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
        ),
        delegate: SliverChildBuilderDelegate(
          childCount: widget.database.decksList.length,
          sliverChildDelegateBuilder,
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: (widget.database.decksList.isEmpty)
          ? const Center(
              child: Text(_emptyListText),
            )
          : CustomScrollView(
              controller: widget.controller,
              slivers: slivers,
            ),
    );
  }

  /// for debugging purposes
  void debugPrint(String msg) {
    if (kDebugMode) {
      print("[DecksPage] $msg");
    }
  }
}

/// A dialog that asks for confirmation to delete the deck and its cards
class RemoveDeckDialog extends StatelessWidget {
  const RemoveDeckDialog(
      {super.key,
      required this.deckID,
      required this.database,
      required this.notifyParent});
  final int deckID;
  final CardsDatabase database;
  final void Function() notifyParent;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Delete deck and all of its cards?"),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel")),
              FilledButton(
                onPressed: () {
                  database.deleteAllFromDeck(deckID);
                  notifyParent();
                  Navigator.pop(context);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
        )
      ],
    );
  }
}

/// A dialog that allows the user to edit deck's name
class EditDeckDialog extends StatelessWidget {
  const EditDeckDialog({
    super.key,
    required this.deckID,
    required this.formKey,
    required this.notifyParent,
    required this.database,
  });

  final GlobalKey<FormState> formKey;
  final void Function() notifyParent;
  final int deckID;
  final CardsDatabase database;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Edit Deck"),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              initialValue: database.getDeckTitle(deckID),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter Deck";
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  database.modifyDeck(deckID, value);
                  notifyParent();
                }
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DialogButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: "Cancel",
            ),
            DialogButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context);
                }
              },
              text: "Save",
            ),
          ],
        ),
      ],
    );
  }
}

/// Deck card
class DecoratedDeck extends StatelessWidget {
  const DecoratedDeck({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          elevation: 5,
          // alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 25),
        ),
      ),
    );
  }
}
