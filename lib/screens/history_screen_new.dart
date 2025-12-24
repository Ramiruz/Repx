import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/drawing_utils.dart';
import '../utils/app_colors.dart';
import '../services/session_storage.dart';
import '../services/session_storage_pullup.dart' as pullup_storage;
import '../services/pullup_workout_storage.dart';
import '../models/pushup_session.dart';
import '../models/pullup_session.dart';
import '../models/pullup_workout.dart';
import 'package:REPX/l10n/app_localizations.dart';

enum ExerciseFilter { all, pushups, pullups }

class HistoryScreenNew extends StatefulWidget {
  const HistoryScreenNew({super.key});

  @override
  State<HistoryScreenNew> createState() => _HistoryScreenNewState();
}

class _HistoryScreenNewState extends State<HistoryScreenNew> {
  ExerciseFilter _selectedFilter = ExerciseFilter.all;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          // AppBar con gradiente
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E27),
                    AppColors.primaryCyan.withOpacity(0.1),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      AppColors.primaryCyan,
                    ],
                  ).createShader(bounds),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(
                        l10n.history.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showCalendar
                      ? Icons.list_rounded
                      : Icons.calendar_month_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showCalendar = !_showCalendar;
                  });
                },
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Filtros de ejercicio
                _buildFilterChips(),

                const SizedBox(height: 16),

                // Calendario (si está visible)
                if (_showCalendar) ...[
                  _buildCalendar(),
                  const SizedBox(height: 16),
                ],

                // Lista de sesiones
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadFilteredSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryCyan),
                          ),
                        ),
                      );
                    }

                    final sessions = snapshot.data ?? [];

                    if (sessions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final sessionData = sessions[index];
                        return _buildSessionCard(sessionData);
                      },
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip(
            label: l10n.all,
            icon: Icons.fitness_center_rounded,
            filter: ExerciseFilter.all,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: l10n.pushups,
            icon: Icons.accessibility_new_rounded,
            filter: ExerciseFilter.pushups,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: l10n.pullups,
            icon: Icons.sports_gymnastics_rounded,
            filter: ExerciseFilter.pullups,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required ExerciseFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryCyan,
                      AppColors.primaryCyan.withOpacity(0.7),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryCyan
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.2),
        ),
      ),
      child: FutureBuilder<Map<DateTime, List<dynamic>>>(
        future: _getTrainingDays(),
        builder: (context, snapshot) {
          final trainingDays = snapshot.data ?? {};

          return TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return trainingDays[normalizedDay] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            // Estilos
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.white70),
              defaultTextStyle: const TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(
                color: AppColors.primaryCyan,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.successGreen,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              weekendStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> sessionData) {
    final type = sessionData['type'] as String;
    final isPushUp = type == 'pushup';

    return GestureDetector(
      onTap: () => _showSessionDetails(sessionData),
      child: Container(
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
            // Icono del ejercicio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPushUp
                      ? [
                          DrawingUtils.accentColor.withOpacity(0.3),
                          DrawingUtils.secondaryColor.withOpacity(0.2),
                        ]
                      : [
                          AppColors.primaryCyan.withOpacity(0.3),
                          AppColors.primaryCyan.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPushUp
                    ? Icons.accessibility_new_rounded
                    : Icons.sports_gymnastics_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Info de la sesión
            Expanded(
              child: _buildSessionInfo(sessionData),
            ),

            // Botón de eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red.withOpacity(0.7),
              onPressed: () => _confirmDelete(sessionData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(Map<String, dynamic> sessionData) {
    final type = sessionData['type'] as String;

    if (type == 'pushup') {
      final session = sessionData['session'] as PushUpSession;
      final dateLabel = _getDateLabel(session.startTime);

      return Column(
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
                '${session.totalReps} push-ups',
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
                '${session.sessionDuration.inMinutes} min',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (type == 'pullup-session') {
      final session = sessionData['session'] as PullUpSession;
      final dateLabel = _getDateLabel(session.startTime);

      return Column(
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
                '${session.totalReps} pull-ups',
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
                '${session.duration.inMinutes}min',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // pullup-workout
      final workout = sessionData['session'] as PullUpWorkout;
      final dateLabel = _getDateLabel(workout.startTime);

      return Column(
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
                '${workout.totalReps} pull-ups (${workout.sets.length} series)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
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
            color: AppColors.primaryCyan.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noSessions,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.startFirstWorkout,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadFilteredSessions() async {
    final pushUpSessions = await SessionStorage.getAllSessions();
    final pullUpSessions =
        await pullup_storage.SessionStoragePullUp.getAllSessions();
    final pullUpWorkouts = await PullUpWorkoutStorage().getWorkouts();

    List<Map<String, dynamic>> allSessions = [];

    // Agregar push-ups
    if (_selectedFilter == ExerciseFilter.all ||
        _selectedFilter == ExerciseFilter.pushups) {
      for (var session in pushUpSessions) {
        allSessions.add({
          'type': 'pushup',
          'session': session,
          'date': session.startTime,
        });
      }
    }

    // Agregar pull-ups (sesiones simples)
    if (_selectedFilter == ExerciseFilter.all ||
        _selectedFilter == ExerciseFilter.pullups) {
      for (var session in pullUpSessions) {
        allSessions.add({
          'type': 'pullup-session',
          'session': session,
          'date': session.startTime,
        });
      }

      // Agregar pull-ups (workouts con series)
      for (var workout in pullUpWorkouts) {
        allSessions.add({
          'type': 'pullup-workout',
          'session': workout,
          'date': workout.startTime,
        });
      }
    }

    // Filtrar por día seleccionado si hay uno
    if (_selectedDay != null) {
      final selectedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );

      allSessions = allSessions.where((sessionData) {
        final sessionDate = sessionData['date'] as DateTime;
        final normalizedDate = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
        );
        return normalizedDate == selectedDate;
      }).toList();
    }

    // Ordenar por fecha (más reciente primero)
    allSessions.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    return allSessions;
  }

  Future<Map<DateTime, List<dynamic>>> _getTrainingDays() async {
    final pushUpSessions = await SessionStorage.getAllSessions();
    final pullUpSessions =
        await pullup_storage.SessionStoragePullUp.getAllSessions();
    final pullUpWorkouts = await PullUpWorkoutStorage().getWorkouts();

    Map<DateTime, List<dynamic>> trainingDays = {};

    // Agregar push-ups
    for (var session in pushUpSessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      trainingDays[date] = [...(trainingDays[date] ?? []), session];
    }

    // Agregar pull-ups
    for (var session in pullUpSessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      trainingDays[date] = [...(trainingDays[date] ?? []), session];
    }

    // Agregar workouts
    for (var workout in pullUpWorkouts) {
      final date = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );
      trainingDays[date] = [...(trainingDays[date] ?? []), workout];
    }

    return trainingDays;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);

    final l10n = AppLocalizations.of(context)!;
    if (sessionDay == today) {
      return '${l10n.today}, ${_formatTime(date)}';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      return '${l10n.yesterday}, ${_formatTime(date)}';
    } else {
      return '${date.day} ${_getMonthName(date.month)}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getMonthName(int month) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december
    ];
    return months[month - 1].substring(0, 3);
  }

  void _showSessionDetails(Map<String, dynamic> sessionData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSessionDetailsSheet(sessionData),
    );
  }

  Widget _buildSessionDetailsSheet(Map<String, dynamic> sessionData) {
    final type = sessionData['type'] as String;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF0A0E27),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type == 'pushup' ? 'Push-Ups' : 'Pull-Ups',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detalles específicos por tipo
          if (type == 'pushup')
            _buildPushUpDetails(sessionData['session'] as PushUpSession)
          else if (type == 'pullup-session')
            _buildPullUpDetails(sessionData['session'] as PullUpSession)
          else
            _buildWorkoutDetails(sessionData['session'] as PullUpWorkout),

          const SizedBox(height: 24),

          // Botón eliminar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(sessionData);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(AppLocalizations.of(context)!.deleteSession),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildPushUpDetails(PushUpSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
            'Repeticiones', '${session.totalReps}', Icons.fitness_center),
        const SizedBox(height: 12),
        _buildDetailRow(
            'Duración', '${session.sessionDuration} min', Icons.timer),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Calidad promedio',
          '${session.averageFormQuality.toStringAsFixed(1)}%',
          Icons.stars,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Fecha',
          _getDateLabel(session.startTime),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildPullUpDetails(PullUpSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
            'Repeticiones', '${session.totalReps}', Icons.fitness_center),
        const SizedBox(height: 12),
        _buildDetailRow(
            'Duración', '${session.duration.inMinutes} min', Icons.timer),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Calidad promedio',
          '${session.averageFormQuality.toStringAsFixed(1)}%',
          Icons.stars,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Fecha',
          _getDateLabel(session.startTime),
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildWorkoutDetails(PullUpWorkout workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Total de repeticiones', '${workout.totalReps}',
            Icons.fitness_center),
        const SizedBox(height: 12),
        _buildDetailRow(
            'Series completadas', '${workout.sets.length}', Icons.layers),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Calidad promedio',
          '${workout.averageFormQuality.toStringAsFixed(1)}%',
          Icons.stars,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Fecha',
          _getDateLabel(workout.startTime),
          Icons.calendar_today,
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        const Text(
          'Detalle de series:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...workout.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryCyan.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serie ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${set.completedReps} reps',
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryCyan,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Map<String, dynamic> sessionData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '¿Eliminar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSession(sessionData);
              setState(() {}); // Refrescar la lista
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(Map<String, dynamic> sessionData) async {
    final type = sessionData['type'] as String;

    if (type == 'pushup') {
      final session = sessionData['session'] as PushUpSession;
      // Obtener todas las sesiones, filtrar la que queremos eliminar, y guardar de nuevo
      final sessions = await SessionStorage.getAllSessions();
      final updatedSessions =
          sessions.where((s) => s.startTime != session.startTime).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pushup_sessions',
          jsonEncode(updatedSessions.map((s) => s.toJson()).toList()));
    } else if (type == 'pullup-session') {
      final session = sessionData['session'] as PullUpSession;
      final sessions =
          await pullup_storage.SessionStoragePullUp.getAllSessions();
      final updatedSessions =
          sessions.where((s) => s.startTime != session.startTime).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pullup_sessions',
          jsonEncode(updatedSessions.map((s) => s.toJson()).toList()));
    } else {
      final workout = sessionData['session'] as PullUpWorkout;
      await PullUpWorkoutStorage().deleteWorkout(workout.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.sessionDeleted),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

