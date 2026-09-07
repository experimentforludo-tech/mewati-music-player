/// Locked TM + 5-band custom. Keep in sync with SOUND_LOCK.json / web eq-presets.ts.
class EqPreset {
  const EqPreset({
    required this.id,
    required this.label,
    required this.gains,
    required this.bass,
    this.width = 1.0,
    this.truBass = 0.0,
    this.focus = 0.0,
    this.definition = 0.0,
    this.makeup = 0.0,
    this.compress = false,
    this.haas = 0.0,
    this.advanced = false,
  });

  final String id;
  final String label;
  final List<double> gains;
  final double bass;
  final double width;
  final double truBass;
  final double focus;
  final double definition;
  final double makeup;
  final bool compress;
  final double haas;
  final bool advanced;
}

class EqPresets {
  static const uiBandsHz = [60.0, 230.0, 910.0, 3600.0, 14000.0];
  static const dspBandsHz = [
    32.0, 64.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0,
  ];
  static const minDb = -15.0;
  static const maxDb = 15.0;
  static const maxBassBoostDb = 6.0;
  static const headphoneHintIds = {'mewati-bass', 'beats', 'wow'};
  static const headphoneHint =
      'Please use your headphones for premium sound quality';

  static const list = <EqPreset>[
    EqPreset(id: 'normal', label: 'Normal', gains: [0, 0, 0, 0, 0], bass: 0),
    EqPreset(
      id: 'mewati-bass',
      label: 'Mewati Bass™',
      gains: [6, 7, 6, 3, -1, -3, -5, -7, -9, -11],
      bass: 3,
      width: 1,
      truBass: 0.35,
      advanced: true,
    ),
    EqPreset(
      id: 'beats',
      label: 'Mewati Beats™',
      gains: [6, 6, 2, -2, -5, -5, -1, 4, 8, 3],
      bass: 1.5,
      width: 1.02,
      truBass: 0.12,
      makeup: 2.0,
      compress: true,
      advanced: true,
    ),
    EqPreset(
      id: 'wow',
      label: 'Mewati Boom™',
      gains: [4, 5, 4, 1, -2, -2, 1, 4, 6, 4],
      bass: 2,
      width: 1.72,
      truBass: 0.6,
      focus: 3.8,
      definition: 6.5,
      makeup: 1.2,
      haas: 0.0009,
      advanced: true,
    ),
    EqPreset(id: 'vocal', label: 'Vocal ++', gains: [-2, -1, 5.5, 5, 0.5], bass: 0),
    EqPreset(id: 'treble', label: 'Treble Boost', gains: [0, 0, 0, 2.5, 6], bass: 0),
  ];

  static EqPreset byId(String id) {
    for (final p in list) {
      if (p.id == id) return p;
    }
    return list[1];
  }

  static List<double> upsample5to10(List<double> g) {
    final a = g.isNotEmpty ? g[0] : 0.0;
    final b = g.length > 1 ? g[1] : 0.0;
    final c = g.length > 2 ? g[2] : 0.0;
    final d = g.length > 3 ? g[3] : 0.0;
    final e = g.length > 4 ? g[4] : 0.0;
    return [a, a, (a + b) / 2, b, (b + c) / 2, c, (c + d) / 2, d, (d + e) / 2, e];
  }
}
