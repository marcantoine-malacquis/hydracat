import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/theme/app_theme.dart';
import 'package:hydracat/features/home/widgets/home_hero_header.dart';

void main() {
  testWidgets('HomeHeroHeader renders title and subtitle', (
    WidgetTester tester,
  ) async {
    const title = 'Welcome Back';
    const subtitle = "Let's keep Cerise hydrated this week";

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: HomeHeroHeader(
            subtitle: subtitle,
          ),
        ),
      ),
    );

    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
  });

  testWidgets('HomeHeroHeader appears above dashboard content placeholder', (
    WidgetTester tester,
  ) async {
    const title = 'Welcome Back';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              HomeHeroHeader(),
              Text("Today's Treatments"),
            ],
          ),
        ),
      ),
    );

    final titleFinder = find.text(title);
    final todaysFinder = find.text("Today's Treatments");

    expect(titleFinder, findsOneWidget);
    expect(todaysFinder, findsOneWidget);

    final titleY = tester.getTopLeft(titleFinder).dy;
    final todaysY = tester.getTopLeft(todaysFinder).dy;

    expect(titleY, lessThan(todaysY));
  });
}
