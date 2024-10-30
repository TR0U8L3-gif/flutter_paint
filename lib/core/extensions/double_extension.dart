extension DoubleExtension on double {
  double toPrecision(int fractionDigits) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}