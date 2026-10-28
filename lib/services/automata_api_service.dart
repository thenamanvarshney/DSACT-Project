import '../models/automaton_model.dart';

/// Pure Dart, production-ready on-device engine for finite automata simulation and DFA minimization.
/// Runs 100% offline with 0ms latency on iOS, Android, macOS, Windows, Linux, and Web.
class AutomataApiService {
  final bool useMock;

  const AutomataApiService({String? baseUrl, this.useMock = false});

  /// Check engine readiness (native on-device engine is always operational).
  Future<bool> checkHealth() async => true;

  /// Validates an input string against an automaton (DFA, NFA, or ε-NFA)
  /// using BFS graph traversal with cycle prevention.
  Future<ValidationResult> validate(Automaton automaton, String inputString) async {
    return _validateAutomaton(automaton, inputString);
  }

  /// Minimizes a DFA using Moore's Partition Refinement algorithm.
  Future<MinimizationResult> minimize(Automaton automaton) async {
    return _minimizeDFA(automaton);
  }

  // ─────────────────────────────────────────────────────────────────
  // Core Algorithmic Engine (Pure Dart)
  // ─────────────────────────────────────────────────────────────────

  ValidationResult _validateAutomaton(Automaton automaton, String inputString) {
    final initial = automaton.initialState;
    if (initial == null) {
      return const ValidationResult(
        accepted: false,
        executionPath: [],
        error: 'No initial state defined',
      );
    }

    final sMap = automaton.stateMap;
    final acceptLabels = automaton.finalStates.map((s) => s.label).toSet();

    // Map: fromStateLabel -> List<AutomatonTransition>
    final transMap = <String, List<AutomatonTransition>>{};
    for (final t in automaton.transitions) {
      final fromLabel = sMap[t.fromStateId]?.label ?? '';
      transMap.putIfAbsent(fromLabel, () => []).add(t);
    }

    // BFS Queue stores: (stateLabel, inputIndex, executionPath)
    final queue = <_BfsNode>[_BfsNode(initial.label, 0, [initial.label])];
    final visited = <String>{'${initial.label}:0'};

    List<String> longestPath = [initial.label];
    List<String>? acceptingPath;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      // Check if input is completely consumed AND currently in an accept state
      if (current.index == inputString.length && acceptLabels.contains(current.state)) {
        acceptingPath = current.path;
        break;
      }

      if (current.path.length > longestPath.length) {
        longestPath = current.path;
      }

      // 1. Process epsilon transitions (does not advance input index)
      for (final t in transMap[current.state] ?? const []) {
        if (t.isEpsilon) {
          final toLabel = sMap[t.toStateId]?.label ?? '';
          final key = '$toLabel:${current.index}';
          if (!visited.contains(key)) {
            visited.add(key);
            queue.add(_BfsNode(toLabel, current.index, [...current.path, toLabel]));
          }
        }
      }

      // 2. Process symbol transitions (advances input index by 1)
      if (current.index < inputString.length) {
        final ch = inputString[current.index];
        for (final t in transMap[current.state] ?? const []) {
          final toLabel = sMap[t.toStateId]?.label ?? '';
          if (t.symbol == ch) {
            final nextIdx = current.index + 1;
            final key = '$toLabel:$nextIdx';
            if (!visited.contains(key)) {
              visited.add(key);
              queue.add(_BfsNode(toLabel, nextIdx, [...current.path, toLabel]));
            }
          }
        }
      }
    }

    if (acceptingPath != null) {
      return ValidationResult(accepted: true, executionPath: acceptingPath);
    }

