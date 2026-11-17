import 'package:flutter/material.dart';
import '../core/catalog.dart';
import '../core/models.dart';
import '../core/nutrition.dart';
import '../core/store.dart';
import 'helpers.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.store});
  final KaloriStore store;
  @override Widget build(BuildContext context) {
    final day = dayKey(DateTime.now());
    final n = store.totalsFor(day);
    final g = store.goal;
    final remaining = g.kcal - n.kcal;
    return ListView(padding: const EdgeInsets.all(16), children: [
      heading(context, t(context, 'today')),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${fmt(context, n.kcal)} / ${g.kcal} kcal', style: Theme.of(context).textTheme.headlineMedium),
        Text('${t(context, remaining >= 0 ? 'remaining' : 'over')}: ${fmt(context, remaining.abs())} kcal'),
        StatBar(title: t(context, 'energy'), value: n.kcal, goal: g.kcal.toDouble(), unit: 'kcal'),
        StatBar(title: t(context, 'protein'), value: n.protein, goal: g.protein, unit: 'g'),
        StatBar(title: t(context, 'carbs'), value: n.carbohydrate, goal: g.carbs, unit: 'g'),
        StatBar(title: t(context, 'fat'), value: n.fat, goal: g.fat, unit: 'g'),
        StatBar(title: t(context, 'water'), value: store.waterFor(day), goal: g.waterMl, unit: 'mL'),
      ]))),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ActionChip(avatar: const Icon(Icons.water_drop_outlined), label: Text('${t(context, 'water')} +250 mL'),
          onPressed: () => perform(context, () => store.addWater(250, day))),
        ActionChip(avatar: const Icon(Icons.monitor_weight_outlined), label: Text(t(context, 'weightKg')),
          onPressed: () async { final kg = await numberDialog(context, t(context, 'weightKg'), max: 600); if (kg != null && context.mounted) await perform(context, () => store.addWeight(kg, day)); }),
        ActionChip(avatar: const Icon(Icons.flag_outlined), label: Text(t(context, 'goals')),
          onPressed: () => pushPage(context, t(context, 'goals'), GoalPage(store: store))),
      ]),
      if (store.latestWeight() != null) ListTile(leading: const Icon(Icons.monitor_weight), title: Text('${t(context, 'weight')}: ${fmt(context, store.latestWeight()!, digits: 1)} kg')),
      if (store.rules['waterPrompt'] == true && store.waterFor(day) == 0) ListTile(leading: const Icon(Icons.water_drop_outlined), title: Text(t(context, 'waterReminder'))),
      if (store.rules['goalWarning'] == true && n.kcal >= g.kcal) ListTile(leading: const Icon(Icons.info_outline), title: Text(t(context, 'warning'))),
      if (store.rules['dailyReview'] == true) ListTile(leading: const Icon(Icons.edit_note), title: Text(t(context, 'noteReminder'))),
      heading(context, t(context, 'week')),
      ...List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final kcal = store.totalsFor(dayKey(d)).kcal;
        return ListTile(dense: true, title: Text(dayKey(d)), subtitle: LinearProgressIndicator(value: (kcal / g.kcal).clamp(0.0, 1.0).toDouble()), trailing: Text('${fmt(context, kcal)} kcal'));
      }),
      Text(t(context, 'medical'), style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class GoalPage extends StatefulWidget {
  const GoalPage({super.key, required this.store});
  final KaloriStore store;
  @override State<GoalPage> createState() => _GoalPageState();
}
class _GoalPageState extends State<GoalPage> {
  late final Map<String, TextEditingController> inputs;
  @override void initState() {
    super.initState(); final g = widget.store.goal;
    inputs = {'energy': TextEditingController(text: g.kcal.toString()), 'protein': TextEditingController(text: g.protein.toString()),
      'carbs': TextEditingController(text: g.carbs.toString()), 'fat': TextEditingController(text: g.fat.toString()), 'waterMl': TextEditingController(text: g.waterMl.toString())};
  }
  @override void dispose() { for (final c in inputs.values) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'goalsHint')),
    ...inputs.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: e.value,
      decoration: InputDecoration(labelText: t(context, e.key), border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)))),
    FilledButton(onPressed: () async {
      final values = inputs.map((key, value) => MapEntry(key, parsePositive(value.text, max: key == 'waterMl' ? 10000 : 8000)));
      if (values.values.any((v) => v == null)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid')))); return; }
      await perform(context, () => widget.store.changeGoal(Goal(kcal: values['energy']!.round(), protein: values['protein']!, carbs: values['carbs']!, fat: values['fat']!, waterMl: values['waterMl']!)));
    }, child: Text(t(context, 'save'))),
  ]);
}

