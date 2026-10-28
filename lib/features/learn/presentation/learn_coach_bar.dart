import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/learn_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'learn_sheet.dart';

/// Compact overlay so a lesson can stay attached while the existing canvas
/// and simulator remain fully usable. Hidden when no lesson is active.
class LearnCoachBar extends ConsumerWidget {
  const LearnCoachBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learnSessionProvider);
    if (session.activeLessonId == null || !session.coachVisible) {
      return const SizedBox.shrink();
    }

    final step = session.currentStep;
    final lesson = session.activeLesson;
    if (step == null || lesson == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${lesson.title} · ${step.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => LearnSheet.show(context),
              child: const Text('Open'),
            ),
            IconButton(
              tooltip: 'Exit lesson',
              onPressed: () =>
                  ref.read(learnSessionProvider.notifier).exitLesson(),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
