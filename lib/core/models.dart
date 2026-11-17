import 'nutrition.dart';

String _str(Map<String, dynamic> json, String key, {int maxLength = 500}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty || value.length > maxLength) throw FormatException('Invalid $key');
  return value;
}
String _optional(Map<String, dynamic> json, String key, {int maxLength = 2000}) {
  final value = json[key] ?? '';
  if (value is! String || value.length > maxLength) throw FormatException('Invalid $key');
  return value;
}
double _positive(Map<String, dynamic> json, String key, {double max = 100000}) {
  final value = json[key];
  if (value is! num || !value.toDouble().isFinite || value <= 0 || value > max) throw FormatException('Invalid $key');
  return value.toDouble();
}

class Food {
  final String id, name, category;
  final Nutrients per100g;
  final double servingGrams;
  const Food({required this.id, required this.name, required this.category, required this.per100g, this.servingGrams = 100});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'per100g': per100g.toJson(), 'servingGrams': servingGrams};
  factory Food.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    return Food(id: _str(j, 'id', maxLength: 90), name: _str(j, 'name', maxLength: 120), category: _str(j, 'category', maxLength: 60), per100g: Nutrients.fromJson(j['per100g']), servingGrams: _positive(j, 'servingGrams', max: 10000));
  }
}

class MealEntry {
  final String id, foodId, foodName, meal, day;
  final double grams;
  final Nutrients nutrients;
  const MealEntry({required this.id, required this.foodId, required this.foodName, required this.meal, required this.day, required this.grams, required this.nutrients});
  Map<String, dynamic> toJson() => {'id': id, 'foodId': foodId, 'foodName': foodName, 'meal': meal, 'day': day, 'grams': grams, 'nutrients': nutrients.toJson()};
  factory MealEntry.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    parseDay(_str(j, 'day', maxLength: 10));
    final meal = _str(j, 'meal', maxLength: 20);
    if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(meal)) throw const FormatException('Invalid meal');
    return MealEntry(id: _str(j, 'id', maxLength: 90), foodId: _str(j, 'foodId', maxLength: 90), foodName: _str(j, 'foodName', maxLength: 120), meal: meal, day: j['day'] as String, grams: _positive(j, 'grams', max: 10000), nutrients: Nutrients.fromJson(j['nutrients']));
  }
}

class Recipe {
  final String id, title, instructions;
  final Map<String, double> ingredients;
  const Recipe({required this.id, required this.title, required this.instructions, required this.ingredients});
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'instructions': instructions, 'ingredients': ingredients};
  factory Recipe.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final parsed = <String, double>{};
    for (final entry in Map<String, dynamic>.from(j['ingredients'] as Map).entries) {
      if (entry.key.length > 90 || entry.value is! num || (entry.value as num) <= 0 || (entry.value as num) > 10000) throw const FormatException('Invalid ingredient');
      parsed[entry.key] = (entry.value as num).toDouble();
    }
    if (parsed.isEmpty || parsed.length > 40) throw const FormatException('Empty recipe');
    return Recipe(id: _str(j, 'id', maxLength: 90), title: _str(j, 'title', maxLength: 120), instructions: _optional(j, 'instructions'), ingredients: parsed);
  }
}

class PlanEntry {
  final String id, day, meal, foodId;
  final double grams;
  const PlanEntry({required this.id, required this.day, required this.meal, required this.foodId, required this.grams});
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'meal': meal, 'foodId': foodId, 'grams': grams};
  factory PlanEntry.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final day = _str(j, 'day', maxLength: 10); parseDay(day);
    final meal = _str(j, 'meal', maxLength: 20);
    if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(meal)) throw const FormatException('Invalid planned meal');
    return PlanEntry(id: _str(j, 'id', maxLength: 90), day: day, meal: meal, foodId: _str(j, 'foodId', maxLength: 90), grams: _positive(j, 'grams', max: 10000));
  }
}

