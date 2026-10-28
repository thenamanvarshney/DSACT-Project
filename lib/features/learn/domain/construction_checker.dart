import '../../../models/automaton_model.dart';
import '../../../services/automata_api_service.dart';
import 'lesson_models.dart';

/// Checks a learner's canvas against a [CanvasGoal] using the existing
/// automaton model and on-device validation engine. Does not mutate the graph.
class ConstructionChecker {
  const ConstructionChecker();

  Future<StepCheckResult> check({
    required Automaton automaton,
    required CanvasGoal goal,
    required AutomataApiService api,
  }) async {
    final details = <String>[];

    if (goal.requiredType != null && automaton.type != goal.requiredType) {
      details.add(
        'Switch the type chip to ${_typeLabel(goal.requiredType!)} — '
        'this lesson is about that machine class.',
      );
    }

    if (goal.minStates != null && automaton.states.length < goal.minStates!) {
      details.add(
        'Add at least ${goal.minStates} state(s). Right now the canvas has '
        '${automaton.states.length}. Each distinct “memory” the machine needs '
        'is usually a state.',
      );
    }

    if (goal.exactStates != null &&
        automaton.states.length != goal.exactStates) {
      details.add(
        'This language needs exactly ${goal.exactStates} states. You have '
        '${automaton.states.length}. Extra states are not wrong forever, but '
        'for this exercise keep only the ones the hint describes.',
      );
    }

    if (goal.requireInitial && automaton.initialState == null) {
      details.add(
        'Mark one state as initial (the play icon). Without a start state the '
        'simulator cannot begin reading the input.',
      );
    }

    if (goal.requireAccepting && automaton.finalStates.isEmpty) {
      details.add(
        'Mark at least one accepting state (double circle / Final). That is '
        'how the machine says “the string I just finished is in the language”.',
      );
    }

    final symbols = automaton.transitions.map((t) => t.symbol).toSet();
    for (final required in goal.requiredSymbols) {
      if (!symbols.contains(required)) {
        details.add(
          'Add a transition labeled "$required". Every alphabet symbol the '
          'language cares about must appear on some arrow.',
        );
      }
    }

    if (goal.requireSelfLoop &&
        !automaton.transitions.any((t) => t.isSelfLoop)) {
      details.add(
        'Add a self-loop (an arrow from a state back to itself). Self-loops '
        'mean “this symbol does not change the property we are tracking”.',
      );
    }

    if (goal.requireCrossTransition &&
        !automaton.transitions.any((t) => !t.isSelfLoop)) {
      details.add(
        'Add an arrow between two different states. That is how the machine '
        'records that the property it is tracking has changed.',
      );
    }

    if (goal.languageCases.isNotEmpty) {
      if (automaton.initialState == null) {
        details.add(
          'Language tests need an initial state so the existing simulator '
          'engine can run.',
        );
      } else {
        for (final test in goal.languageCases) {
          final result = await api.validate(automaton, test.input);
          final shown = test.input.isEmpty ? 'ε (empty string)' : '"${test.input}"';
          if (result.accepted != test.shouldAccept) {
            if (test.shouldAccept) {
              details.add(
                'The engine rejected $shown, but it should be accepted. '
                '${test.why}',
              );
            } else {
              details.add(
                'The engine accepted $shown, but it should be rejected. '
                '${test.why}',
              );
            }
          }
        }
      }
    }

    if (details.isEmpty) {
      return StepCheckResult(passed: true, message: goal.successMessage);
    }

    return StepCheckResult(
      passed: false,
      message: details.length == 1
          ? details.first
          : 'A few pieces are still missing. Fix these, then check again.',
      details: details,
    );
  }

  String _typeLabel(AutomatonType type) {
    return switch (type) {
      AutomatonType.dfa => 'DFA',
      AutomatonType.nfa => 'NFA',
      AutomatonType.enfa => 'ε-NFA',
    };
  }
}
