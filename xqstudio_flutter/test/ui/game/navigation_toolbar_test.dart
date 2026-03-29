import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xqstudio/ui/game/navigation_toolbar.dart';

IconButton _findIconButton(WidgetTester tester, IconData icon) {
  final finder = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(IconButton),
  );
  return tester.widget<IconButton>(finder);
}

void main() {
  group('GameNavigationToolbar', () {
    testWidgets('renders all five buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameNavigationToolbar()),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNWidgets(5));
    });

    testWidgets('prev and first are disabled at step 0', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameNavigationToolbar()),
          ),
        ),
      );

      expect(_findIconButton(tester, Icons.first_page).onPressed, isNull);
      expect(_findIconButton(tester, Icons.chevron_left).onPressed, isNull);
    });

    testWidgets('delete is disabled at step 0', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameNavigationToolbar()),
          ),
        ),
      );

      expect(_findIconButton(tester, Icons.delete).onPressed, isNull);
    });

    testWidgets('next and last are disabled when no moves exist',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameNavigationToolbar()),
          ),
        ),
      );

      expect(_findIconButton(tester, Icons.chevron_right).onPressed, isNull);
      expect(_findIconButton(tester, Icons.last_page).onPressed, isNull);
    });
  });
}
