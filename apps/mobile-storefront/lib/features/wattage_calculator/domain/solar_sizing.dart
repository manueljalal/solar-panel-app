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

/// Rule-of-thumb sizing for Iraq, the way installers quote it:
///
/// * The array must carry the daytime load directly and, when there are
///   batteries, also recharge what the night used — within Iraq's ~5.5
///   peak sun hours — with 25% headroom for heat, dust and wiring losses.
/// * The inverter covers the larger of the day and night loads with 25%
///   headroom, rounded up to a size that is actually sold for that phase.
/// * Batteries are 5.12 kWh lithium (LiFePO4) modules, 90% usable, 95%
///   round-trip efficient, sized for one night.
class SolarSizing {
  SolarSizing._();

  static const panelWattage = 585;
  static const batteryModuleKwh = 5.12;
  static const peakSunHours = 5.5;
  static const _headroom = 1.25;
  static const _batteryUsable = 0.9 * 0.95;
  static const _performanceRatio = 0.8;

  static const _singlePhaseInverters = [3.0, 4, 5, 6, 8, 10, 12];
  static const _threePhaseInverters = [5.0, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100];

  /// Current to power at Iraqi grid voltage: 230 V single phase,
  /// 400 V line-to-line (√3 × V × I) three phase.
  static double ampsToKw(double amps, Phase phase) => switch (phase) {
        Phase.single => amps * 230 / 1000,
        Phase.three => math.sqrt(3) * 400 * amps / 1000,
      };

  static SizingResult calculate(SizingInput input) {
    final battery = input.hasBattery;
    final nightKwh = battery ? input.nightLoadKw * input.nightHours : 0.0;

    final arrayKwp = (input.dayLoadKw + nightKwh / peakSunHours) * _headroom;
    final panelCount = arrayKwp <= 0 ? 0 : (arrayKwp * 1000 / panelWattage).ceil();
    final installedKwp = panelCount * panelWattage / 1000;

    final peakLoad = battery ? math.max(input.dayLoadKw, input.nightLoadKw) : input.dayLoadKw;
    final inverterKw = peakLoad <= 0 ? 0.0 : _inverterSize(peakLoad * _headroom, input.phase);

    final batteryKwhNeeded = nightKwh / _batteryUsable;
    final batteryCount = batteryKwhNeeded <= 0 ? 0 : (batteryKwhNeeded / batteryModuleKwh).ceil();

    return SizingResult(
      panelCount: panelCount,
      arrayKwp: installedKwp,
      inverterKw: inverterKw,
      batteryCount: batteryCount,
      batteryKwh: batteryCount * batteryModuleKwh,
      dailyProductionKwh: installedKwp * peakSunHours * _performanceRatio,
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
