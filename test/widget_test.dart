import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbridge/app.dart';
import 'package:skillbridge/core/validators.dart';
import 'package:skillbridge/data/local/local_store.dart';
import 'package:skillbridge/state/app_state.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [storeProvider.overrideWithValue(LocalStore(prefs))],
    child: const SkillBridgeApp(),
  ));
}

void main() {
  group('validators', () {
    test('rejects invalid emails', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('worker@skillbridge.app'), isNull);
    });

    test('requires strong enough passwords', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('password123'), isNull);
    });

    test('checks password confirmation', () {
      expect(Validators.confirmPassword('abc12345', 'xyz98765'), isNotNull);
      expect(Validators.confirmPassword('password123', 'password123'), isNull);
    });
  });

  testWidgets('splash leads to the onboarding pages', (tester) async {
    await _pumpApp(tester);
    expect(find.text('SkillBridge'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Show It'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Prove It'), findsOneWidget);
  });

  testWidgets('a demo client reaches the client dashboard', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Client'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as demo'));
    await tester.pumpAndSettle();
    expect(find.text('Post Job'), findsWidgets);
    expect(find.text('Categories'), findsOneWidget);
  });
}
