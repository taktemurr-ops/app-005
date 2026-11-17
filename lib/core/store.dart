import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'catalog.dart';
import 'models.dart';
import 'nutrition.dart';

abstract class StoreBackend {
  Future<String?> read();
  Future<void> write(String content);
  Future<void> delete();
}

class SecureBackend implements StoreBackend {
  const SecureBackend();
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static const _key = 'kalori360_v1';
  @override Future<String?> read() => _storage.read(key: _key);
  @override Future<void> write(String content) => _storage.write(key: _key, value: content);
  @override Future<void> delete() => _storage.delete(key: _key);
}

class MemoryBackend implements StoreBackend {
  String? content;
  bool failWrites = false;
  @override Future<String?> read() async => content;
  @override Future<void> write(String value) async { if (failWrites) throw StateError('Simulated storage failure'); content = value; }
  @override Future<void> delete() async { if (failWrites) throw StateError('Simulated storage failure'); content = null; }
}

class KaloriStore extends ChangeNotifier {
  KaloriStore({StoreBackend? backend}) : _backend = backend ?? const SecureBackend();
  final StoreBackend _backend;
  Future<void> _writeQueue = Future<void>.value();
  bool initialized = false;
  List<Food> foods = defaultFoods();
  List<MealEntry> meals = [];
  List<Recipe> recipes = defaultRecipes();
  List<PlanEntry> plans = [];
  List<Note> notes = [];
  List<TaskItem> tasks = [];
  List<Project> projects = [];
  List<Intake> water = [];
  List<WeighIn> weights = [];
  List<Challenge> challenges = [];
  List<Member> members = [];
  Set<String> lessonsDone = {};
  Set<String> favoritedFoods = {};
  Map<String, bool> rules = {'waterPrompt': true, 'dailyReview': true, 'goalWarning': true};
  Goal goal = const Goal();
  String activeMemberId = 'self';
  String? loadError;
  int _counter = 0;

