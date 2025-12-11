import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

void main() {
  group('HydraList', () {
    testWidgets('renders Material ListTile with dividers by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(
            body: HydraList(
              items: [
                HydraListItem(title: Text('First')),
                HydraListItem(title: Text('Second')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(HydraList), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders Cupertino list section and tiles on iOS', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            body: HydraList(
              header: Text('Header'),
              footer: Text('Footer'),
              items: [
                HydraListItem(title: Text('First')),
                HydraListItem(title: Text('Second')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoListSection), findsOneWidget);
      expect(find.byType(CupertinoListTile), findsNWidgets(2));
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('fires onTap for tiles on both platforms', (tester) async {
      var tapped = 0;

      Future<void> pumpForPlatform(TargetPlatform platform) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            home: Scaffold(
              body: HydraList(
                showDividers: false,
                items: [
                  HydraListItem(
                    title: Text('Tap me $platform'),
                    onTap: () => tapped++,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await pumpForPlatform(TargetPlatform.android);
      await tester.tap(find.text('Tap me TargetPlatform.android'));
      await tester.pumpAndSettle();
      expect(tapped, 1);

      await pumpForPlatform(TargetPlatform.iOS);
      await tester.tap(find.text('Tap me TargetPlatform.iOS'));
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });
  });
}