class FoodLogTab extends StatefulWidget {
  const FoodLogTab({super.key, required this.store});
  final KaloriStore store;
  @override State<FoodLogTab> createState() => _FoodLogTabState();
}
class _FoodLogTabState extends State<FoodLogTab> {
  DateTime day = DateTime.now(); Food? selected; String meal = standardMeals.first;
  final amount = TextEditingController(text: '100');
  @override void dispose() { amount.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final dayId = dayKey(day); final rows = widget.store.entriesFor(dayId); final total = widget.store.totalsFor(dayId);
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(title: Text(t(context, 'date')), subtitle: Text(dayId), trailing: const Icon(Icons.calendar_month),
        onTap: () async { final picked = await chooseDate(context, day); if (picked != null && mounted) setState(() => day = picked); }),
      heading(context, t(context, 'logMeal')),
      FoodPicker(store: widget.store, value: selected, onChange: (v) => setState(() => selected = v)),
      const SizedBox(height: 10),
      MealPicker(value: meal, onChange: (v) => setState(() => meal = v)),
      const SizedBox(height: 10),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: t(context, 'grams'), border: const OutlineInputBorder())),
      const SizedBox(height: 10),
      FilledButton.icon(icon: const Icon(Icons.add_circle_outline), label: Text(t(context, 'save')), onPressed: () async {
        final grams = parsePositive(amount.text, max: 10000);
        if (selected == null || grams == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid')))); return; }
        await perform(context, () => widget.store.addMeal(selected!, grams, meal, dayId));
      }),
      heading(context, '${t(context, 'dayTotal')}: ${fmt(context, total.kcal)} kcal'),
      StatBar(title: t(context, 'protein'), value: total.protein, goal: widget.store.goal.protein, unit: 'g'),
      ...standardMeals.map((type) {
        final group = rows.where((e) => e.meal == type).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          heading(context, t(context, type)),
          if (group.isEmpty) empty(context),
          ...group.map((e) => Card(child: ListTile(
            title: Text(e.foodName),
            subtitle: Text('${fmt(context, e.grams, digits: 1)} g · ${fmt(context, e.nutrients.kcal)} kcal'),
            trailing: IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () => perform(context, () => widget.store.removeMeal(e.id))),
          ))),
        ]);
      }),
    ]);
  }
}

