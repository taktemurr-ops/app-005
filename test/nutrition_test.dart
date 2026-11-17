import 'package:flutter_test/flutter_test.dart';
import 'package:kalori_360/core/catalog.dart';
import 'package:kalori_360/core/models.dart';
import 'package:kalori_360/core/nutrition.dart';

void main() {
  group('nutrition calculations', () {
    test('100 g and serving conversions are consistent', () {
      final oats = defaultFoods().firstWhere((f) => f.id == 'oats');
      final serving = oats.per100g.scale(0.4);
      expect(serving.kcal, closeTo(155.6, 0.001));
      expect(serving.protein, closeTo(6.76, 0.001));
      final doubled = serving + serving;
      expect(doubled.kcal, closeTo(311.2, 0.001));
    });
    test('Unicode digits and decimal separators are supported', () {
      expect(parsePositive('١٢٣٫٥'), 123.5);
      expect(parsePositive('۱۲۳,۵'), 123.5);
      expect(parsePositive(' 123.5 '), 123.5);
      expect(parsePositive('0'), isNull);
      expect(parsePositive('-5'), isNull);
      expect(parsePositive('1.2.3'), isNull);
      expect(parsePositive('1e9'), isNull);
      expect(parsePositive('NaN'), isNull);
      expect(parsePositive('Infinity'), isNull);
      expect(parsePositive('99999999'), isNull);
    });
    test('day keys roundtrip and reject overflow', () {
      expect(dayKey(DateTime(2026, 11, 17)), '2026-11-17');
      expect(parseDay('2026-11-17').day, 17);
      expect(() => parseDay('2026-02-30'), throwsFormatException);
      expect(() => parseDay('2026/11/17'), throwsFormatException);
    });
    test('bmi and BMR formula are deterministic', () {
      expect(calculateBmi(70, 175), closeTo(22.857, 0.001));
      expect(estimateBmr(weightKg: 70, heightCm: 175, age: 30, male: true), closeTo(1648.75, 0.001));
      expect(safeGoalKcal(1648.75, 1.4), 2308);
      expect(() => calculateBmi(70, 0), throwsArgumentError);
      expect(() => estimateBmr(weightKg: 70, heightCm: 175, age: 2, male: false), throwsArgumentError);
    });
    test('malformed nutrient maps are rejected', () {
      expect(() => Nutrients.fromJson({'kcal': -2, 'protein': 0, 'carbohydrate': 0, 'fat': 0, 'fiber': 0}), throwsFormatException);
      expect(() => Nutrients.fromJson({'kcal': 'text', 'protein': 0, 'carbohydrate': 0, 'fat': 0, 'fiber': 0}), throwsFormatException);
    });
  });
}