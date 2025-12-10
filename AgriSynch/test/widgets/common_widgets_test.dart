import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Tests - Basic Components', () {
    testWidgets('ElevatedButton displays text and responds to tap', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Click Me'),
            ),
          ),
        ),
      );

      // Verify button is displayed
      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify button was pressed
      expect(buttonPressed, isTrue);
    });

    testWidgets('TextField accepts input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Enter text'),
            ),
          ),
        ),
      );

      // Verify TextField is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(controller.text, equals('Hello World'));
    });

    testWidgets('Form validation works correctly', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Test empty input
      await tester.enterText(find.byType(TextFormField), '');
      formKey.currentState?.validate();
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid');
      formKey.currentState?.validate();
      await tester.pump();
      expect(find.text('Invalid email format'), findsOneWidget);

      // Test valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(formKey.currentState?.validate(), isTrue);
    });

    testWidgets('ListView displays multiple items', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                );
              },
            ),
          ),
        ),
      );

      // Verify all items are found
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }

      // Verify ListView is displayed
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('Card widget displays content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Card Title'),
                    SizedBox(height: 8),
                    Text('Card Description'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Description'), findsOneWidget);
    });

    testWidgets('IconButton displays icon and handles tap', (WidgetTester tester) async {
      bool iconTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                iconTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(iconTapped, isTrue);
    });

    testWidgets('SnackBar appears and dismisses', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test SnackBar')),
                    );
                  },
                  child: const Text('Show SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Mid animation

      expect(find.text('Test SnackBar'), findsOneWidget);

      // Wait for SnackBar to dismiss
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Test SnackBar'), findsNothing);
    });

    testWidgets('Checkbox toggles state', (WidgetTester tester) async {
      bool isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(isChecked, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(isChecked, isTrue);
    });

    testWidgets('Circular Progress Indicator displays', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppBar displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test AppBar'),
            ),
          ),
        ),
      );

      expect(find.text('Test AppBar'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('Widget Tests - Navigation', () {
    testWidgets('Navigation to new page works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondPage(),
                      ),
                    );
                  },
                  child: const Text('Go to Second Page'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Go to Second Page'), findsOneWidget);
      expect(find.byType(SecondPage), findsNothing);

      await tester.tap(find.text('Go to Second Page'));
      await tester.pumpAndSettle();

      expect(find.byType(SecondPage), findsOneWidget);
      expect(find.text('Go to Second Page'), findsNothing);
    });

    testWidgets('Back button returns to previous page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondPage(),
                      ),
                    );
                  },
                  child: const Text('Go to Second Page'),
                );
              },
            ),
          ),
        ),
      );

      // Navigate to second page
      await tester.tap(find.text('Go to Second Page'));
      await tester.pumpAndSettle();
      expect(find.byType(SecondPage), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Go to Second Page'), findsOneWidget);
      expect(find.byType(SecondPage), findsNothing);
    });
  });
}

// Helper widget for navigation tests
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: const Center(
        child: Text('Second Page'),
      ),
    );
  }
}
