import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/util/dialog_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Page to add/edit a card
class CardEditor extends StatefulWidget {
  final CardsDatabase database;
  final Function() notifyParent;
  final void Function()? onEdit;
  // always null?
  /// deck to be pre selected
  final int deckID;

  /// Card index from database to edit
  final int? cardIndex;

  const CardEditor({
    super.key,
    required this.database,
    required this.notifyParent,
    this.onEdit,
    this.cardIndex,
    // TODO always null?
    required this.deckID,
  });

  @override
  State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  final _dialogTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _deckFormKey = GlobalKey<FormState>();
  String? _frontText;
  String? _backText;
  String? _dropDownValue;

  List<DropdownMenuItem<String>> _dropDownItems = [];

  void saveCard(String frontText, String backText, int deckID) {
    if (widget.cardIndex != null &&
        widget.cardIndex! < widget.database.cardsList.length) {
      // Edit Card
      widget.database
          .modifyCard(widget.cardIndex!, frontText, backText, deckID);
    } else {
      // Add Card
      widget.database
          .addCard(frontText: frontText, backText: backText, deckID: deckID);
    }

    widget.notifyParent();
    Navigator.of(context).pop();
  }

  List<DropdownMenuItem<String>> getDropDownItems() {
    List<String> decksNames = <String>[];

    // populate [deckNames]
    for (List deck in widget.database.decksList) {
      decksNames.add(deck[CardsDatabase.deckNameIndex]);
    }
    return decksNames.map((String item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _dropDownItems = getDropDownItems();

    if (widget.deckID != -1) {
      // init deck selection
      _dropDownValue = widget.database.getDeckTitle(widget.deckID);
    }

    // Set up for edit mode
    if (widget.cardIndex != null &&
        widget.cardIndex! < widget.database.cardsList.length) {
      debugPrint("build(): --- Card Edit mode ---");

      _frontText = widget.database.cardsList[widget.cardIndex!]
          [CardsDatabase.frontIndex];
      _backText =
          widget.database.cardsList[widget.cardIndex!][CardsDatabase.backIndex];

      int deckID = widget.database.cardsList[widget.cardIndex!]
          [CardsDatabase.cardDeckIDIndex];

      // Get Deck String
      _dropDownValue ??=
          widget.database.decksList[deckID][CardsDatabase.deckNameIndex];

      debugPrint("build(): _dropDownValue: $_dropDownValue");
    }
  }

  @override
  void dispose() {
    _dialogTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.cardIndex == null) ? "Add a Card" : "Edit Card"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          debugPrint("Save button _dropDownValue: $_dropDownValue");
          if (_formKey.currentState!.validate() && _dropDownValue != null) {
            _formKey.currentState!.save();
            int deckID = widget.database.deckWhere(_dropDownValue ?? "");

            if (deckID == -1) {
              debugPrint(
                  "FloatingActionButton(): Deck $_dropDownValue doesn't exist");
            } else {
              saveCard(
                _frontText ?? "",
                _backText ?? "",
                widget.database.deckWhere(_dropDownValue ?? ""),
                // widget.database.decksList
                //     .indexWhere((deck) => deck == _dropDownValue),
              );
            }
          }
        },
        tooltip: "Save",
        label: const Text("Save"),
        icon: const Icon(Icons.save),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                CardTextFormField(
                  initialValue: _frontText,
                  labelText: "Front text",
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return "Please enter Front Text";
                    }
                    return null;
                  },
                  onSave: (value) {
                    if (value != null) {
                      _frontText = value;
                    }
                  },
                ),
                CardTextFormField(
                  initialValue: _backText,
                  labelText: "Back text",
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return "Please enter Back Text";
                    }
                    return null;
                  },
                  onSave: (value) {
                    if (value != null) {
                      _backText = value;
                    }
                  },
                ),
                Padding(
                  // decks drop down list
                  padding: const EdgeInsets.all(10.0),
                  child: DropdownButtonFormField<String>(
                    // TODO: doesn't assign initial value
                    value: _dropDownValue,
                    items: _dropDownItems,
                    onChanged: (String? value) {
                      _dropDownValue = value;
                      setState(() {});
                      debugPrint(
                          "DropdownButtonFormField selected _dropDownValue: $_dropDownValue");
                    },
                    validator: (String? value) {
                      return (value == null)
                          ? "Please Choose deck from the list"
                          : null;
                    },
                    hint: const Text("Select deck"),
                  ),
                ),
                Row(
                  // add deck dialog
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FilledButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AddDeckDialog(
                                  formKey: _deckFormKey,
                                  database: widget.database,
                                  controller: _dialogTextController,
                                  onAdd: () {
                                    _dropDownItems = getDropDownItems();
                                    _dropDownValue = widget.database.decksList
                                        .last[CardsDatabase.deckNameIndex];
                                  },
                                  notifyParent: () => setState(() {}),
                                );
                              },
                            );
                          },
                          child: const Text("Add deck"),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 80,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Prints debug message
  void debugPrint(String msg) {
    if (kDebugMode) print("[CardEditor] $msg");
  }
}

class AddDeckDialog extends StatelessWidget {
  const AddDeckDialog({
    super.key,
    required this.database,
    required this.controller,
    required this.notifyParent,
    required this.onAdd,
    required this.formKey,
  });

  final CardsDatabase database;
  final Function() notifyParent;

  /// this function is called when "Add" button is pressed
  final VoidCallback onAdd;
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Add deck"),
      children: <Widget>[
        Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              autofocus: true,
              maxLength: 50,
              validator: (value) {
                if (value != null) {
                  if (value.isEmpty) {
                    return "Please enter deck";
                  } else if (database.decksList.contains(value)) {
                    return "Deck already exists";
                  }
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  database.addDeck(value);
                }
              },
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Deck name",
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                  text: "Cancel",
                  onPressed: () {
                    notifyParent();
                    controller.clear();
                    Navigator.pop(context);
                  }),
              DialogButton(
                text: "Add",
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    onAdd();
                    notifyParent(); // To refresh list
                    controller.clear();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  /// Prints debug message
  void debugPrint(String msg) {
    if (kDebugMode) {
      print("[AddDeckDialog] $msg");
    }
  }
}

/// Input Text field box
class CardTextFormField extends StatelessWidget {
  const CardTextFormField({
    super.key,
    this.labelText,
    required this.validator,
    required this.onSave,
    this.initialValue,
  });

  final String? labelText;
  final String? Function(String? value) validator;
  final void Function(String? value) onSave;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        autofocus: true,
        maxLength: 100,
        initialValue: initialValue,
        keyboardType: TextInputType.multiline,
        minLines: 3,
        maxLines: 5,
        validator: validator,
        onSaved: onSave,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          // hintText: _textHint,
          labelText: labelText,
        ),
      ),
    );
  }
}
