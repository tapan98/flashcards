import 'package:flutter/material.dart';
import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/util/dialog_button.dart';

class DecoratedDeck extends StatelessWidget {
  /// Deck card
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

class EditDeckDialog extends StatelessWidget {
  /// A dialog that allows the user to edit deck's name
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        ),
      ],
    );
  }
}

class RemoveDeckDialog extends StatelessWidget {
  /// A dialog that asks for confirmation to delete the deck and its cards
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
