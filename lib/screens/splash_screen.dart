import 'dart:async';

import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late AnimationController _particleController;
  @override
  void initState() {
    super.initState();

    // Controlador para fade in general
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Controlador para escala del ícono
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para pulso sutil
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    // Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();

    // Navegación
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.18).clamp(110.0, 260.0);
    final titleSize = (size.width * 0.04).clamp(28.0, 48.0);
    final subtitleSize = (size.width * 0.018).clamp(12.0, 26.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF070713),
              const Color(0xFF0f1724).withOpacity(0.95),
              const Color(0xFF1b2a4a).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_particleController, _scaleController, _pulseController]),
              builder: (context, _) {
                return Stack(
                  children: [
                    // Partículas de fondo: cubren toda la UI
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ParticlePainter(
                          progress: _particleController.value,
                          color: const Color(0xFF18FFFF),
                          count: 12,
                        ),
                      ),
                    ),

                    // Contenido principal centrado
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Premium logo card (sin partículas aquí)
                          Transform.scale(
                            scale:
                                _scaleAnimation.value * _pulseAnimation.value,
                            child: SizedBox(
                              width: logoSize,
                              height: logoSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.06),
                                          Colors.white.withOpacity(0.02),
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.6),
                                          blurRadius: 30,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF18FFFF)
                                              .withOpacity(0.12),
                                          blurRadius: 40,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/icon/app_icon.png',
                                          width: logoSize * 0.56,
                                          height: logoSize * 0.56,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Title
                          Text(
                            'REPX',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.45),
                                  offset: const Offset(0, 3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle / claim
                          Text(
                            'Intelligent form detection • Real-time feedback',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.72),
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Slim progress bar
                          SizedBox(
                            width: (size.width * 0.26).clamp(160.0, 420.0),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF18FFFF),
                                                const Color(0xFF7B61FF)
                                                    .withOpacity(0.95),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: AnimatedBuilder(
                                          animation: _particleController,
                                          builder: (context, _) {
                                            final pos =
                                                (_particleController.value *
                                                        1.6) -
                                                    0.3;
                                            return Align(
                                              alignment:
                                                  Alignment(pos * 2 - 1, 0),
                                              child: Container(
                                                width: 60,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white
                                                          .withOpacity(0.18),
                                                      Colors.white
                                                          .withOpacity(0.03),
                                                      Colors.white
                                                          .withOpacity(0.0),
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.2,
                                                      1.0
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Version footer
                          Opacity(
                            opacity: 0.72,
                            child: Text(
                              'v${1}.${0}.${0}  •  © ${DateTime.now().year} FitLabs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Painter simple para partículas ascendentes que cubren todo el fondo (UI)
class _ParticlePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final int count;

  _ParticlePainter(
      {required this.progress, required this.color, this.count = 5});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final travel = size.height * 1.4;

    for (var i = 0; i < count; i++) {
      final offsetFactor = (i - (count - 1) / 2);
      final xOffset = offsetFactor * (size.width * 0.14);
      var t = (progress + i * 0.14) % 1.0;
      // ease out for smoother movement
      t = Curves.easeOut.transform(t);
      final y = size.height * 0.7 - t * travel;
      final minR = size.width * 0.02;
      final maxR = size.width * 0.06;
      final radius = minR + (maxR - minR) * (1 - t);
      final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.95;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(centerX + xOffset, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.count != count;
  }
}