    return ValidationResult(accepted: false, executionPath: longestPath);
  }

  MinimizationResult _minimizeDFA(Automaton automaton) {
    final initial = automaton.initialState;
    if (initial == null) {
      return const MinimizationResult(
        states: [],
        initialState: '',
        acceptStates: [],
        transitions: [],
        error: 'Initial state is required for minimization',
      );
    }

    final sMap = automaton.stateMap;
    final allStateLabels = automaton.states.map((s) => s.label).toSet();
    final acceptLabels = automaton.finalStates.map((s) => s.label).toSet();
    final alphabet = automaton.alphabet.isEmpty
        ? ['0', '1']
        : (List<String>.from(automaton.alphabet)..sort());

    // 1. Reachable state elimination (BFS from initialState)
    final reachable = <String>{initial.label};
    final queue = <String>[initial.label];

    // Build label-based transitions list
    final labelTransitions = <Map<String, String>>[];
    for (final t in automaton.transitions) {
      final fromLabel = sMap[t.fromStateId]?.label;
      final toLabel = sMap[t.toStateId]?.label;
      if (fromLabel != null && toLabel != null) {
        labelTransitions.add({'from': fromLabel, 'to': toLabel, 'symbol': t.symbol});
      }
    }

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      for (final t in labelTransitions) {
        if (t['from'] == curr && !reachable.contains(t['to'])) {
          reachable.add(t['to']!);
          queue.add(t['to']!);
        }
      }
    }

    final reachableStates = allStateLabels.where((s) => reachable.contains(s)).toList()..sort();
    final reachableAccept = reachableStates.where((s) => acceptLabels.contains(s)).toList()..sort();
    final reachableNonAccept = reachableStates.where((s) => !acceptLabels.contains(s)).toList()..sort();

    final reachableTrans = labelTransitions
        .where((t) => reachable.contains(t['from']) && reachable.contains(t['to']))
        .toList();

    // Transition lookup: "from:::symbol" -> target
    final transitionLookup = <String, String>{};
    for (final t in reachableTrans) {
      transitionLookup['${t['from']}:::${t['symbol']}'] = t['to']!;
    }

    String? getTarget(String state, String symbol) =>
        transitionLookup['$state:::$symbol'];

    // 2. Initial Partition P0: [Accept States, Non-Accept States]
    List<List<String>> partition = [];
    if (reachableAccept.isNotEmpty && reachableNonAccept.isNotEmpty) {
      partition = [reachableAccept, reachableNonAccept];
    } else if (reachableAccept.isNotEmpty) {
      partition = [reachableAccept];
    } else {
      partition = [reachableNonAccept];
    }

    // 3. Partition refinement loop (Moore's Algorithm)
    bool changed = true;
    while (changed) {
      changed = false;
      final nextPartition = <List<String>>[];

      for (final group in partition) {
        if (group.length <= 1) {
          nextPartition.add(group);
          continue;
        }

        // Group states by their transition signature
        final subgroups = <String, List<String>>{};

        for (final state in group) {
          final signature = alphabet.map((symbol) {
            final target = getTarget(state, symbol);
            if (target == null) return '-1';
            final targetIdx = partition.indexWhere((grp) => grp.contains(target));
            return targetIdx.toString();
          }).join('|');

          subgroups.putIfAbsent(signature, () => []).add(state);
        }

        if (subgroups.length > 1) {
          changed = true;
        }

        for (final sub in subgroups.values) {
          sub.sort();
          nextPartition.add(sub);
        }
      }

      partition = nextPartition;
    }

    String getGroupName(List<String> group) =>
        group.length == 1 ? group[0] : (List<String>.from(group)..sort()).join('_');

    // 4. Reconstruct minimized DFA
    final newStates = partition.map(getGroupName).toList()..sort();

    final initialGroup = partition.firstWhere(
      (grp) => grp.contains(initial.label),
      orElse: () => [initial.label],
    );
    final newInitialState = getGroupName(initialGroup);

    final newAcceptStates = partition
        .where((grp) => grp.any((s) => reachableAccept.contains(s)))
        .map(getGroupName)
        .toList()
      ..sort();

    final newTransitions = <Map<String, String>>[];
    final addedKeys = <String>{};

    for (final group in partition) {
      final fromName = getGroupName(group);
      final representative = group[0];

      for (final symbol in alphabet) {
        final target = getTarget(representative, symbol);
        if (target != null) {
          final targetGroup = partition.firstWhere(
            (grp) => grp.contains(target),
            orElse: () => [],
          );
          if (targetGroup.isNotEmpty) {
            final toName = getGroupName(targetGroup);
            final key = '$fromName:::$toName:::$symbol';
            if (!addedKeys.contains(key)) {
              addedKeys.add(key);
              newTransitions.add({
                'from': fromName,
                'to': toName,
                'symbol': symbol,
              });
            }
          }
        }
      }
    }

    return MinimizationResult(
      states: newStates,
      initialState: newInitialState,
      acceptStates: newAcceptStates,
      transitions: newTransitions,
    );
  }
}

class _BfsNode {
  final String state;
  final int index;
  final List<String> path;

  _BfsNode(this.state, this.index, this.path);
}
