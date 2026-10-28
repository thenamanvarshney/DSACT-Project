import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dsact_app/core/providers/automaton_providers.dart';
import 'package:dsact_app/features/home/presentation/home_page.dart';
import 'package:dsact_app/services/automata_api_service.dart';

void main() {
  testWidgets('App builds and shows DSACT title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automataApiProvider.overrideWithValue(AutomataApiService(useMock: true)),
          backendStatusProvider.overrideWith((ref) => Future.value(false)),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Automata Canvas'), findsOneWidget);
  });
}
