import 'dart:math' as math;

class Nutrients {
  final double kcal, protein, carbohydrate, fat, fiber;
  const Nutrients({this.kcal = 0, this.protein = 0, this.carbohydrate = 0, this.fat = 0, this.fiber = 0});
  Nutrients operator +(Nutrients other) => Nutrients(kcal: kcal + other.kcal, protein: protein + other.protein, carbohydrate: carbohydrate + other.carbohydrate, fat: fat + other.fat, fiber: fiber + other.fiber);
  Nutrients scale(num factor) => Nutrients(kcal: kcal * factor, protein: protein * factor, carbohydrate: carbohydrate * factor, fat: fat * factor, fiber: fiber * factor);
  Map<String, dynamic> toJson() => {'kcal': kcal, 'protein': protein, 'carbohydrate': carbohydrate, 'fat': fat, 'fiber': fiber};
  factory Nutrients.fromJson(Object? value) {
    final json = Map<String, dynamic>.from(value as Map);
    double read(String key) {
      final n = json[key];
      if (n is! num || !n.toDouble().isFinite || n < 0 || n > 100000) throw const FormatException('Invalid nutrients');
      return n.toDouble();
    }
    return Nutrients(kcal: read('kcal'), protein: read('protein'), carbohydrate: read('carbohydrate'), fat: read('fat'), fiber: read('fiber'));
  }
}

String dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime parseDay(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) throw const FormatException('Invalid day');
  final result = DateTime.parse(value);
  if (dayKey(result) != value) throw const FormatException('Invalid calendar day');
  return result;
}

/// Digits from Latin, Arabic-Indic and Extended Arabic-Indic alphabets.
String normalizeDigits(String input) => input.replaceAllMapped(RegExp(r'[\u0660-\u0669\u06F0-\u06F9]'), (match) {
  final value = match.group(0)!.runes.single;
  return (value >= 0x06F0 ? value - 0x06F0 : value - 0x0660).toString();
});

double? parsePositive(String input, {double max = 100000}) {
  final clean = normalizeDigits(input.trim()).replaceAll('٫', '.').replaceAll(',', '.');
  if (clean.length > 24 || !RegExp(r'^\d+(?:\.\d{1,4})?$').hasMatch(clean)) return null;
  final result = double.tryParse(clean);
  return result != null && result.isFinite && result > 0 && result <= max ? result : null;
}

double calculateBmi(double weightKg, double heightCm) {
  if (![weightKg, heightCm].every((n) => n.isFinite && n > 0)) throw ArgumentError('Invalid body measurements');
  return weightKg / math.pow(heightCm / 100, 2);
}

double estimateBmr({required double weightKg, required double heightCm, required int age, required bool male}) {
  if (weightKg <= 0 || heightCm <= 0 || age < 13 || age > 110) throw ArgumentError('Invalid inputs');
  return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + (male ? 5 : -161);
}

int safeGoalKcal(double bmr, double activityMultiplier, {double adjustment = 0}) {
  if (!bmr.isFinite || bmr <= 0 || !activityMultiplier.isFinite || activityMultiplier < 1.2 || activityMultiplier > 2.0) throw ArgumentError('Invalid calorie estimate');
  return (bmr * activityMultiplier + adjustment).round().clamp(1200, 6000).toInt();
}