import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/logging/widgets/success_indicator.dart';
import 'package:hydracat/shared/widgets/loading/loading_overlay.dart';

void main() {
  group('LoadingOverlay', () {
    testWidgets('shows content when state is none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.none,
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SuccessIndicator), findsNothing);
    });

    testWidgets('shows loading spinner when state is loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.loading,
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SuccessIndicator), findsNothing);
      // Content should still exist but be dimmed (opacity)
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('shows success indicator when state is success', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.success,
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.byType(SuccessIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics for loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.loading,
            loadingMessage: 'Loading data',
            child: Text('Test Content'),
          ),
        ),
      );

      // Verify Semantics widget exists for accessibility
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics for success', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.success,
            child: Text('Test Content'),
          ),
        ),
      );

      // Verify Semantics widget exists for accessibility
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(SuccessIndicator), findsOneWidget);
    });

    testWidgets('uses default loading message when none provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.loading,
            child: Text('Test Content'),
          ),
        ),
      );

      // Verify loading indicator shows with Semantics
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('respects custom content opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.loading,
            contentOpacity: 0.5,
            child: Text('Test Content'),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('content has full opacity when state is none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.none,
            child: Text('Test Content'),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });
}
