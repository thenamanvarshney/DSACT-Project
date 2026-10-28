import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/automaton_model.dart';
import '../../services/automata_api_service.dart';

export '../../models/automaton_model.dart';

// ── Service Provider ────────────────────────────────────────────────
final automataApiProvider = Provider<AutomataApiService>((ref) {
  return AutomataApiService();
});

/// Backend connectivity status provider
final backendStatusProvider = FutureProvider<bool>((ref) async {
  final api = ref.watch(automataApiProvider);
  return api.checkHealth();
});

// ── Canvas View State ───────────────────────────────────────────────

/// Represents the visual state of the interactive canvas.
class CanvasViewState {
  final double zoom;
  final double panX;
  final double panY;
  final String? selectedStateId;
  final String? selectedTransitionId;
  final String? connectingFromStateId; // During transition creation

  const CanvasViewState({
    this.zoom = 1.0,
    this.panX = 0,
    this.panY = 0,
    this.selectedStateId,
    this.selectedTransitionId,
    this.connectingFromStateId,
  });

  CanvasViewState copyWith({
    double? zoom,
    double? panX,
    double? panY,
    String? selectedStateId,
    String? selectedTransitionId,
    String? connectingFromStateId,
    bool clearSelection = false,
    bool clearConnecting = false,
  }) {
    return CanvasViewState(
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      selectedStateId:
          clearSelection ? null : (selectedStateId ?? this.selectedStateId),
      selectedTransitionId: clearSelection
          ? null
          : (selectedTransitionId ?? this.selectedTransitionId),
      connectingFromStateId: clearConnecting
          ? null
          : (connectingFromStateId ?? this.connectingFromStateId),
    );
  }
}

class CanvasViewNotifier extends Notifier<CanvasViewState> {
  @override
  CanvasViewState build() => const CanvasViewState();

  void selectState(String id) {
    state = state.copyWith(
      selectedStateId: id,
      selectedTransitionId: null,
      clearConnecting: true,
    );
  }

  void selectTransition(String id) {
    state = state.copyWith(
      selectedStateId: null,
      selectedTransitionId: id,
      clearConnecting: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true, clearConnecting: true);
  }

  void startConnecting(String fromStateId) {
    state = state.copyWith(connectingFromStateId: fromStateId);
  }

  void cancelConnecting() {
    state = state.copyWith(clearConnecting: true);
  }

  void setZoom(double z) {
    state = state.copyWith(zoom: z.clamp(0.5, 3.0));
  }
}

final canvasViewProvider =
    NotifierProvider<CanvasViewNotifier, CanvasViewState>(
  CanvasViewNotifier.new,
);

// ── Automaton Graph State ───────────────────────────────────────────

class AutomatonNotifier extends Notifier<Automaton> {
  final List<Automaton> _undoStack = [];
  final List<Automaton> _redoStack = [];

  @override
  Automaton build() => Automaton.empty();

