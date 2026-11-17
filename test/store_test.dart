import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori_360/core/models.dart';
import 'package:kalori_360/core/nutrition.dart';
import 'package:kalori_360/core/store.dart';

void main() {
  const today = '2026-11-17';
  group('encrypted-store-compatible state model', () {
    late MemoryBackend backend;
    late KaloriStore store;
    setUp(() async {
      backend = MemoryBackend();
      store = KaloriStore(backend: backend);
      await store.load();
    });
    tearDown(() => store.dispose());

    test('starts with a real food catalogue and fixed recipe nutrients', () {
      expect(store.foods.length, greaterThan(10));
      expect(store.recipes.length, greaterThan(0));
      final recipe = store.recipes.first;
      expect(store.recipeNutrients(recipe).kcal, greaterThan(100));
    });
    test('records meals and preserves historical nutrients after custom food is updated', () async {
      final apple = store.findFood('apple')!;
      await store.addMeal(apple, 150, 'breakfast', today);
      final n = store.totalsFor(today);
      expect(n.kcal, closeTo(78, 0.001));
      expect(n.carbohydrate, closeTo(20.7, 0.001));
      expect(store.entriesFor('2026-11-18'), isEmpty);
      await store.removeMeal(store.entriesFor(today).single.id);
      expect(store.totalsFor(today).kcal, 0);
    });
    test('rejects invalid logged amounts and meal types', () async {
      expect(() => store.addMeal(store.foods.first, -50, 'lunch', today), throwsArgumentError);
      expect(() => store.addMeal(store.foods.first, 120, 'brunch', today), throwsArgumentError);
      expect(store.meals, isEmpty);
    });
    test('logs plans, allows deletion and protects foods used by plans', () async {
      await store.addFood('Sample', 'test', const Nutrients(kcal: 120), 100);
      final custom = store.foods.last;
      await store.addPlan(today, 'dinner', custom.id, 250);
      expect(() => store.deleteFood(custom.id), throwsStateError);
      await store.logPlan(store.plans.single);
      expect(store.totalsFor(today).kcal, 300);
      await store.removePlan(store.plans.single.id);
      await store.deleteFood(custom.id);
      expect(store.findFood(custom.id), isNull);
    });
    test('recipe builder computes nutrients', () async {
      await store.addRecipe('Apple + oats', 'Mix', {'apple': 100, 'oats': 40});
      final recipe = store.recipes.last;
      expect(store.recipeNutrients(recipe).kcal, closeTo(207.6, 0.001));
      expect(recipe.ingredients.length, 2);
      await store.deleteRecipe(recipe.id);
      expect(store.recipes.any((e) => e.id == recipe.id), isFalse);
    });
    test('concurrent local writes are serialized and not lost', () async {
      await Future.wait(List.generate(40, (_) => store.addWater(100, today)));
      expect(store.waterFor(today), 4000);
      final restored = KaloriStore(backend: backend);
      await restored.load();
      expect(restored.waterFor(today), 4000);
      restored.dispose();
    });
    test('water, weight and targets persist', () async {
      await store.addWater(250, today);
      await store.addWater(500, today);
      await store.addWeight(75.4, today);
      await store.changeGoal(const Goal(kcal: 1800, protein: 90, carbs: 195, fat: 55, waterMl: 2500));
      expect(store.waterFor(today), 750);
      expect(store.latestWeight(), 75.4);
      final restored = KaloriStore(backend: backend);
      await restored.load();
      expect(restored.goal.kcal, 1800);
      expect(restored.waterFor(today), 750);
      expect(restored.latestWeight(), 75.4);
      restored.dispose();
    });
    test('journals, projects, checklists and challenges are actionable', () async {
      await store.addNote('A good day', today);
      await store.addProject('Plan lunches', 'Prepare meals on Sunday');
      final project = store.projects.single;
      await store.addTask('Get groceries', projectId: project.id);
      await store.toggleTask(store.tasks.single.id);
      expect(store.tasks.single.done, isTrue);
      await store.addChallenge('Drink water', 7);
      await store.toggleChallenge(store.challenges.single.id, today);
      expect(store.challenges.single.completedDays, contains(today));
      expect(store.totalPoints, 10);
      await store.completeLesson('macros');
      expect(store.totalPoints, 30);
      await store.toggleProject(project.id);
      expect(store.projects.single.done, isTrue);
      await store.deleteProject(project.id);
      expect(store.tasks, isEmpty);
      expect(store.notes.single.text, 'A good day');
    });
    test('favorites, households and local rules work', () async {
      await store.toggleFavorite('apple');
      expect(store.favoritedFoods, contains('apple'));
      await store.addMember('Family A');
      expect(store.members.single.name, 'Family A');
      await store.toggleRule('waterPrompt');
      expect(store.rules['waterPrompt'], false);
      await store.deleteMember(store.members.single.id);
      expect(store.members, isEmpty);
    });
    test('JSON backup is portable and roundtrips all modules', () async {
      await store.addMeal(store.foods.first, 100, 'breakfast', today);
      await store.addNote('Çok iyi gün 🌿 العربية', today);
      await store.addProject('P', 'Hello');
      final raw = store.exportJson();
      expect(raw, contains('Çok iyi gün'));
      final other = KaloriStore(backend: MemoryBackend());
      await other.load();
      await other.importJson(raw);
      expect(other.meals.length, 1);
      expect(other.notes.single.text, 'Çok iyi gün 🌿 العربية');
      expect(other.projects.single.title, 'P');
      other.dispose();
    });
    test('malformed import is fully rejected; valid data remain', () async {
      await store.addNote('Keep', today);
      final before = backend.content;
      expect(() => store.importJson('{broken'), throwsFormatException);
      final corrupted = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      (corrupted['meals'] as List).add({'bad': true});
      expect(() => store.importJson(jsonEncode(corrupted)), throwsA(isA<Exception>()));
      expect(store.notes.single.text, 'Keep');
      expect(backend.content, before);
    });
    test('failed writes roll back memory and leave disk untouched', () async {
      await store.addNote('Original', today);
      final before = backend.content;
      backend.failWrites = true;
      expect(() => store.addNote('Lost', today), throwsStateError);
      expect(store.notes.map((e) => e.text).toList(), ['Original']);
      expect(backend.content, before);
    });
    test('clear all deletes data but seeds the catalogue again', () async {
      await store.addNote('Secret', today);
      await store.reset();
      expect(backend.content, isNull);
      expect(store.notes, isEmpty);
      expect(store.foods, isNotEmpty);
    });
    test('corrupted encrypted backup is preserved on load', () async {
      backend.content = 'this is not JSON';
      final newStore = KaloriStore(backend: backend);
      await newStore.load();
      expect(newStore.loadError, isNotNull);
      expect(backend.content, 'this is not JSON');
      expect(() => newStore.addNote('Blocked', today), throwsStateError);
      newStore.dispose();
    });
    test('oversize backup rejected', () {
      expect(() => KaloriStore.decodeBackup(' ' * 5000001), throwsFormatException);
    });
  });
}