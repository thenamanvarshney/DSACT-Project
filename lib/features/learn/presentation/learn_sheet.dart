import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/automaton_providers.dart';
import '../../../core/providers/learn_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/automata_presets.dart';
import '../domain/lesson_models.dart';

/// Modal learning catalog and guided player. Opened from the existing top bar;
/// does not replace canvas, library, matrix, or simulate.
class LearnSheet extends ConsumerWidget {
  const LearnSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LearnSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learnSessionProvider);
    final inLesson = session.activeLessonId != null && session.coachVisible;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.indigoGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    inLesson
                        ? Icons.menu_book_rounded
                        : Icons.school_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inLesson
                            ? (session.activeLesson?.title ?? 'Lesson')
                            : 'Learn Automata',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inLesson
                            ? 'Step ${session.stepIndex + 1} of ${session.activeLesson!.steps.length}'
                            : 'Guidance uses the existing canvas and simulator',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (inLesson)
                  TextButton(
                    onPressed: () {
                      ref.read(learnSessionProvider.notifier).exitLesson();
                    },
                    child: const Text('Catalog'),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: inLesson
                ? const _LessonPlayer()
                : const _LessonCatalogView(),
          ),
        ],
      ),
    );
  }
}

class _LessonCatalogView extends ConsumerWidget {
  const _LessonCatalogView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learnSessionProvider);
    final lessons = LessonCatalog.all;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: lessons.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (ctx, index) {
        if (index == 0) {
          return const Text(
            'Work through these in order. Construction steps grade the machine '
            'already on your canvas. Nothing in Canvas, Simulate, Matrix, or '
            'Library is replaced.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          );
        }
        final lesson = lessons[index - 1];
        final done = session.completedLessonIds.contains(lesson.id);
        return _LessonCard(lesson: lesson, completed: done);
      },
    );
  }
}

class _LessonCard extends ConsumerWidget {
  final Lesson lesson;
  final bool completed;

  const _LessonCard({required this.lesson, required this.completed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary.withAlpha(77)),
                ),
                child: Text(
                  '${lesson.level} · ${lesson.module}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (completed)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.successBase, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.subtitle,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(learnSessionProvider.notifier).startLesson(lesson.id);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(completed ? 'Replay' : 'Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPlayer extends ConsumerWidget {
  const _LessonPlayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learnSessionProvider);
    final step = session.currentStep;
    final lesson = session.activeLesson;
    if (step == null || lesson == null) {
      return const Center(child: Text('No active lesson'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (session.stepIndex + 1) / lesson.steps.length,
              minHeight: 6,
              backgroundColor: AppColors.borderSubtle,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.body,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              if (step.whyRequired != null) ...[
                const SizedBox(height: 12),
                _InfoCallout(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Why this is required',
                  body: step.whyRequired!,
                ),
              ],
              if (step.kind == LessonStepKind.question &&
                  step.question != null) ...[
                const SizedBox(height: 16),
                _QuizBlock(question: step.question!, session: session),
              ],
              if (step.kind == LessonStepKind.canvasCheck) ...[
                const SizedBox(height: 16),
                const _InfoCallout(
                  icon: Icons.hub_rounded,
                  title: 'Use the existing canvas',
                  body:
                      'Add states and arrows with the tools you already have. '
                      'This panel only checks your machine; it does not draw it.',
                ),
              ],
              if (step.kind == LessonStepKind.simulate) ...[
                const SizedBox(height: 16),
                _SimulateActions(step: step),
              ],
              if (session.lastCheck != null) ...[
                const SizedBox(height: 12),
                _FeedbackCard(result: session.lastCheck!),
              ],
              if (step.hints.isNotEmpty) ...[
                const SizedBox(height: 12),
                _HintBlock(step: step, hintLevel: session.hintLevel),
              ],
            ],
          ),
        ),
        _PlayerControls(session: session, step: step),
      ],
    );
  }
}

