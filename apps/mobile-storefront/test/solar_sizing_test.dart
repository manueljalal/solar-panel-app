import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/wattage_calculator/domain/solar_sizing.dart';

void main() {
  test('on-grid 5 kW single phase: 11 panels, 8 kW inverter, no batteries', () {
    final r = SolarSizing.calculate(const SizingInput(type: SystemType.onGrid, phase: Phase.single, dayLoadKw: 5));
    // 5 kW × 1.25 = 6.25 kWp → ceil(6250 / 585) = 11 panels.
    expect(r.panelCount, 11);
    expect(r.inverterKw, 8);
    expect(r.batteryCount, 0);
  });

  test('hybrid with battery sizes for the night: 3 kW day, 2 kW × 10 h night', () {
    final r = SolarSizing.calculate(const SizingInput(
      type: SystemType.hybrid,
      phase: Phase.single,
      dayLoadKw: 3,
      nightLoadKw: 2,
      nightHours: 10,
    ));
    // (3 + 20 / 5.5) × 1.25 = 8.3 kWp → 15 panels; 20 kWh / 0.855 → 5 modules.
    expect(r.panelCount, 15);
    expect(r.inverterKw, 4);
    expect(r.batteryCount, 5);
    expect(r.batteryKwh, closeTo(25.6, 0.001));
  });

  test('hybrid without battery ignores the night load', () {
    final r = SolarSizing.calculate(const SizingInput(
      type: SystemType.hybrid,
      phase: Phase.single,
      dayLoadKw: 3,
      nightLoadKw: 2,
      nightHours: 10,
      withBattery: false,
    ));
    expect(r.batteryCount, 0);
    expect(r.panelCount, 7); // 3.75 kWp
  });

  test('off-grid always has batteries; three-phase inverters start at 5 kW', () {
    final r = SolarSizing.calculate(const SizingInput(
      type: SystemType.offGrid,
      phase: Phase.three,
      dayLoadKw: 2,
      nightLoadKw: 1,
      nightHours: 8,
      withBattery: false,
    ));
    expect(r.batteryCount, greaterThan(0));
    expect(r.inverterKw, 5);
  });

  test('amps convert at 230 V single phase and 400 V three phase', () {
    expect(SolarSizing.ampsToKw(20, Phase.single), closeTo(4.6, 0.001));
    expect(SolarSizing.ampsToKw(10, Phase.three), closeTo(6.93, 0.01));
  });
}