class FoodsTab extends StatefulWidget {
  const FoodsTab({super.key, required this.store});
  final KaloriStore store;
  @override State<FoodsTab> createState() => _FoodsTabState();
}
class _FoodsTabState extends State<FoodsTab> {
  String query = ''; bool favorites = false;
  @override Widget build(BuildContext context) {
    final results = widget.store.foods.where((f) => f.name.toLowerCase().contains(query.toLowerCase()) && (!favorites || widget.store.favoritedFoods.contains(f.id))).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: t(context, 'search'), border: const OutlineInputBorder()))),
        IconButton(tooltip: t(context, 'favorites'), icon: Icon(favorites ? Icons.star : Icons.star_border), onPressed: () => setState(() => favorites = !favorites))]),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(icon: const Icon(Icons.add), label: Text(t(context, 'newFood')),
        onPressed: () => pushPage(context, t(context, 'newFood'), AddFoodPage(store: widget.store))),
      ...results.map((food) => Card(child: ListTile(
        title: Text(food.name),
        subtitle: Text('${fmt(context, food.per100g.kcal)} kcal / 100 g · P ${fmt(context, food.per100g.protein, digits: 1)} g'),
        leading: IconButton(tooltip: t(context, 'favorite'), icon: Icon(widget.store.favoritedFoods.contains(food.id) ? Icons.star : Icons.star_border),
          onPressed: () => perform(context, () => widget.store.toggleFavorite(food.id))),
        trailing: food.id.contains('_') ? IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () async {
          if (await confirm(context) && context.mounted) await perform(context, () => widget.store.deleteFood(food.id));
        }) : null,
      ))),
      heading(context, t(context, 'recipes')),
      FilledButton.tonalIcon(icon: const Icon(Icons.restaurant_menu), label: Text(t(context, 'newRecipe')),
        onPressed: () => pushPage(context, t(context, 'newRecipe'), RecipeEditor(store: widget.store))),
      ...widget.store.recipes.map((recipe) => Card(child: ListTile(
        title: Text(recipe.title), subtitle: Text('${fmt(context, widget.store.recipeNutrients(recipe).kcal)} kcal · ${recipe.ingredients.length} ${t(context, 'foods')}'),
        onTap: () => pushPage(context, recipe.title, RecipeDetail(store: widget.store, recipe: recipe)),
        trailing: IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () async {
          if (await confirm(context) && context.mounted) await perform(context, () => widget.store.deleteRecipe(recipe.id));
        }),
      ))),
    ]);
  }
}

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key, required this.store}); final KaloriStore store;
  @override State<AddFoodPage> createState() => _AddFoodPageState();
}
class _AddFoodPageState extends State<AddFoodPage> {
  final fields = <String, TextEditingController>{};
  @override void initState() { super.initState();
    for (final key in ['name', 'category', 'serving', 'energy', 'protein', 'carbs', 'fat', 'fiber']) {
      fields[key] = TextEditingController(text: ['serving'].contains(key) ? '100' : ['energy', 'protein', 'carbs', 'fat', 'fiber'].contains(key) ? '0' : '');
    }
  }
  @override void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'nutrition')),
    ...fields.entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: entry.value,
      maxLength: entry.key == 'name' ? 120 : entry.key == 'category' ? 60 : null,
      keyboardType: ['name', 'category'].contains(entry.key) ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: t(context, entry.key), border: const OutlineInputBorder())))),
    FilledButton(onPressed: () async {
      final s = fields['serving']!.text; final numeric = ['energy', 'protein', 'carbs', 'fat', 'fiber'];
      final values = <String, double>{};
      for (final key in numeric) {
        final raw = normalizeDigits(fields[key]!.text.trim()).replaceAll('٫', '.').replaceAll(',', '.');
        final number = double.tryParse(raw);
        if (number == null || !number.isFinite || number < 0 || number > 100000) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid')))); return; }
        values[key] = number;
      }
      final serving = parsePositive(s, max: 10000);
      if (serving == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid')))); return; }
      await perform(context, () => widget.store.addFood(fields['name']!.text, fields['category']!.text.isEmpty ? 'custom' : fields['category']!.text,
        Nutrients(kcal: values['energy']!, protein: values['protein']!, carbohydrate: values['carbs']!, fat: values['fat']!, fiber: values['fiber']!), serving));
    }, child: Text(t(context, 'save'))),
  ]);
}

