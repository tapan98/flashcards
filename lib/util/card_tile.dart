import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

/// builds a Card that can be flipped
class CardTile extends StatelessWidget {
  final String frontText;
  final String backText;
  final Color? backgroundColorFront;
  final Color? foregroundColorFront;
  final Color? backgroundColorBack;
  final Color? foregroundColorBack;
  final bool testMode;
  final FlipCardController controller;

  const CardTile({
    super.key,
    required this.frontText,
    required this.backText,
    required this.controller,
    this.testMode = false,
    this.backgroundColorFront,
    this.foregroundColorFront,
    this.backgroundColorBack,
    this.foregroundColorBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: FlipCard(
        fill: Fill.fillBack,
        side: CardSide.FRONT,
        flipOnTouch: false,
        controller: controller,
        front: DecoratedCard(
          // front
          controller: controller,
          text: frontText,
          backgroundColor:
              backgroundColorFront ?? theme.colorScheme.secondaryContainer,
          foregroundColor:
              foregroundColorFront ?? theme.colorScheme.onSecondaryContainer,
          testMode: testMode,
        ),
        back: DecoratedCard(
          // back
          text: backText,
          controller: controller,
          backgroundColor:
              backgroundColorBack ?? theme.colorScheme.tertiaryContainer,
          foregroundColor:
              foregroundColorBack ?? theme.colorScheme.onTertiaryContainer,
          testMode: testMode,
        ),
      ),
    );
  }
}

class DecoratedCard extends StatelessWidget {
  final String text;
  final FlipCardController controller;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool testMode;

  const DecoratedCard({
    super.key,
    required this.text,
    required this.controller,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.testMode,
  });

  List<Widget> getChildrenItems() {
    List<Widget> items = <Widget>[
      Expanded(
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: 30, color: foregroundColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    // Button to flip the card shouldn't be built in test mode
    if (testMode == false) {
      items.addAll([
        Divider(
          color: foregroundColor,
        ),
        ElevatedButton(
          onPressed: () => controller.toggleCard(),
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
          child: const SizedBox(
            height: 50,
            width: double.infinity,
            child: Center(
              child: Text(
                "Flip card",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      ]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Material(
        color: backgroundColor,
        elevation: 5.0,
        borderRadius: const BorderRadius.all(Radius.circular(25.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: getChildrenItems(),
        ),
      ),
    );
  }
}
