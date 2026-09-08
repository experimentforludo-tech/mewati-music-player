import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'eq_presets.dart';
import 'sound_policy.dart';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  static const _channel = MethodChannel('mewati.sound/dsp');
  static const presetPrefsKey = 'mtp-eq-preset-v1';
  static const _legacyPresetKey = 'eq_preset';
  static const _customEqBandsKey = 'custom_eq_band_gains';
  static const _customEqBassKey = 'custom_eq_bass_boost';
  static const defaultPresetId = 'normal';

  bool _isInitialized = false;
  bool _dspAlive = false;
  bool get isSupported => SoundPolicy.isSoftwareEngine;
  bool get dspAlive => _dspAlive;

  List<dynamic> get androidAudioEffects => const [];

  static const double maxBassBoostDb = EqPresets.maxBassBoostDb;

  Timer? _persistDebounce;
  List<double>? _pendingBands;
  double? _pendingBass;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!SoundPolicy.isSoftwareEngine) {
      _isInitialized = true;
      _dspAlive = false;
      return;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('init') ?? false;
      _dspAlive = ok;
    } on MissingPluginException {
      _dspAlive = false;
    } catch (e) {
      _dspAlive = false;
      if (kDebugMode) debugPrint('EqualizerService init dry: $e');
    }
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(presetPrefsKey) ??
          prefs.getString(_legacyPresetKey) ??
          defaultPresetId;
      if (prefs.getString(presetPrefsKey) == null) {
        await prefs.setString(presetPrefsKey, saved);
      }
      await applyPreset(saved);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService apply saved dry: $e');
    }
  }

  Future<void> applyPreset(String preset) async {
    try {
      if (!_isInitialized) await init();
      if (preset == 'custom') {
        await _applyPersistedCustomEq();
        await _savePresetId('custom');
        return;
      }
      final p = EqPresets.byId(preset);
      await _pushNative(p);
      await _savePresetId(p.id);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService applyPreset: $e');
    }
  }

  bool shouldHintHeadphones(String id) => EqPresets.headphoneHintIds.contains(id);

  Future<void> applyCustomSnapshot({
    required List<double> bandGains,
    required double bassBoostDb,
  }) async {
    try {
      final gains = [
        for (final g in bandGains) g.clamp(EqPresets.minDb, EqPresets.maxDb)
      ];
      final bass = bassBoostDb.clamp(0.0, maxBassBoostDb);
      _schedulePersist(gains, bass);
      await _pushCustom(gains, bass);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService applyCustomSnapshot: $e');
    }
  }

  Future<void> setBandGain(int bandIndex, double gainDb) async {
    try {
      final saved = await loadPersistedCustomEq(bandCount: EqPresets.uiBandsHz.length);
      final gains = List<double>.from(saved.bandGains);
      if (bandIndex < 0 || bandIndex >= gains.length) return;
      gains[bandIndex] = gainDb.clamp(EqPresets.minDb, EqPresets.maxDb);
      _schedulePersist(gains, saved.bassBoostDb);
      await _pushCustom(gains, saved.bassBoostDb);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService setBandGain: $e');
    }
  }

  Future<void> setBassBoost(double gainDb) async {
    try {
      final saved = await loadPersistedCustomEq(bandCount: EqPresets.uiBandsHz.length);
      final bass = gainDb.clamp(0.0, maxBassBoostDb);
      _schedulePersist(saved.bandGains, bass);
      await _pushCustom(saved.bandGains, bass);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService setBassBoost: $e');
    }
  }

  void _schedulePersist(List<double> bandGains, double bassBoostDb) {
    _pendingBands = List<double>.from(bandGains);
    _pendingBass = bassBoostDb;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 280), () {
      final g = _pendingBands;
      final b = _pendingBass;
      if (g == null || b == null) return;
      unawaited(persistCustomEq(bandGains: g, bassBoostDb: b));
    });
  }

  Future<void> persistCustomEq({
    required List<double> bandGains,
    required double bassBoostDb,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customEqBandsKey, jsonEncode(bandGains));
      await prefs.setDouble(_customEqBassKey, bassBoostDb);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService persistCustomEq: $e');
    }
  }

  Future<({List<double> bandGains, double bassBoostDb})> loadPersistedCustomEq({
    required int bandCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customEqBandsKey);
      List<double> gains;
      if (raw != null) {
        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        gains = List<double>.generate(
          bandCount,
          (i) => i < decoded.length ? decoded[i].clamp(EqPresets.minDb, EqPresets.maxDb) : 0.0,
        );
      } else {
        gains = List<double>.filled(bandCount, 0.0);
      }
      final bass = (prefs.getDouble(_customEqBassKey) ?? 0.0).clamp(0.0, maxBassBoostDb);
      return (bandGains: gains, bassBoostDb: bass);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService loadPersistedCustomEq: $e');
      return (bandGains: List<double>.filled(bandCount, 0.0), bassBoostDb: 0.0);
    }
  }

  Future<void> resetCustomEq() async {
    _persistDebounce?.cancel();
    final zeros = List<double>.filled(EqPresets.uiBandsHz.length, 0.0);
    await persistCustomEq(bandGains: zeros, bassBoostDb: 0);
    await _pushCustom(zeros, 0);
  }

  Future<void> _applyPersistedCustomEq() async {
    final saved = await loadPersistedCustomEq(bandCount: EqPresets.uiBandsHz.length);
    await _pushCustom(saved.bandGains, saved.bassBoostDb);
  }

  Future<void> _savePresetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(presetPrefsKey, id);
    await prefs.setString(_legacyPresetKey, id);
  }

  Future<void> _pushNative(EqPreset p) async {
    if (!_dspAlive) return;
    try {
      final gains = p.advanced ? p.gains : EqPresets.upsample5to10(p.gains);
      await _channel.invokeMethod('apply', {
        'gains': gains,
        'bass': p.bass,
        'width': p.advanced ? p.width : 1.0,
        'truBass': p.advanced ? p.truBass : 0.0,
        'focus': p.advanced ? p.focus : 0.0,
        'definition': p.advanced ? p.definition : 0.0,
        'makeup': p.advanced ? p.makeup : 0.0,
        'compress': p.advanced && p.compress,
        'haas': p.advanced ? p.haas : 0.0,
        'air': p.advanced ? p.air : 0.0,
        'truTreble': p.advanced ? p.truTreble : 0.0,
      });
    } catch (e) {
      _dspAlive = false;
      if (kDebugMode) debugPrint('EqualizerService native apply failed, staying dry: $e');
    }
  }

  Future<void> _pushCustom(List<double> gains5, double bass) async {
    if (!_dspAlive) return;
    try {
      await _channel.invokeMethod('apply', {
        'gains': EqPresets.upsample5to10(gains5),
        'bass': bass,
        'width': 1.0,
        'truBass': 0.0,
        'focus': 0.0,
        'definition': 0.0,
        'makeup': 0.0,
        'compress': false,
        'haas': 0.0,
        'air': 0.0,
        'truTreble': 0.0,
      });
    } catch (e) {
      _dspAlive = false;
      if (kDebugMode) debugPrint('EqualizerService custom apply dry: $e');
    }
  }
}