import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/navigation/hydra_app_bar.dart';

void main() {
  group('HydraAppBar', () {
    testWidgets('shows Material AppBar on Android', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test Title'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify Material AppBar is shown
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CupertinoNavigationBar), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows CupertinoNavigationBar on iOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test Title'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoNavigationBar is shown
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows CupertinoNavigationBar on macOS', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test Title'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify CupertinoNavigationBar is shown
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('maps title to middle on Cupertino', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('My Title'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.middle, isA<Text>());
      final middle = navBar.middle;
      if (middle != null && middle is Text) {
        expect(middle.data, 'My Title');
      }
    });

    testWidgets('maps actions to trailing on Cupertino', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: HydraAppBar(
            title: const Text('Test'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.trailing, isNotNull);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('wraps multiple actions in Row on Cupertino', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: HydraAppBar(
            title: const Text('Test'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.trailing, isA<Row>());
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('maps leading widget correctly', (tester) async {
      final leadingButton = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {},
      );

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: HydraAppBar(
            title: const Text('Test'),
            leading: leadingButton,
          ),
          body: const SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.leading, equals(leadingButton));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('applies backgroundColor on Material', (tester) async {
      const testColor = Colors.red;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            backgroundColor: testColor,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(testColor));
    });

    testWidgets('applies backgroundColor on Cupertino', (tester) async {
      const testColor = Colors.blue;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            backgroundColor: testColor,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.backgroundColor, equals(testColor));
    });

    testWidgets(
      'removes border on Cupertino when backgroundColor is transparent',
      (tester) async {
        final testWidget = MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(
            appBar: HydraAppBar(
              title: Text('Test'),
              backgroundColor: Colors.transparent,
            ),
            body: SizedBox(),
          ),
        );

        await tester.pumpWidget(testWidget);

        final navBar = tester.widget<CupertinoNavigationBar>(
          find.byType(CupertinoNavigationBar),
        );
        expect(navBar.border, isNull);
      },
    );

    testWidgets('applies foregroundColor on Material', (tester) async {
      const testColor = Colors.white;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            foregroundColor: testColor,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.foregroundColor, equals(testColor));
    });

    testWidgets('applies centerTitle on Material', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            centerTitle: true,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('handles automaticallyImplyLeading on Material', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            automaticallyImplyLeading: false,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, isFalse);
    });

    testWidgets('implements PreferredSizeWidget correctly', (tester) async {
      const customHeight = 100.0;

      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            toolbarHeight: customHeight,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, equals(customHeight));

      // Verify preferredSize
      final hydraAppBar = tester.widget<HydraAppBar>(
        find.byType(HydraAppBar),
      );
      expect(hydraAppBar.preferredSize.height, equals(customHeight));
    });

    testWidgets('handles null title gracefully', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.middle, isNull);
    });

    testWidgets('handles null actions gracefully', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.trailing, isNull);
    });

    testWidgets('handles empty actions list gracefully', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            actions: [],
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.trailing, isNull);
    });
  });

  group('HydraAppBar Style Variants', () {
    testWidgets('applies default style background', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final expectedColor = Color.alphaBlend(
        AppColors.primary.withValues(alpha: 0.06),
        AppColors.background,
      );
      expect(appBar.backgroundColor, equals(expectedColor));
    });

    testWidgets('applies accent style background', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            style: HydraAppBarStyle.accent,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final expectedColor = Color.alphaBlend(
        AppColors.primary.withValues(alpha: 0.12),
        AppColors.background,
      );
      expect(appBar.backgroundColor, equals(expectedColor));
    });

    testWidgets('applies transparent style background', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            style: HydraAppBarStyle.transparent,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(Colors.transparent));
    });

    testWidgets('applies toolbarHeight from theme', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, equals(AppSpacing.appBarHeight));
    });

    testWidgets('applies horizontal padding to title', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test Title'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Title should be wrapped in Padding
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        equals(AppSpacing.appBarContentPadding),
      );
    });

    testWidgets('removes border on Cupertino for transparent style', (
      tester,
    ) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            style: HydraAppBarStyle.transparent,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.border, isNull);
    });

    testWidgets('shows border on Cupertino for default style', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.border, isNotNull);
    });

    testWidgets('shows border on Cupertino for accent style', (tester) async {
      final testWidget = MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(
          appBar: HydraAppBar(
            title: Text('Test'),
            style: HydraAppBarStyle.accent,
          ),
          body: SizedBox(),
        ),
      );

      await tester.pumpWidget(testWidget);

      final navBar = tester.widget<CupertinoNavigationBar>(
        find.byType(CupertinoNavigationBar),
      );
      expect(navBar.border, isNotNull);
    });
  });
}
