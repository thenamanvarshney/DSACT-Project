import 'package:flutter_test/flutter_test.dart';
import 'package:dsact_app/models/automata_presets.dart';
import 'package:dsact_app/services/automata_api_service.dart';

void main() {
  group('Automaton Models & Serialization', () {
    test('Converts correctly to backend /api/validate JSON', () {
      final s0 = const AutomatonState(id: '0', label: 'q0', x: 0, y: 0, isInitial: true, isFinal: false);
      final s1 = const AutomatonState(id: '1', label: 'q1', x: 0, y: 0, isInitial: false, isFinal: true);
      final t = const AutomatonTransition(id: 't1', fromStateId: '0', toStateId: '1', symbol: 'a');

      final automaton = Automaton(
        id: 'test_a',
        name: 'Test',
        type: AutomatonType.dfa,
        states: [s0, s1],
        transitions: [t],
        alphabet: ['a'],
      );

      final json = automaton.toValidateJson('a');
      expect(json['initialState'], 'q0');
      expect(json['acceptStates'], ['q1']);
      expect(json['inputString'], 'a');
      expect(json['transitions'], [
        {'from': 'q0', 'to': 'q1', 'symbol': 'a'}
      ]);
    });

    test('Converts correctly to backend /api/minimize JSON', () {
      final s0 = const AutomatonState(id: '0', label: 'q0', x: 0, y: 0, isInitial: true, isFinal: false);
      final s1 = const AutomatonState(id: '1', label: 'q1', x: 0, y: 0, isInitial: false, isFinal: true);
      final t = const AutomatonTransition(id: 't1', fromStateId: '0', toStateId: '1', symbol: 'a');

      final automaton = Automaton(
        id: 'test_a',
        name: 'Test',
        type: AutomatonType.dfa,
        states: [s0, s1],
        transitions: [t],
        alphabet: ['a'],
      );

      final json = automaton.toMinimizeJson();
      expect(json['initialState'], 'q0');
      expect(json['acceptStates'], ['q1']);
      expect(json['states'], ['q0', 'q1']);
      expect(json['transitions'], [
        {'from': 'q0', 'to': 'q1', 'symbol': 'a'}
      ]);
    });
  });

  group('Automata Presets & Validation', () {
    final api = AutomataApiService(useMock: true);

    test('All presets are properly structured', () {
      final presets = AutomataPreset.allPresets;
      expect(presets.length, greaterThanOrEqualTo(5));

      for (final p in presets) {
        expect(p.name.isNotEmpty, true);
        expect(p.automaton.initialState, isNotNull);
        expect(p.automaton.states.isNotEmpty, true);
        expect(p.automaton.alphabet.isNotEmpty, true);
      }
    });

    test('Even 0s preset correctly accepts even number of 0s and rejects odd', () async {
      final preset = AutomataPreset.allPresets.firstWhere((p) => p.id == 'even_zeros');
      
      final resEven = await api.validate(preset.automaton, '00');
      expect(resEven.accepted, isTrue);

      final resOdd = await api.validate(preset.automaton, '000');
      expect(resOdd.accepted, isFalse);

      final resMixed = await api.validate(preset.automaton, '10101');
      expect(resMixed.accepted, isTrue);
    });

    test('Ends with 01 preset validates terminal substring', () async {
      final preset = AutomataPreset.allPresets.firstWhere((p) => p.id == 'ends_with_01');

      final resAccept = await api.validate(preset.automaton, '1101');
      expect(resAccept.accepted, isTrue);

      final resReject = await api.validate(preset.automaton, '1100');
      expect(resReject.accepted, isFalse);
    });

    test('Moore DFA minimization optimizes redundant states into minimal quotient', () async {
      final redundantPreset = AutomataPreset.allPresets.firstWhere((p) => p.id == 'redundant_dfa');
      expect(redundantPreset.automaton.states.length, 5);

      final minResult = await api.minimize(redundantPreset.automaton);
      expect(minResult.states.length, lessThan(5));
      expect(minResult.initialState.isNotEmpty, isTrue);
      expect(minResult.acceptStates.isNotEmpty, isTrue);
      expect(minResult.transitions.isNotEmpty, isTrue);
    });

    test('Epsilon NFA properly computes epsilon closures', () async {
      final epsPreset = AutomataPreset.allPresets.firstWhere((p) => p.id == 'epsilon_nfa');

      final resAccept = await api.validate(epsPreset.automaton, 'ab');
      expect(resAccept.accepted, isTrue);
    });
  });
}
