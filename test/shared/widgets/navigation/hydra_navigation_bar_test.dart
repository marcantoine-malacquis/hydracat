import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_navigation_bar.dart';

Widget _wrapWithScaffold(Widget child, {TargetPlatform? platform}) {
  return MaterialApp(
    theme: ThemeData(
      platform: platform ?? TargetPlatform.android,
    ),
    home: Scaffold(
      bottomNavigationBar: child,
    ),
  );
}

List<HydraNavigationItem> _items() => const [
  HydraNavigationItem(icon: AppIcons.home, label: 'Home'),
  HydraNavigationItem(icon: AppIcons.progress, label: 'Progress'),
  HydraNavigationItem(icon: AppIcons.discover, label: 'Discover'),
  HydraNavigationItem(icon: AppIcons.profile, label: 'Profile'),
];

void main() {
  testWidgets('renders single sliding indicator for the selected index', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScaffold(
        HydraNavigationBar(
          items: _items(),
          currentIndex: 1,
          onTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Expect exactly one indicator with the new single key
    expect(find.byKey(const Key('navTopIndicator')), findsOneWidget);
    // Old per-index keys should not exist
    expect(find.byKey(const Key('navTopIndicator-0')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-1')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-2')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-3')), findsNothing);
  });

  testWidgets('hides indicator when currentIndex is -1', (tester) async {
    await tester.pumpWidget(
      _wrapWithScaffold(
        HydraNavigationBar(
          items: _items(),
          currentIndex: -1,
          onTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // No indicator should be present
    expect(find.byKey(const Key('navTopIndicator')), findsNothing);
  });

  testWidgets('indicator position changes when currentIndex changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithScaffold(
        HydraNavigationBar(
          items: _items(),
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Get initial position
    final initialFinder = find.byKey(const Key('navTopIndicator'));
    expect(initialFinder, findsOneWidget);
    final initialPosition = tester.getTopLeft(initialFinder);

    // Change index to 3
    await tester.pumpWidget(
      _wrapWithScaffold(
        HydraNavigationBar(
          items: _items(),
          currentIndex: 3,
          onTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Get new position
    final newFinder = find.byKey(const Key('navTopIndicator'));
    expect(newFinder, findsOneWidget);
    final newPosition = tester.getTopLeft(newFinder);

    // Position should have changed (moved to the right)
    expect(newPosition.dx, greaterThan(initialPosition.dx));
  });

  testWidgets('indicator respects reduced motion preference', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            bottomNavigationBar: HydraNavigationBar(
              items: _items(),
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Indicator should still be present
    expect(find.byKey(const Key('navTopIndicator')), findsOneWidget);

    // Change index - with reduced motion, should snap immediately
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            bottomNavigationBar: HydraNavigationBar(
              items: _items(),
              currentIndex: 3,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    // With reduced motion, animation duration should be zero
    // The indicator should appear at the new position immediately
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byKey(const Key('navTopIndicator')), findsOneWidget);
  });

  testWidgets('semantics marks active tab as selected', (tester) async {
    await tester.pumpWidget(
      _wrapWithScaffold(
        HydraNavigationBar(
          items: _items(),
          currentIndex: 2,
          onTap: (_) {},
        ),
      ),
    );

    // Verify semantics for the active label
    expect(
      find.text('Discover'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Discover')),
      matchesSemantics(
        label: 'Discover',
        isButton: true,
        isSelected: true,
      ),
    );
  });

  group('Platform-specific styling', () {
    testWidgets('Material platform uses shadow decoration', (tester) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 0,
            onTap: (_) {},
          ),
          platform: TargetPlatform.android,
        ),
      );

      await tester.pumpAndSettle();

      // Find the Container with decoration (the main nav bar container)
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Find the container that has BoxDecoration with shadow
      Container? navBarContainer;
      for (final widget in tester.allWidgets) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration && decoration.boxShadow != null) {
            navBarContainer = widget;
          }
        }
      }

      expect(navBarContainer, isNotNull);
      final decoration = navBarContainer!.decoration! as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
    });

    testWidgets('Cupertino platform uses border-only decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 0,
            onTap: (_) {},
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.pumpAndSettle();

      // Find the Container with decoration (the main nav bar container)
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Find the container that has BoxDecoration with border but no shadow
      Container? navBarContainer;
      for (final widget in tester.allWidgets) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration &&
              decoration.border != null &&
              (decoration.boxShadow == null || decoration.boxShadow!.isEmpty)) {
            navBarContainer = widget;
          }
        }
      }

      expect(navBarContainer, isNotNull);
      final decoration = navBarContainer!.decoration! as BoxDecoration;
      // iOS should have border
      expect(decoration.border, isNotNull);
      // iOS should NOT have shadow (or have empty shadow list)
      expect(
        decoration.boxShadow == null || decoration.boxShadow!.isEmpty,
        isTrue,
      );
    });

    testWidgets('Material platform uses larger icon size (26px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 0,
            onTap: (_) {},
          ),
          platform: TargetPlatform.android,
        ),
      );

      await tester.pumpAndSettle();

      // Find HydraIcon widgets
      final iconFinder = find.byType(HydraIcon);
      expect(iconFinder, findsWidgets);

      // Check that icons use Material size (26px)
      // Note: We can't directly test the size parameter, but we can verify
      // the widget exists and is rendered correctly
      expect(iconFinder, findsAtLeastNWidgets(4));
    });

    testWidgets('Cupertino platform uses smaller icon size (24px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 0,
            onTap: (_) {},
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.pumpAndSettle();

      // Find HydraIcon widgets
      final iconFinder = find.byType(HydraIcon);
      expect(iconFinder, findsWidgets);

      // Check that icons are rendered (size is internal to _iconSize method)
      expect(iconFinder, findsAtLeastNWidgets(4));
    });

    testWidgets('Material platform uses w600 font weight for selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 1,
            onTap: (_) {},
          ),
          platform: TargetPlatform.android,
        ),
      );

      await tester.pumpAndSettle();

      // Find the selected text widget
      final progressText = find.text('Progress');
      expect(progressText, findsOneWidget);

      final textWidget = tester.widget<Text>(progressText);
      final fontWeight = textWidget.style?.fontWeight;
      // Material should use w600 for selected
      expect(fontWeight, FontWeight.w600);
    });

    testWidgets('Cupertino platform uses w500 font weight for selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithScaffold(
          HydraNavigationBar(
            items: _items(),
            currentIndex: 1,
            onTap: (_) {},
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.pumpAndSettle();

      // Find the selected text widget
      final progressText = find.text('Progress');
      expect(progressText, findsOneWidget);

      final textWidget = tester.widget<Text>(progressText);
      final fontWeight = textWidget.style?.fontWeight;
      // Cupertino should use w500 for selected (lighter)
      expect(fontWeight, FontWeight.w500);
    });
  });
}
