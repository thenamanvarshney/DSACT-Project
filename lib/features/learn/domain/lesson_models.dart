import '../../../models/automaton_model.dart';

/// Kinds of guided lesson steps. New modules can reuse these without
/// changing the existing canvas or automata engine.
enum LessonStepKind {
  explain,
  question,
  canvasCheck,
  simulate,
  complete,
}

/// A single multiple-choice checkpoint. Answers stay hidden until the
/// learner submits a choice.
class QuizQuestion {
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final Map<int, String> mistakeFeedback;

  const QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    this.mistakeFeedback = const {},
  });
}

/// Language test used with the existing on-device validate engine.
class LanguageCase {
  final String input;
  final bool shouldAccept;
  final String why;

  const LanguageCase({
    required this.input,
    required this.shouldAccept,
    required this.why,
  });
}

/// Structural + language goals checked against the live canvas automaton.
class CanvasGoal {
  final int? minStates;
  final int? exactStates;
  final bool requireInitial;
  final bool requireAccepting;
  final AutomatonType? requiredType;
  final List<String> requiredSymbols;
  final bool requireSelfLoop;
  final bool requireCrossTransition;
  final List<LanguageCase> languageCases;
  final String successMessage;

  const CanvasGoal({
    this.minStates,
    this.exactStates,
    this.requireInitial = false,
    this.requireAccepting = false,
    this.requiredType,
    this.requiredSymbols = const [],
    this.requireSelfLoop = false,
    this.requireCrossTransition = false,
    this.languageCases = const [],
    this.successMessage = 'That construction matches the goal.',
  });
}

/// Guides the learner to run the existing simulator (does not replace it).
class SimulateGoal {
  final String? loadPresetId;
  final String suggestedInput;
  final bool expectAccepted;
  final String why;

  const SimulateGoal({
    this.loadPresetId,
    required this.suggestedInput,
    required this.expectAccepted,
    required this.why,
  });
}

class LessonStep {
  final String id;
  final LessonStepKind kind;
  final String title;
  final String body;
  final String? whyRequired;
  final List<String> hints;
  final QuizQuestion? question;
  final CanvasGoal? canvasGoal;
  final SimulateGoal? simulateGoal;

  const LessonStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.whyRequired,
    this.hints = const [],
    this.question,
    this.canvasGoal,
    this.simulateGoal,
  });
}

class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String level;
  final String module;
  final List<LessonStep> steps;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.module,
    required this.steps,
  });
}

class StepCheckResult {
  final bool passed;
  final String message;
  final List<String> details;

  const StepCheckResult({
    required this.passed,
    required this.message,
    this.details = const [],
  });
}
