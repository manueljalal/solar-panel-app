/// Real (if simplified) sizing math — matches the reference PDF's
/// wattage calculator: system size = daily usage ÷ peak sunlight hours,
/// then divided into panels of a fixed wattage.
class SystemSizeEstimate {
  const SystemSizeEstimate({required this.systemKw, required this.panelCount, required this.panelWattage});

  factory SystemSizeEstimate.calculate({
    required double dailyUsageKwh,
    required double peakSunHours,
    int panelWattage = 450,
  }) {
    if (peakSunHours <= 0) {
      return SystemSizeEstimate(systemKw: 0, panelCount: 0, panelWattage: panelWattage);
    }
    final systemKw = dailyUsageKwh / peakSunHours;
    final panelCount = (systemKw * 1000 / panelWattage).ceil();
    return SystemSizeEstimate(systemKw: systemKw, panelCount: panelCount, panelWattage: panelWattage);
  }

  final double systemKw;
  final int panelCount;
  final int panelWattage;
}