class RecipeEditor extends StatefulWidget {
  const RecipeEditor({super.key, required this.store}); final KaloriStore store;
  @override State<RecipeEditor> createState() => _RecipeEditorState();
}
class _RecipeEditorState extends State<RecipeEditor> {
  final title = TextEditingController(); final instructions = TextEditingController(); final grams = TextEditingController(text: '100');
  Food? selected; final ingredients = <String, double>{};
  @override void dispose() { title.dispose(); instructions.dispose(); grams.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    TextField(controller: title, maxLength: 120, decoration: InputDecoration(labelText: t(context, 'title'))),
    TextField(controller: instructions, maxLength: 2000, maxLines: 4, decoration: InputDecoration(labelText: t(context, 'instructions'))),
    FoodPicker(store: widget.store, value: selected, onChange: (v) => setState(() => selected = v)),
    TextField(controller: grams, decoration: InputDecoration(labelText: t(context, 'grams')), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    OutlinedButton(onPressed: () {
      final amount = parsePositive(grams.text, max: 10000);
      if (selected == null || amount == null) return;
      setState(() => ingredients[selected!.id] = amount);
    }, child: Text(t(context, 'add'))),
    ...ingredients.entries.map((e) => ListTile(title: Text(widget.store.findFood(e.key)?.name ?? e.key), subtitle: Text('${e.value} g'),
      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => ingredients.remove(e.key))))),
    FilledButton(onPressed: () => perform(context, () => widget.store.addRecipe(title.text, instructions.text, ingredients)), child: Text(t(context, 'save'))),
  ]);
}

class RecipeDetail extends StatelessWidget {
  const RecipeDetail({super.key, required this.store, required this.recipe});
  final KaloriStore store; final Recipe recipe;
  @override Widget build(BuildContext context) {
    final n = store.recipeNutrients(recipe);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(recipe.instructions), heading(context, t(context, 'nutrition')),
      Text('${fmt(context, n.kcal)} kcal · P ${fmt(context, n.protein, digits: 1)} g · C ${fmt(context, n.carbohydrate, digits: 1)} g · F ${fmt(context, n.fat, digits: 1)} g'),
      ...recipe.ingredients.entries.map((e) => ListTile(title: Text(store.findFood(e.key)?.name ?? e.key), trailing: Text('${fmt(context, e.value)} g'))),
      FilledButton(onPressed: () async {
        final day = dayKey(DateTime.now());
        for (final entry in recipe.ingredients.entries) {
          final food = store.findFood(entry.key);
          if (food != null && context.mounted) await perform(context, () => store.addMeal(food, entry.value, 'lunch', day));
        }
      }, child: Text(t(context, 'logMeal'))),
    ]);
  }
}

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key, required this.store}); final KaloriStore store;
  @override State<PlannerTab> createState() => _PlannerTabState();
}
class _PlannerTabState extends State<PlannerTab> {
  DateTime date = DateTime.now(); Food? food; String meal = standardMeals.first;
  final grams = TextEditingController(text: '100');
  @override void dispose() { grams.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final day = dayKey(date); final plans = widget.store.plans.where((p) => p.day == day).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(title: Text(t(context, 'planFor')), subtitle: Text(day), trailing: const Icon(Icons.calendar_month),
        onTap: () async { final picked = await chooseDate(context, date); if (picked != null && mounted) setState(() => date = picked); }),
      heading(context, t(context, 'newPlan')),
      FoodPicker(store: widget.store, value: food, onChange: (v) => setState(() => food = v)),
      const SizedBox(height: 10), MealPicker(value: meal, onChange: (v) => setState(() => meal = v)),
      TextField(controller: grams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t(context, 'grams'))),
      FilledButton(onPressed: () async {
        final n = parsePositive(grams.text, max: 10000);
        if (food == null || n == null) return;
        await perform(context, () => widget.store.addPlan(day, meal, food!.id, n));
      }, child: Text(t(context, 'save'))),
      heading(context, t(context, 'planner')),
      if (plans.isEmpty) empty(context),
      ...plans.map((p) => Card(child: ListTile(
        title: Text('${t(context, p.meal)} — ${widget.store.findFood(p.foodId)?.name ?? p.foodId}'),
        subtitle: Text('${fmt(context, p.grams)} g'),
        trailing: Wrap(children: [
          IconButton(tooltip: t(context, 'logPlan'), icon: const Icon(Icons.check), onPressed: () => perform(context, () => widget.store.logPlan(p))),
          IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () => perform(context, () => widget.store.removePlan(p.id))),
        ]),
      ))),
    ]);
  }
}