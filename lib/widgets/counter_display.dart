import 'package:flutter/material.dart';
import '../utils/drawing_utils.dart';

/// Widget para mostrar el contador de repeticiones
class CounterDisplay extends StatelessWidget {
  final int count;
  final String phase;
  final double formQuality;
  final bool isActive;

  const CounterDisplay({
    super.key,
    required this.count,
    this.phase = 'PREP',
    this.formQuality = 0.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        gradient: DrawingUtils.createAppGradient(),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: DrawingUtils.accentColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de fase
          Text(
            phase.toUpperCase(),
            style: TextStyle(
              color: _getPhaseColor(),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 10),

          // Contador principal
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0, end: count.toDouble()),
            builder: (context, value, child) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                ),
              );
            },
          ),

          const SizedBox(height: 5),

          // Label
          const Text(
            'REPETICIONES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          // Barra de calidad
          _buildQualityIndicator(),
        ],
      ),
    );
  }

  Widget _buildQualityIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CALIDAD',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${formQuality.toStringAsFixed(0)}%',
              style: TextStyle(
                color: DrawingUtils.getQualityColor(formQuality),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (formQuality / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: DrawingUtils.getQualityColor(formQuality),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: DrawingUtils.getQualityColor(
                          formQuality,
                        ).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPhaseColor() {
    if (!isActive) return Colors.white70;

    switch (phase.toUpperCase()) {
      case 'ARRIBA':
        return DrawingUtils.correctColor;
      case 'ABAJO':
        return DrawingUtils.accentColor;
      case 'TRANSICIÓN':
        return DrawingUtils.warningColor;
      default:
        return Colors.white70;
    }
  }
}

