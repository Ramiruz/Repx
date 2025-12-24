import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar configuraciones de la app
class SettingsService extends ChangeNotifier {
  static const String _showSkeletonKey = 'show_skeleton';
  static const String _showAnglesKey = 'show_angles';
  static const String _showQualityBarKey = 'show_quality_bar';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _minAngleThresholdKey = 'min_angle_threshold';
  static const String _requirePersonKey =
      'require_person'; // NUEVO: Validar presencia de persona

  // Valores por defecto
  bool _showSkeleton = true;
  bool _showAngles = true;
  bool _showQualityBar = true;
  bool _soundEnabled = false;
  double _minAngleThreshold = 100.0;
  bool _requirePerson = true; // CRÍTICO: Validar que haya alguien

  // Getters
  bool get showSkeleton => _showSkeleton;
  bool get showAngles => _showAngles;
  bool get showQualityBar => _showQualityBar;
  bool get soundEnabled => _soundEnabled;
  double get minAngleThreshold => _minAngleThreshold;
  bool get requirePerson => _requirePerson;

  /// Carga configuraciones desde SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _showSkeleton = prefs.getBool(_showSkeletonKey) ?? true;
      _showAngles = prefs.getBool(_showAnglesKey) ?? true;
      _showQualityBar = prefs.getBool(_showQualityBarKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? false;
      _minAngleThreshold = prefs.getDouble(_minAngleThresholdKey) ?? 100.0;
      _requirePerson = prefs.getBool(_requirePersonKey) ??
          true; // Por defecto: SÍ validar persona

      notifyListeners();
      print('✅ Configuraciones cargadas');
    } catch (e) {
      print('❌ Error cargando configuraciones: $e');
    }
  }

  /// Actualiza showSkeleton
  Future<void> setShowSkeleton(bool value) async {
    _showSkeleton = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSkeletonKey, value);
    notifyListeners();
  }

  /// Actualiza showAngles
  Future<void> setShowAngles(bool value) async {
    _showAngles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAnglesKey, value);
    notifyListeners();
  }

  /// Actualiza showQualityBar
  Future<void> setShowQualityBar(bool value) async {
    _showQualityBar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showQualityBarKey, value);
    notifyListeners();
  }

  /// Actualiza soundEnabled
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
    notifyListeners();
  }

  /// Actualiza minAngleThreshold
  Future<void> setMinAngleThreshold(double value) async {
    _minAngleThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_minAngleThresholdKey, value);
    notifyListeners();
  }

  /// Actualiza requirePerson (CRÍTICO)
  Future<void> setRequirePerson(bool value) async {
    _requirePerson = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requirePersonKey, value);
    notifyListeners();
  }

  /// Resetea todas las configuraciones
  Future<void> resetSettings() async {
    _showSkeleton = true;
    _showAngles = true;
    _showQualityBar = true;
    _soundEnabled = false;
    _minAngleThreshold = 100.0;
    _requirePerson = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
    print('✅ Configuraciones reseteadas');
  }
}

