import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../canvas/presentation/widgets/automata_canvas.dart';
import '../../canvas/presentation/widgets/canvas_top_bar.dart';
import '../../canvas/presentation/widgets/presets_sheet.dart';
import '../../canvas/presentation/widgets/transition_matrix_sheet.dart';
import '../../learn/presentation/learn_coach_bar.dart';
import '../../simulation/presentation/widgets/simulation_bottom_sheet.dart';

/// Kinetic Toybox Main Workspace Page
/// Combines the interactive AutomataCanvas, CanvasTopBar,
/// bottom simulation drawer, and mobile/tablet navigation bar.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showSimPanel = false;
  int _activeNavIndex = 0; // 0: Canvas, 1: Simulate, 2: Matrix, 3: Library

  void _onNavTap(int index) {
    setState(() => _activeNavIndex = index);
    switch (index) {
      case 0:
        if (_showSimPanel) {
          setState(() => _showSimPanel = false);
        }
        break;
      case 1:
        setState(() => _showSimPanel = true);
        break;
      case 2:
        TransitionMatrixSheet.show(context);
        break;
      case 3:
        PresetsSheet.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Kinetic Toybox Top Bar ──
            CanvasTopBar(
              isSimOpen: _showSimPanel,
              onToggleSim: () {
                setState(() {
                  _showSimPanel = !_showSimPanel;
                  _activeNavIndex = _showSimPanel ? 1 : 0;
                });
              },
            ),

            const LearnCoachBar(),

            // ── Main Canvas Viewport (Guaranteed visible space) ──
            const Expanded(
              flex: 5,
              child: AutomataCanvas(),
            ),

            // ── Simulation Bottom Sheet (Constrained to prevent squishing canvas) ──
            if (_showSimPanel)
              Expanded(
                flex: 5,
                child: SimulationBottomSheet(
                  onClose: () {
                    setState(() {
                      _showSimPanel = false;
                      _activeNavIndex = 0;
                    });
                  },
                ),
              ),

            // ── Matiks / Canva Style Bottom Navigation Bar ──
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.hub_rounded,
            label: 'Canvas',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.play_circle_fill_rounded,
            label: 'Simulate',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.grid_view_rounded,
            label: 'Matrix',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.folder_open_rounded,
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeNavIndex == index ||
        (index == 1 && _showSimPanel);

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
