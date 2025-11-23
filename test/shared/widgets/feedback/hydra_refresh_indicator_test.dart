import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/feedback/hydra_refresh_indicator.dart';

void main() {
  group('HydraRefreshIndicator', () {
    testWidgets('renders RefreshIndicator on Material platform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: const SingleChildScrollView(
                child: SizedBox(height: 1000, child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(CupertinoSliverRefreshControl), findsNothing);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('renders CupertinoSliverRefreshControl on iOS platform', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: const SingleChildScrollView(
                child: SizedBox(height: 1000, child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      // Check that CupertinoSliverRefreshControl exists in the slivers
      final customScrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(
        customScrollView.slivers.first,
        isA<CupertinoSliverRefreshControl>(),
      );
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('converts SingleChildScrollView to CustomScrollView on iOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customScrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(customScrollView, isNotNull);
      expect(find.byType(SliverToBoxAdapter), findsOneWidget);
      // Check that CupertinoSliverRefreshControl exists in the slivers
      expect(
        customScrollView.slivers.first,
        isA<CupertinoSliverRefreshControl>(),
      );
    });

    testWidgets('handles CustomScrollView on iOS by adding refresh control', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Text('Content'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customScrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(customScrollView, isNotNull);
      expect(customScrollView.slivers.length, 2); // Refresh control +
      // original sliver
      // Check that CupertinoSliverRefreshControl exists in the slivers
      expect(
        customScrollView.slivers.first,
        isA<CupertinoSliverRefreshControl>(),
      );
    });

    testWidgets(
      'calls onRefresh callback when refresh is triggered on Material',
      (
        WidgetTester tester,
      ) async {
        var refreshCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HydraRefreshIndicator(
                onRefresh: () async {
                  refreshCalled = true;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                minRefreshDuration: const Duration(milliseconds: 100),
                child: const SingleChildScrollView(
                  child: SizedBox(
                    height: 1000,
                    child: Text('Content'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the RefreshIndicator and trigger a refresh
        final refreshIndicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );

        // Simulate pull-to-refresh by calling onRefresh directly
        // The wrapped callback should enforce minimum duration
        final startTime = DateTime.now();
        await refreshIndicator.onRefresh();
        final elapsed = DateTime.now().difference(startTime);

        expect(refreshCalled, isTrue);
        // Verify that minimum duration was enforced (allowing some
        // margin for test execution)
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
      },
    );

    testWidgets('passes through Material-specific parameters', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.blue;
      const testBackgroundColor = Colors.grey;
      const testDisplacement = 50.0;
      const testEdgeOffset = 10.0;
      const testStrokeWidth = 3.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              color: testColor,
              backgroundColor: testBackgroundColor,
              displacement: testDisplacement,
              edgeOffset: testEdgeOffset,
              strokeWidth: testStrokeWidth,
              child: const SingleChildScrollView(
                child: SizedBox(height: 1000, child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      expect(refreshIndicator.color, testColor);
      expect(refreshIndicator.backgroundColor, testBackgroundColor);
      expect(refreshIndicator.displacement, testDisplacement);
      expect(refreshIndicator.edgeOffset, testEdgeOffset);
      expect(refreshIndicator.strokeWidth, testStrokeWidth);
    });

    testWidgets('handles non-scrollable child on iOS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: HydraRefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: const Text('Non-scrollable content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still create a CustomScrollView with SliverToBoxAdapter
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverToBoxAdapter), findsOneWidget);
      // Check that CupertinoSliverRefreshControl exists in the slivers
      final customScrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(
        customScrollView.slivers.first,
        isA<CupertinoSliverRefreshControl>(),
      );
    });

    testWidgets(
      'builds correctly with minRefreshDuration and enableHaptics on Material',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HydraRefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                minRefreshDuration: const Duration(milliseconds: 200),
                enableHaptics: false,
                child: const SingleChildScrollView(
                  child: SizedBox(height: 1000, child: Text('Content')),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'builds correctly with minRefreshDuration and enableHaptics on iOS',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              body: HydraRefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                minRefreshDuration: const Duration(milliseconds: 200),
                child: const SingleChildScrollView(
                  child: SizedBox(height: 1000, child: Text('Content')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CustomScrollView), findsOneWidget);
        // Check that CupertinoSliverRefreshControl exists in the slivers
        final customScrollView = tester.widget<CustomScrollView>(
          find.byType(CustomScrollView),
        );
        expect(
          customScrollView.slivers.first,
          isA<CupertinoSliverRefreshControl>(),
        );
      },
    );

    testWidgets(
      'wrapped onRefresh callback is called and completes on Material',
      (
        WidgetTester tester,
      ) async {
        var refreshCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HydraRefreshIndicator(
                onRefresh: () async {
                  refreshCalled = true;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                minRefreshDuration: const Duration(milliseconds: 100),
                child: const SingleChildScrollView(
                  child: SizedBox(
                    height: 1000,
                    child: Text('Content'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Find the RefreshIndicator and trigger a refresh
        final refreshIndicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );

        // Simulate pull-to-refresh by calling onRefresh directly
        // The wrapped callback should enforce minimum duration
        final startTime = DateTime.now();
        await refreshIndicator.onRefresh();
        final elapsed = DateTime.now().difference(startTime);

        expect(refreshCalled, isTrue);
        // Verify that minimum duration was enforced (allowing some margin
        // for test execution)
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
      },
    );

    testWidgets(
      'wrapped onRefresh callback is called and completes on iOS',
      (
        WidgetTester tester,
      ) async {
        var refreshCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              body: HydraRefreshIndicator(
                onRefresh: () async {
                  refreshCalled = true;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                minRefreshDuration: const Duration(milliseconds: 100),
                child: const SingleChildScrollView(
                  child: SizedBox(
                    height: 1000,
                    child: Text('Content'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the CupertinoSliverRefreshControl from the CustomScrollView
        // slivers
        final customScrollView = tester.widget<CustomScrollView>(
          find.byType(CustomScrollView),
        );
        final refreshControl =
            customScrollView.slivers.first as CupertinoSliverRefreshControl;

        // Simulate pull-to-refresh by calling onRefresh directly
        // The wrapped callback should enforce minimum duration
        final startTime = DateTime.now();
        await refreshControl.onRefresh!();
        final elapsed = DateTime.now().difference(startTime);

        expect(refreshCalled, isTrue);
        // Verify that minimum duration was enforced (allowing some margin
        // for test execution)
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
      },
    );
  });
}
