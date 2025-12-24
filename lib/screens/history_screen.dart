import 'package:flutter/material.dart';
import '../utils/drawing_utils.dart';
import '../services/session_storage.dart';
import '../services/session_storage_pullup.dart';
import '../models/pushup_session.dart';
import '../models/pullup_session.dart';

/// Pantalla de historial de sesiones - Diseño moderno con datos reales
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, DrawingUtils.accentColor],
          ).createShader(bounds),
          child: const Text(
            'HISTORIAL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: _loadAllSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(DrawingUtils.accentColor),
              ),
            );
          }

          final pushUpSessions =
              snapshot.data?['pushups'] as List<PushUpSession>? ?? [];
          final pullUpSessions =
              snapshot.data?['pullups'] as List<PullUpSession>? ?? [];
          final allSessions = _mergeSessions(pushUpSessions, pullUpSessions);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Stats header con datos reales
              FutureBuilder<Map<String, dynamic>>(
                future: _loadCombinedStats(),
                builder: (context, statsSnapshot) {
                  final stats = statsSnapshot.data ?? {};
                  return _buildStatsHeader(
                    totalReps: stats['totalReps'] ?? 0,
                    avgQuality: stats['averageQuality'] ?? 0.0,
                    streak: stats['streak'] ?? 0,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Título de sesiones
              const Text(
                'Sesiones Recientes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Lista de sesiones reales o mensaje vacío
              if (allSessions.isEmpty)
                _buildEmptyState()
              else
                ...allSessions.map((sessionData) {
                  if (sessionData['type'] == 'pushup') {
                    return _buildPushUpCard(
                        session: sessionData['session'] as PushUpSession);
                  } else {
                    return _buildPullUpCard(
                        session: sessionData['session'] as PullUpSession);
                  }
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(
      {required int totalReps,
      required double avgQuality,
      required int streak}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DrawingUtils.accentColor.withOpacity(0.15),
            DrawingUtils.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DrawingUtils.accentColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: DrawingUtils.accentColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Total', totalReps.toString(), Icons.fitness_center_rounded),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildStatItem('Promedio', '${avgQuality.toStringAsFixed(1)}%',
              Icons.stars_rounded),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildStatItem(
              'Racha', '${streak}d', Icons.local_fire_department_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: DrawingUtils.accentColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: DrawingUtils.accentColor.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay sesiones todavía',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza tu primer entrenamiento',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushUpCard({required PushUpSession session}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
        session.startTime.year, session.startTime.month, session.startTime.day);

    String dateLabel;
    if (sessionDay == today) {
      dateLabel = 'Hoy, ${_formatTime(session.startTime)}';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Ayer, ${_formatTime(session.startTime)}';
    } else {
      dateLabel =
          '${session.startTime.day} ${_getMonthName(session.startTime.month)}, ${_formatTime(session.startTime)}';
    }

    final duration = session.sessionDuration;
    final reps = session.totalReps;
    final quality = session.averageFormQuality;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Icono Push-Up
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DrawingUtils.accentColor.withOpacity(0.3),
                  DrawingUtils.secondaryColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$reps push-ups',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quality badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DrawingUtils.correctColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DrawingUtils.correctColor.withOpacity(0.5),
              ),
            ),
            child: Text(
              '${quality.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month - 1];
  }

  // =============== MÉTODOS HELPER PARA COMBINAR SESIONES ===============

  /// Carga todas las sesiones de ambos tipos
  Future<Map<String, List<dynamic>>> _loadAllSessions() async {
    final pushUpSessions = await SessionStorage.getAllSessions();
    final pullUpSessions = await SessionStoragePullUp.getAllSessions();

    print('📊 [History] Loaded ${pushUpSessions.length} push-up sessions');
    print('📊 [History] Loaded ${pullUpSessions.length} pull-up sessions');

    return {
      'pushups': pushUpSessions,
      'pullups': pullUpSessions,
    };
  }

  /// Combina y ordena sesiones por fecha (más reciente primero)
  List<Map<String, dynamic>> _mergeSessions(
    List<PushUpSession> pushUps,
    List<PullUpSession> pullUps,
  ) {
    final List<Map<String, dynamic>> merged = [];

    // Agregar Push-Ups
    for (final session in pushUps) {
      merged.add({
        'type': 'pushup',
        'session': session,
        'startTime': session.startTime,
      });
    }

    // Agregar Pull-Ups
    for (final session in pullUps) {
      merged.add({
        'type': 'pullup',
        'session': session,
        'startTime': session.startTime,
      });
    }

    // Ordenar por fecha (más reciente primero)
    merged.sort((a, b) =>
        (b['startTime'] as DateTime).compareTo(a['startTime'] as DateTime));

    return merged;
  }

  /// Carga estadísticas combinadas de ambos tipos
  Future<Map<String, dynamic>> _loadCombinedStats() async {
    final pushUpStats = await SessionStorage.getGlobalStats();
    final pullUpStats = await SessionStoragePullUp.getGlobalStats();

    final totalSessions = (pushUpStats['totalSessions'] ?? 0) +
        (pullUpStats['totalSessions'] ?? 0);
    final totalReps =
        (pushUpStats['totalReps'] ?? 0) + (pullUpStats['totalReps'] ?? 0);

    // Promedio ponderado de calidad
    final pushUpTotal = pushUpStats['totalReps'] ?? 0;
    final pullUpTotal = pullUpStats['totalReps'] ?? 0;
    final pushUpQuality = pushUpStats['averageQuality'] ?? 0.0;
    final pullUpQuality = pullUpStats['averageQuality'] ?? 0.0;

    double averageQuality = 0.0;
    if (totalReps > 0) {
      averageQuality =
          ((pushUpTotal * pushUpQuality) + (pullUpTotal * pullUpQuality)) /
              totalReps;
    }

    // Usar la racha más grande
    final streak =
        (pushUpStats['streak'] ?? 0) > (pullUpStats['currentStreak'] ?? 0)
            ? pushUpStats['streak']
            : pullUpStats['currentStreak'];

    return {
      'totalSessions': totalSessions,
      'totalReps': totalReps,
      'averageQuality': averageQuality,
      'streak': streak,
    };
  }

  /// Construye card para Pull-Ups
  Widget _buildPullUpCard({required PullUpSession session}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
        session.startTime.year, session.startTime.month, session.startTime.day);

    String dateLabel;
    if (sessionDay == today) {
      dateLabel = 'Hoy, ${_formatTime(session.startTime)}';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Ayer, ${_formatTime(session.startTime)}';
    } else {
      dateLabel =
          '${session.startTime.day} ${_getMonthName(session.startTime.month)}, ${_formatTime(session.startTime)}';
    }

    final duration = session.duration;
    final reps = session.totalReps;
    final quality = session.averageFormQuality;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Icono Pull-Up
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4)
                      .withOpacity(0.3), // Cyan para Pull-Ups
                  const Color(0xFF0097A7).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$reps pull-ups',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quality badge (cyan para Pull-Ups)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.5),
              ),
            ),
            child: Text(
              '${quality.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

