import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../learn/presentation/learn_sheet.dart';
import 'presets_sheet.dart';

/// Kinetic Toybox Top Toolbar — clean, glassmorphic header with machine switcher,
/// type chips, minimization trigger, and hero simulation CTA.
class CanvasTopBar extends ConsumerStatefulWidget {
  final VoidCallback? onToggleSim;
  final bool isSimOpen;

  const CanvasTopBar({
    super.key,
    this.onToggleSim,
    this.isSimOpen = false,
  });

  @override
  ConsumerState<CanvasTopBar> createState() => _CanvasTopBarState();
}

class _CanvasTopBarState extends ConsumerState<CanvasTopBar> {
  bool _isMinimizing = false;

  Future<void> _handleMinimize(Automaton automaton) async {
    if (automaton.initialState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot minimize: Set an initial state first.'),
          backgroundColor: AppColors.errorBase,
        ),
      );
      return;
    }

    setState(() => _isMinimizing = true);
    final prevCount = automaton.states.length;

    try {
      final api = ref.read(automataApiProvider);
      final result =
          await ref.read(automatonProvider.notifier).minimize(api);

      if (mounted) {
        final newCount = result.states.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            content: Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DFA Minimized: $prevCount states ➔ $newCount states!',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minimization failed: $e'),
            backgroundColor: AppColors.errorBase,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMinimizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final automaton = ref.watch(automatonProvider);
    final backendStatus = ref.watch(backendStatusProvider);

    final isDfa = automaton.type == AutomatonType.dfa;
    final canMinimize = isDfa && automaton.states.isNotEmpty && !_isMinimizing;

    final alphabetString = automaton.alphabet.isEmpty
        ? 'Σ={0,1}'
        : 'Σ={${automaton.alphabet.join(',')}}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Left: App Brand & Current Preset Selector ──
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Logo Squircle
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE94057).withAlpha(80),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.all_inclusive_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Automata Canvas',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'DSACT • AutoMatik Workbench',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        // Preset / Project Selector Pill
                        GestureDetector(
                          onTap: () => PresetsSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(80),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.hub_rounded,
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  automaton.name.isEmpty
                                      ? 'Custom Automaton'
                                      : automaton.name,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down_rounded,
                                    size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Automata Type Selector Chips
                        _TypeChip(
                          label: 'DFA',
                          isSelected: automaton.type == AutomatonType.dfa,
                          onTap: () => ref
                              .read(automatonProvider.notifier)
                              .setAutomatonType(AutomatonType.dfa),
                        ),
                        const SizedBox(width: 5),
                        _TypeChip(
                          label: 'NFA',
                          isSelected: automaton.type == AutomatonType.nfa,
                          onTap: () => ref
                              .read(automatonProvider.notifier)
                              .setAutomatonType(AutomatonType.nfa),
                        ),
                        const SizedBox(width: 5),
                        _TypeChip(
                          label: 'ε-NFA',
                          isSelected: automaton.type == AutomatonType.enfa,
                          onTap: () => ref
                              .read(automatonProvider.notifier)
                              .setAutomatonType(AutomatonType.enfa),
                        ),

                        const SizedBox(width: 10),

                        // DFA Minimization Action
                        if (isDfa)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: canMinimize
                                    ? AppColors.primary
                                    : AppColors.borderSubtle,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: canMinimize
                                ? () => _handleMinimize(automaton)
                                : null,
                            icon: _isMinimizing
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.compress_rounded, size: 15),
                            label: const Text(
                              'Minimize DFA',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // ── Right: Machine Stat Pills & Run CTA ──
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Machine Status pill: e.g. Valid DFA • 3 States • Σ={0,1}
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.successBase,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${automaton.states.length} States  •  ${automaton.transitions.length} Rules  •  $alphabetString',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Backend connectivity status pill
                        backendStatus.when(
                          data: (isOnline) => _BackendPill(isOnline: isOnline),
                          loading: () => const _BackendPill(isLoading: true),
                          error: (_, _) => const _BackendPill(isOnline: false),
                        ),

                        const SizedBox(width: 10),

                        // Templates action
                        IconButton(
                          tooltip: 'Templates & Presets',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => PresetsSheet.show(context),
                          icon: const Icon(Icons.auto_awesome_rounded,
                              size: 18, color: AppColors.primary),
                        ),

                        const SizedBox(width: 6),

                        IconButton(
                          tooltip: 'Learn Automata',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => LearnSheet.show(context),
                          icon: const Icon(Icons.school_rounded,
                              size: 18, color: AppColors.primary),
                        ),

                        const SizedBox(width: 6),

                        // Hero "Simulate" CTA Button with vibrant gradient
                        GestureDetector(
                          onTap: widget.onToggleSim,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: widget.isSimOpen
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.errorBase,
                                        Color(0xFFE94057)
                                      ],
                                    )
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isSimOpen
                                          ? AppColors.errorBase
                                          : const Color(0xFFE94057))
                                      .withAlpha(80),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isSimOpen
                                      ? Icons.close_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isSimOpen ? 'Close Drawer' : 'Simulate',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BackendPill extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;

  const _BackendPill({this.isOnline = false, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.successBase;
    const label = 'On-Device Engine';

    return Tooltip(
      message: 'Native high-performance Dart BFS simulation and Moore DFA minimization engine (100% offline & zero-latency)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
