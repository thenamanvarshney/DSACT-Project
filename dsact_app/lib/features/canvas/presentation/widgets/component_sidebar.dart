import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';

/// Canva-style floating sidebar with draggable component templates and quick actions.
class ComponentSidebar extends ConsumerWidget {
  const ComponentSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automaton = ref.watch(automatonProvider);
    final canvasView = ref.watch(canvasViewProvider);

    return Container(
      width: 72,
      margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(240),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // ── Add Normal State ──
          _ToolButton(
            icon: Icons.circle_outlined,
            label: 'State',
            tooltip: 'Add Normal State',
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 200 + (automaton.states.length * 80.0 % 600),
                    y: 200 + (automaton.states.length * 60.0 % 400),
                  );
            },
          ),
          const SizedBox(height: 4),

          // ── Add Initial State ──
          _ToolButton(
            icon: Icons.play_circle_outline_rounded,
            label: 'Initial',
            tooltip: 'Add Initial State',
            color: AppColors.stateInitial,
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 150 + (automaton.states.length * 80.0 % 600),
                    y: 200 + (automaton.states.length * 60.0 % 400),
                    isInitial: true,
                  );
            },
          ),
          const SizedBox(height: 4),

          // ── Add Final State ──
          _ToolButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Final',
            tooltip: 'Add Final/Accepting State',
            color: AppColors.stateFinal,
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 250 + (automaton.states.length * 80.0 % 600),
                    y: 200 + (automaton.states.length * 60.0 % 400),
                    isFinal: true,
                  );
            },
          ),
          const _SidebarDivider(),

          // ── Transition Tool ──
          _ToolButton(
            icon: Icons.arrow_right_alt_rounded,
            label: 'Link',
            tooltip: 'Create Transition (or click state)',
            color: AppColors.accentCyan,
            isActive: canvasView.connectingFromStateId != null,
            onTap: () {
              if (canvasView.connectingFromStateId != null) {
                ref.read(canvasViewProvider.notifier).cancelConnecting();
                return;
              }

              if (automaton.states.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Add at least one state before creating a transition.'),
                    backgroundColor: AppColors.accentCoral,
                  ),
                );
                return;
              }

              if (canvasView.selectedStateId != null) {
                ref
                    .read(canvasViewProvider.notifier)
                    .startConnecting(canvasView.selectedStateId!);
              } else {
                _showAddTransitionPicker(context, ref, automaton);
              }
            },
          ),
          const _SidebarDivider(),

          // ── Undo ──
          _ToolButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            tooltip: 'Undo',
            onTap: () => ref.read(automatonProvider.notifier).undo(),
          ),
          const SizedBox(height: 4),

          // ── Redo ──
          _ToolButton(
            icon: Icons.redo_rounded,
            label: 'Redo',
            tooltip: 'Redo',
            onTap: () => ref.read(automatonProvider.notifier).redo(),
          ),
          const _SidebarDivider(),

          // ── Clear All ──
          _ToolButton(
            icon: Icons.delete_sweep_rounded,
            label: 'Clear',
            tooltip: 'Clear Canvas',
            color: AppColors.accentCoral,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Clear Canvas?'),
                  content: const Text(
                    'This will remove all states and transitions.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCoral,
                      ),
                      onPressed: () {
                        ref.read(automatonProvider.notifier).clearAll();
                        ref.read(canvasViewProvider.notifier).clearSelection();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showAddTransitionPicker(
    BuildContext context,
    WidgetRef ref,
    Automaton automaton,
  ) {
    if (automaton.states.isEmpty) return;

    String fromId = automaton.states.first.id;
    String toId = automaton.states.first.id;
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.arrow_right_alt_rounded,
                    color: AppColors.accentCyan, size: 24),
                SizedBox(width: 8),
                Text('Create Transition',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'From State:',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButton<String>(
                    value: fromId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.cardDark,
                    items: automaton.states.map<DropdownMenuItem<String>>((st) {
                      return DropdownMenuItem<String>(
                        value: st.id,
                        child: Text(st.label,
                            style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => fromId = val);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'To State:',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButton<String>(
                    value: toId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.cardDark,
                    items: automaton.states.map<DropdownMenuItem<String>>((st) {
                      return DropdownMenuItem<String>(
                        value: st.id,
                        child: Text(st.label,
                            style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => toId = val);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Input Symbol:',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                  decoration: InputDecoration(
                    hintText: 'e.g. 0, 1, a, or empty for ε',
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: ['0', '1', 'a', 'b', 'ε'].map((sym) {
                    return ActionChip(
                      backgroundColor: AppColors.surfaceDark,
                      label: Text(
                        sym,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        ctrl.text = sym;
                        ctrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: ctrl.text.length),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final symbol = ctrl.text.trim();
                  ref.read(automatonProvider.notifier).addTransition(
                        fromStateId: fromId,
                        toStateId: toId,
                        symbol: symbol,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Add Transition',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color? color;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textSecondary;
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverCtrl.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverCtrl.reverse();
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (context, child) {
              final scale = 1.0 + _hoverCtrl.value * 0.08;
              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? color.withAlpha(51)
                        : (_isHovered ? Colors.white.withAlpha(20) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: widget.isActive
                        ? Border.all(color: color.withAlpha(153), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 22,
                        color: widget.isActive ? color : (_isHovered ? Colors.white : color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                          color: widget.isActive ? color : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withAlpha(15),
    );
  }
}
