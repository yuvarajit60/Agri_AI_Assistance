import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agri_ai_assistant/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgriAiApp()));
    await tester.pump();

    expect(find.text('உழவனின் நண்பன்'), findsOneWidget);

    // Let MockAuthRepository's simulated network delay resolve before the
    // test tears down, otherwise flutter_test flags the pending Timer.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
