import 'package:flash_your_memory/data/database.dart';
import 'package:flash_your_memory/pages/cards_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/deck_page_utils.dart';
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
      motion: const DrawerMotion(),
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
      motion: const DrawerMotion(),
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
    return Slidable(
      startActionPane: startActionPane(context, index),
      endActionPane: endActionPane(context, index),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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

    _debugPrint("build(): creating slivers list");
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
  void _debugPrint(String msg) {
    if (kDebugMode) {
      print("[DecksPage] $msg");
    }
  }
}