  String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_counter++}_${Random.secure().nextInt(99999999)}';
  Food? findFood(String id) { for (final food in foods) { if (food.id == id) return food; } return null; }
  Nutrients recipeNutrients(Recipe recipe) {
    var total = const Nutrients();
    for (final entry in recipe.ingredients.entries) {
      final food = findFood(entry.key);
      if (food != null) total = total + food.per100g.scale(entry.value / 100);
    }
    return total;
  }
  List<MealEntry> entriesFor(String day) => meals.where((entry) => entry.day == day).toList();
  Nutrients totalsFor(String day) => entriesFor(day).fold(const Nutrients(), (a, b) => a + b.nutrients);
  double waterFor(String day) => water.where((e) => e.day == day).fold(0, (double a, e) => a + e.amount);
  double? latestWeight() => weights.isEmpty ? null : (weights.toList()..sort((a, b) => b.day.compareTo(a.day))).first.kg;
  int get lessonPoints => lessonsDone.length * 20;
  int get challengePoints => challenges.fold(0, (int sum, c) => sum + c.completedDays.length * 10);
  int get totalPoints => lessonPoints + challengePoints;

  Map<String, dynamic> _snapshot() => {
    'schemaVersion': 1,
    'foods': foods.map((f) => f.toJson()).toList(),
    'meals': meals.map((m) => m.toJson()).toList(),
    'recipes': recipes.map((r) => r.toJson()).toList(),
    'plans': plans.map((p) => p.toJson()).toList(),
    'notes': notes.map((n) => n.toJson()).toList(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'projects': projects.map((p) => p.toJson()).toList(),
    'water': water.map((w) => w.toJson()).toList(),
    'weights': weights.map((w) => w.toJson()).toList(),
    'challenges': challenges.map((c) => c.toJson()).toList(),
    'members': members.map((m) => m.toJson()).toList(),
    'lessonsDone': lessonsDone.toList(),
    'favoritedFoods': favoritedFoods.toList(),
    'rules': rules,
    'goal': goal.toJson(),
  };

  void _restore(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) throw const FormatException('Unsupported backup version');
    List<T> parse<T>(String key, T Function(Object?) convert) {
      final list = json[key];
      if (list is! List || list.length > 15000) throw FormatException('Invalid $key');
      return list.map(convert).toList();
    }
    final nextFoods = parse('foods', Food.fromJson);
    final nextMeals = parse('meals', MealEntry.fromJson);
    final nextRecipes = parse('recipes', Recipe.fromJson);
    final nextPlans = parse('plans', PlanEntry.fromJson);
    final nextNotes = parse('notes', Note.fromJson);
    final nextTasks = parse('tasks', TaskItem.fromJson);
    final nextProjects = parse('projects', Project.fromJson);
    final nextWater = parse('water', Intake.fromJson);
    final nextWeights = parse('weights', WeighIn.fromJson);
    final nextChallenges = parse('challenges', Challenge.fromJson);
    final nextMembers = parse('members', Member.fromJson);
    final nextGoal = Goal.fromJson(json['goal']);
    final nextLessons = Set<String>.from(json['lessonsDone'] as List);
    final nextFavorites = Set<String>.from(json['favoritedFoods'] as List);
    final nextRules = Map<String, bool>.from(json['rules'] as Map);
    if (nextFoods.isEmpty || nextFoods.length > 10000 || nextRecipes.length > 10000 || nextMembers.length > 50 || nextLessons.any((v) => v.length > 100) || nextFavorites.any((v) => v.length > 100)) throw const FormatException('Invalid collection size');
    if (nextFoods.map((e) => e.id).toSet().length != nextFoods.length) throw const FormatException('Duplicate food IDs');
    foods = nextFoods; meals = nextMeals; recipes = nextRecipes; plans = nextPlans; notes = nextNotes;
    tasks = nextTasks; projects = nextProjects; water = nextWater; weights = nextWeights; challenges = nextChallenges;
    members = nextMembers; goal = nextGoal; lessonsDone = nextLessons; favoritedFoods = nextFavorites; rules = nextRules;
    notifyListeners();
  }

  /// Validate and decode complete backup before mutation, so a corrupt backup does not discard working state.
  static Map<String, dynamic> decodeBackup(String data) {
    if (data.length > 5000000) throw const FormatException('Backup too large');
    final json = jsonDecode(data);
    if (json is! Map) throw const FormatException('Backup is not an object');
    return Map<String, dynamic>.from(json);
  }

  Future<void> load() async {
    try {
      final raw = await _backend.read();
      if (raw != null) _restore(decodeBackup(raw));
      loadError = null;
    } catch (_) { loadError = 'Could not restore saved data; the original backup was not overwritten.'; }
    initialized = true;
    notifyListeners();
  }
  String exportJson() => const JsonEncoder.withIndent('  ').convert({'exportedAt': DateTime.now().toUtc().toIso8601String(), ..._snapshot()});
  Future<void> importJson(String raw) async {
    final decoded = decodeBackup(raw);
    final candidate = KaloriStore(backend: MemoryBackend());
    try {
      candidate._restore(decoded); // Validated before modifying encrypted state.
      final encoded = jsonEncode(candidate._snapshot());
      await _enqueue(() async {
        await _backend.write(encoded);
        _restore(candidate._snapshot());
      });
    } finally {
      candidate.dispose();
    }
  }
  // Serialize all operations that touch encrypted storage, even when users tap
  // several buttons quickly. A failed operation must not block later writes.
  Future<T> _enqueue<T>(Future<T> Function() work) {
    final result = _writeQueue.then((_) => work());
    _writeQueue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
  Future<void> _transaction(void Function() mutate) => _enqueue(() async {
    if (loadError != null) throw StateError('Cannot write until storage is recovered');
    final before = _snapshot();
    try {
      mutate();
      await _backend.write(jsonEncode(_snapshot()));
      notifyListeners();
    } catch (_) {
      _restore(before);
      rethrow;
    }
  });
  Future<void> reset() => _enqueue(() async {
    await _backend.delete();
    _restore(KaloriStore(backend: MemoryBackend())._snapshot());
    loadError = null;
  });
  Future<void> addFood(String name, String category, Nutrients per100g, double serving) => _transaction(() {
    if (name.trim().isEmpty || name.length > 120 || category.trim().isEmpty || category.length > 60 || !serving.isFinite || serving <= 0 || serving > 10000) throw ArgumentError('Invalid food');
    foods.add(Food(id: newId(), name: name.trim(), category: category, per100g: per100g, servingGrams: serving));
  });
  Future<void> deleteFood(String id) => _transaction(() {
    if (defaultFoods().any((f) => f.id == id)) throw StateError('Built-in foods cannot be deleted');
    if (recipes.any((r) => r.ingredients.containsKey(id)) || plans.any((p) => p.foodId == id)) throw StateError('Food is used in recipes or plans');
    foods.removeWhere((f) => f.id == id);
    favoritedFoods.remove(id);
  });
  Future<void> toggleFavorite(String id) => _transaction(() { if (!favoritedFoods.remove(id)) favoritedFoods.add(id); });
  Future<void> addMeal(Food food, double grams, String meal, String day) => _transaction(() {
    parseDay(day);
    if (!standardMeals.contains(meal) || !grams.isFinite || grams <= 0 || grams > 10000) throw ArgumentError('Invalid meal');
    meals.add(MealEntry(id: newId(), foodId: food.id, foodName: food.name, meal: meal, day: day, grams: grams, nutrients: food.per100g.scale(grams / 100)));
  });
  Future<void> removeMeal(String id) => _transaction(() => meals.removeWhere((m) => m.id == id));
  Future<void> addWater(double ml, String day) => _transaction(() {
    parseDay(day); if (!ml.isFinite || ml <= 0 || ml > 10000) throw ArgumentError('Invalid water');
    water.add(Intake(id: newId(), day: day, amount: ml));
  });
  Future<void> addWeight(double kg, String day) => _transaction(() {
    parseDay(day); if (!kg.isFinite || kg <= 0 || kg > 600) throw ArgumentError('Invalid weight');
    weights.add(WeighIn(id: newId(), day: day, kg: kg));
  });
  Future<void> changeGoal(Goal newGoal) => _transaction(() {
    Goal.fromJson(newGoal.toJson());
    goal = newGoal;
  });
  Future<void> addRecipe(String title, String instructions, Map<String, double> ingredients) => _transaction(() {
    if (ingredients.isEmpty || ingredients.length > 40 || title.trim().isEmpty || title.length > 120 || instructions.length > 2000) throw ArgumentError('Invalid recipe');
    for (final e in ingredients.entries) { if (findFood(e.key) == null || !e.value.isFinite || e.value <= 0 || e.value > 10000) throw ArgumentError('Invalid recipe ingredient'); }
    recipes.add(Recipe(id: newId(), title: title.trim(), instructions: instructions, ingredients: Map.of(ingredients)));
  });
  Future<void> deleteRecipe(String id) => _transaction(() => recipes.removeWhere((e) => e.id == id));
  Future<void> addPlan(String day, String meal, String foodId, double grams) => _transaction(() {
    parseDay(day); if (!standardMeals.contains(meal) || findFood(foodId) == null || grams <= 0 || !grams.isFinite || grams > 10000) throw ArgumentError('Invalid plan');
    plans.add(PlanEntry(id: newId(), day: day, meal: meal, foodId: foodId, grams: grams));
  });
  Future<void> removePlan(String id) => _transaction(() => plans.removeWhere((e) => e.id == id));
  Future<void> logPlan(PlanEntry plan) async {
    final food = findFood(plan.foodId);
    if (food == null) throw StateError('Planned food not found');
    await addMeal(food, plan.grams, plan.meal, plan.day);
  }
  Future<void> addNote(String content, String day) => _transaction(() {
    parseDay(day); if (content.trim().isEmpty || content.length > 2000) throw ArgumentError('Invalid note');
    notes.add(Note(id: newId(), day: day, text: content.trim()));
  });
  Future<void> deleteNote(String id) => _transaction(() => notes.removeWhere((e) => e.id == id));
  Future<void> addProject(String title, String description) => _transaction(() {
    if (title.trim().isEmpty || title.length > 160 || description.length > 2000) throw ArgumentError('Invalid project');
    projects.add(Project(id: newId(), title: title.trim(), description: description));
  });
  Future<void> toggleProject(String id) => _transaction(() {
    final index = projects.indexWhere((e) => e.id == id);
    if (index >= 0) projects[index] = projects[index].toggle();
  });
  Future<void> deleteProject(String id) => _transaction(() {
    projects.removeWhere((p) => p.id == id); tasks.removeWhere((t) => t.projectId == id);
  });
  Future<void> addTask(String title, {String projectId = ''}) => _transaction(() {
    if (title.trim().isEmpty || title.length > 160) throw ArgumentError('Invalid task');
    tasks.add(TaskItem(id: newId(), title: title.trim(), projectId: projectId));
  });
  Future<void> toggleTask(String id) => _transaction(() {
    final index = tasks.indexWhere((e) => e.id == id);
    if (index >= 0) tasks[index] = tasks[index].toggle();
  });
  Future<void> deleteTask(String id) => _transaction(() => tasks.removeWhere((e) => e.id == id));
  Future<void> addChallenge(String title, int targetDays) => _transaction(() {
    if (title.trim().isEmpty || title.length > 120 || targetDays < 1 || targetDays > 365) throw ArgumentError('Invalid challenge');
    challenges.add(Challenge(id: newId(), title: title.trim(), targetDays: targetDays, completedDays: {}));
  });
  Future<void> toggleChallenge(String id, String day) => _transaction(() {
    final index = challenges.indexWhere((c) => c.id == id);
    if (index >= 0) challenges[index] = challenges[index].toggle(day);
  });
  Future<void> removeChallenge(String id) => _transaction(() => challenges.removeWhere((e) => e.id == id));
  Future<void> completeLesson(String id) => _transaction(() { if (!lessonsDone.remove(id)) lessonsDone.add(id); });
  Future<void> addMember(String name) => _transaction(() {
    if (name.trim().isEmpty || name.length > 90 || members.length >= 50) throw ArgumentError('Invalid family member');
    members.add(Member(id: newId(), name: name.trim()));
  });
  Future<void> deleteMember(String id) => _transaction(() => members.removeWhere((m) => m.id == id));
  Future<void> toggleRule(String rule) => _transaction(() { if (!rules.containsKey(rule)) throw ArgumentError('Unknown rule'); rules[rule] = !(rules[rule] ?? false); });
}