import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';

/// Modal bottom sheet displaying the formal State Transition Matrix δ(q, σ)
class TransitionMatrixSheet extends ConsumerWidget {
  const TransitionMatrixSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TransitionMatrixSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automaton = ref.watch(automatonProvider);
    final states = automaton.states;
    final alphabet = automaton.alphabet.isEmpty ? ['0', '1'] : automaton.alphabet;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
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
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transition Matrix (δ Table)',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Formal transition mapping δ: Q × Σ → P(Q)',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

          // Matrix content
          Expanded(
            child: states.isEmpty
                ? const Center(
                    child: Text(
                      'No states in current automaton.\nAdd states to canvas to inspect matrix.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.surfaceContainerLow,
                        ),
                        border: TableBorder.all(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(16),
                          width: 1.2,
                        ),
                        columns: [
                          const DataColumn(
                            label: Text(
                              'State (q)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          ...alphabet.map(
                            (sym) => DataColumn(
                              label: Center(
                                child: Text(
                                  'σ = "$sym"',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: states.map((st) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (st.isInitial) ...[
                                      const Icon(Icons.arrow_right_alt_rounded,
                                          color: AppColors.primary, size: 18),
                                      const SizedBox(width: 4),
                                    ],
                                    if (st.isFinal) ...[
                                      const Icon(Icons.stars_rounded,
                                          color: AppColors.successBase, size: 18),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      st.label,
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: st.isFinal
                                            ? AppColors.successBase
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...alphabet.map((sym) {
                                final matching = automaton.transitions.where(
                                  (t) =>
                                      t.fromStateId == st.id &&
                                      t.symbol == sym,
                                );
                                final targetLabels = matching
                                    .map((t) =>
                                        automaton.stateMap[t.toStateId]?.label ??
                                        '?')
                                    .toList();

                                return DataCell(
                                  Center(
                                    child: targetLabels.isEmpty
                                        ? const Text(
                                            '∅',
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              targetLabels.join(', '),
                                              style: const TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
