import 'package:flutter/material.dart';
import 'package:REPX/l10n/app_localizations.dart';

/// Tipos de ejercicios disponibles en la app
enum ExerciseType {
  pushUps,
  pullUps,
}

extension ExerciseTypeExtension on ExerciseType {
  String get name {
    switch (this) {
      case ExerciseType.pushUps:
        return 'Push-Ups';
      case ExerciseType.pullUps:
        return 'Pull-Ups';
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseType.pushUps:
        return 'PUSH-UPS';
      case ExerciseType.pullUps:
        return 'PULL-UPS';
    }
  }

  String get subtitle {
    switch (this) {
      case ExerciseType.pushUps:
        return 'Flexiones de pecho';
      case ExerciseType.pullUps:
        return 'Dominadas en barra';
    }
  }

  // Métodos localizados (requieren BuildContext)
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ExerciseType.pushUps:
        return l10n.pushups.toUpperCase();
      case ExerciseType.pullUps:
        return l10n.pullups.toUpperCase();
    }
  }

  String getSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ExerciseType.pushUps:
        return l10n.chestPushups;
      case ExerciseType.pullUps:
        return l10n.barPullUps;
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseType.pushUps:
        return '💪';
      case ExerciseType.pullUps:
        return '🏋️';
    }
  }
}

