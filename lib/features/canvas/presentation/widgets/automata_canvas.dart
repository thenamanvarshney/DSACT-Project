import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';
import 'state_inspector_sheet.dart';

/// Kinetic Toybox Automata Canvas — tactile, claymorphic nodes, dot-matrix grid,
/// smooth Bézier transitions, floating quick inspector, and Canva-style bottom dock.
class AutomataCanvas extends ConsumerStatefulWidget {
  const AutomataCanvas({super.key});

  @override
  ConsumerState<AutomataCanvas> createState() => _AutomataCanvasState();
}

class _AutomataCanvasState extends ConsumerState<AutomataCanvas>
    with TickerProviderStateMixin {
  final TransformationController _transformCtrl = TransformationController();
  String? _draggingStateId;
  bool _didDragPushUndo = false;

  // Pointer tracking for transition connection
  Offset? _connectingLineEnd;

  // Glow animation for active simulation state & transitions
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  static const double stateRadius = 36.0; // 72px diameter

  @override
  Widget build(BuildContext context) {
    final automaton = ref.watch(automatonProvider);
    final canvasView = ref.watch(canvasViewProvider);
    final simState = ref.watch(simulationProvider);

    final isConnecting = canvasView.connectingFromStateId != null;
    final isDragging = _draggingStateId != null;

    return Container(
      color: AppColors.canvasBg,
      child: Stack(
        children: [
          // ── Main interactive canvas viewport ──
          LayoutBuilder(builder: (context, constraints) {
            return InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.35,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(2500),
              panEnabled: !isDragging,
              scaleEnabled: !isDragging,
              child: MouseRegion(
                cursor: isConnecting
                    ? SystemMouseCursors.click
                    : (isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.basic),
                onHover: (e) {
                  if (isConnecting) {
                    setState(() {
                      _connectingLineEnd =
                          _transformCtrl.toScene(e.localPosition);
                    });
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _onCanvasTap(details, automaton, canvasView),
                  onPanUpdate: (details) {
                    if (isConnecting) {
                      setState(() {
                        _connectingLineEnd =
                            _transformCtrl.toScene(details.localPosition);
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(4000, 4000),
                        painter: _AutomatonCanvasPainter(
                          automaton: automaton,
                          canvasView: canvasView,
                          simState: simState,
                          glowValue: _glowAnim.value,
                          connectingLineEnd: _connectingLineEnd,
                          connectingFromId: canvasView.connectingFromStateId,
                        ),
                        child: _buildGestureOverlay(
                            automaton, canvasView, simState),
                      );
                    },
                  ),
                ),
              ),
            );
          }),

          // ── Floating Connecting Mode Banner ──
          if (isConnecting) _buildConnectingBanner(automaton, canvasView),

          // ── Canva-Style Floating Bottom Dock (Responsive & Scroll-Safe) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildFloatingDock(automaton, canvasView),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds gesture overlays over each state node and the selected action pill.
  Widget _buildGestureOverlay(
    Automaton automaton,
    CanvasViewState canvasView,
    SimulationState simState,
  ) {
    return SizedBox(
      width: 4000,
      height: 4000,
      child: Stack(
        children: [
          // State nodes gesture detectors
          ...automaton.states.map((st) {
            final isConnecting = canvasView.connectingFromStateId != null;
            const touchRadius = stateRadius + 18;

            return Positioned(
              left: st.x - touchRadius,
              top: st.y - touchRadius,
              width: touchRadius * 2,
              height: touchRadius * 2,
              child: MouseRegion(
                cursor: isConnecting
                    ? SystemMouseCursors.click
                    : (_draggingStateId == st.id
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab),
                child: Listener(
                  onPointerDown: (_) {
                    if (!isConnecting) {
                      setState(() => _draggingStateId = st.id);
                    }
                  },
                  onPointerUp: (_) {
                    if (_draggingStateId != null) {
                      setState(() => _draggingStateId = null);
                    }
                  },
                  onPointerCancel: (_) {
                    if (_draggingStateId != null) {
                      setState(() => _draggingStateId = null);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onStateTap(st, canvasView),
                    onDoubleTap: () => StateInspectorSheet.show(context, st),
                    onSecondaryTap: () => StateInspectorSheet.show(context, st),
                    onLongPress: () => _onStateLongPress(st),
                    onPanStart: (d) => _onStateDragStart(st, d),
                    onPanUpdate: (d) => _onStateDragUpdate(st, d),
                    onPanEnd: (_) => _onStateDragEnd(),
                    onPanCancel: () => _onStateDragEnd(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            );
          }),

          // Floating Quick Action Squircle above currently selected state
          if (canvasView.selectedStateId != null &&
              canvasView.connectingFromStateId == null)
            _buildSelectedStateActionPill(automaton, canvasView),
        ],
      ),
    );
  }

  /// Canva-Style Floating Quick Action Pill above selected node
  Widget _buildSelectedStateActionPill(
    Automaton automaton,
    CanvasViewState canvasView,
  ) {
    final selectedState = automaton.stateMap[canvasView.selectedStateId];
    if (selectedState == null) return const SizedBox.shrink();

    return Positioned(
      left: selectedState.x - 90,
      top: selectedState.y - stateRadius - 62,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inspect / Properties (Star)
            _QuickActionIcon(
              icon: Icons.star_rounded,
              tooltip: 'Inspect State & Rules',
              color: AppColors.primary,
              onTap: () => StateInspectorSheet.show(context, selectedState),
            ),
            const SizedBox(width: 4),

            // Link / Connect (δ)
            _QuickActionIcon(
              icon: Icons.alt_route_rounded,
              tooltip: 'Create Transition from ${selectedState.label}',
              color: AppColors.accentSecondary,
              onTap: () {
                ref
                    .read(canvasViewProvider.notifier)
                    .startConnecting(selectedState.id);
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(width: 4),

            // Toggle Final / Accepting (Target/Check)
            _QuickActionIcon(
              icon: selectedState.isFinal
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              tooltip: selectedState.isFinal
                  ? 'Remove Final State'
                  : 'Set as Final/Accepting State',
              color: AppColors.successBase,
              onTap: () {
                ref
                    .read(automatonProvider.notifier)
                    .toggleFinal(selectedState.id);
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(width: 4),

            // Delete
            _QuickActionIcon(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete State',
              color: AppColors.errorBase,
              onTap: () {
                ref
                    .read(automatonProvider.notifier)
                    .removeState(selectedState.id);
                ref.read(canvasViewProvider.notifier).clearSelection();
                HapticFeedback.mediumImpact();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Canva-style Floating Dock (Bottom Center of Canvas)
  Widget _buildFloatingDock(
    Automaton automaton,
    CanvasViewState canvasView,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Start State Pill ──
          _DockPillButton(
            icon: Icons.play_arrow_rounded,
            label: 'Start',
            pillColor: const Color(0xFFEDE9FE),
            textColor: AppColors.primary,
            iconColor: AppColors.primary,
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 200 + (automaton.states.length * 80.0 % 600),
                    y: 220 + (automaton.states.length * 60.0 % 400),
                    isInitial: true,
                  );
            },
          ),
          const SizedBox(width: 5),

          // ── Normal State Pill ──
          _DockPillButton(
            icon: Icons.circle_outlined,
            label: 'State',
            pillColor: AppColors.surfaceContainerLow,
            textColor: AppColors.textPrimary,
            iconColor: AppColors.textSecondary,
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 250 + (automaton.states.length * 80.0 % 600),
                    y: 220 + (automaton.states.length * 60.0 % 400),
                  );
            },
          ),
          const SizedBox(width: 5),

          // ── Final State Pill ──
          _DockPillButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Final',
            pillColor: const Color(0xFFFFECEB),
            textColor: AppColors.errorBase,
            iconColor: AppColors.errorBase,
            onTap: () {
              ref.read(automatonProvider.notifier).addState(
                    x: 300 + (automaton.states.length * 80.0 % 600),
                    y: 220 + (automaton.states.length * 60.0 % 400),
                    isFinal: true,
                  );
            },
          ),
          const SizedBox(width: 5),

          // ── Transition Link Pill (δ) ──
          _DockPillButton(
            icon: Icons.alt_route_rounded,
            label: 'δ Link',
            pillColor: const Color(0xFFE0F2FE),
            textColor: const Color(0xFF0284C7),
            iconColor: const Color(0xFF0284C7),
            isActive: canvasView.connectingFromStateId != null,
            onTap: () {
              if (canvasView.connectingFromStateId != null) {
                ref.read(canvasViewProvider.notifier).cancelConnecting();
                return;
              }
              if (automaton.states.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add at least one state first.'),
                    backgroundColor: AppColors.errorBase,
                  ),
                );
                return;
              }
              if (canvasView.selectedStateId != null) {
                ref
                    .read(canvasViewProvider.notifier)
                    .startConnecting(canvasView.selectedStateId!);
              } else {
                ref
                    .read(canvasViewProvider.notifier)
                    .startConnecting(automaton.states.first.id);
              }
            },
          ),
          const SizedBox(width: 6),

          // ── Quick Alphabet Trigger (Σ) ──
          GestureDetector(
            onTap: () {
              _showAlphabetDialog();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.indigoGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Σ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlphabetDialog() {
    final automaton = ref.read(automatonProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('Input Alphabet (Σ)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recognized symbols derived from existing transition rules:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: (automaton.alphabet.isEmpty
                      ? ['0', '1']
                      : automaton.alphabet)
                  .map((sym) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    sym,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Banner displayed at top when in transition connection mode
  Widget _buildConnectingBanner(
    Automaton automaton,
    CanvasViewState canvasView,
  ) {
    final fromState = automaton.stateMap[canvasView.connectingFromStateId];
    final fromLabel = fromState?.label ?? '?';

    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accentSecondary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentSecondary.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alt_route_rounded,
                  color: AppColors.accentSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Linking from "$fromLabel" ➔ Tap target state or itself',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  ref.read(canvasViewProvider.notifier).cancelConnecting();
                  setState(() => _connectingLineEnd = null);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorBase.withAlpha(100)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.errorBase,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCanvasTap(
      TapUpDetails details, Automaton automaton, CanvasViewState cv) {
    if (cv.connectingFromStateId != null) {
      ref.read(canvasViewProvider.notifier).cancelConnecting();
      setState(() => _connectingLineEnd = null);
      return;
    }

    final tapPos = _transformCtrl.toScene(details.localPosition);
    for (final t in automaton.transitions) {
      if (_isTransitionHit(t, automaton, tapPos)) {
        ref.read(canvasViewProvider.notifier).selectTransition(t.id);
        _showEditSymbolDialog(t);
        return;
      }
    }

    ref.read(canvasViewProvider.notifier).clearSelection();
  }

  bool _isTransitionHit(
      AutomatonTransition t, Automaton automaton, Offset tapPos) {
    final sMap = automaton.stateMap;
    final from = sMap[t.fromStateId];
    final to = sMap[t.toStateId];
    if (from == null || to == null) return false;

    if (t.isSelfLoop) {
      final loopCenter = Offset(from.x, from.y - stateRadius - 28);
      return (loopCenter - tapPos).distance < 28;
    }

    final mid = Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
    return (mid - tapPos).distance < 30;
  }

  void _onStateTap(AutomatonState st, CanvasViewState cv) {
    if (cv.connectingFromStateId != null) {
      final fromId = cv.connectingFromStateId!;
      ref.read(canvasViewProvider.notifier).cancelConnecting();
      setState(() => _connectingLineEnd = null);
      _showAddTransitionDialog(fromId, st.id);
      return;
    }

    ref.read(canvasViewProvider.notifier).selectState(st.id);
    HapticFeedback.selectionClick();
  }

  void _onStateLongPress(AutomatonState st) {
    ref.read(canvasViewProvider.notifier).startConnecting(st.id);
    HapticFeedback.mediumImpact();
  }

  void _onStateDragStart(AutomatonState st, DragStartDetails d) {
    setState(() {
      _draggingStateId = st.id;
      _didDragPushUndo = false;
    });
  }

  void _onStateDragUpdate(AutomatonState st, DragUpdateDetails d) {
    if (_draggingStateId != st.id) return;
    if (!_didDragPushUndo) {
      ref.read(automatonProvider.notifier).beginDrag();
      _didDragPushUndo = true;
    }

    final matrix = _transformCtrl.value;
    final scale = matrix.getMaxScaleOnAxis();

    final current = ref.read(automatonProvider).stateMap[st.id];
    if (current == null) return;

    ref.read(automatonProvider.notifier).moveState(
          st.id,
          (current.x + d.delta.dx / scale).clamp(60.0, 3940.0),
          (current.y + d.delta.dy / scale).clamp(60.0, 3940.0),
        );
  }

  void _onStateDragEnd() {
    setState(() {
      _draggingStateId = null;
      _didDragPushUndo = false;
    });
  }

  void _showAddTransitionDialog(String fromId, String toId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final sMap = ref.read(automatonProvider).stateMap;
        final fromLabel = sMap[fromId]?.label ?? '?';
        final toLabel = sMap[toId]?.label ?? '?';

        void submit() {
          final symbol = ctrl.text.trim();
          ref.read(automatonProvider.notifier).addTransition(
                fromStateId: fromId,
                toStateId: toId,
                symbol: symbol,
              );
          Navigator.pop(ctx);
        }

        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_right_alt_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transition: $fromLabel ➔ $toLabel',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter symbol to trigger this transition (or ε for epsilon):',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. 0, 1, a, or empty for ε',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick symbols:',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: ['0', '1', 'a', 'b', 'ε'].map((sym) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceContainerLow,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    label: Text(
                      sym,
                      style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ctrl.text = sym == 'ε' ? 'ε' : sym;
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
              onPressed: submit,
              child: const Text('Add Rule'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSymbolDialog(AutomatonTransition t) {
    final ctrl = TextEditingController(text: t.symbol);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Transition Symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(
                  fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Symbol (e.g. 0, 1, a, ε)',
              ),
              onSubmitted: (val) {
                ref
                    .read(automatonProvider.notifier)
                    .updateTransitionSymbol(t.id, val.trim());
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['0', '1', 'a', 'b', 'ε'].map((sym) {
                return ActionChip(
                  label: Text(sym),
                  onPressed: () => ctrl.text = sym,
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(automatonProvider.notifier).removeTransition(t.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorBase)),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(automatonProvider.notifier)
                  .updateTransitionSymbol(t.id, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _DockPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color pillColor;
  final Color textColor;
  final Color iconColor;
  final bool isActive;
  final VoidCallback onTap;

  const _DockPillButton({
    required this.icon,
    required this.label,
    required this.pillColor,
    required this.textColor,
    required this.iconColor,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : pillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: isActive ? Colors.white : textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Custom Painter — Kinetic Toybox Dot Grid, Claymorphic Nodes, Béziers
// ─────────────────────────────────────────────────────────────────────

class _AutomatonCanvasPainter extends CustomPainter {
  final Automaton automaton;
  final CanvasViewState canvasView;
  final SimulationState simState;
  final double glowValue;
  final Offset? connectingLineEnd;
  final String? connectingFromId;

  _AutomatonCanvasPainter({
    required this.automaton,
    required this.canvasView,
    required this.simState,
    required this.glowValue,
    this.connectingLineEnd,
    this.connectingFromId,
  });

  static const double R = _AutomataCanvasState.stateRadius;

  @override
  void paint(Canvas canvas, Size size) {
    _drawDotGrid(canvas, size);
    _drawTransitions(canvas);
    _drawStates(canvas);
    _drawConnectingLine(canvas);
  }

  /// Subtle pastel dot grid (spacing: 24px)
  void _drawDotGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = AppColors.gridDot;
    const spacing = 24.0;
    const dotRadius = 1.3;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  void _drawStates(Canvas canvas) {
    for (final state in automaton.states) {
      final center = Offset(state.x, state.y);
      final isSelected = canvasView.selectedStateId == state.id;
      final isActive = simState.activeStateLabel == state.label;
      final isConnectingSource = canvasView.connectingFromStateId == state.id;

      final isSimulating = simState.isRunning && simState.result != null;

      // ─ 1. Active Simulation Glow / Halo (Neon Lime / Indigo) ─
      if (isActive) {
        final neonPaint = Paint()
          ..color = AppColors.accentLime.withAlpha((glowValue * 190).round())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * glowValue);
        canvas.drawCircle(center, R + 14, neonPaint);

        final ringPaint = Paint()
          ..color = AppColors.primary.withAlpha(120)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(center, R + 6, ringPaint);
      }

      // ─ 2. Selection Ring ─
      if (isSelected || isConnectingSource) {
        final selRing = Paint()
          ..color = (isConnectingSource
                  ? AppColors.accentSecondary
                  : AppColors.primary)
              .withAlpha(120)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(center, R + 7, selRing);
      }

      // ─ 3. Soft Drop Shadow under node (Claymorphism) ─
      final shadowPaint = Paint()
        ..color = const Color(0x18000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(center.dx, center.dy + 4), R, shadowPaint);

      // ─ 4. Node Circle Base Fill (Crisp Pure White or Active Soft Tint) ─
      final fillPaint = Paint()
        ..color = isActive
            ? (state.isFinal ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF))
            : (isSimulating ? Colors.white.withAlpha(220) : Colors.white);
      canvas.drawCircle(center, R, fillPaint);

      // ─ 5. Node Border (3.5px solid Electric Indigo, Emerald, or Neon Lime) ─
      final borderPaint = Paint()
        ..color = isActive
            ? AppColors.accentLime
            : (state.isFinal ? AppColors.successBase : AppColors.primary)
                .withAlpha(isSimulating && !isActive ? 130 : 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 4.5 : 3.5;
      canvas.drawCircle(center, R, borderPaint);

      // Floating "ACTIVE HEAD" Badge during simulation
      if (isActive) {
        _drawPillBadge(
          canvas,
          state.isFinal ? '★ ACTIVE [F]' : '★ ACTIVE HEAD',
          Offset(center.dx, center.dy - R - 16),
          badgeColor: AppColors.primary,
          textColor: Colors.white,
        );
      }

      // ─ 6. Accepting State: Double Concentric Ring (56px inner) ─
      if (state.isFinal) {
        final innerRing = Paint()
          ..color = AppColors.successBase.withAlpha(isActive ? 255 : 160)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, R - 6, innerRing);

        // Green "ACCEPT" pill badge beneath node
        _drawPillBadge(
          canvas,
          'ACCEPT',
          Offset(center.dx, center.dy + R + 14),
          badgeColor: const Color(0xFFD1FAE5),
          textColor: const Color(0xFF065F46),
        );
      }

      // ─ 7. Initial / Start State: Entry Arrow on left + "start" badge ─
      if (state.isInitial) {
        _drawInitialEntry(canvas, center);
      }

      // ─ 8. State Label Text (e.g. q0, q1, q2) ─
      final tp = TextPainter(
        text: TextSpan(
          text: state.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }
  }

  /// Inbound start arrow + cute "start" badge
  void _drawInitialEntry(Canvas canvas, Offset center) {
    final arrowPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final startX = center.dx - R - 36;
    final endX = center.dx - R - 2;
    canvas.drawLine(Offset(startX, center.dy), Offset(endX, center.dy), arrowPaint);

    // Arrowhead tip
    final path = Path()
      ..moveTo(endX, center.dy)
      ..lineTo(endX - 9, center.dy - 6)
      ..lineTo(endX - 9, center.dy + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);

    // Cute "start" pill badge
    _drawPillBadge(
      canvas,
      'start',
      Offset(startX - 18, center.dy),
      badgeColor: AppColors.primary,
      textColor: Colors.white,
    );
  }

  void _drawPillBadge(
    Canvas canvas,
    String text,
    Offset center, {
    required Color badgeColor,
    required Color textColor,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: tp.width + 14,
        height: tp.height + 6,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(rect, Paint()..color = badgeColor);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawTransitions(Canvas canvas) {
    final sMap = automaton.stateMap;

    final pairMap = <String, List<AutomatonTransition>>{};
    for (final t in automaton.transitions) {
      final key = _pairKey(t.fromStateId, t.toStateId);
      pairMap.putIfAbsent(key, () => []).add(t);
    }

    for (final t in automaton.transitions) {
      final from = sMap[t.fromStateId];
      final to = sMap[t.toStateId];
      if (from == null || to == null) continue;

      final isSelected = canvasView.selectedTransitionId == t.id;
      final isActiveTransition = _isTransitionActive(t, from, to);

      Color lineColor = AppColors.primary;
      if (isActiveTransition) lineColor = AppColors.accentLime;
      if (isSelected) lineColor = AppColors.accentSecondary;

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = isActiveTransition ? 3.5 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (t.isSelfLoop) {
        _drawSelfLoop(canvas, from, t, paint, lineColor, isActiveTransition);
      } else {
        final pairKey = _pairKey(t.fromStateId, t.toStateId);
        final siblings = pairMap[pairKey] ?? [t];
        final idx = siblings.indexOf(t);
        _drawCurvedTransition(
          canvas,
          from,
          to,
          t,
          paint,
          lineColor,
          idx,
          siblings.length,
          isActiveTransition,
        );
      }
    }
  }

  String _pairKey(String a, String b) {
    return a.compareTo(b) <= 0 ? '$a::$b' : '$b::$a';
  }

  bool _isTransitionActive(
      AutomatonTransition t, AutomatonState from, AutomatonState to) {
    if (!simState.isRunning || simState.result == null) return false;
    final path = simState.result!.executionPath;
    final step = simState.currentStep;
    if (step <= 0 || step >= path.length) return false;
    if (path[step - 1] != from.label || path[step] != to.label) return false;

    final input = simState.inputString;
    final charIdx = step - 1;
    if (charIdx >= 0 && charIdx < input.length) {
      final sym = input[charIdx];
      if (t.symbol != sym && !t.isEpsilon) return false;
    }
    return true;
  }

  void _drawSelfLoop(
    Canvas canvas,
    AutomatonState state,
    AutomatonTransition t,
    Paint paint,
    Color arrowColor,
    bool isActive,
  ) {
    final center = Offset(state.x, state.y);
    final loopRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - R - 22),
      width: 40,
      height: 36,
    );

    if (isActive) {
      final glowPaint = Paint()
        ..color = AppColors.accentLime.withAlpha((glowValue * 180).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawOval(loopRect, glowPaint);
    }

    canvas.drawOval(loopRect, paint);

    _drawArrowhead(
      canvas,
      Offset(loopRect.right - 5, loopRect.bottom - 4),
      Offset(loopRect.right - 1, loopRect.bottom + 2),
      arrowColor,
    );

    final label = t.symbol.isEmpty ? 'ε' : t.symbol;
    _drawSymbolPill(canvas, label, Offset(center.dx, center.dy - R - 48));
  }

  void _drawCurvedTransition(
    Canvas canvas,
    AutomatonState from,
    AutomatonState to,
    AutomatonTransition t,
    Paint paint,
    Color arrowColor,
    int idx,
    int totalSiblings,
    bool isActive,
  ) {
    final p0 = Offset(from.x, from.y);
    final p2 = Offset(to.x, to.y);

    final dx = p2.dx - p0.dx;
    final dy = p2.dy - p0.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final hasReverse = automaton.transitions.any(
        (other) => other.fromStateId == to.id && other.toStateId == from.id);

    final offset = (idx - (totalSiblings - 1) / 2) * 26;
    final baseCurve = hasReverse ? 32.0 : (totalSiblings > 1 ? 26.0 : 0.0);
    final curveAmount = baseCurve + offset + (t.curvature * 80.0);

    final nx = -dy / dist;
    final ny = dx / dist;

    final flipMult = (hasReverse && from.id.compareTo(to.id) > 0) ? -1.0 : 1.0;

    final mid = Offset(
      (p0.dx + p2.dx) / 2 + nx * curveAmount * flipMult,
      (p0.dy + p2.dy) / 2 + ny * curveAmount * flipMult,
    );

    final startAngle = atan2(mid.dy - p0.dy, mid.dx - p0.dx);
    final endAngle = atan2(mid.dy - p2.dy, mid.dx - p2.dx);
    final startPt =
        Offset(p0.dx + cos(startAngle) * R, p0.dy + sin(startAngle) * R);
    final endPt =
        Offset(p2.dx + cos(endAngle) * R, p2.dy + sin(endAngle) * R);

    final path = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, endPt.dx, endPt.dy);

    if (isActive) {
      final glowPaint = Paint()
        ..color = AppColors.accentLime.withAlpha((glowValue * 190).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, paint);

    // Arrowhead tip
    final arrowDir = atan2(endPt.dy - mid.dy, endPt.dx - mid.dx);
    _drawArrowheadAtAngle(canvas, endPt, arrowDir, arrowColor);

    // Transition symbol pill centered on the Bézier arc
    final label = t.symbol.isEmpty ? 'ε' : t.symbol;
    _drawSymbolPill(canvas, label, Offset(mid.dx, mid.dy - 12));
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    _drawArrowheadAtAngle(canvas, to, angle, color);
  }

  void _drawArrowheadAtAngle(
      Canvas canvas, Offset tip, double angle, Color color) {
    const len = 11.0;
    const spread = 0.45;
    final p1 = Offset(
      tip.dx - len * cos(angle - spread),
      tip.dy - len * sin(angle - spread),
    );
    final p2 = Offset(
      tip.dx - len * cos(angle + spread),
      tip.dy - len * sin(angle + spread),
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Floating tactile symbol pill (Matiks/Canva style)
  void _drawSymbolPill(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'JetBrains Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: pos,
        width: tp.width + 18,
        height: tp.height + 8,
      ),
      const Radius.circular(8),
    );

    // Drop shadow
    canvas.drawRRect(
      bgRect.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x10000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Pure white claymorphic pill fill
    canvas.drawRRect(bgRect, Paint()..color = Colors.white);

    // Border
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = AppColors.borderSubtle
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawConnectingLine(Canvas canvas) {
    if (connectingFromId == null || connectingLineEnd == null) return;
    final from = automaton.stateMap[connectingFromId!];
    if (from == null) return;

    final paint = Paint()
      ..color = AppColors.accentSecondary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(from.x, from.y);
    final end = connectingLineEnd!;

    canvas.drawLine(start, end, paint);
    _drawArrowhead(canvas, start, end, AppColors.accentSecondary);
  }

  @override
  bool shouldRepaint(covariant _AutomatonCanvasPainter oldDelegate) => true;
}
