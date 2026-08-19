import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediahub/app/app.dart';

void main() {
  testWidgets('MediaHubApp foundation navigation shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediaHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial home screen title and welcome text display
    expect(find.text('Welcome to MediaHub'), findsOneWidget);
    expect(find.text('Local-First Multimedia Hub'), findsOneWidget);
  });
}
