import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_navigation_bar.dart';

Widget _wrapWithScaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: child,
    ),
  );
}

List<HydraNavigationItem> _items() => const [
  HydraNavigationItem(icon: AppIcons.home, label: 'Home'),
  HydraNavigationItem(icon: AppIcons.progress, label: 'Progress'),
  HydraNavigationItem(icon: AppIcons.learn, label: 'Learn'),
  HydraNavigationItem(icon: AppIcons.profile, label: 'Profile'),
];

void main() {
  testWidgets('renders only one top indicator for the selected index', (
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

    // Expect exactly one indicator with index 1
    expect(find.byKey(const Key('navTopIndicator-1')), findsOneWidget);
    expect(find.byKey(const Key('navTopIndicator-0')), findsNothing);
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

    // No indicator keys should be present
    expect(find.byKey(const Key('navTopIndicator-0')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-1')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-2')), findsNothing);
    expect(find.byKey(const Key('navTopIndicator-3')), findsNothing);
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
      find.text('Learn'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Learn')),
      matchesSemantics(
        label: 'Learn',
        isButton: true,
        isSelected: true,
      ),
    );
  });
}
