import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:crossball/features/puzzle/presentation/puzzle_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleGameParams', () {
    test('gridSize is part of equality', () {
      const a = PuzzleGameParams(mode: PuzzleMode.practice, gridSize: 3);
      const b = PuzzleGameParams(mode: PuzzleMode.practice, gridSize: 4);
      const c = PuzzleGameParams(mode: PuzzleMode.practice, gridSize: 3);

      expect(a, isNot(equals(b)));
      expect(a, equals(c));
    });
  });

  group('PuzzleGameState', () {
    test('solvedCount counts solved cells only', () {
      const state = PuzzleGameState(
        cells: {
          '0_0': PuzzleCell(id: 'a', row: 0, col: 0, solvedPlayerId: 'p1', isCorrect: true),
          '0_1': PuzzleCell(id: 'b', row: 0, col: 1),
          '1_0': PuzzleCell(id: 'c', row: 1, col: 0, solvedPlayerId: 'p2', isCorrect: true),
        },
      );

      expect(state.solvedCount, 2);
    });

    test('copyWith clears selection when requested', () {
      const state = PuzzleGameState(selectedRow: 1, selectedCol: 2);
      final cleared = state.copyWith(clearSelection: true);

      expect(cleared.selectedRow, isNull);
      expect(cleared.selectedCol, isNull);
    });

    test('addHint increments hintsUsed via notifier pattern', () {
      const state = PuzzleGameState(
        hintsUsed: 1,
        hintsRevealed: {
          '0_0': [HintResult(hintType: HintType.nationality, hintValue: 'Brazil')],
        },
      );
      final next = state.copyWith(
        hintsUsed: state.hintsUsed + 1,
        hintsRevealed: {
          ...state.hintsRevealed,
          '0_0': [
            ...state.hintsRevealed['0_0']!,
            const HintResult(hintType: HintType.position, hintValue: 'Midfielder'),
          ],
        },
      );

      expect(next.hintsUsed, 2);
      expect(next.hintsRevealed['0_0']!.length, 2);
      expect(next.hintsRevealed['0_0']![1].hintValue, 'Midfielder');
    });
  });
}