  void _pushUndo() {
    _undoStack.add(state);
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state);
    state = _undoStack.removeLast();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state);
    state = _redoStack.removeLast();
  }

  // ── State Management ──

  int _stateCounter = 0;

  void addState({
    required double x,
    required double y,
    bool isInitial = false,
    bool isFinal = false,
  }) {
    _pushUndo();
    // If setting initial, clear any existing initial
    var updatedStates = [...state.states];
    if (isInitial) {
      updatedStates = updatedStates
          .map((s) => s.isInitial ? s.copyWith(isInitial: false) : s)
          .toList();
    }
    final newState = AutomatonState.create(
      label: 'q$_stateCounter',
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
    );
    _stateCounter++;
    updatedStates.add(newState);
    state = state.copyWith(states: updatedStates);
  }

  void removeState(String stateId) {
    _pushUndo();
    state = state.copyWith(
      states: state.states.where((s) => s.id != stateId).toList(),
      transitions: state.transitions
          .where((t) => t.fromStateId != stateId && t.toStateId != stateId)
          .toList(),
    );
  }

  void moveState(String stateId, double x, double y) {
    state = state.copyWith(
      states: state.states.map((s) {
        return s.id == stateId ? s.copyWith(x: x, y: y) : s;
      }).toList(),
    );
  }

  void updateStateLabel(String stateId, String label) {
    _pushUndo();
    state = state.copyWith(
      states: state.states.map((s) {
        return s.id == stateId ? s.copyWith(label: label) : s;
      }).toList(),
    );
  }

  void toggleInitial(String stateId) {
    _pushUndo();
    state = state.copyWith(
      states: state.states.map((s) {
        if (s.id == stateId) return s.copyWith(isInitial: !s.isInitial);
        if (s.isInitial) return s.copyWith(isInitial: false);
        return s;
      }).toList(),
    );
  }

  void toggleFinal(String stateId) {
    _pushUndo();
    state = state.copyWith(
      states: state.states.map((s) {
        return s.id == stateId ? s.copyWith(isFinal: !s.isFinal) : s;
      }).toList(),
    );
  }

  // ── Transition Management ──

  void addTransition({
    required String fromStateId,
    required String toStateId,
    required String symbol,
  }) {
    _pushUndo();
    final t = AutomatonTransition.create(
      fromStateId: fromStateId,
      toStateId: toStateId,
      symbol: symbol,
    );
    state = state.copyWith(transitions: [...state.transitions, t]);
    _updateAlphabet();
  }

  void removeTransition(String transitionId) {
    _pushUndo();
    state = state.copyWith(
      transitions:
          state.transitions.where((t) => t.id != transitionId).toList(),
    );
    _updateAlphabet();
  }

  void updateTransitionSymbol(String transitionId, String symbol) {
    _pushUndo();
    state = state.copyWith(
      transitions: state.transitions.map((t) {
        return t.id == transitionId ? t.copyWith(symbol: symbol) : t;
      }).toList(),
    );
    _updateAlphabet();
  }

  void _updateAlphabet() {
    final symbols = state.transitions
        .map((t) => t.symbol)
        .where(
            (s) => s.isNotEmpty && s != 'ε' && s != 'λ' && s != 'epsilon')
        .toSet()
        .toList()
      ..sort();
    state = state.copyWith(alphabet: symbols);
  }

  void setAutomatonType(AutomatonType type) {
    state = state.copyWith(type: type);
  }

  void clearAll() {
    _pushUndo();
    _stateCounter = 0;
    state = Automaton.empty();
  }

  /// Load a pre-defined educational preset automaton.
  void loadPreset(Automaton preset) {
    _pushUndo();
    state = preset;
    _stateCounter = preset.states.length;
    _updateAlphabet();
  }

  /// Minimize the current DFA using the Node.js backend.
  Future<MinimizationResult> minimize(AutomataApiService api) async {
    _pushUndo();
    final result = await api.minimize(state);

    final count = result.states.length;
    final centerX = 400.0;
    final centerY = 280.0;
    final radius = count <= 2 ? 140.0 : (count <= 4 ? 180.0 : 220.0);

    final labelToId = <String, String>{};
    final newStates = <AutomatonState>[];

    for (int i = 0; i < count; i++) {
      final label = result.states[i];
      final id = 'min_state_$i';
      labelToId[label] = id;

      final angle = (2 * pi * i / count) - (pi / 2);
      final x = count == 1 ? centerX : centerX + radius * cos(angle);
      final y = count == 1 ? centerY : centerY + radius * sin(angle);

      newStates.add(AutomatonState(
        id: id,
        label: label,
        x: x,
        y: y,
        isInitial: label == result.initialState,
        isFinal: result.acceptStates.contains(label),
      ));
    }

    final newTransitions = <AutomatonTransition>[];
    int tCounter = 0;
    for (final t in result.transitions) {
      final fromId = labelToId[t['from']];
      final toId = labelToId[t['to']];
      if (fromId != null && toId != null) {
        // Compute subtle curvature if reverse transition exists
        final isSelf = fromId == toId;
        final hasReverse = !isSelf && result.transitions.any(
          (other) => other['from'] == t['to'] && other['to'] == t['from'],
        );

        newTransitions.add(AutomatonTransition(
          id: 'min_t_${tCounter++}',
          fromStateId: fromId,
          toStateId: toId,
          symbol: t['symbol'] ?? '',
          curvature: hasReverse ? 0.25 : 0.0,
        ));
      }
    }

    state = Automaton(
      id: 'min_${DateTime.now().millisecondsSinceEpoch}',
      name: '${state.name.isEmpty ? "Automaton" : state.name} (Minimized)',
      type: AutomatonType.dfa,
      states: newStates,
      transitions: newTransitions,
      alphabet: state.alphabet,
    );
    _updateAlphabet();
    return result;
  }

  /// Save the undo checkpoint when drag starts.
  void beginDrag() {
    _pushUndo();
  }
}

final automatonProvider =
    NotifierProvider<AutomatonNotifier, Automaton>(
  AutomatonNotifier.new,
);

// ── Simulation State ────────────────────────────────────────────────

class SimulationState {
  final bool isRunning;
  final bool isLoading;
  final ValidationResult? result;
  final int currentStep; // index into executionPath
  final String inputString;
  final String? error;

  const SimulationState({
    this.isRunning = false,
    this.isLoading = false,
    this.result,
    this.currentStep = 0,
    this.inputString = '',
    this.error,
  });

  SimulationState copyWith({
    bool? isRunning,
    bool? isLoading,
    ValidationResult? result,
    int? currentStep,
    String? inputString,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SimulationState(
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      currentStep: currentStep ?? this.currentStep,
      inputString: inputString ?? this.inputString,
      error: clearError ? null : (error ?? this.error),
    );
  }

  String? get activeStateLabel {
    if (result == null || result!.executionPath.isEmpty) return null;
    if (currentStep < 0 || currentStep >= result!.executionPath.length) {
      return null;
    }
    return result!.executionPath[currentStep];
  }

  bool get isComplete =>
      result != null && currentStep >= result!.executionPath.length - 1;
}

class SimulationNotifier extends Notifier<SimulationState> {
  @override
  SimulationState build() => const SimulationState();

  void setInputString(String s) {
    state = state.copyWith(inputString: s, clearError: true);
  }

  Future<void> runSimulation() async {
    final automaton = ref.read(automatonProvider);
    if (automaton.initialState == null) {
      state = state.copyWith(error: 'Define an initial state first');
      return;
    }
    if (state.inputString.isEmpty) {
      state = state.copyWith(error: 'Enter an input string');
      return;
    }

    state = state.copyWith(
        isLoading: true, clearError: true, clearResult: true);

    try {
      final api = ref.read(automataApiProvider);
      final result = await api.validate(automaton, state.inputString);
      state = state.copyWith(
        isLoading: false,
        isRunning: true,
        result: result,
        currentStep: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void stepForward() {
    if (state.result == null) return;
    if (state.currentStep < state.result!.executionPath.length - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void stepBackward() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void jumpToStep(int step) {
    if (state.result == null) return;
    state = state.copyWith(
      currentStep: step.clamp(0, state.result!.executionPath.length - 1),
    );
  }

  void reset() {
    state = const SimulationState();
  }

  void stop() {
    state = state.copyWith(
        isRunning: false, currentStep: 0, clearResult: true);
  }
}

final simulationProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(
  SimulationNotifier.new,
);
