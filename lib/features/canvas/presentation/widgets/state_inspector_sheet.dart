import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';

/// Canva-inspired State Inspector Sheet for editing state properties and rules.
class StateInspectorSheet extends ConsumerStatefulWidget {
  final AutomatonState state;

  const StateInspectorSheet({super.key, required this.state});

  static Future<void> show(BuildContext context, AutomatonState state) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StateInspectorSheet(state: state),
    );
  }

  @override
  ConsumerState<StateInspectorSheet> createState() => _StateInspectorSheetState();
}

class _StateInspectorSheetState extends ConsumerState<StateInspectorSheet> {
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.state.label);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final automaton = ref.watch(automatonProvider);
    final currentState =
        automaton.stateMap[widget.state.id] ?? widget.state;
    final outgoingTransitions = automaton.transitions
        .where((t) => t.fromStateId == currentState.id)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hub_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'State Inspector',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              'ID: ${currentState.id}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Configure state attributes, transitions, and rules',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── State Label ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'State Label',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Visual identifier',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _labelCtrl,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text(
                        'δ:',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary),
                      onPressed: () {
                        final val = _labelCtrl.text.trim();
                        if (val.isNotEmpty) {
                          ref
                              .read(automatonProvider.notifier)
                              .updateStateLabel(currentState.id, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Renamed state to "$val"'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  onSubmitted: (val) {
                    final trimmed = val.trim();
                    if (trimmed.isNotEmpty) {
                      ref
                          .read(automatonProvider.notifier)
                          .updateStateLabel(currentState.id, trimmed);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Quick symbol pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['q0', 'q1', 'q2', 'q3', 'S', 'A', 'B'].map((sym) {
                    final isCurrent = _labelCtrl.text == sym;
                    return ActionChip(
                      backgroundColor: isCurrent
                          ? AppColors.primary.withAlpha(30)
                          : AppColors.surfaceContainerLow,
                      side: BorderSide(
                        color: isCurrent ? AppColors.primary : AppColors.borderSubtle,
                      ),
                      label: Text(
                        sym,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      onPressed: () {
                        _labelCtrl.text = sym;
                        ref
                            .read(automatonProvider.notifier)
                            .updateStateLabel(currentState.id, sym);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── State Properties ──
                const Text(
                  'State Properties',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // Initial State switch card
                _PropertyCard(
                  icon: Icons.play_circle_rounded,
                  iconColor: AppColors.primary,
                  title: 'Initial / Start State (q0)',
                  subtitle: 'Starting entry point for input strings',
                  value: currentState.isInitial,
                  onChanged: (val) {
                    ref
                        .read(automatonProvider.notifier)
                        .toggleInitial(currentState.id);
                  },
                ),
                const SizedBox(height: 10),

                // Accepting / Final State switch card
                _PropertyCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.successBase,
                  title: 'Accepting / Final State (F)',
                  subtitle: 'Strings ending here will be accepted',
                  value: currentState.isFinal,
                  onChanged: (val) {
                    ref
                        .read(automatonProvider.notifier)
                        .toggleFinal(currentState.id);
                  },
                ),

                const SizedBox(height: 24),

                // ── Outgoing Transitions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Outgoing Transitions',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentSecondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${outgoingTransitions.length}',
                            style: const TextStyle(
                              color: AppColors.accentSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(canvasViewProvider.notifier)
                            .startConnecting(currentState.id);
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Rule',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (outgoingTransitions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Center(
                      child: Text(
                        'No outgoing transitions yet. Tap "+ Add Rule" or link from canvas.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...outgoingTransitions.map((t) {
                    final target = automaton.stateMap[t.toStateId];
                    final targetLabel = target?.label ?? '?';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.symbol.isEmpty ? 'ε' : t.symbol,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_right_alt_rounded,
                              color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            targetLabel,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          if (t.isSelfLoop) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '(self)',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.errorBase, size: 18),
                            onPressed: () {
                              ref
                                  .read(automatonProvider.notifier)
                                  .removeTransition(t.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // ── Delete State Button ──
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorBase,
                    side: const BorderSide(color: AppColors.errorBase, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(automatonProvider.notifier)
                        .removeState(currentState.id);
                    ref.read(canvasViewProvider.notifier).clearSelection();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Delete State "${currentState.label}"',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PropertyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? iconColor.withAlpha(120) : AppColors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