class _InfoCallout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCallout({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizBlock extends ConsumerWidget {
  final QuizQuestion question;
  final LearnSession session;

  const _QuizBlock({required this.question, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < question.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _choiceColor(i),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: session.answerRevealed &&
                        session.selectedChoice == question.correctIndex
                    ? null
                    : () =>
                        ref.read(learnSessionProvider.notifier).selectChoice(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    question.choices[i],
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!session.answerRevealed)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: session.selectedChoice == null
                  ? null
                  : () => ref.read(learnSessionProvider.notifier).submitAnswer(),
              child: const Text('Check answer'),
            ),
          ),
        if (session.answerRevealed) ...[
          const SizedBox(height: 8),
          _InfoCallout(
            icon: session.selectedChoice == question.correctIndex
                ? Icons.check_rounded
                : Icons.close_rounded,
            title: session.selectedChoice == question.correctIndex
                ? 'Correct'
                : 'Not yet',
            body: session.selectedChoice == question.correctIndex
                ? question.explanation
                : (question.mistakeFeedback[session.selectedChoice!] ??
                    question.explanation),
          ),
        ],
      ],
    );
  }

  Color _choiceColor(int i) {
    final selected = session.selectedChoice == i;
    if (!session.answerRevealed) {
      return selected
          ? AppColors.primary.withAlpha(30)
          : AppColors.surfaceContainerLow;
    }
    if (i == question.correctIndex) {
      return AppColors.successBase.withAlpha(40);
    }
    if (selected) {
      return AppColors.errorBase.withAlpha(40);
    }
    return AppColors.surfaceContainerLow;
  }
}

class _SimulateActions extends ConsumerWidget {
  final LessonStep step;

  const _SimulateActions({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = step.simulateGoal;
    if (goal == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCallout(
          icon: Icons.play_circle_outline_rounded,
          title: 'Use the existing Simulate drawer',
          body:
              'Suggested input: "${goal.suggestedInput}". Open Simulate from the '
              'top bar, enter that string, run it, then return here and tap '
              'Check engine result.',
        ),
        if (goal.loadPresetId != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final preset = AutomataPreset.allPresets.firstWhere(
                (p) => p.id == goal.loadPresetId,
              );
              ref.read(automatonProvider.notifier).loadPreset(preset.automaton);
              ref
                  .read(simulationProvider.notifier)
                  .setInputString(goal.suggestedInput);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loaded "${preset.name}" for this step'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Load suggested Library machine'),
          ),
        ],
      ],
    );
  }
}

class _HintBlock extends ConsumerWidget {
  final LessonStep step;
  final int hintLevel;

  const _HintBlock({required this.step, required this.hintLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hintLevel > 0)
          ...List.generate(hintLevel, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoCallout(
                icon: Icons.tips_and_updates_outlined,
                title: 'Hint ${i + 1}',
                body: step.hints[i],
              ),
            );
          }),
        if (hintLevel < step.hints.length)
          TextButton.icon(
            onPressed: () =>
                ref.read(learnSessionProvider.notifier).revealHint(),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: Text(
              hintLevel == 0 ? 'I need a hint' : 'Another hint',
            ),
          ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final StepCheckResult result;

  const _FeedbackCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? AppColors.successBase : AppColors.errorBase;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.passed ? 'Looks good' : 'Needs a fix',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.message,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (!result.passed && result.details.length > 1)
            ...result.details.map(
              (d) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '• $d',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerControls extends ConsumerWidget {
  final LearnSession session;
  final LessonStep step;

  const _PlayerControls({required this.session, required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(learnSessionProvider.notifier);
    final canNext = notifier.canAdvance();
    final isLast = session.activeLesson != null &&
        session.stepIndex >= session.activeLesson!.steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous step',
            onPressed: session.stepIndex > 0 ? notifier.previousStep : null,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          if (step.kind == LessonStepKind.canvasCheck)
            Expanded(
              child: OutlinedButton(
                onPressed: session.checking ? null : notifier.checkCanvas,
                child: Text(session.checking ? 'Checking…' : 'Check construction'),
              ),
            ),
          if (step.kind == LessonStepKind.simulate)
            Expanded(
              child: OutlinedButton(
                onPressed: session.checking
                    ? null
                    : notifier.checkSimulation,
                child: const Text('Check engine result'),
              ),
            ),
          if (step.kind != LessonStepKind.canvasCheck &&
              step.kind != LessonStepKind.simulate)
            const Spacer(),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canNext
                ? () {
                    if (isLast) {
                      notifier.nextStep();
                      notifier.exitLesson();
                    } else {
                      notifier.nextStep();
                    }
                  }
                : null,
            child: Text(isLast ? 'Finish' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
