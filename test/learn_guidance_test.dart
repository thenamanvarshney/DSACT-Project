import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dsact_app/core/providers/automaton_providers.dart';
import 'package:dsact_app/features/home/presentation/home_page.dart';
import 'package:dsact_app/features/learn/domain/construction_checker.dart';
import 'package:dsact_app/features/learn/domain/lesson_catalog.dart';
import 'package:dsact_app/features/learn/domain/lesson_models.dart';
import 'package:dsact_app/models/automata_presets.dart';
import 'package:dsact_app/services/automata_api_service.dart';

void main() {
  group('Lesson catalog', () {
    test('ships beginner through practice modules', () {
      expect(LessonCatalog.all.length, greaterThanOrEqualTo(5));
      expect(LessonCatalog.byId('concepts_from_zero'), isNotNull);
      expect(LessonCatalog.byId('build_even_zeros'), isNotNull);
      expect(LessonCatalog.byId('guided_simulator'), isNotNull);
      expect(LessonCatalog.byId('nfa_epsilon_module'), isNotNull);
      expect(LessonCatalog.byId('practice_ends_with_01'), isNotNull);
    });

    test('questions hide answers in the prompt text', () {
      for (final lesson in LessonCatalog.all) {
        for (final step in lesson.steps) {
          final q = step.question;
          if (q == null) continue;
          expect(q.choices.length, greaterThanOrEqualTo(2));
          expect(q.correctIndex, inInclusiveRange(0, q.choices.length - 1));
        }
      }
    });
  });

  group('Construction checker uses existing engine', () {
    const checker = ConstructionChecker();
    final api = AutomataApiService(useMock: true);

    test('rejects an empty canvas for even-zeros language', () async {
      final goal = LessonCatalog.dfaEvenZerosBuild.steps
          .firstWhere((s) => s.id == 'b6')
          .canvasGoal!;
      final result = await checker.check(
        automaton: Automaton.empty(),
        goal: goal,
        api: api,
      );
      expect(result.passed, isFalse);
    });

    test('accepts the existing Even 0s preset', () async {
      final goal = LessonCatalog.dfaEvenZerosBuild.steps
          .firstWhere((s) => s.id == 'b6')
          .canvasGoal!;
      final preset =
          AutomataPreset.allPresets.firstWhere((p) => p.id == 'even_zeros');
      final result = await checker.check(
        automaton: preset.automaton,
        goal: goal,
        api: api,
      );
      expect(result.passed, isTrue, reason: result.message);
    });

    test('accepts the existing Ends with 01 preset for practice', () async {
      final goal = LessonCatalog.independentPractice.steps
          .firstWhere((s) => s.id == 'p2')
          .canvasGoal!;
      final preset =
          AutomataPreset.allPresets.firstWhere((p) => p.id == 'ends_with_01');
      final result = await checker.check(
        automaton: preset.automaton,
        goal: goal,
        api: api,
      );
      expect(result.passed, isTrue, reason: result.message);
    });
  });

  testWidgets('existing home still shows Automata Canvas and Learn entry',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automataApiProvider
              .overrideWithValue(AutomataApiService(useMock: true)),
          backendStatusProvider.overrideWith((ref) => Future.value(false)),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    expect(find.text('Automata Canvas'), findsOneWidget);
    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Simulate'), findsWidgets);
    expect(find.text('Matrix'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byTooltip('Learn Automata'), findsOneWidget);
  });
}
