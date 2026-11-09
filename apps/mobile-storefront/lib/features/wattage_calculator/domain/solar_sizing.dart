import 'dart:math' as math;

enum SystemType { onGrid, hybrid, offGrid }

enum Phase { single, three }

/// What the shopper typed, with loads already converted to kW (see
/// [SolarSizing.ampsToKw]).
class SizingInput {
  const SizingInput({
    required this.type,
    required this.phase,
    required this.dayLoadKw,
    this.nightLoadKw = 0,
    this.nightHours = 0,
    this.withBattery = true,
  });

  final SystemType type;
  final Phase phase;

  /// On-grid: the load to cover. Hybrid/off-grid: the daytime load.
  final double dayLoadKw;
  final double nightLoadKw;
  final double nightHours;

  /// Hybrid only — off-grid always has batteries, on-grid never does.
  final bool withBattery;

  bool get hasBattery => switch (type) {
        SystemType.onGrid => false,
        SystemType.hybrid => withBattery,
        SystemType.offGrid => true,
      };
}

class SizingResult {
  const SizingResult({
    required this.panelCount,
    required this.arrayKwp,
    required this.inverterKw,
    required this.batteryCount,
    required this.batteryKwh,
    required this.dailyProductionKwh,
  });

  final int panelCount;
  final double arrayKwp;
  final double inverterKw;
  final int batteryCount;
  final double batteryKwh;
  final double dailyProductionKwh;
}

/// The sizing assumptions. Admins set them in the console (config/calculator,
/// written by admin-updateCalculatorSettings); [defaults] is used until then
/// or if they can't be loaded.
class SizingConfig {
  const SizingConfig({
    required this.panelWattage,
    required this.batteryModuleKwh,
    required this.peakSunHours,
    required this.lossMarginPercent,
    required this.batteryUsablePercent,
    required this.performancePercent,
  });

  static const defaults = SizingConfig(
    panelWattage: 585,
    batteryModuleKwh: 5.12,
    peakSunHours: 5.5,
    lossMarginPercent: 25,
    batteryUsablePercent: 85.5, // 90% depth of discharge × 95% efficiency
    performancePercent: 80,
  );

  factory SizingConfig.fromMap(Map<String, dynamic>? d) {
    double v(String key, double fallback) {
      final x = d?[key];
      return x is num && x > 0 ? x.toDouble() : fallback;
    }

    const f = defaults;
    return SizingConfig(
      panelWattage: v('panelWattage', f.panelWattage.toDouble()).round(),
      batteryModuleKwh: v('batteryModuleKwh', f.batteryModuleKwh),
      peakSunHours: v('peakSunHours', f.peakSunHours),
      lossMarginPercent: d?['lossMarginPercent'] is num ? (d!['lossMarginPercent'] as num).toDouble() : f.lossMarginPercent,
      batteryUsablePercent: v('batteryUsablePercent', f.batteryUsablePercent),
      performancePercent: v('performancePercent', f.performancePercent),
    );
  }

  final int panelWattage;
  final double batteryModuleKwh;
  final double peakSunHours;
  final double lossMarginPercent;
  final double batteryUsablePercent;
  final double performancePercent;
}

/// Rule-of-thumb sizing, the way installers quote it:
///
/// * The array must carry the daytime load directly and, when there are
///   batteries, also recharge what the night used — within the peak sun
///   hours — plus a loss margin for heat, dust and wiring.
/// * The inverter covers the larger of the day and night loads plus the
///   same margin, rounded up to a size that is actually sold for that phase.
/// * Batteries are modules of a fixed size, of which only the usable share
///   counts, sized for one night.
class SolarSizing {
  SolarSizing._();

  static const _singlePhaseInverters = [3.0, 4, 5, 6, 8, 10, 12];
  static const _threePhaseInverters = [5.0, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100];

  /// Current to power at Iraqi grid voltage: 230 V single phase,
  /// 400 V line-to-line (√3 × V × I) three phase.
  static double ampsToKw(double amps, Phase phase) => switch (phase) {
        Phase.single => amps * 230 / 1000,
        Phase.three => math.sqrt(3) * 400 * amps / 1000,
      };

  static SizingResult calculate(SizingInput input, [SizingConfig config = SizingConfig.defaults]) {
    final battery = input.hasBattery;
    final nightKwh = battery ? input.nightLoadKw * input.nightHours : 0.0;
    final headroom = 1 + config.lossMarginPercent / 100;

    final arrayKwp = (input.dayLoadKw + nightKwh / config.peakSunHours) * headroom;
    final panelCount = arrayKwp <= 0 ? 0 : (arrayKwp * 1000 / config.panelWattage).ceil();
    final installedKwp = panelCount * config.panelWattage / 1000;

    final peakLoad = battery ? math.max(input.dayLoadKw, input.nightLoadKw) : input.dayLoadKw;
    final inverterKw = peakLoad <= 0 ? 0.0 : _inverterSize(peakLoad * headroom, input.phase);

    final batteryKwhNeeded = nightKwh / (config.batteryUsablePercent / 100);
    final batteryCount = batteryKwhNeeded <= 0 ? 0 : (batteryKwhNeeded / config.batteryModuleKwh).ceil();

    return SizingResult(
      panelCount: panelCount,
      arrayKwp: installedKwp,
      inverterKw: inverterKw,
      batteryCount: batteryCount,
      batteryKwh: batteryCount * config.batteryModuleKwh,
      dailyProductionKwh: installedKwp * config.peakSunHours * config.performancePercent / 100,
    );
  }

  static double _inverterSize(double kw, Phase phase) {
    final sizes = phase == Phase.single ? _singlePhaseInverters : _threePhaseInverters;
    for (final s in sizes) {
      if (s >= kw) return s.toDouble();
    }
    // Beyond the largest single unit: whole tens of kW (paralleled units).
    return (kw / 10).ceil() * 10.0;
  }
}
