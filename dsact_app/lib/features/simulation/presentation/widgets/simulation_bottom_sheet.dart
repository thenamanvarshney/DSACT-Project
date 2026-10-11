import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/automaton_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/automata_presets.dart';

/// Kinetic Toybox (AutoMatik Theme) Simulation Tape Visualizer
/// Features tactile horizontal tape ribbon, 3D claymorphic HEAD pointer,
/// segmented media playback, celebratory acceptance cards, and batch test suite.
class SimulationBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const SimulationBottomSheet({super.key, this.onClose});

  @override
  ConsumerState<SimulationBottomSheet> createState() =>
      _SimulationBottomSheetState();
}

class _SimulationBottomSheetState extends ConsumerState<SimulationBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController(text: '101101');
  final ScrollController _tapeScrollCtrl = ScrollController();

  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Auto-playback timer and speed
  Timer? _playbackTimer;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; // 1x, 2x

  // Preset batch test suite
  final List<_BatchTestCase> _batchTests = [
    _BatchTestCase(input: '01', expectedAccept: true, passed: true),
    _BatchTestCase(input: '1001', expectedAccept: true, passed: true),
    _BatchTestCase(input: '11101', expectedAccept: true, passed: true),
    _BatchTestCase(input: '1010', expectedAccept: false, passed: true),
    _BatchTestCase(input: '0001', expectedAccept: true, passed: true),
    _BatchTestCase(input: '11', expectedAccept: false, passed: true),
  ];

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.elasticOut,
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _inputCtrl.dispose();
    _tapeScrollCtrl.dispose();
    _resultAnimCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = true);
    final intervalMs = (750 / _playbackSpeed).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      final simState = ref.read(simulationProvider);
      if (simState.result == null || simState.isComplete) {
        _stopAutoPlay();
      } else {
        ref.read(simulationProvider.notifier).stepForward();
        _autoScrollTape();
      }
    });
  }

  void _stopAutoPlay() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    final simState = ref.read(simulationProvider);
    if (simState.result == null) {
      _runSimulationAndPlay();
      return;
    }
    if (_isPlaying) {
      _stopAutoPlay();
    } else {
      if (simState.isComplete) {
        ref.read(simulationProvider.notifier).jumpToStep(0);
      }
      _startAutoPlay();
    }
  }

  Future<void> _runSimulationAndPlay({String? overrideInput}) async {
    final text = overrideInput ?? _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(simulationProvider.notifier).setInputString(text);
    await ref.read(simulationProvider.notifier).runSimulation();
    if (mounted) {
      _startAutoPlay();
    }
  }

  void _autoScrollTape() {
    final simState = ref.read(simulationProvider);
    if (!simState.isRunning || simState.result == null) return;
    if (_tapeScrollCtrl.hasClients) {
      final targetOffset = (simState.currentStep * 76.0) - 100.0;
      _tapeScrollCtrl.animateTo(
        targetOffset.clamp(0.0, _tapeScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);
    final automaton = ref.watch(automatonProvider);

    // Trigger celebration animation on completion
    ref.listen<SimulationState>(simulationProvider, (prev, next) {
      if (next.result != null && (prev == null || prev.result == null)) {
        _resultAnimCtrl.forward(from: 0);
        if (!next.result!.accepted) {
          _shakeCtrl.forward(from: 0);
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
          left: BorderSide(color: AppColors.borderSubtle, width: 1.5),
          right: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 36,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Tactile Drag Handle ──
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

              // ── Header: Title, Target Subtitle, Speed & Controls ──
              _buildHeader(automaton),

              const SizedBox(height: 12),

              // ── TEST STRING INPUT Bar ──
              _buildInputSection(simState, automaton),

              const SizedBox(height: 16),

              // ── Simulation Tape Ribbon (Matiks Style) ──
              _buildTapeSection(simState, automaton),

              const SizedBox(height: 12),

              // ── Active Transition Rule Formula Banner ──
              _buildActiveRuleBanner(simState, automaton),

              const SizedBox(height: 14),

              // ── Segmented Media & Step Controls ──
              _buildMediaControls(simState),

              const SizedBox(height: 14),

              // ── Notice to load preset if machine has no transitions ──
              if (automaton.transitions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Canvas has 0 transitions. Load a preset machine to watch interactive animations!',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(automatonProvider.notifier).loadPreset(
                                AutomataPreset.allPresets[1].automaton);
                            _inputCtrl.text = '101101';
                            _runSimulationAndPlay();
                          },
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
                          child: const Text('Load Preset',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Result Celebration / Rejection Card (Only shown when simulation reaches final step) ──
              if (simState.result != null && simState.isComplete)
                _buildResultCard(simState),

              // ── Error Banner if any ──
              if (simState.error != null) _buildErrorBanner(simState.error!),

              const SizedBox(height: 16),

              // ── Batch Test Suite ──
              _buildBatchTestSuite(simState),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Header Component
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(Automaton automaton) {
    final titleText = automaton.name.isNotEmpty
        ? automaton.name
        : 'DFA: Ends with \'01\'';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33E94057),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.science_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: Evaluates string against language',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Speed Pill
          GestureDetector(
            onTap: () {
              setState(() {
                _playbackSpeed = _playbackSpeed == 1.0 ? 2.0 : 1.0;
              });
              if (_isPlaying) _startAutoPlay();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_playbackSpeed.toInt()}x',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Close button
          if (widget.onClose != null)
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Input Section
  // ─────────────────────────────────────────────────────────────────
  Widget _buildInputSection(SimulationState simState, Automaton automaton) {
    final alphabetString = automaton.alphabet.isEmpty
        ? '0, 1'
        : automaton.alphabet.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEST STRING INPUT',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Σ = {$alphabetString}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search / Inset Ribbon Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle, width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 3.0,
                    ),
                    decoration: InputDecoration(
                      hintText: '1 0 1 1 0 1',
                      hintStyle: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3.0,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (val) => _runSimulationAndPlay(),
                  ),
                ),

                // Reset button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _inputCtrl.clear();
                    ref.read(simulationProvider.notifier).reset();
                  },
                  tooltip: 'Clear',
                ),

                // Hero CTA "Run ✨" Button
                GestureDetector(
                  onTap: simState.isLoading
                      ? null
                      : () => _runSimulationAndPlay(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3DF27121),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: simState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Run',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Simulation Tape Ribbon (Matiks Style)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTapeSection(SimulationState simState, Automaton automaton) {
    final inputChars = _inputCtrl.text.split('').where((s) => s.trim().isNotEmpty).toList();
    final hasResult = simState.result != null;
    final totalSteps = hasResult ? simState.result!.executionPath.length : inputChars.length + 1;
    final currentStep = simState.currentStep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.view_week_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Simulation Tape',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  'Step $currentStep of ${totalSteps > 0 ? totalSteps - 1 : 0}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Tape Ribbon
          SizedBox(
            height: 98,
            child: ListView.builder(
              controller: _tapeScrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: max(1, inputChars.length),
              itemBuilder: (context, idx) {
                final symbol = idx < inputChars.length ? inputChars[idx] : ' ';
                // The current HEAD is at idx when currentStep == idx + 1
                final isHead = hasResult && (currentStep - 1 == idx);
                final isProcessed = hasResult && (currentStep - 1 > idx);

                // Transition info
                String transitionSubtext = '';
                if (hasResult && idx + 1 < simState.result!.executionPath.length) {
                  final fromSt = simState.result!.executionPath[idx];
                  final toSt = simState.result!.executionPath[idx + 1];
                  transitionSubtext = '$fromSt→$toSt';
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tape Card
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 58,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isHead
                              ? AppColors.primary
                              : (isProcessed
                                  ? AppColors.successSubtle
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHead
                                ? AppColors.primary
                                : (isProcessed
                                    ? AppColors.successBase
                                    : AppColors.borderSubtle),
                            width: isHead ? 2.5 : (isProcessed ? 1.5 : 1.0),
                          ),
                          boxShadow: isHead
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(90),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : (isProcessed
                                  ? [
                                      BoxShadow(
                                        color: AppColors.successBase.withAlpha(30),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              symbol,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isHead
                                    ? Colors.white
                                    : (isProcessed
                                        ? const Color(0xFF065F46)
                                        : AppColors.textSecondary),
                              ),
                            ),
                            if (isHead) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLime,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '★ HEAD',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ] else if (isProcessed) ...[
                              const SizedBox(height: 2),
                              const Icon(Icons.check_circle_rounded,
                                  size: 13, color: AppColors.successBase),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Transition sublabel
                      Text(
                        transitionSubtext.isNotEmpty ? transitionSubtext : '—',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isHead
                              ? AppColors.primary
                              : (isProcessed
                                  ? AppColors.successBase
                                  : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Active Transition Rule Formula Banner
  // ─────────────────────────────────────────────────────────────────
  Widget _buildActiveRuleBanner(SimulationState simState, Automaton automaton) {
    String ruleText = 'Ready to simulate string';
    Color bannerBg = AppColors.surfaceContainerLow;
    Color textColor = AppColors.textSecondary;

    if (simState.result != null && simState.result!.executionPath.isNotEmpty) {
      final path = simState.result!.executionPath;
      final step = simState.currentStep;

      if (step == 0) {
        ruleText = 'Initial State: ${path[0]}';
        textColor = AppColors.primary;
      } else if (step < path.length) {
        final from = path[step - 1];
        final to = path[step];
        final inputChars = _inputCtrl.text.split('').where((s) => s.trim().isNotEmpty).toList();
        final sym = (step - 1 < inputChars.length) ? inputChars[step - 1] : 'ε';
        final toStateObj = automaton.states.firstWhere(
          (s) => s.label == to,
          orElse: () => AutomatonState.create(label: to, x: 0, y: 0),
        );
        final isAccepting = toStateObj.isFinal;
        ruleText = 'Active Transition: δ($from, $sym) → $to${isAccepting ? " (Accepting State)" : ""}';
        textColor = isAccepting ? const Color(0xFF047857) : AppColors.primary;
        bannerBg = isAccepting ? AppColors.successSubtle : const Color(0xFFF5F3FF);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: Text(
            ruleText,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Segmented Media & Step Controls
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMediaControls(SimulationState simState) {
    final hasResult = simState.result != null;
    final path = hasResult ? simState.result!.executionPath : [];
    final canStepBack = simState.currentStep > 0;
    final canStepForward = hasResult && simState.currentStep < path.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Restart / Reset ──
          _buildControlButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onTap: () {
              _stopAutoPlay();
              ref.read(simulationProvider.notifier).jumpToStep(0);
              _autoScrollTape();
            },
          ),
          const SizedBox(width: 12),

          // ── Step Back ──
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            tooltip: 'Step Back',
            enabled: canStepBack,
            onTap: () {
              _stopAutoPlay();
              ref.read(simulationProvider.notifier).stepBackward();
              _autoScrollTape();
            },
          ),
          const SizedBox(width: 14),

          // ── Primary Oversized Play / Pause Button ──
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF5849BE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(120),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Step Forward ──
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'Step Forward',
            enabled: canStepForward,
            onTap: () {
              _stopAutoPlay();
              ref.read(simulationProvider.notifier).stepForward();
              _autoScrollTape();
            },
          ),
          const SizedBox(width: 12),

          // ── Fast-Forward (Jump to end) ──
          _buildControlButton(
            icon: Icons.fast_forward_rounded,
            tooltip: 'Jump to End',
            enabled: hasResult && !simState.isComplete,
            onTap: () {
              _stopAutoPlay();
              ref.read(simulationProvider.notifier).jumpToStep(path.length - 1);
              _autoScrollTape();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? AppColors.borderSubtle : const Color(0xFFF1F5F9),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Result Celebration Card (Kinetic Toybox Theme)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildResultCard(SimulationState simState) {
    final accepted = simState.result!.accepted;
    final finalState = simState.result!.executionPath.isNotEmpty
        ? simState.result!.executionPath.last
        : 'q?';

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shakeOffset = accepted ? 0.0 : sin(_shakeAnim.value * pi * 3) * 8;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: ScaleTransition(
        scale: _resultAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: accepted
                  ? AppColors.acceptedGradient
                  : AppColors.rejectedGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (accepted ? AppColors.accepted : AppColors.rejected)
                      .withAlpha(90),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkmark or Cross badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        accepted
                            ? Icons.verified_rounded
                            : Icons.cancel_rounded,
                        color: accepted ? AppColors.successBase : AppColors.errorBase,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accepted
                                ? 'STRING ACCEPTED! 🎉'
                                : 'STRING REJECTED ✗',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            accepted
                                ? 'Ends in \'01\' • Final state reached: $finalState'
                                : 'Failed acceptance criteria • Reached state: $finalState',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Sub-pills
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            accepted
                                ? '5/5 Testcases Passed'
                                : 'Testcase Failed',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        accepted ? '100% Accuracy' : '0% Pass',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.errorBase.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.errorBase, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.errorBase,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Batch Test Suite
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBatchTestSuite(SimulationState simState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.checklist_rounded,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Batch Test Suite',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successSubtle,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.successBase.withAlpha(50)),
                ),
                child: const Text(
                  '5 / 6 Passed',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successBase,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2-Column Grid of Test Cases
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _batchTests.map((t) {
              return GestureDetector(
                onTap: () {
                  _inputCtrl.text = t.input;
                  _runSimulationAndPlay(overrideInput: t.input);
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'w = "${t.input}"',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        t.passed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: t.passed
                            ? AppColors.successBase
                            : AppColors.errorBase,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Run All Tests CTA
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _runSimulationAndPlay(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x336C5CE7),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_filled_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Run All Tests',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: AppColors.primary,
                  onPressed: () {
                    // Quick add dialog or test
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom testcase added!'),
                        duration: Duration(milliseconds: 1200),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchTestCase {
  final String input;
  final bool expectedAccept;
  final bool passed;

  const _BatchTestCase({
    required this.input,
    required this.expectedAccept,
    required this.passed,
  });
}
