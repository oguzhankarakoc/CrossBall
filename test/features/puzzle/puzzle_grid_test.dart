import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/theme/app_theme.dart';
import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:crossball/features/puzzle/presentation/widgets/puzzle_grid.dart';

Puzzle _demoPuzzle() {
  Club club(String id, String name, String slug, String primary, String secondary) => Club(
        id: id,
        name: name,
        slug: slug,
        badgePrimaryColor: primary,
        badgeSecondaryColor: secondary,
        badgeAccentColor: '#FFD700',
        badgeInitials: id.substring(0, 3).toUpperCase(),
      );

  final rows = [
    club('bar', 'Barcelona', 'barcelona', '#A50044', '#004D98'),
    club('che', 'Chelsea', 'chelsea', '#034694', '#FFFFFF'),
    club('bay', 'Bayern', 'bayern-munich', '#DC052D', '#0066B2'),
  ];
  final cols = [
    club('rma', 'Real Madrid', 'real-madrid', '#F5F5F5', '#FEBE10'),
    club('mun', 'Man United', 'manchester-united', '#DA291C', '#FBE122'),
    club('juv', 'Juventus', 'juventus', '#000000', '#FFFFFF'),
  ];

  final cells = <PuzzleCell>[
    for (var r = 0; r < 3; r++)
      for (var c = 0; c < 3; c++)
        PuzzleCell(id: 'cell_${r}_$c', row: r, col: c),
  ];

  return Puzzle(
    id: 'test',
    date: '2026-07-03',
    gridSize: 3,
    rowClubs: rows,
    colClubs: cols,
    cells: cells,
  );
}

void main() {
  testWidgets('PuzzleGrid renders 9 tappable cells and 6 club badges', (tester) async {
    final puzzle = _demoPuzzle();
    final cells = {
      for (final cell in puzzle.cells) '${cell.row}_${cell.col}': cell,
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightPitch(),
        home: Scaffold(
          body: Center(
            child: PuzzleGrid(
              puzzle: puzzle,
              cells: cells,
              onCellTap: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsNWidgets(9));
    expect(find.byType(PuzzleGrid), findsOneWidget);

    final gridBox = tester.renderObject<RenderBox>(find.byType(PuzzleGrid));
    expect(gridBox.size.height, greaterThan(200));
    expect(gridBox.size.width, greaterThan(300));
  });
}
