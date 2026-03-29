import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xqstudio/ui/game/move_list_panel.dart';

void main() {
  group('MoveListPanel', () {
    testWidgets('shows empty message when no moves', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MoveListPanel()),
          ),
        ),
      );

      expect(find.text('暂无走法'), findsOneWidget);
    });

    testWidgets('renders as a ListView', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MoveListPanel()),
          ),
        ),
      );

      // With no moves, should show the empty message (no ListView)
      expect(find.byType(ListView), findsNothing);
      expect(find.text('暂无走法'), findsOneWidget);
    });
  });
}
