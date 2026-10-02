// GridWidget: renders an N x N grid of `SquareTile`s based on the
// `GameState`. It highlights tiles during reveal and routes tile taps
// back to the engine via `onTileTap`.

import 'package:flutter/material.dart';
import '../../domain/game_state.dart';
import 'square_tile.dart';

class GridWidget extends StatelessWidget {
  final GameState state;
  final void Function(int index) onTileTap;

  const GridWidget({Key? key, required this.state, required this.onTileTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final n = state.gridSize;
    final total = n * n;

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest.shortestSide; // square area
      final tileSize = size / n;

      return Center(
        child: SizedBox(
          width: tileSize * n,
          height: tileSize * n,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: n,
            ),
            itemCount: total,
            itemBuilder: (context, index) {
              final isHighlighted = index == state.highlightedIndex; // currently revealed

              // Consider a tile 'revealed' if it appears earlier in the sequence
              final revealedCount = state.guessIndex;
              final sequence = state.sequence;
              final isRevealedPersist = revealedCount > 0 && sequence.indexWhere((e) => e == index) >= 0 && sequence.indexOf(index) < revealedCount;

              // Mistake handling: determine if this tile was guessed incorrectly
              final isMistaken = state.mistakenIndices.contains(index);

              return GestureDetector(
                onTap: () => onTileTap(index),
                child: SquareTile(
                  highlighted: isHighlighted,
                  revealed: isRevealedPersist,
                  mistaken: isMistaken,
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
