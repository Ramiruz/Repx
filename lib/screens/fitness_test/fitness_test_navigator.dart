import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:REPX/l10n/app_localizations.dart';
import '../../models/fitness_test/fitness_test_state.dart';
import '../../models/fitness_test/fitness_test_result.dart';
import '../../services/fitness_test/fitness_test_controller.dart';
import 'fitness_test_intro_screen.dart';
import 'fitness_exercise_screen.dart';
import 'rest_screen.dart';
import 'fitness_test_summary_screen.dart';

/// Navegador principal del Fitness Test
/// 
/// Gestiona el flujo completo de 7 pantallas con transiciones automáticas
class FitnessTestNavigator extends StatefulWidget {
  const FitnessTestNavigator({super.key});

  @override
  State<FitnessTestNavigator> createState() => _FitnessTestNavigatorState();
}

class _FitnessTestNavigatorState extends State<FitnessTestNavigator> {
  late FitnessTestController _controller;
  bool _isInitialized = false;
  FitnessTestResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = FitnessTestController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
      _controller.startTest();
      
      // Escuchar cambios de fase para navegación automática
      _controller.phaseStream.listen(_onPhaseChanged);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error inicializando FitnessTestNavigator: $e');
    }
  }

  void _onPhaseChanged(FitnessTestPhase phase) {
    // Las transiciones se manejan automáticamente por el controller
    // Solo necesitamos reconstruir la UI
    if (mounted) {
      setState(() {});
    }

    // Si llegamos al summary, generar resultado
    if (phase == FitnessTestPhase.summary) {
      _result = _controller.generateResult();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restaurar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _getExerciseName(FitnessTestExerciseType type, AppLocalizations l10n) {
    switch (type) {
      case FitnessTestExerciseType.pushup:
        return l10n.flexiones;
      case FitnessTestExerciseType.squat:
        return l10n.sentadillas;
      case FitnessTestExerciseType.abdominal:
        return l10n.abdominales;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_isInitialized) {
      return _buildLoadingScreen(l10n);
    }

    return ChangeNotifierProvider<FitnessTestController>.value(
      value: _controller,
      child: Consumer<FitnessTestController>(
        builder: (context, controller, _) {
          return _buildCurrentScreen(controller.state.currentPhase, l10n);
        },
      ),
    );
  }

  Widget _buildLoadingScreen(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00F5FF),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.preparingFitnessTest,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(FitnessTestPhase phase, AppLocalizations l10n) {
    switch (phase) {
      case FitnessTestPhase.intro:
        return FitnessTestIntroScreen(
          onStartTest: () {
            _controller.advanceToNextPhase();
          },
        );

      case FitnessTestPhase.pushup:
        return FitnessExerciseScreen(
          exerciseType: FitnessTestExerciseType.pushup,
          onTimeUp: () {
            // El controller ya maneja la transición automática
          },
        );

      case FitnessTestPhase.rest1:
        return RestScreen(
          remainingSeconds: _controller.state.remainingSeconds,
          nextExerciseName: l10n.sentadillas,
          isSecondRest: false,
          onSkip: () {
            _controller.skipRest();
          },
        );

      case FitnessTestPhase.squat:
        return FitnessExerciseScreen(
          exerciseType: FitnessTestExerciseType.squat,
          onTimeUp: () {},
        );

      case FitnessTestPhase.rest2:
        return RestScreen(
          remainingSeconds: _controller.state.remainingSeconds,
          nextExerciseName: l10n.abdominales,
          isSecondRest: true,
          onSkip: () {
            _controller.skipRest();
          },
        );

      case FitnessTestPhase.abdominal:
        return FitnessExerciseScreen(
          exerciseType: FitnessTestExerciseType.abdominal,
          onTimeUp: () {},
        );

      case FitnessTestPhase.summary:
      case FitnessTestPhase.completed:
        // Generar resultado si no existe
        _result ??= _controller.generateResult();
        
        return FitnessTestSummaryScreen(
          result: _result!,
          onSave: () async {
            await _controller.saveResult(_result!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${l10n.resultSaved}'),
                  backgroundColor: const Color(0xFF06FFA5),
                ),
              );
            }
          },
          onShare: () {
            // TODO: Implementar compartir
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📤 ${l10n.shareComingSoon}'),
              ),
            );
          },
          onHome: () {
            Navigator.of(context).pop();
          },
        );
    }
  }
}
