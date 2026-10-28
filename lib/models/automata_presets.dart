import 'automaton_model.dart';
export 'automaton_model.dart';

/// Pre-built finite automata presets for learning and testing.
class AutomataPreset {
  final String id;
  final String name;
  final String description;
  final AutomatonType type;
  final List<String> testStrings;
  final Automaton automaton;

  const AutomataPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.testStrings,
    required this.automaton,
  });

  static List<AutomataPreset> get allPresets => [
        _evenZerosPreset,
        _endsWith01Preset,
        _redundantDfaPreset,
        _divisibleBy3Preset,
        _nfaBranchingPreset,
        _epsilonNfaPreset,
      ];

  // ── 1. Even Number of 0s (DFA) ──────────────────────────────────
  static final AutomataPreset _evenZerosPreset = AutomataPreset(
    id: 'even_zeros',
    name: 'Even Number of 0s',
    description: 'Accepts any binary string containing an even count of "0"s (including zero zeros).',
    type: AutomatonType.dfa,
    testStrings: ['1', '00', '1001', '0101', '0', '000'],
    automaton: Automaton(
      id: 'preset_even_zeros',
      name: 'Even 0s DFA',
      type: AutomatonType.dfa,
      states: [
        const AutomatonState(
          id: 's0',
          label: 'q0',
          x: 250,
          y: 280,
          isInitial: true,
          isFinal: true,
        ),
        const AutomatonState(
          id: 's1',
          label: 'q1',
          x: 450,
          y: 280,
          isInitial: false,
          isFinal: false,
        ),
      ],
      transitions: [
        AutomatonTransition(id: 't0_0', fromStateId: 's0', toStateId: 's1', symbol: '0', curvature: -0.25),
        AutomatonTransition(id: 't1_0', fromStateId: 's1', toStateId: 's0', symbol: '0', curvature: -0.25),
        AutomatonTransition(id: 't0_1', fromStateId: 's0', toStateId: 's0', symbol: '1'),
        AutomatonTransition(id: 't1_1', fromStateId: 's1', toStateId: 's1', symbol: '1'),
      ],
      alphabet: ['0', '1'],
    ),
  );

  // ── 2. Ends with '01' (DFA) ──────────────────────────────────────
  static final AutomataPreset _endsWith01Preset = AutomataPreset(
    id: 'ends_with_01',
    name: "Ends with '01'",
    description: 'Accepts all binary strings that terminate with the substring "01".',
    type: AutomatonType.dfa,
    testStrings: ['01', '101', '0001', '1101', '0', '00', '10'],
    automaton: Automaton(
      id: 'preset_ends_01',
      name: "Ends with '01'",
      type: AutomatonType.dfa,
      states: [
        const AutomatonState(
          id: 's0',
          label: 'q0',
          x: 200,
          y: 280,
          isInitial: true,
          isFinal: false,
        ),
        const AutomatonState(
          id: 's1',
          label: 'q1',
          x: 380,
          y: 280,
          isInitial: false,
          isFinal: false,
        ),
        const AutomatonState(
          id: 's2',
          label: 'q2',
          x: 560,
          y: 280,
          isInitial: false,
          isFinal: true,
        ),
      ],
      transitions: [
        AutomatonTransition(id: 't0_1', fromStateId: 's0', toStateId: 's0', symbol: '1'),
        AutomatonTransition(id: 't0_0', fromStateId: 's0', toStateId: 's1', symbol: '0'),
        AutomatonTransition(id: 't1_0', fromStateId: 's1', toStateId: 's1', symbol: '0'),
        AutomatonTransition(id: 't1_1', fromStateId: 's1', toStateId: 's2', symbol: '1'),
        AutomatonTransition(id: 't2_0', fromStateId: 's2', toStateId: 's1', symbol: '0', curvature: 0.35),
        AutomatonTransition(id: 't2_1', fromStateId: 's2', toStateId: 's0', symbol: '1', curvature: 0.5),
      ],
      alphabet: ['0', '1'],
    ),
  );

  // ── 3. Redundant States DFA (Ideal for Minimization!) ──────────────
  static final AutomataPreset _redundantDfaPreset = AutomataPreset(
    id: 'redundant_dfa',
    name: 'Redundant DFA (For Minimization)',
    description: 'A 5-state DFA accepting strings containing "a". Contains equivalent & redundant states to demonstrate Moore minimization.',
    type: AutomatonType.dfa,
    testStrings: ['a', 'ba', 'aab', 'b', 'bb'],
    automaton: Automaton(
      id: 'preset_redundant',
      name: 'Redundant DFA',
      type: AutomatonType.dfa,
      states: [
        const AutomatonState(id: 'r0', label: 'q0', x: 180, y: 220, isInitial: true, isFinal: false),
        const AutomatonState(id: 'r1', label: 'q1', x: 340, y: 150, isInitial: false, isFinal: false),
        const AutomatonState(id: 'r2', label: 'q2', x: 340, y: 310, isInitial: false, isFinal: false),
        const AutomatonState(id: 'r3', label: 'q3', x: 520, y: 150, isInitial: false, isFinal: true),
        const AutomatonState(id: 'r4', label: 'q4', x: 520, y: 310, isInitial: false, isFinal: true),
      ],
      transitions: [
        AutomatonTransition(id: 'rt0_a', fromStateId: 'r0', toStateId: 'r1', symbol: 'a'),
        AutomatonTransition(id: 'rt0_b', fromStateId: 'r0', toStateId: 'r2', symbol: 'b'),
        AutomatonTransition(id: 'rt1_a', fromStateId: 'r1', toStateId: 'r3', symbol: 'a'),
        AutomatonTransition(id: 'rt1_b', fromStateId: 'r1', toStateId: 'r4', symbol: 'b'),
        AutomatonTransition(id: 'rt2_a', fromStateId: 'r2', toStateId: 'r3', symbol: 'a'),
        AutomatonTransition(id: 'rt2_b', fromStateId: 'r2', toStateId: 'r4', symbol: 'b'),
        AutomatonTransition(id: 'rt3_a', fromStateId: 'r3', toStateId: 'r3', symbol: 'a'),
        AutomatonTransition(id: 'rt3_b', fromStateId: 'r3', toStateId: 'r4', symbol: 'b'),
        AutomatonTransition(id: 'rt4_a', fromStateId: 'r4', toStateId: 'r3', symbol: 'a'),
        AutomatonTransition(id: 'rt4_b', fromStateId: 'r4', toStateId: 'r4', symbol: 'b'),
      ],
      alphabet: ['a', 'b'],
    ),
  );

  // ── 4. Divisible by 3 (Binary Modulo 3) ────────────────────────────
  static final AutomataPreset _divisibleBy3Preset = AutomataPreset(
    id: 'divisible_by_3',
    name: 'Binary Divisible by 3',
    description: 'Accepts binary representations of integers divisible by 3 (e.g. 0, 3=11, 6=110, 9=1001).',
    type: AutomatonType.dfa,
    testStrings: ['0', '11', '110', '1001', '1100', '1', '10', '100'],
    automaton: Automaton(
      id: 'preset_div3',
      name: 'Mod 3 DFA',
      type: AutomatonType.dfa,
      states: [
        const AutomatonState(id: 'm0', label: 'rem0', x: 220, y: 260, isInitial: true, isFinal: true),
        const AutomatonState(id: 'm1', label: 'rem1', x: 420, y: 160, isInitial: false, isFinal: false),
        const AutomatonState(id: 'm2', label: 'rem2', x: 420, y: 360, isInitial: false, isFinal: false),
      ],
      transitions: [
        AutomatonTransition(id: 'mt0_0', fromStateId: 'm0', toStateId: 'm0', symbol: '0'),
        AutomatonTransition(id: 'mt0_1', fromStateId: 'm0', toStateId: 'm1', symbol: '1'),
        AutomatonTransition(id: 'mt1_0', fromStateId: 'm1', toStateId: 'm2', symbol: '0', curvature: -0.2),
        AutomatonTransition(id: 'mt1_1', fromStateId: 'm1', toStateId: 'm0', symbol: '1', curvature: 0.2),
        AutomatonTransition(id: 'mt2_0', fromStateId: 'm2', toStateId: 'm1', symbol: '0', curvature: -0.2),
        AutomatonTransition(id: 'mt2_1', fromStateId: 'm2', toStateId: 'm2', symbol: '1'),
      ],
      alphabet: ['0', '1'],
    ),
  );

  // ── 5. Branching NFA (Non-deterministic) ──────────────────────────
  static final AutomataPreset _nfaBranchingPreset = AutomataPreset(
    id: 'nfa_branching',
    name: 'Ends with 01 or 10 (NFA)',
    description: 'Demonstrates non-deterministic state branching guessing whether to match "01" or "10".',
    type: AutomatonType.nfa,
    testStrings: ['01', '10', '001', '110', '010', '101'],
    automaton: Automaton(
      id: 'preset_nfa',
      name: 'Branching NFA',
      type: AutomatonType.nfa,
      states: [
        const AutomatonState(id: 'n0', label: 'q0', x: 180, y: 260, isInitial: true, isFinal: false),
        const AutomatonState(id: 'n1', label: 'q1', x: 360, y: 160, isInitial: false, isFinal: false),
        const AutomatonState(id: 'n2', label: 'q2', x: 540, y: 160, isInitial: false, isFinal: true),
        const AutomatonState(id: 'n3', label: 'q3', x: 360, y: 360, isInitial: false, isFinal: false),
        const AutomatonState(id: 'n4', label: 'q4', x: 540, y: 360, isInitial: false, isFinal: true),
      ],
      transitions: [
        AutomatonTransition(id: 'nt0_0_loop', fromStateId: 'n0', toStateId: 'n0', symbol: '0'),
        AutomatonTransition(id: 'nt0_1_loop', fromStateId: 'n0', toStateId: 'n0', symbol: '1'),
        AutomatonTransition(id: 'nt0_1_branch', fromStateId: 'n0', toStateId: 'n1', symbol: '0'),
        AutomatonTransition(id: 'nt1_2', fromStateId: 'n1', toStateId: 'n2', symbol: '1'),
        AutomatonTransition(id: 'nt0_3_branch', fromStateId: 'n0', toStateId: 'n3', symbol: '1'),
        AutomatonTransition(id: 'nt3_4', fromStateId: 'n3', toStateId: 'n4', symbol: '0'),
      ],
      alphabet: ['0', '1'],
    ),
  );

  // ── 6. ε-NFA (Epsilon Transitions) ────────────────────────────────
  static final AutomataPreset _epsilonNfaPreset = AutomataPreset(
    id: 'epsilon_nfa',
    name: 'Union (a* | b*) (ε-NFA)',
    description: 'Uses epsilon (ε) transitions from initial state to simulate language union a* + b*.',
    type: AutomatonType.enfa,
    testStrings: ['a', 'aaa', 'b', 'bbb', '', 'ab', 'ba'],
    automaton: Automaton(
      id: 'preset_enfa',
      name: 'Union ε-NFA',
      type: AutomatonType.enfa,
      states: [
        const AutomatonState(id: 'e0', label: 'start', x: 180, y: 260, isInitial: true, isFinal: false),
        const AutomatonState(id: 'e1', label: 'only_a', x: 400, y: 160, isInitial: false, isFinal: true),
        const AutomatonState(id: 'e2', label: 'only_b', x: 400, y: 360, isInitial: false, isFinal: true),
      ],
      transitions: [
        AutomatonTransition(id: 'et0_1', fromStateId: 'e0', toStateId: 'e1', symbol: 'ε'),
        AutomatonTransition(id: 'et0_2', fromStateId: 'e0', toStateId: 'e2', symbol: 'ε'),
        AutomatonTransition(id: 'et1_a', fromStateId: 'e1', toStateId: 'e1', symbol: 'a'),
        AutomatonTransition(id: 'et2_b', fromStateId: 'e2', toStateId: 'e2', symbol: 'b'),
      ],
      alphabet: ['a', 'b', 'ε'],
    ),
  );
}
