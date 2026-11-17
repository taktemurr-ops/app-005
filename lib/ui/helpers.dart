import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/catalog.dart';
import '../core/models.dart';
import '../core/nutrition.dart';
import '../core/strings.dart';
import '../core/store.dart';

String t(BuildContext context, String key) => Texts.get(context, key);
String fmt(BuildContext context, num n, {int digits = 0}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits).format(n);
}

Future<void> perform(BuildContext context, Future<void> Function() callback) async {
  try {
    await callback();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'success'))));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t(context, 'failed')}: $error')));
  }
}

Future<String?> textDialog(BuildContext context, String title, {String initial = '', bool multiline = false}) async {
  final controller = TextEditingController(text: initial);
  try {
    return await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, maxLength: multiline ? 2000 : 160,
        maxLines: multiline ? 6 : 1, decoration: InputDecoration(labelText: title)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(t(c, 'cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(t(c, 'save')))],
    ));
  } finally { controller.dispose(); }
}

Future<double?> numberDialog(BuildContext context, String title, {String initial = '', double max = 100000}) async {
  final raw = await textDialog(context, title, initial: initial);
  if (raw == null) return null;
  final result = parsePositive(raw, max: max);
  if (result == null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid'))));
  }
  return result;
}

Future<bool> confirm(BuildContext context, {String? body}) async => await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
  title: Text(t(dialog, 'confirm')), content: Text(body ?? t(dialog, 'eraseWarning')),
  actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(t(dialog, 'cancel'))),
    FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(t(dialog, 'delete')))])) ?? false;

Future<DateTime?> chooseDate(BuildContext context, DateTime initial) => showDatePicker(context: context, initialDate: initial,
  firstDate: DateTime(2000), lastDate: DateTime(2100));

void pushPage(BuildContext context, String title, Widget child) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (c) => Scaffold(
  appBar: AppBar(title: Text(title)), body: SafeArea(child: child))));

Widget heading(BuildContext context, String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title, style: Theme.of(context).textTheme.titleLarge));
Widget empty(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(t(context, 'noEntries'))));

class FoodPicker extends StatelessWidget {
  const FoodPicker({super.key, required this.store, required this.value, required this.onChange});
  final KaloriStore store;
  final Food? value;
  final ValueChanged<Food?> onChange;
  @override Widget build(BuildContext context) => DropdownButtonFormField<String>(
    isExpanded: true, value: store.foods.any((e) => e.id == value?.id) ? value?.id : null,
    decoration: InputDecoration(labelText: t(context, 'food'), border: const OutlineInputBorder()),
    items: store.foods.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: (id) => onChange(store.findFood(id ?? '')),
  );
}

class MealPicker extends StatelessWidget {
  const MealPicker({super.key, required this.value, required this.onChange});
  final String value;
  final ValueChanged<String> onChange;
  @override Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(labelText: t(context, 'meal'), border: const OutlineInputBorder()),
    items: standardMeals.map((m) => DropdownMenuItem(value: m, child: Text(t(context, m)))).toList(),
    onChanged: (v) { if (v != null) onChange(v); },
  );
}

class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.title, required this.value, required this.goal, required this.unit});
  final String title, unit;
  final double value, goal;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$title: ${fmt(context, value, digits: 1)} / ${fmt(context, goal, digits: 1)} $unit'),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: goal > 0 ? (value / goal).clamp(0.0, 1.0).toDouble() : 0),
    ],
  ));
}