class Note {
  final String id, day, text;
  const Note({required this.id, required this.day, required this.text});
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'text': text};
  factory Note.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final day = _str(j, 'day', maxLength: 10); parseDay(day);
    return Note(id: _str(j, 'id', maxLength: 90), day: day, text: _str(j, 'text', maxLength: 2000));
  }
}

class TaskItem {
  final String id, title, projectId;
  final bool done;
  const TaskItem({required this.id, required this.title, this.projectId = '', this.done = false});
  TaskItem toggle() => TaskItem(id: id, title: title, projectId: projectId, done: !done);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'projectId': projectId, 'done': done};
  factory TaskItem.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    return TaskItem(id: _str(j, 'id', maxLength: 90), title: _str(j, 'title', maxLength: 160), projectId: _optional(j, 'projectId', maxLength: 90), done: j['done'] == true);
  }
}

class Goal {
  final int kcal;
  final double protein, carbs, fat, waterMl;
  const Goal({this.kcal = 2000, this.protein = 100, this.carbs = 230, this.fat = 65, this.waterMl = 2000});
  Map<String, dynamic> toJson() => {'kcal': kcal, 'protein': protein, 'carbs': carbs, 'fat': fat, 'waterMl': waterMl};
  factory Goal.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    return Goal(kcal: _positive(j, 'kcal', max: 8000).round(), protein: _positive(j, 'protein', max: 1000), carbs: _positive(j, 'carbs', max: 1000), fat: _positive(j, 'fat', max: 1000), waterMl: _positive(j, 'waterMl', max: 10000));
  }
}

class Intake {
  final String id, day;
  final double amount;
  const Intake({required this.id, required this.day, required this.amount});
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'amount': amount};
  factory Intake.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final day = _str(j, 'day', maxLength: 10); parseDay(day);
    return Intake(id: _str(j, 'id', maxLength: 90), day: day, amount: _positive(j, 'amount', max: 10000));
  }
}

class WeighIn {
  final String id, day;
  final double kg;
  const WeighIn({required this.id, required this.day, required this.kg});
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'kg': kg};
  factory WeighIn.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final day = _str(j, 'day', maxLength: 10); parseDay(day);
    return WeighIn(id: _str(j, 'id', maxLength: 90), day: day, kg: _positive(j, 'kg', max: 600));
  }
}

class Challenge {
  final String id, title;
  final int targetDays;
  final Set<String> completedDays;
  const Challenge({required this.id, required this.title, required this.targetDays, required this.completedDays});
  Challenge toggle(String day) {
    parseDay(day);
    final days = {...completedDays};
    if (!days.remove(day)) days.add(day);
    return Challenge(id: id, title: title, targetDays: targetDays, completedDays: days);
  }
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'targetDays': targetDays, 'completedDays': completedDays.toList()};
  factory Challenge.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    final target = j['targetDays'];
    if (target is! int || target < 1 || target > 365) throw const FormatException('Invalid challenge');
    final days = (j['completedDays'] as List).map((v) => v as String).toSet();
    for (final d in days) { parseDay(d); }
    return Challenge(id: _str(j, 'id', maxLength: 90), title: _str(j, 'title', maxLength: 120), targetDays: target, completedDays: days);
  }
}

class Member {
  final String id, name;
  const Member({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Member.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    return Member(id: _str(j, 'id', maxLength: 90), name: _str(j, 'name', maxLength: 90));
  }
}

class Project {
  final String id, title, description;
  final bool done;
  const Project({required this.id, required this.title, required this.description, this.done = false});
  Project toggle() => Project(id: id, title: title, description: description, done: !done);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'done': done};
  factory Project.fromJson(Object? value) {
    final j = Map<String, dynamic>.from(value as Map);
    return Project(id: _str(j, 'id', maxLength: 90), title: _str(j, 'title', maxLength: 160), description: _optional(j, 'description', maxLength: 2000), done: j['done'] == true);
  }
}