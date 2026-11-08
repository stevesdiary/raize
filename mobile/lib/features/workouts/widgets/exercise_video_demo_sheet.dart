import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/workout_models.dart';

/// Interactive modal sheet providing biomechanical video demonstrations,
/// multi-angle kinematics, rep tempo pacing, and form cues for an exercise.
class ExerciseVideoDemoSheet extends StatefulWidget {
  final Exercise exercise;
  final bool autoPlayAnimation;

  const ExerciseVideoDemoSheet({
    super.key,
    required this.exercise,
    this.autoPlayAnimation = true,
  });

  static Future<void> show(
    BuildContext context,
    Exercise exercise, {
    bool autoPlay = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseVideoDemoSheet(
        exercise: exercise,
        autoPlayAnimation: autoPlay,
      ),
    );
  }

  @override
  State<ExerciseVideoDemoSheet> createState() => _ExerciseVideoDemoSheetState();
}

class _ExerciseVideoDemoSheetState extends State<ExerciseVideoDemoSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late bool _isPlaying;
  double _playbackSpeed = 1.0;
  int _selectedAngleIndex = 0; // 0: 45° Oblique, 1: Frontal, 2: Lateral, 3: Top-Down, -1: Custom Orbit
  int _selectedTab = 0; // 0: Biomechanics & 3D Rig, 1: Form Cues, 2: Safeguards
  int _displayMode = 0; // 0: 3D HUMAN RIG (R2 ASSET), 1: CLOUD VIDEO STREAM

  double _yawAngle = 0.52; // Horizontal orbital rotation
  double _pitchAngle = 0.22; // Vertical elevation angle

  final List<String> _cameraAngles = ['45° OBLIQUE', 'FRONTAL PLANE', 'LATERAL SIDE', 'TOP-DOWN'];

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlayAnimation;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Standard 4-second rep cadence
    );
    if (widget.autoPlayAnimation) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _animController.stop();
        _isPlaying = false;
      } else {
        _animController.repeat();
        _isPlaying = true;
      }
    });
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 0.5;
        _animController.duration = const Duration(milliseconds: 8000);
      } else if (_playbackSpeed == 0.5) {
        _playbackSpeed = 1.5;
        _animController.duration = const Duration(milliseconds: 2666);
      } else {
        _playbackSpeed = 1.0;
        _animController.duration = const Duration(milliseconds: 4000);
      }
      if (_isPlaying) {
        _animController.repeat();
      }
    });
  }

  void _setCameraAnglePreset(int index) {
    setState(() {
      _selectedAngleIndex = index;
      switch (index) {
        case 0:
          _yawAngle = 0.52;
          _pitchAngle = 0.22;
          break;
        case 1:
          _yawAngle = 0.0;
          _pitchAngle = 0.12;
          break;
        case 2:
          _yawAngle = math.pi / 2;
          _pitchAngle = 0.08;
          break;
        case 3:
          _yawAngle = 0.0;
          _pitchAngle = 1.25;
          break;
      }
    });
  }

  String _getRepPhase(double progress) {
    if (progress < 0.60) {
      return 'ECCENTRIC (DESCENT • 3s)';
    } else if (progress < 0.75) {
      return 'STRETCH / ISOMETRIC PAUSE (1s)';
    } else {
      return 'CONCENTRIC (EXPLOSIVE DRIVE • 1s)';
    }
  }

  Color _getPhaseColor(double progress) {
    if (progress < 0.60) {
      return AppColors.amber;
    } else if (progress < 0.75) {
      return AppColors.kineticIndigo;
    } else {
      return AppColors.neonEmerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exercise = widget.exercise;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Drag Handle & Header Bar
          _buildHeaderBar(context),

          // 2. Main Scrollable Demonstration Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3D Rig / Video Stream Mode Selector
                  _buildModeSwitcher(),
                  const SizedBox(height: 12),

                  // Kinematic Video Demonstration & 3D Rig Player
                  _buildVideoPlayerCanvas(),
                  const SizedBox(height: 14),

                  // Player Transport & View Angle Controls
                  _buildTransportControls(),
                  const SizedBox(height: 10),

                  // Camera Orbit Preset Chips & Reset
                  if (_displayMode == 0) ...[
                    _buildCameraAngleChips(),
                    const SizedBox(height: 14),
                  ] else ...[
                    const SizedBox(height: 8),
                  ],

                  // Segmented Detail Tabs
                  _buildSegmentedTabSelector(),
                  const SizedBox(height: 18),

                  // Tab Content View
                  if (_selectedTab == 0) _buildMechanicsTab(exercise),
                  if (_selectedTab == 1) _buildFormCuesTab(exercise),
                  if (_selectedTab == 2) _buildSafeguardsTab(exercise),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Drag Notch
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Return / Dismiss Button
              Tooltip(
                message: 'Close Demonstration',
                child: InkWell(
                  key: const Key('close_video_demo_button'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.cardElevated,
                      border: Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.neonEmerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.neonEmerald.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: colors.neonEmerald),
                    const SizedBox(width: 4),
                    Text(
                      'AI FORM VETTED',
                      style: TextStyle(
                        color: colors.neonEmerald,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sub-header Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '4K KINEMATIC DEMONSTRATION',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.exercise.equipment.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('mode_toggle_3d_rig'),
              onTap: () => setState(() => _displayMode = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _displayMode == 0 ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_in_ar_rounded,
                      size: 14,
                      color: _displayMode == 0 ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '3D HUMAN RIG',
                      style: TextStyle(
                        color: _displayMode == 0 ? Colors.white : colors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('mode_toggle_cloud_stream'),
              onTap: () => setState(() => _displayMode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _displayMode == 1 ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_sync_rounded,
                      size: 14,
                      color: _displayMode == 1 ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CLOUD VIDEO STREAM',
                      style: TextStyle(
                        color: _displayMode == 1 ? Colors.white : colors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerCanvas() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _animController.value;
        final phaseLabel = _getRepPhase(progress);
        final phaseColor = _getPhaseColor(progress);

        if (_displayMode == 0) {
          return _build3dHumanRigCanvas(progress, phaseLabel, phaseColor);
        } else {
          return _buildCloudVideoStreamCanvas(progress, phaseLabel, phaseColor);
        }
      },
    );
  }

  Widget _build3dHumanRigCanvas(double progress, String phaseLabel, Color phaseColor) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF070B12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withAlpha(colors.isDark ? 35 : 20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 3D Perspective Biomechanical Viewport with Freeform Orbit Drag
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _yawAngle += details.delta.dx * 0.012;
                  _pitchAngle = (_pitchAngle - details.delta.dy * 0.012).clamp(-0.8, 1.4);
                  _selectedAngleIndex = -1; // Set to custom orbit
                });
              },
              child: CustomPaint(
                painter: _Human3dKinematicPainter(
                  progress: progress,
                  yaw: _yawAngle,
                  pitch: _pitchAngle,
                  exerciseName: widget.exercise.name,
                  isDark: colors.isDark,
                  themeColors: colors,
                ),
              ),
            ),
          ),

          // Top Overlay: Phase HUD & Orbit Readout
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: phaseColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withAlpha(40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        progress < 0.60
                            ? Icons.arrow_downward_rounded
                            : (progress < 0.75 ? Icons.pause_circle_rounded : Icons.arrow_upward_rounded),
                        size: 13,
                        color: phaseColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        phaseLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: phaseColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rotate_90_degrees_ccw_rounded,
                        size: 11,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedAngleIndex >= 0 && _selectedAngleIndex < _cameraAngles.length
                            ? _cameraAngles[_selectedAngleIndex]
                            : 'ORBIT ${(_yawAngle * 180 / math.pi).toInt() % 360}°',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mid-Bottom Overlay: Cloudflare R2 Watermark & Touch Drag Hint
          Positioned(
            left: 14,
            right: 14,
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 10, color: colors.neonEmerald),
                      const SizedBox(width: 4),
                      Text(
                        'R2 • ${widget.exercise.storageBucket ?? "raize-media"}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: colors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 10, color: colors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'DRAG 360° TO INSPECT RIG',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Overlay: Live Scrub Progress Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '00:0${(progress * 4).toInt()}',
                    style: GoogleFonts.spaceGrotesk(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: colors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '00:04',
                    style: GoogleFonts.spaceGrotesk(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudVideoStreamCanvas(double progress, String phaseLabel, Color phaseColor) {
    final colors = context.colors;
    final videoUrl = widget.exercise.videoUrl ?? 'https://media.raize.fit/exercises/video/exercise-4k.mp4';

    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Simulated 4K Cloud Video Frame
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withAlpha(30),
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.exercise.name.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '4K UHD • 60 FPS • CLOUDFLARE R2 CDN',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          // Top Header: Video Stream Metadata
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neonEmerald, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt_rounded, size: 12, color: AppColors.neonEmerald),
                      SizedBox(width: 4),
                      Text(
                        '⚡ CLOUDFLARE R2 EDGE CACHED',
                        style: TextStyle(
                          color: AppColors.neonEmerald,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Text(
                    '18.4 MBPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom URL & Scrub Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.black.withValues(alpha: 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '00:0${(progress * 4).toInt()}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppColors.cardElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonEmerald),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '00:04',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportControls() {
    final colors = context.colors;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Play / Pause Button
          InkWell(
            key: const Key('play_pause_demo_button'),
            onTap: _togglePlayPause,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isPlaying ? 'Pause Demo' : 'Play Demo',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Playback Speed Toggle
          InkWell(
            onTap: _cycleSpeed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed_rounded, color: colors.kineticIndigo, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_playbackSpeed}x Speed',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Multi-Angle Perspective Switcher
          InkWell(
            onTap: () {
              final nextIndex = (_selectedAngleIndex + 1) % _cameraAngles.length;
              _setCameraAnglePreset(nextIndex);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.video_camera_front_outlined, color: colors.emerald, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Switch Angle',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraAngleChips() {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _cameraAngles.length; i++) ...[
            GestureDetector(
              onTap: () => _setCameraAnglePreset(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _selectedAngleIndex == i
                      ? colors.primary.withAlpha(colors.isDark ? 50 : 25)
                      : colors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedAngleIndex == i ? colors.primary : colors.borderSubtle,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i == 0
                          ? Icons.screen_rotation_rounded
                          : (i == 1
                              ? Icons.view_compact_rounded
                              : (i == 2 ? Icons.view_sidebar_rounded : Icons.flight_takeoff_rounded)),
                      size: 12,
                      color: _selectedAngleIndex == i ? colors.primary : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _cameraAngles[i],
                      style: TextStyle(
                        color: _selectedAngleIndex == i ? colors.primary : colors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Reset View button
          GestureDetector(
            key: const Key('reset_3d_camera_button'),
            onTap: () => _setCameraAnglePreset(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restart_alt_rounded, size: 12, color: colors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    'RESET',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabSelector() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'BIOMECHANICS'),
          _buildTabItem(1, 'FORM CUES'),
          _buildTabItem(2, 'RED FLAGS'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final colors = context.colors;
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMechanicsTab(Exercise exercise) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Muscle Engagement Meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PRIMARY TARGET EMG ENGAGEMENT',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '94% PEAK ACTIVATION',
                    style: GoogleFonts.spaceGrotesk(
                      color: colors.neonEmerald,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exercise.primaryMuscle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.94,
                  minHeight: 6,
                  backgroundColor: colors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.neonEmerald),
                ),
              ),
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'SYNERGIST & STABILIZER MUSCLES',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: exercise.secondaryMuscles.map((muscle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        muscle,
                        style: TextStyle(
                          color: colors.kineticIndigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tempo & Breathing Protocol Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'PRESCRIPTION TEMPO METRONOME',
                    style: TextStyle(
                      color: colors.amber,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exercise.tempo,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.air_rounded, size: 16, color: colors.emerald),
                  const SizedBox(width: 8),
                  Text(
                    'VALSALVA BREATHING CADENCE',
                    style: TextStyle(
                      color: colors.emerald,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                exercise.breathingCue,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Cloudflare R2 Object Storage 3D Rig Specifications Card
        _buildObjectStorageRigCard(exercise, colors),
      ],
    );
  }

  Widget _buildObjectStorageRigCard(Exercise exercise, dynamic colors) {
    final slug = exercise.name.toLowerCase().replaceAll(' ', '-');
    final glbUrl = exercise.animation3dUrl ?? 'https://media.raize.fit/exercises/3d/$slug-human-3d.glb';
    final bucketName = exercise.storageBucket ?? 'raize-media';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_rounded, size: 16, color: colors.neonEmerald),
                  const SizedBox(width: 8),
                  Text(
                    'CLOUDFLARE R2 OBJECT STORAGE',
                    style: TextStyle(
                      color: colors.neonEmerald,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.neonEmerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.neonEmerald.withAlpha(50)),
                ),
                child: Text(
                  '3D ASSETS SYNCED',
                  style: TextStyle(
                    color: colors.neonEmerald,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '3D Human Biomechanical Rig Specification',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _buildSpecRow(colors, 'Bucket Container', bucketName),
          _buildSpecRow(colors, 'Mesh Polycount', '${exercise.meshPolycount} Triangles'),
          _buildSpecRow(colors, 'Articulation Rig', '${exercise.rigBonesCount} Biomechanical Joints'),
          _buildSpecRow(colors, 'Asset Formats', 'glTF 2.0 (.glb) & Apple ARKit (.usdz)'),
          _buildSpecRow(colors, 'Motion Capture Cadence', '60 FPS Ultra-HD Biomechanics'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: colors.kineticIndigo),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    glbUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontFamily: 'monospace',
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

  Widget _buildSpecRow(dynamic colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCuesTab(Exercise exercise) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP-BY-STEP EXECUTION PROTOCOL',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...exercise.formCues.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final cue = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cue,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSafeguardsTab(Exercise exercise) {
    final colors = context.colors;
    final mistakes = exercise.commonMistakes.isNotEmpty
        ? exercise.commonMistakes
        : [
            'Bouncing weight off connective tissue',
            'Allowing elbows to flare uncontrollably',
            'Losing intra-abdominal core brace mid-rep',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRITICAL FORM PITFALLS & RED FLAGS',
          style: TextStyle(
            color: colors.destructive,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...mistakes.map((mistake) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.destructive.withAlpha(colors.isDark ? 15 : 10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.destructive.withAlpha(colors.isDark ? 50 : 35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: colors.destructive,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mistake,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Helper 3D vector point for spherical projection and orbital rotation.
class _Point3D {
  final double x;
  final double y;
  final double z;

  const _Point3D(this.x, this.y, this.z);

  _Point3D rotateY(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return _Point3D(
      x * cosA + z * sinA,
      y,
      -x * sinA + z * cosA,
    );
  }

  _Point3D rotateX(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return _Point3D(
      x,
      y * cosA - z * sinA,
      y * sinA + z * cosA,
    );
  }

  Offset project(Size size, {double focalLength = 320.0, double scale = 0.95, double yShift = 8.0}) {
    final cx = size.width / 2;
    final cy = size.height / 2 + yShift;
    final cameraZ = focalLength + z;
    final depth = cameraZ > 30.0 ? focalLength / cameraZ : 1.0;
    return Offset(
      cx + x * scale * depth,
      cy + y * scale * depth,
    );
  }
}

/// High-performance 3D kinematic painter rendering a volumetric human
/// biomechanical skeletal rig, anatomical EMG muscle activation heatmap,
/// Olympic equipment, 360° camera orbit, and real-time joint telemetry.
class _Human3dKinematicPainter extends CustomPainter {
  final double progress;
  final double yaw;
  final double pitch;
  final String exerciseName;
  final bool isDark;
  final dynamic themeColors;

  _Human3dKinematicPainter({
    required this.progress,
    required this.yaw,
    required this.pitch,
    required this.exerciseName,
    this.isDark = true,
    this.themeColors,
  });

  Offset _proj(_Point3D p, Size size) {
    return p.rotateY(yaw).rotateX(pitch).project(size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = themeColors != null ? themeColors.primary as Color : AppColors.primary;
    final emeraldColor = themeColors != null ? themeColors.neonEmerald as Color : AppColors.neonEmerald;
    final indigoColor = themeColors != null ? themeColors.kineticIndigo as Color : AppColors.kineticIndigo;

    // 1. Perspective 3D Biomechanics Studio Floor Grid (y = 75)
    final gridLinePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.04)
      ..strokeWidth = 1.0;

    for (double gx = -120; gx <= 120; gx += 30) {
      final pStart = _proj(_Point3D(gx, 75, -90), size);
      final pEnd = _proj(_Point3D(gx, 75, 90), size);
      canvas.drawLine(pStart, pEnd, gridLinePaint);
    }
    for (double gz = -90; gz <= 90; gz += 30) {
      final pStart = _proj(_Point3D(-120, 75, gz), size);
      final pEnd = _proj(_Point3D(120, 75, gz), size);
      canvas.drawLine(pStart, pEnd, gridLinePaint);
    }

    // 2. Repetition Kinematic Cadence Displacement (0.0 -> 1.0)
    double barDisplacement = 0.0;
    if (progress < 0.60) {
      final t = progress / 0.60;
      barDisplacement = math.sin(t * math.pi / 2); // Smooth eccentric descent
    } else if (progress < 0.75) {
      barDisplacement = 1.0; // Isometric stretch pause at sternum
    } else {
      final t = (progress - 0.75) / 0.25;
      barDisplacement = 1.0 - math.sin(t * math.pi / 2); // Concentric explosive drive
    }

    // 3. 3D Weight Bench & Uprights
    final benchPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
      ..style = PaintingStyle.fill;
    final benchBorderPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bp1 = _proj(const _Point3D(-24, 22, -80), size);
    final bp2 = _proj(const _Point3D(24, 22, -80), size);
    final bp3 = _proj(const _Point3D(24, 22, 60), size);
    final bp4 = _proj(const _Point3D(-24, 22, 60), size);

    final benchPath = Path()
      ..moveTo(bp1.dx, bp1.dy)
      ..lineTo(bp2.dx, bp2.dy)
      ..lineTo(bp3.dx, bp3.dy)
      ..lineTo(bp4.dx, bp4.dy)
      ..close();
    canvas.drawPath(benchPath, benchPaint);
    canvas.drawPath(benchPath, benchBorderPaint);

    // Bench Uprights
    final uprightPaint = Paint()
      ..color = (isDark ? const Color(0xFF475569) : const Color(0xFF64748B))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final ul1 = _proj(const _Point3D(-48, 75, -60), size);
    final ul2 = _proj(const _Point3D(-48, -32, -60), size);
    final ur1 = _proj(const _Point3D(48, 75, -60), size);
    final ur2 = _proj(const _Point3D(48, -32, -60), size);
    canvas.drawLine(ul1, ul2, uprightPaint);
    canvas.drawLine(ur1, ur2, uprightPaint);

    // 4. Barbell Coordinates (J-Curve Trajectory)
    final topLockoutY = -52.0;
    final bottomChestY = -4.0;
    final topLockoutZ = -44.0;
    final bottomChestZ = -26.0;

    final currentBarY = topLockoutY + (bottomChestY - topLockoutY) * barDisplacement;
    final currentBarZ = topLockoutZ + (bottomChestZ - topLockoutZ) * barDisplacement;

    // J-Curve Bar Path Ribbon
    final pathRibbonPaint = Paint()
      ..color = emeraldColor.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final pathStart = _proj(const _Point3D(0, -52, -44), size);
    final pathMid = _proj(const _Point3D(0, -28, -35), size);
    final pathEnd = _proj(const _Point3D(0, -4, -26), size);
    final jCurve = Path()
      ..moveTo(pathStart.dx, pathStart.dy)
      ..quadraticBezierTo(pathMid.dx, pathMid.dy, pathEnd.dx, pathEnd.dy);
    canvas.drawPath(jCurve, pathRibbonPaint);

    // 5. 3D Human Biomechanical Rig & Skeletal Nodes
    final skeletonPaint = Paint()
      ..color = (isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF1E293B))
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Cranium / Head
    final headPoint = _proj(const _Point3D(0, 8, -68), size);
    final neckPoint = _proj(const _Point3D(0, 14, -50), size);
    canvas.drawCircle(headPoint, 10.0, skeletonPaint);
    canvas.drawLine(headPoint, neckPoint, skeletonPaint);

    // Shoulders & Clavicle
    final sternalNotch = _proj(const _Point3D(0, 12, -44), size);
    final leftShoulder = _proj(const _Point3D(-38, 14, -44), size);
    final rightShoulder = _proj(const _Point3D(38, 14, -44), size);
    canvas.drawLine(sternalNotch, leftShoulder, skeletonPaint);
    canvas.drawLine(sternalNotch, rightShoulder, skeletonPaint);
    canvas.drawCircle(leftShoulder, 4.0, jointPaint);
    canvas.drawCircle(rightShoulder, 4.0, jointPaint);

    // Thoracic & Lumbar Spine (Powerlifting Arch)
    final thoracicPoint = _proj(const _Point3D(0, 8, -22), size);
    final lumbarPoint = _proj(const _Point3D(0, 6, 8), size);
    final pelvisPoint = _proj(const _Point3D(0, 18, 50), size);
    canvas.drawLine(neckPoint, sternalNotch, skeletonPaint);
    canvas.drawLine(sternalNotch, thoracicPoint, skeletonPaint);
    canvas.drawLine(thoracicPoint, lumbarPoint, skeletonPaint);
    canvas.drawLine(lumbarPoint, pelvisPoint, skeletonPaint);

    // Pelvis & Lower Extremities (Leg Drive)
    final leftHip = _proj(const _Point3D(-20, 18, 52), size);
    final rightHip = _proj(const _Point3D(20, 18, 52), size);
    final leftKnee = _proj(const _Point3D(-38, 38, 68), size);
    final rightKnee = _proj(const _Point3D(38, 38, 68), size);
    final leftFoot = _proj(const _Point3D(-42, 75, 60), size);
    final rightFoot = _proj(const _Point3D(42, 75, 60), size);

    canvas.drawLine(pelvisPoint, leftHip, skeletonPaint);
    canvas.drawLine(pelvisPoint, rightHip, skeletonPaint);
    canvas.drawLine(leftHip, leftKnee, skeletonPaint);
    canvas.drawLine(rightHip, rightKnee, skeletonPaint);
    canvas.drawLine(leftKnee, leftFoot, skeletonPaint);
    canvas.drawLine(rightKnee, rightFoot, skeletonPaint);
    canvas.drawCircle(leftKnee, 3.5, jointPaint);
    canvas.drawCircle(rightKnee, 3.5, jointPaint);

    // 6. Anatomical EMG Muscle Activation Heatmap (Pectoralis Major Slabs)
    final emgIntensity = (0.40 + (barDisplacement * 0.35) + (progress >= 0.75 ? 0.25 : 0.0)).clamp(0.0, 1.0);
    final muscleGlowColor = Color.lerp(indigoColor, emeraldColor, emgIntensity)!;

    final muscleHeatmapPaint = Paint()
      ..color = muscleGlowColor.withValues(alpha: isDark ? 0.50 * emgIntensity : 0.35 * emgIntensity)
      ..style = PaintingStyle.fill;

    // Left Pec Slab
    final lp1 = _proj(const _Point3D(0, 10, -42), size);
    final lp2 = _proj(const _Point3D(-18, 12, -44), size);
    final lp3 = _proj(const _Point3D(-36, 14, -42), size);
    final lp4 = _proj(const _Point3D(-28, 10, -18), size);
    final lp5 = _proj(const _Point3D(0, 7, -14), size);

    final leftPecPath = Path()
      ..moveTo(lp1.dx, lp1.dy)
      ..lineTo(lp2.dx, lp2.dy)
      ..lineTo(lp3.dx, lp3.dy)
      ..lineTo(lp4.dx, lp4.dy)
      ..lineTo(lp5.dx, lp5.dy)
      ..close();
    canvas.drawPath(leftPecPath, muscleHeatmapPaint);

    // Right Pec Slab
    final rp1 = _proj(const _Point3D(0, 10, -42), size);
    final rp2 = _proj(const _Point3D(18, 12, -44), size);
    final rp3 = _proj(const _Point3D(36, 14, -42), size);
    final rp4 = _proj(const _Point3D(28, 10, -18), size);
    final rp5 = _proj(const _Point3D(0, 7, -14), size);

    final rightPecPath = Path()
      ..moveTo(rp1.dx, rp1.dy)
      ..lineTo(rp2.dx, rp2.dy)
      ..lineTo(rp3.dx, rp3.dy)
      ..lineTo(rp4.dx, rp4.dy)
      ..lineTo(rp5.dx, rp5.dy)
      ..close();
    canvas.drawPath(rightPecPath, muscleHeatmapPaint);

    // 7. Arms, Elbows, Dynamic Flexion Arc & Barbell Grip
    final leftHand = _proj(_Point3D(-50, currentBarY, currentBarZ), size);
    final rightHand = _proj(_Point3D(50, currentBarY, currentBarZ), size);

    final leftElbow = _proj(
      _Point3D(-40 - 22 * barDisplacement, -20 + 32 * barDisplacement, -42 + 10 * barDisplacement),
      size,
    );
    final rightElbow = _proj(
      _Point3D(40 + 22 * barDisplacement, -20 + 32 * barDisplacement, -42 + 10 * barDisplacement),
      size,
    );

    canvas.drawLine(leftShoulder, leftElbow, skeletonPaint);
    canvas.drawLine(leftElbow, leftHand, skeletonPaint);
    canvas.drawLine(rightShoulder, rightElbow, skeletonPaint);
    canvas.drawLine(rightElbow, rightHand, skeletonPaint);

    canvas.drawCircle(leftElbow, 4.0, jointPaint);
    canvas.drawCircle(rightElbow, 4.0, jointPaint);
    canvas.drawCircle(leftHand, 3.5, skeletonPaint);
    canvas.drawCircle(rightHand, 3.5, skeletonPaint);

    // 8. Dynamic 3D Elbow Angle Arc & Callout (165° -> 88°)
    final currentAngle = (165 - (barDisplacement * 77)).toInt();
    final arcPaint = Paint()
      ..color = emeraldColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(rightElbow, 14.0, arcPaint);

    final angleTextPainter = TextPainter(
      text: TextSpan(
        text: 'ELBOW: $currentAngle°',
        style: GoogleFonts.spaceGrotesk(
          color: emeraldColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    angleTextPainter.paint(canvas, Offset(rightElbow.dx + 12, rightElbow.dy - 16));

    // 9. Olympic Barbell & 3D Cylindrical Bumper Plates
    final barbellPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF334155))
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final barLeft = _proj(_Point3D(-118, currentBarY, currentBarZ), size);
    final barRight = _proj(_Point3D(118, currentBarY, currentBarZ), size);
    canvas.drawLine(barLeft, barRight, barbellPaint);

    // 3D Bumper Plates (20kg / 45lb) with perspective rim thickness
    final platePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final plateRimPaint = Paint()
      ..color = (isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF0F172A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left Plate Cylinder
    final lpOuter = _proj(_Point3D(-94, currentBarY, currentBarZ), size);
    final lpInner = _proj(_Point3D(-86, currentBarY, currentBarZ), size);
    final leftRect = Rect.fromCenter(center: lpOuter, width: 14, height: 48);
    canvas.drawOval(leftRect, platePaint);
    canvas.drawOval(leftRect, plateRimPaint);
    canvas.drawLine(Offset(lpOuter.dx, lpOuter.dy - 24), Offset(lpInner.dx, lpInner.dy - 24), plateRimPaint);
    canvas.drawLine(Offset(lpOuter.dx, lpOuter.dy + 24), Offset(lpInner.dx, lpInner.dy + 24), plateRimPaint);

    // Right Plate Cylinder
    final rpOuter = _proj(_Point3D(94, currentBarY, currentBarZ), size);
    final rpInner = _proj(_Point3D(86, currentBarY, currentBarZ), size);
    final rightRect = Rect.fromCenter(center: rpOuter, width: 14, height: 48);
    canvas.drawOval(rightRect, platePaint);
    canvas.drawOval(rightRect, plateRimPaint);
    canvas.drawLine(Offset(rpOuter.dx, rpOuter.dy - 24), Offset(rpInner.dx, rpInner.dy - 24), plateRimPaint);
    canvas.drawLine(Offset(rpOuter.dx, rpOuter.dy + 24), Offset(rpInner.dx, rpInner.dy + 24), plateRimPaint);
  }

  @override
  bool shouldRepaint(covariant _Human3dKinematicPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.exerciseName != exerciseName ||
        oldDelegate.isDark != isDark;
  }
}

/// Backward-compatible adapter for tests and external widgets.
class ExerciseKinematicPainter extends _Human3dKinematicPainter {
  ExerciseKinematicPainter({
    required super.progress,
    required int angleIndex,
    required super.exerciseName,
  }) : super(
          yaw: angleIndex == 0 ? 0.52 : (angleIndex == 1 ? 0.0 : math.pi / 2),
          pitch: angleIndex == 0 ? 0.22 : (angleIndex == 1 ? 0.12 : 0.08),
        );
}
