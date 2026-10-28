import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/learn/domain/construction_checker.dart';
import '../../features/learn/domain/lesson_catalog.dart';
import '../../features/learn/domain/lesson_models.dart';
import 'automaton_providers.dart';

export '../../features/learn/domain/lesson_models.dart';
export '../../features/learn/domain/lesson_catalog.dart';

class LearnSession {
  final String? activeLessonId;
  final int stepIndex;
  final Set<String> completedLessonIds;
  final int hintLevel;
  final bool coachVisible;
  final StepCheckResult? lastCheck;
  final int? selectedChoice;
  final bool answerRevealed;
  final bool checking;

  const LearnSession({
    this.activeLessonId,
    this.stepIndex = 0,
    this.completedLessonIds = const {},
    this.hintLevel = 0,
    this.coachVisible = false,
    this.lastCheck,
    this.selectedChoice,
    this.answerRevealed = false,
    this.checking = false,
  });

  Lesson? get activeLesson =>
      activeLessonId == null ? null : LessonCatalog.byId(activeLessonId!);

  LessonStep? get currentStep {
    final lesson = activeLesson;
    if (lesson == null || lesson.steps.isEmpty) return null;
    final i = stepIndex.clamp(0, lesson.steps.length - 1);
    return lesson.steps[i];
  }

  LearnSession copyWith({
    String? activeLessonId,
    int? stepIndex,
    Set<String>? completedLessonIds,
    int? hintLevel,
    bool? coachVisible,
    StepCheckResult? lastCheck,
    int? selectedChoice,
    bool? answerRevealed,
    bool? checking,
    bool clearLesson = false,
    bool clearCheck = false,
    bool clearChoice = false,
  }) {
    return LearnSession(
      activeLessonId:
          clearLesson ? null : (activeLessonId ?? this.activeLessonId),
      stepIndex: stepIndex ?? this.stepIndex,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      hintLevel: hintLevel ?? this.hintLevel,
      coachVisible: coachVisible ?? this.coachVisible,
      lastCheck: clearCheck ? null : (lastCheck ?? this.lastCheck),
      selectedChoice:
          clearChoice ? null : (selectedChoice ?? this.selectedChoice),
      answerRevealed: answerRevealed ?? this.answerRevealed,
      checking: checking ?? this.checking,
    );
  }
}

class LearnNotifier extends Notifier<LearnSession> {
  static const _checker = ConstructionChecker();

  @override
  LearnSession build() => const LearnSession();

  void startLesson(String lessonId) {
    final lesson = LessonCatalog.byId(lessonId);
    if (lesson == null) return;
    state = LearnSession(
      activeLessonId: lessonId,
      stepIndex: 0,
      completedLessonIds: state.completedLessonIds,
      coachVisible: true,
    );
  }

  void exitLesson() {
    state = state.copyWith(clearLesson: true, coachVisible: false, stepIndex: 0);
  }

  void showCoach() {
    if (state.activeLessonId != null) {
      state = state.copyWith(coachVisible: true);
    }
  }

  void hideCoach() {
    state = state.copyWith(coachVisible: false);
  }

  void revealHint() {
    final step = state.currentStep;
    if (step == null || step.hints.isEmpty) return;
    final next = (state.hintLevel + 1).clamp(0, step.hints.length);
    state = state.copyWith(hintLevel: next);
  }

  void selectChoice(int index) {
    final correct = state.currentStep?.question?.correctIndex;
    if (state.answerRevealed && state.selectedChoice == correct) return;
    state = state.copyWith(
      selectedChoice: index,
      answerRevealed: false,
    );
  }

  void submitAnswer() {
    final step = state.currentStep;
    final q = step?.question;
    if (q == null || state.selectedChoice == null) return;
    state = state.copyWith(answerRevealed: true);
  }

  void nextStep() {
    final lesson = state.activeLesson;
    if (lesson == null) return;
    if (!_canAdvance(state)) return;

    if (state.stepIndex >= lesson.steps.length - 1) {
      final done = {...state.completedLessonIds, lesson.id};
      state = state.copyWith(
        completedLessonIds: done,
        coachVisible: true,
      );
      return;
    }

    state = state.copyWith(
      stepIndex: state.stepIndex + 1,
      hintLevel: 0,
      clearCheck: true,
      clearChoice: true,
      answerRevealed: false,
    );
  }

  void previousStep() {
    if (state.stepIndex <= 0) return;
    state = state.copyWith(
      stepIndex: state.stepIndex - 1,
      hintLevel: 0,
      clearCheck: true,
      clearChoice: true,
      answerRevealed: false,
    );
  }

  bool canAdvance() => _canAdvance(state);

  bool _canAdvance(LearnSession session) {
    final step = session.currentStep;
    if (step == null) return false;
    switch (step.kind) {
      case LessonStepKind.explain:
      case LessonStepKind.complete:
        return true;
      case LessonStepKind.question:
        return session.answerRevealed &&
            session.selectedChoice == step.question?.correctIndex;
      case LessonStepKind.canvasCheck:
        return session.lastCheck?.passed == true;
      case LessonStepKind.simulate:
        return session.lastCheck?.passed == true;
    }
  }

  Future<void> checkCanvas() async {
    final step = state.currentStep;
    final goal = step?.canvasGoal;
    if (goal == null) return;

    state = state.copyWith(checking: true);
    final automaton = ref.read(automatonProvider);
    final api = ref.read(automataApiProvider);
    final result = await _checker.check(
      automaton: automaton,
      goal: goal,
      api: api,
    );
    state = state.copyWith(checking: false, lastCheck: result);
  }

  Future<void> checkSimulation() async {
    final step = state.currentStep;
    final goal = step?.simulateGoal;
    if (goal == null) return;

    final automaton = ref.read(automatonProvider);
    final api = ref.read(automataApiProvider);
    final sim = ref.read(simulationProvider);

    final input = sim.inputString.isNotEmpty
        ? sim.inputString
        : goal.suggestedInput;

    if (automaton.initialState == null) {
      state = state.copyWith(
        lastCheck: const StepCheckResult(
          passed: false,
          message:
              'Load or build a machine with a start state, then run Simulate.',
        ),
      );
      return;
    }

    final result = await api.validate(automaton, input);
    final expected = goal.expectAccepted;
    if (input != goal.suggestedInput) {
      state = state.copyWith(
        lastCheck: StepCheckResult(
          passed: false,
          message:
              'Use the suggested tape "${goal.suggestedInput}" in Simulate (you currently have "$input"), then check again.',
        ),
      );
      return;
    }

    if (result.accepted == expected) {
      state = state.copyWith(
        lastCheck: StepCheckResult(
          passed: true,
          message:
              'The on-device engine ${expected ? "accepted" : "rejected"} "$input". ${goal.why}',
        ),
      );
    } else {
      state = state.copyWith(
        lastCheck: StepCheckResult(
          passed: false,
          message: expected
              ? 'Expected accept for "$input", but the engine rejected it. ${goal.why} Load the suggested Library preset if your canvas is a different machine.'
              : 'Expected reject for "$input", but the engine accepted it. ${goal.why}',
        ),
      );
    }
  }
}

final learnSessionProvider =
    NotifierProvider<LearnNotifier, LearnSession>(LearnNotifier.new);
