import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../models/fitness_test/fitness_test_result.dart';
import '../../models/fitness_test/fitness_level.dart';
import '../../models/fitness_test/fitness_test_state.dart';
import '../../services/fitness_test/fitness_level_calculator.dart';

/// Pantalla de resumen y resultados del Fitness Test
class FitnessTestSummaryScreen extends StatelessWidget {
  /// Resultado del test
  final FitnessTestResult result;

  /// Callback al guardar
  final VoidCallback onSave;

  /// Callback al compartir
  final VoidCallback? onShare;

  /// Callback al ir a home
  final VoidCallback onHome;

  const FitnessTestSummaryScreen({
    super.key,
    required this.result,
    required this.onSave,
    this.onShare,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header con nivel
            _buildHeader(),

            // Resultados scrollables
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Tarjetas de ejercicios
                    _buildExerciseCard(
                      emoji: FitnessTestExerciseType.pushup.emoji,
                      name: 'FLEXIONES',
                      reps: result.pushupCount,
                      quality: result.pushupQuality,
                      status: result.pushupStatus,
                    ),
                    _buildExerciseCard(
                      emoji: FitnessTestExerciseType.squat.emoji,
                      name: 'SENTADILLAS',
                      reps: result.squatCount,
                      quality: result.squatQuality,
                      status: result.squatStatus,
                    ),
                    _buildExerciseCard(
                      emoji: FitnessTestExerciseType.abdominal.emoji,
                      name: 'ABDOMINALES',
                      reps: result.abdominalCount,
                      quality: result.abdominalQuality,
                      status: result.abdominalStatus,
                    ),
                    const SizedBox(height: 16),
                    // Resumen total
                    _buildTotalCard(),
                    const SizedBox(height: 16),
                    // Sugerencias
                    _buildSuggestionsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Text(
                'RESULTADOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Badge de nivel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result.level.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'NIVEL ${result.level.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required String emoji,
    required String name,
    required int reps,
    required double quality,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassWhite,
        ),
      ),
      child: Row(
        children: [
          // Emoji grande
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.cardBgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calidad: ${(quality * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Estado: $status',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Reps
          Column(
            children: [
              Text(
                '$reps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'reps',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.2),
            AppColors.primaryPurple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalStat(
                icon: Icons.fitness_center,
                label: 'TOTAL',
                value: '${result.totalReps}',
                unit: 'reps',
              ),
              _buildTotalStat(
                icon: Icons.star,
                label: 'NIVEL',
                value: result.level.displayName,
                unit: '',
              ),
              _buildTotalStat(
                icon: Icons.calendar_today,
                label: 'FECHA',
                value: dateFormat.format(result.timestamp),
                unit: '',
                smallValue: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStat({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    bool smallValue = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryCyan, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: smallValue ? 14 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsCard() {
    if (result.suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, 
                   color: AppColors.warningYellow, size: 24),
              const SizedBox(width: 8),
              const Text(
                'SUGERENCIAS PARA MEJORAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...result.suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(
                  color: AppColors.warningYellow, fontSize: 14)),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Guardar
          Expanded(
            child: _buildActionButton(
              icon: Icons.save_alt,
              label: 'GUARDAR',
              onPressed: onSave,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          // Compartir
          if (onShare != null) ...[
            Expanded(
              child: _buildActionButton(
                icon: Icons.share,
                label: 'COMPARTIR',
                onPressed: onShare!,
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Home
          Expanded(
            child: _buildActionButton(
              icon: Icons.home,
              label: 'HOME',
              onPressed: onHome,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white70, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Excelente')) return AppColors.successGreen;
    if (status.contains('Muy Bien')) return AppColors.successGreen;
    if (status.contains('Bien')) return AppColors.warningYellow;
    return AppColors.errorPink;
  }
}

