import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xqstudio/ui/game/game_screen.dart';
import 'package:xqstudio/ui/game/navigation_toolbar.dart';

void main() {
  group('GameScreen', () {
    testWidgets('renders in narrow layout', (tester) async {
      // Default test size is 800x600, which is <= 800 wide => narrow layout
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameScreen()),
          ),
        ),
      );

      // Should contain the navigation toolbar
      expect(find.byType(GameNavigationToolbar), findsOneWidget);

      // Should contain the tab labels
      expect(find.text('走法'), findsOneWidget);
      expect(find.text('变着'), findsOneWidget);
      expect(find.text('注释'), findsOneWidget);
    });

    testWidgets('renders in wide layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: GameScreen()),
          ),
        ),
      );

      // Should contain the navigation toolbar
      expect(find.byType(GameNavigationToolbar), findsOneWidget);

      // Should contain the tab labels
      expect(find.text('走法'), findsOneWidget);
      expect(find.text('变着'), findsOneWidget);
      expect(find.text('注释'), findsOneWidget);
    });
  });
}
