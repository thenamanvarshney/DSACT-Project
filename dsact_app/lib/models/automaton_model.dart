import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a single state node on the canvas.
class AutomatonState {
  final String id;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;

  const AutomatonState({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
  });

  factory AutomatonState.create({
    required String label,
    required double x,
    required double y,
    bool isInitial = false,
    bool isFinal = false,
  }) {
    return AutomatonState(
      id: _uuid.v4(),
      label: label,
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
    );
  }

  AutomatonState copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
  }) {
    return AutomatonState(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'x': x,
        'y': y,
        'isInitial': isInitial,
        'isFinal': isFinal,
      };

  factory AutomatonState.fromJson(Map<String, dynamic> json) {
    return AutomatonState(
      id: json['id'] as String? ?? _uuid.v4(),
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isInitial: json['isInitial'] as bool? ?? false,
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AutomatonState && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a transition edge between states.
class AutomatonTransition {
  final String id;
  final String fromStateId;
  final String toStateId;
  final String symbol; // '' or 'ε' or 'λ' for epsilon
  final double curvature;

  const AutomatonTransition({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.symbol,
    this.curvature = 0.0,
  });

  factory AutomatonTransition.create({
    required String fromStateId,
    required String toStateId,
    required String symbol,
    double curvature = 0.0,
  }) {
    return AutomatonTransition(
      id: _uuid.v4(),
      fromStateId: fromStateId,
      toStateId: toStateId,
      symbol: symbol,
      curvature: curvature,
    );
  }

  bool get isSelfLoop => fromStateId == toStateId;

  bool get isEpsilon =>
      symbol.isEmpty || symbol == 'ε' || symbol == 'epsilon' || symbol == 'λ';

  AutomatonTransition copyWith({
    String? id,
    String? fromStateId,
    String? toStateId,
    String? symbol,
    double? curvature,
  }) {
    return AutomatonTransition(
      id: id ?? this.id,
      fromStateId: fromStateId ?? this.fromStateId,
      toStateId: toStateId ?? this.toStateId,
      symbol: symbol ?? this.symbol,
      curvature: curvature ?? this.curvature,
    );
  }

  /// Convert to backend transition format: { from, to, symbol }
  Map<String, dynamic> toBackendJson(Map<String, AutomatonState> stateMap) {
    return {
      'from': stateMap[fromStateId]?.label ?? fromStateId,
      'to': stateMap[toStateId]?.label ?? toStateId,
      'symbol': symbol,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromStateId': fromStateId,
        'toStateId': toStateId,
        'symbol': symbol,
      };

  factory AutomatonTransition.fromJson(Map<String, dynamic> json) {
    return AutomatonTransition(
      id: json['id'] as String? ?? _uuid.v4(),
      fromStateId: json['fromStateId'] as String,
      toStateId: json['toStateId'] as String,
      symbol: json['symbol'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AutomatonTransition && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// The type of automaton.
enum AutomatonType { dfa, nfa, enfa }

/// Full automaton graph (states + transitions + metadata).
class Automaton {
  final String id;
  final String name;
  final AutomatonType type;
  final List<AutomatonState> states;
  final List<AutomatonTransition> transitions;
  final List<String> alphabet;

  const Automaton({
    required this.id,
    required this.name,
    required this.type,
    required this.states,
    required this.transitions,
    required this.alphabet,
  });

  factory Automaton.empty({String name = 'Untitled Automaton'}) {
    return Automaton(
      id: _uuid.v4(),
      name: name,
      type: AutomatonType.dfa,
      states: const [],
      transitions: const [],
      alphabet: const [],
    );
  }

  Automaton copyWith({
    String? id,
    String? name,
    AutomatonType? type,
    List<AutomatonState>? states,
    List<AutomatonTransition>? transitions,
    List<String>? alphabet,
  }) {
    return Automaton(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      alphabet: alphabet ?? this.alphabet,
    );
  }

  AutomatonState? get initialState =>
      states.where((s) => s.isInitial).firstOrNull;

  List<AutomatonState> get finalStates =>
      states.where((s) => s.isFinal).toList();

  /// Build the state map from id -> state
  Map<String, AutomatonState> get stateMap =>
      {for (final s in states) s.id: s};

  /// Convert to the backend request format for /api/validate.
  Map<String, dynamic> toValidateJson(String inputString) {
    final sMap = stateMap;
    return {
      'initialState': initialState?.label ?? '',
      'acceptStates': finalStates.map((s) => s.label).toList(),
      'transitions':
          transitions.map((t) => t.toBackendJson(sMap)).toList(),
      'inputString': inputString,
    };
  }

  /// Convert to the backend request format for /api/minimize.
  Map<String, dynamic> toMinimizeJson() {
    final sMap = stateMap;
    return {
      'initialState': initialState?.label ?? '',
      'acceptStates': finalStates.map((s) => s.label).toList(),
      'transitions':
          transitions.map((t) => t.toBackendJson(sMap)).toList(),
      'states': states.map((s) => s.label).toList(),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'states': states.map((s) => s.toJson()).toList(),
        'transitions': transitions.map((t) => t.toJson()).toList(),
        'alphabet': alphabet,
      };

  factory Automaton.fromJson(Map<String, dynamic> json) {
    return Automaton(
      id: json['id'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Untitled',
      type: AutomatonType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'dfa'),
        orElse: () => AutomatonType.dfa,
      ),
      states: (json['states'] as List)
          .map((e) => AutomatonState.fromJson(e as Map<String, dynamic>))
          .toList(),
      transitions: (json['transitions'] as List)
          .map(
              (e) => AutomatonTransition.fromJson(e as Map<String, dynamic>))
          .toList(),
      alphabet: (json['alphabet'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Response from the /api/validate endpoint.
class ValidationResult {
  final bool accepted;
  final List<String> executionPath;
  final String? error;

  const ValidationResult({
    required this.accepted,
    required this.executionPath,
    this.error,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      accepted: json['accepted'] as bool? ?? false,
      executionPath: (json['executionPath'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      error: json['error'] as String?,
    );
  }
}

/// Response from the /api/minimize endpoint.
class MinimizationResult {
  final List<String> states;
  final String initialState;
  final List<String> acceptStates;
  final List<Map<String, String>> transitions;
  final String? error;

  const MinimizationResult({
    required this.states,
    required this.initialState,
    required this.acceptStates,
    required this.transitions,
    this.error,
  });

  factory MinimizationResult.fromJson(Map<String, dynamic> json) {
    return MinimizationResult(
      states: (json['states'] as List?)?.cast<String>() ?? [],
      initialState: json['initialState'] as String? ?? '',
      acceptStates: (json['acceptStates'] as List?)?.cast<String>() ?? [],
      transitions: (json['transitions'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      error: json['error'] as String?,
    );
  }
}
