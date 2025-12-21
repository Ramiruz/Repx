import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'exercise_selection_screen.dart';
import 'history_screen_new.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Pantalla de inicio - Diseño premium minimalista profesional con animaciones
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particlesController;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();

    // Animación del logo - pulso suave
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Animación de partículas de fondo
    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Fondo animado con partículas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlesPainter(
                    animation: _particlesController.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          // Gradiente base
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  AppColors.primaryPurple.withOpacity(0.08),
                  AppColors.darkBg,
                  AppColors.darkBg,
                ],
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo animado con pulso y brillo
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryCyan
                                        .withOpacity(_logoGlow.value),
                                    width: 2,
                                  ),
                                  color: AppColors.cardBg.withOpacity(0.3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryCyan
                                          .withOpacity(_logoGlow.value * 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon/app_icon_foreground.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 50),

                        // Título elegante
                        const Text(
                          'REPX',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 10,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'COUNTER',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: AppColors.primaryCyan.withOpacity(0.9),
                            letterSpacing: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Subtítulo minimalista
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.aiPoweredTraining,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 70),

                        // Botón principal
                        _buildStartButton(context),

                        const SizedBox(height: 24),

                        // Características
                        _buildFeatures(),
                      ],
                    ),
                  ),
                ),

                // Stats rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStat(
                              l10n.history,
                              Icons.history_rounded,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HistoryScreenNew(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickStat(
                              l10n.settings,
                              Icons.settings_rounded,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildQuickStat(
                        l10n.personalTrainer,
                        Icons.smart_toy_rounded,
                        () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ChatbotScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 350),
                          ),
                        ),
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.systemReady,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.positionDeviceAndStart,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return _AnimatedButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isFullWidth && icon == Icons.smart_toy_rounded
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.25),
                    AppColors.primaryPurple.withOpacity(0.15),
                  ],
                )
              : null,
          color: isFullWidth && icon == Icons.smart_toy_rounded
              ? null
              : AppColors.cardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFullWidth && icon == Icons.smart_toy_rounded
                ? AppColors.primaryCyan.withOpacity(0.4)
                : Colors.white.withOpacity(0.15),
            width: isFullWidth && icon == Icons.smart_toy_rounded ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isFullWidth && icon == Icons.smart_toy_rounded
                  ? AppColors.primaryCyan
                  : Colors.white.withOpacity(0.9),
              size: isFullWidth ? 22 : 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isFullWidth && icon == Icons.smart_toy_rounded
                      ? Colors.white
                      : Colors.white.withOpacity(0.9),
                  fontSize: isFullWidth ? 15 : 14,
                  fontWeight: isFullWidth ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AnimatedButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExerciseSelectionScreen(),
          ),
        );
      },
      scaleDown: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: AppColors.primaryCyan,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              l10n.start,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeature(Icons.videocam, l10n.realTime),
        const SizedBox(width: 32),
        _buildFeature(Icons.assessment, l10n.validation),
        const SizedBox(width: 32),
        _buildFeature(Icons.analytics, l10n.statistics),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryCyan.withOpacity(0.8),
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Widget de botón con animación de escala interactiva
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double scaleDown;

  const _AnimatedButton({
    required this.onTap,
    required this.child,
    this.scaleDown = 0.96,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Painter para partículas flotantes en el fondo
class ParticlesPainter extends CustomPainter {
  final double animation;
  final Random random = Random(42);

  ParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Generar partículas flotantes (más numerosas y visibles)
    for (int i = 0; i < 50; i++) {
      final seedX = random.nextDouble();
      final seedY = random.nextDouble();
      final speed = 0.2 + random.nextDouble() * 0.6;
      final offset = (animation * speed) % 1.0;

      final x = size.width * seedX;
      final y = (size.height * seedY + size.height * offset) % size.height;

      final particleSize = 2.0 + random.nextDouble() * 4.0;
      final opacity = 0.2 + random.nextDouble() * 0.3;

      paint.color =
          (i % 3 == 0 ? AppColors.primaryCyan : AppColors.primaryPurple)
              .withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Añadir brillo/glow a algunas partículas
      if (i % 5 == 0) {
        paint.color = paint.color.withOpacity(opacity * 0.3);
        canvas.drawCircle(Offset(x, y), particleSize * 2, paint);
      }
    }

    // Líneas de conexión más visibles
    for (int i = 0; i < 15; i++) {
      final seedX1 = random.nextDouble();
      final seedY1 = random.nextDouble();
      final seedX2 = random.nextDouble();
      final seedY2 = random.nextDouble();

      final x1 = size.width * seedX1;
      final y1 = size.height * seedY1;
      final x2 = size.width * seedX2;
      final y2 = size.height * seedY2;

      paint.color = AppColors.primaryCyan.withOpacity(0.08);
      paint.strokeWidth = 1.0;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) =>
      animation != oldDelegate.animation;
}
