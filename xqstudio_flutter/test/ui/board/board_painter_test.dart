import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/ui/board/board_widget.dart';

void main() {
  group('BoardWidget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 450,
                child: BoardWidget(boardState: BoardState.standard()),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('tap triggers onTap callback', (tester) async {
      int? tappedXY;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 450,
                child: BoardWidget(
                  boardState: BoardState.standard(),
                  onTap: (xy) => tappedXY = xy,
                ),
              ),
            ),
          ),
        ),
      );

      // Find the GestureDetector and tap near a grid intersection.
      final finder = find.byType(GestureDetector);
      expect(finder, findsOneWidget);

      // Tap at the center of the board widget.
      await tester.tap(finder);
      await tester.pump();
      expect(tappedXY, isNotNull);
    });

    testWidgets('renders with selection and move indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 450,
                child: BoardWidget(
                  boardState: BoardState.standard(),
                  selectedXY: 40, // shuai at (4,0)
                  lastMoveFromXY: 12,
                  lastMoveToXY: 14,
                ),
              ),
            ),
          ),
        ),
      );
      // Just verify it doesn't throw.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with reversed board', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 450,
                child: BoardWidget(
                  boardState: BoardState.standard(),
                  reversed: true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
