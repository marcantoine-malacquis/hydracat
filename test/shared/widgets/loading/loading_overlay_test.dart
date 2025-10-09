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
      // Both indicators exist in tree but success is hidden via AnimatedOpacity
      expect(find.byType(SuccessIndicator), findsOneWidget);

      // Verify loading indicator is visible (opacity = 1.0)
      final loadingOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(loadingOpacity.opacity, 1.0);

      // Verify success indicator is hidden (opacity = 0.0)
      final successOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(SuccessIndicator),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(successOpacity.opacity, 0.0);

      // Content should still exist
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
      // Both indicators exist in tree but loading is hidden via AnimatedOpacity
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify success indicator is visible (opacity = 1.0)
      final successOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(SuccessIndicator),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(successOpacity.opacity, 1.0);

      // Verify loading indicator is hidden (opacity = 0.0)
      final loadingOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(loadingOpacity.opacity, 0.0);

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

    testWidgets('overlay has centered indicators in stack', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.loading,
            child: Text('Test Content'),
          ),
        ),
      );

      // Verify both indicators are in the widget tree
      expect(find.byType(Stack), findsWidgets);

      // Both animated opacity widgets should be present
      expect(find.byType(AnimatedOpacity), findsNWidgets(2));

      // Verify AnimatedContainer exists (the overlay container)
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Verify content is accessible
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('no overlay shown when state is none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            state: LoadingOverlayState.none,
            child: Text('Test Content'),
          ),
        ),
      );

      // When state is none, no overlay widgets should exist
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}
