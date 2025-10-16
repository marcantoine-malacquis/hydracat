import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';
import 'package:hydracat/shared/widgets/fluid/fluid_daily_summary_card.dart';

void main() {
  testWidgets('shows goal reached state', (tester) async {
    const view = FluidDailySummaryView(
      givenMl: 1000,
      goalMl: 1000,
      isToday: true,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FluidDailySummaryCard(summary: view)),
      ),
    );

    expect(find.textContaining('Goal reached'), findsOneWidget);
    expect(find.textContaining('1,000'), findsNothing); // formatting uses ml/L
  });

  testWidgets('shows remaining for today', (tester) async {
    const view = FluidDailySummaryView(
      givenMl: 750,
      goalMl: 1000,
      isToday: true,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FluidDailySummaryCard(summary: view)),
      ),
    );

    expect(find.textContaining('250'), findsWidgets);
  });

  testWidgets('shows missed for past day', (tester) async {
    const view = FluidDailySummaryView(
      givenMl: 500,
      goalMl: 1000,
      isToday: false,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FluidDailySummaryCard(summary: view)),
      ),
    );

    expect(find.textContaining('Missed'), findsOneWidget);
  });
}
