import 'package:flutter/material.dart';
import '../utils/drawing_utils.dart';

/// Widget para mostrar indicadores de ángulos en tiempo real
class AngleIndicator extends StatelessWidget {
  final String label;
  final double? angle;
  final double minGoodAngle;
  final double maxGoodAngle;
  final IconData icon;

  const AngleIndicator({
    super.key,
    required this.label,
    this.angle,
    this.minGoodAngle = 0,
    this.maxGoodAngle = 180,
    this.icon = Icons.straighten,
  });

  @override
  Widget build(BuildContext context) {
    final isGoodAngle =
        angle != null && angle! >= minGoodAngle && angle! <= maxGoodAngle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              isGoodAngle
                  ? DrawingUtils.correctColor
                  : DrawingUtils.warningColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isGoodAngle
                    ? DrawingUtils.correctColor
                    : DrawingUtils.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                angle != null ? '${angle!.toStringAsFixed(0)}°' : '---',
                style: TextStyle(
                  color: isGoodAngle ? DrawingUtils.correctColor : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

