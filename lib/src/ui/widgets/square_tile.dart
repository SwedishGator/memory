// SquareTile: visual representation of a single grid cell. It shows
// three states: normal, highlighted (during reveal), and revealed (already
// guessed correctly).

import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final bool highlighted;
  final bool revealed;
  final bool mistaken;

  const SquareTile({Key? key, this.highlighted = false, this.revealed = false, this.mistaken = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    if (highlighted) {
      color = Colors.orange; // currently being shown in sequence
    } else if (revealed) {
      color = Colors.green; // already correctly guessed
    } else if (mistaken) {
      color = Colors.redAccent; // user guessed this incorrectly
    } else {
      color = Colors.grey.shade300; // default
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
