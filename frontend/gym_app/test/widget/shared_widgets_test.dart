import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/custom_button.dart';
import 'package:gym_app/core/widgets/custom_text_field.dart';
import 'package:gym_app/core/widgets/stat_card.dart';
import 'package:gym_app/core/widgets/activity_card.dart';

void main() {
  group('CustomButton Widget', () {
    testWidgets('renders text and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Click Me',
            onPressed: () => tapped = true,
          ),
        ),
      ));

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      expect(tapped, true);
    });

    testWidgets('renders as outlined button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Outlined',
            isOutlined: true,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  group('CustomTextField Widget', () {
    testWidgets('renders label and hint, and accepts input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Username',
            hintText: 'Enter username',
            controller: controller,
          ),
        ),
      ));

      expect(find.text('Username'), findsWidgets);
      expect(find.text('Enter username'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Antigravity');
      expect(controller.text, 'Antigravity');
    });
  });

  group('StatCard Widget', () {
    testWidgets('renders title, value, and icon correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Active Users',
            value: '42',
            icon: Icons.people,
          ),
        ),
      ));

      expect(find.text('Active Users'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });

  group('ActivityCard Widget', () {
    testWidgets('renders title, description, and reacts to action tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 450,
              child: ActivityCard(
                title: 'Warm Up',
                description: 'Stretching exercises',
                imageUrl: 'https://example.com/warmup.png',
                actionText: 'Start Set',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Warm Up'), findsOneWidget);
      expect(find.text('Stretching exercises'), findsOneWidget);
      expect(find.text('Start Set'), findsOneWidget);

      await tester.tap(find.text('Start Set'));
      expect(tapped, true);
    });
  });
}
