import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/store.dart';
import '../core/models.dart';
import '../core/nutrition.dart';
import 'helpers.dart';

class ModuleItem {
  final String key;
  final IconData icon;
  const ModuleItem(this.key, this.icon);
}

const modules = <ModuleItem>[
  ModuleItem('insights', Icons.psychology_outlined), ModuleItem('analytics', Icons.insights),
  ModuleItem('challenge', Icons.emoji_events_outlined), ModuleItem('community', Icons.forum_outlined),
  ModuleItem('academy', Icons.school_outlined), ModuleItem('toolbox', Icons.calculate_outlined),
  ModuleItem('journal', Icons.menu_book_outlined), ModuleItem('market', Icons.travel_explore_outlined),
  ModuleItem('assistant', Icons.smart_toy_outlined), ModuleItem('projects', Icons.folder_outlined),
  ModuleItem('tasks', Icons.checklist), ModuleItem('automations', Icons.settings_suggest_outlined),
  ModuleItem('answers', Icons.stars_outlined), ModuleItem('family', Icons.family_restroom),
  ModuleItem('studio', Icons.analytics_outlined), ModuleItem('goals', Icons.flag_outlined),
  ModuleItem('course', Icons.book_outlined), ModuleItem('decision', Icons.rule_outlined),
  ModuleItem('premium', Icons.workspace_premium_outlined), ModuleItem('privacy', Icons.privacy_tip_outlined),
];

class MoreTab extends StatelessWidget {
  const MoreTab({super.key, required this.store});
  final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t(context, 'app'), style: Theme.of(context).textTheme.titleLarge), Text(t(context, 'menuHelp')),
      Text('${t(context, 'points')}: ${store.totalPoints}'),
    ]))),
    ...modules.map((m) => Card(child: ListTile(
      leading: Icon(m.icon), title: Text(t(context, m.key)), trailing: const Icon(Icons.chevron_right),
      onTap: () => pushPage(context, t(context, m.key), ModulePage(store: store, kind: m.key)),
    ))),
  ]);
}

class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.store, required this.kind});
  final KaloriStore store;
  final String kind;
  @override Widget build(BuildContext context) {
    switch (kind) {
      case 'insights': case 'assistant': return InsightsPage(store: store, assistant: kind == 'assistant');
      case 'analytics': case 'studio': return AnalyticsPage(store: store, professional: kind == 'studio');
      case 'challenge': case 'answers': return ChallengesPage(store: store, gamified: kind == 'answers');
      case 'community': case 'journal': return JournalPage(store: store, reflection: kind == 'community');
      case 'academy': case 'course': return LessonsPage(store: store, shortCourse: kind == 'course');
      case 'toolbox': case 'decision': return CalculatorPage(store: store, decision: kind == 'decision');
      case 'market': return DiscoveryPage(store: store);
      case 'projects': return ProjectsPage(store: store);
      case 'tasks': return TasksPage(store: store);
      case 'automations': return AutomationPage(store: store);
      case 'family': return FamilyPage(store: store);
      case 'goals': return QuickGoalsPage(store: store);
      case 'premium': return PremiumPage();
      case 'privacy': return PrivacyPage(store: store);
      default: return Center(child: Text(t(context, 'noEntries')));
    }
  }
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.store, required this.assistant});
  final KaloriStore store; final bool assistant;
  @override Widget build(BuildContext context) {
    final day = dayKey(DateTime.now()); final today = store.totalsFor(day);
    final target = store.goal;
    final prompts = <String>[
      '${t(context, 'energy')}: ${fmt(context, today.kcal)} / ${target.kcal} kcal.',
      if (today.kcal == 0) t(context, 'mealAdvice'),
      if (today.protein < target.protein) '${t(context, 'protein')}: ${fmt(context, target.protein - today.protein, digits: 1)} g ${t(context, 'remaining').toLowerCase()}.',
      if (store.waterFor(day) < target.waterMl) '${t(context, 'water')}: ${fmt(context, target.waterMl - store.waterFor(day))} mL ${t(context, 'remaining').toLowerCase()}.',
      if (today.kcal >= target.kcal) t(context, 'warning'),
      t(context, 'medical'),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      heading(context, t(context, assistant ? 'assistant' : 'insights')),
      if (assistant) Text(t(context, 'offline')),
      ...prompts.map((tip) => Card(child: ListTile(leading: const Icon(Icons.lightbulb_outline), title: Text(tip)))),
      heading(context, t(context, 'week')),
      Text('${store.meals.where((e) => DateTime.tryParse(e.day)?.isAfter(DateTime.now().subtract(const Duration(days: 7))) ?? false).length} ${t(context, 'logMeal').toLowerCase()}'),
    ]);
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key, required this.store, required this.professional});
  final KaloriStore store; final bool professional;
  @override Widget build(BuildContext context) {
    final days = List.generate(7, (i) => dayKey(DateTime.now().subtract(Duration(days: 6 - i))));
    return ListView(padding: const EdgeInsets.all(16), children: [
      heading(context, t(context, 'week')),
      ...days.map((day) {
        final n = store.totalsFor(day);
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Text(day, style: Theme.of(context).textTheme.titleMedium),
          StatBar(title: t(context, 'energy'), value: n.kcal, goal: store.goal.kcal.toDouble(), unit: 'kcal'),
          StatBar(title: t(context, 'protein'), value: n.protein, goal: store.goal.protein, unit: 'g'),
          StatBar(title: t(context, 'water'), value: store.waterFor(day), goal: store.goal.waterMl, unit: 'mL'),
        ])));
      }),
      ListTile(title: Text('${t(context, 'weight')}: ${store.latestWeight() == null ? '—' : '${fmt(context, store.latestWeight()!, digits: 1)} kg'}')),
      if (professional) ...[
        heading(context, t(context, 'studio')),
        Text('${t(context, 'foods')}: ${store.foods.length} · ${t(context, 'recipes')}: ${store.recipes.length} · ${t(context, 'log')}: ${store.meals.length}'),
        FilledButton.icon(icon: const Icon(Icons.file_download_outlined), label: Text(t(context, 'export')),
          onPressed: () => pushPage(context, t(context, 'export'), ExportPage(store: store))),
      ],
    ]);
  }
}

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key, required this.store, required this.gamified});
  final KaloriStore store; final bool gamified;
  @override Widget build(BuildContext context) {
    final day = dayKey(DateTime.now());
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${t(context, 'points')}: ${store.totalPoints}', style: Theme.of(context).textTheme.titleLarge),
      FilledButton.tonalIcon(icon: const Icon(Icons.add), label: Text(t(context, 'newChallenge')), onPressed: () async {
        final title = await textDialog(context, t(context, 'newChallenge'));
        if (title == null || title.isEmpty || !context.mounted) return;
        final days = await numberDialog(context, t(context, 'targetDays'), initial: '7', max: 365);
        if (days != null && context.mounted) await perform(context, () => store.addChallenge(title, days.round()));
      }),
      ...store.challenges.map((c) => Card(child: Column(children: [
        ListTile(title: Text(c.title), subtitle: Text('${c.completedDays.length}/${c.targetDays} ${t(context, 'targetDays')}'),
          trailing: IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () => perform(context, () => store.removeChallenge(c.id)))),
        LinearProgressIndicator(value: (c.completedDays.length / c.targetDays).clamp(0.0, 1.0).toDouble()),
        CheckboxListTile(title: Text('${t(context, 'complete')}: $day'), value: c.completedDays.contains(day),
          onChanged: (_) => perform(context, () => store.toggleChallenge(c.id, day))),
      ]))),
      if (gamified) ...[
        heading(context, t(context, 'academy')),
        Text(t(context, 'answers')),
        ...lessons.map((e) => CheckboxListTile(
          title: Text(e.title), value: store.lessonsDone.contains(e.id),
          onChanged: (_) => perform(context, () => store.completeLesson(e.id)),
        )),
      ],
    ]);
  }
}

class Lesson {
  final String id, title, content;
  const Lesson(this.id, this.title, this.content);
}
const lessons = <Lesson>[
  Lesson('portion', 'Portions / Porsiyonlar', 'Compare food amounts using consistent weights. / Besinleri tutarlı gram ölçüleriyle karşılaştırın.'),
  Lesson('macros', 'Macronutrients / Makro besinler', 'Carbohydrates and proteins provide approximately 4 kcal/g; fats approximately 9 kcal/g. / Karbonhidrat ve protein yaklaşık 4 kcal/g, yağ yaklaşık 9 kcal/g sağlar.'),
  Lesson('hydration', 'Hydration / Su tüketimi', 'Water needs vary across people, activity levels and climate. / Su gereksinimi kişiye, aktiviteye ve iklime göre değişir.'),
  Lesson('fiber', 'Fiber / Lif', 'Vegetables, legumes and whole grains can contribute dietary fiber. / Sebze, baklagil ve tam tahıllar lif kaynağıdır.'),
  Lesson('labels', 'Reading labels / Etiket okuma', 'Compare calories and serving size before interpreting package numbers. / Paket bilgilerini yorumlamadan önce porsiyon ve kaloriyi karşılaştırın.'),
  Lesson('planning', 'Meal planning / Öğün planlama', 'Plan a balanced food mix that fits your preferences and restrictions. / Tercih ve kısıtlarınıza uygun dengeli öğünler planlayın.'),
  Lesson('patterns', 'Trends / Eğilimler', 'Single days are noisy; longer-term patterns are more informative. / Tek gün yerine uzun dönem eğilimleri değerlendirin.'),
  Lesson('habits', 'Small habits / Küçük alışkanlıklar', 'Choose sustainable actions you can repeat. / Sürdürülebilir alışkanlıklar seçin.'),
];

class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key, required this.store, required this.shortCourse});
  final KaloriStore store; final bool shortCourse;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('${t(context, 'lessonDone')}: ${store.lessonsDone.length}/${lessons.length} · ${t(context, 'points')}: ${store.lessonPoints}'),
    LinearProgressIndicator(value: store.lessonsDone.length / lessons.length),
    ...lessons.asMap().entries.where((entry) => !shortCourse || entry.key < 4).map((entry) {
      final lesson = entry.value;
      return Card(child: Column(children: [ListTile(title: Text('${entry.key + 1}. ${lesson.title}'), subtitle: Text(lesson.content)),
        CheckboxListTile(title: Text(t(context, 'markLesson')), value: store.lessonsDone.contains(lesson.id),
          onChanged: (_) => perform(context, () => store.completeLesson(lesson.id))) ]));
    }),
  ]);
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key, required this.store, required this.reflection});
  final KaloriStore store; final bool reflection;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    if (reflection) Text(t(context, 'menuHelp')),
    FilledButton.tonalIcon(icon: const Icon(Icons.edit_note), label: Text(t(context, 'newNote')), onPressed: () async {
      final note = await textDialog(context, t(context, 'newNote'), multiline: true);
      if (note != null && note.isNotEmpty && context.mounted) await perform(context, () => store.addNote(note, dayKey(DateTime.now())));
    }),
    ...store.notes.reversed.map((n) => Card(child: ListTile(
      title: Text(n.text), subtitle: Text(n.day),
      trailing: IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline),
        onPressed: () => perform(context, () => store.deleteNote(n.id))),
    ))),
  ]);
}

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key, required this.store});
  final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'offline')),
    heading(context, t(context, 'recipes')),
    ...store.recipes.map((r) => Card(child: ListTile(
      title: Text(r.title), subtitle: Text('${fmt(context, store.recipeNutrients(r).kcal)} kcal'),
      onTap: () => pushPage(context, r.title, ListView(padding: const EdgeInsets.all(16), children: [
        Text(r.instructions), heading(context, t(context, 'nutrition')),
        ...r.ingredients.entries.map((e) => ListTile(title: Text(store.findFood(e.key)?.name ?? e.key), trailing: Text('${e.value} g'))),
      ])),
    ))),
    heading(context, t(context, 'foods')),
    ...store.foods.map((f) => ListTile(title: Text(f.name), subtitle: Text('${fmt(context, f.per100g.kcal)} kcal/100g'))),
  ]);
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.store, this.projectId = ''});
  final KaloriStore store; final String projectId;
  @override Widget build(BuildContext context) {
    final items = store.tasks.where((task) => projectId.isEmpty || task.projectId == projectId).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      FilledButton.tonalIcon(icon: const Icon(Icons.add), label: Text(t(context, 'newTask')), onPressed: () async {
        final title = await textDialog(context, t(context, 'newTask'));
        if (title != null && title.isNotEmpty && context.mounted) await perform(context, () => store.addTask(title, projectId: projectId));
      }),
      if (items.isEmpty) empty(context),
      ...items.map((item) => Card(child: Row(children: [
        Expanded(child: CheckboxListTile(title: Text(item.title), value: item.done, onChanged: (_) => perform(context, () => store.toggleTask(item.id)))),
        IconButton(tooltip: t(context, 'delete'), icon: const Icon(Icons.delete_outline), onPressed: () => perform(context, () => store.deleteTask(item.id))),
      ]))),
    ]);
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key, required this.store}); final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    FilledButton.tonalIcon(icon: const Icon(Icons.add), label: Text(t(context, 'projects')), onPressed: () async {
      final title = await textDialog(context, t(context, 'title'));
      if (title == null || title.isEmpty || !context.mounted) return;
      final description = await textDialog(context, t(context, 'text'));
      if (description != null && context.mounted) await perform(context, () => store.addProject(title, description));
    }),
    ...store.projects.map((p) => Card(child: Column(children: [
      CheckboxListTile(title: Text(p.title), subtitle: Text(p.description), value: p.done,
        onChanged: (_) => perform(context, () => store.toggleProject(p.id))),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => pushPage(context, p.title, TasksPage(store: store, projectId: p.id)), child: Text(t(context, 'tasks'))),
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirm(context) && context.mounted) await perform(context, () => store.deleteProject(p.id)); }),
      ]),
    ]))),
  ]);
}

class AutomationPage extends StatelessWidget {
  const AutomationPage({super.key, required this.store}); final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'rulesHint')),
    ...store.rules.entries.map((rule) => SwitchListTile(
      title: Text(t(context, rule.key)), value: rule.value,
      onChanged: (_) => perform(context, () => store.toggleRule(rule.key)),
    )),
  ]);
}

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key, required this.store}); final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'familyHint')),
    FilledButton.tonalIcon(icon: const Icon(Icons.person_add_alt_1), label: Text(t(context, 'member')), onPressed: () async {
      final name = await textDialog(context, t(context, 'member'));
      if (name != null && name.isNotEmpty && context.mounted) await perform(context, () => store.addMember(name));
    }),
    ...store.members.map((m) => Card(child: ListTile(title: Text(m.name), trailing: IconButton(tooltip: t(context, 'delete'),
      icon: const Icon(Icons.delete_outline), onPressed: () => perform(context, () => store.deleteMember(m.id)))))),
  ]);
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.store, required this.decision});
  final KaloriStore store; final bool decision;
  @override State<CalculatorPage> createState() => _CalculatorPageState();
}
class _CalculatorPageState extends State<CalculatorPage> {
  final height = TextEditingController(text: '170');
  final weight = TextEditingController(text: '70');
  final age = TextEditingController(text: '30');
  final activity = TextEditingController(text: '1.4');
  bool male = false; String result = '';
  @override void dispose() { height.dispose(); weight.dispose(); age.dispose(); activity.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'medical')),
    for (final e in <String, TextEditingController>{'height': height, 'weightKg': weight, 'age': age, 'activity': activity}.entries)
      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: e.value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t(context, e.key), border: const OutlineInputBorder()))),
    SwitchListTile(title: Text(t(context, 'male')), value: male, onChanged: (v) => setState(() => male = v)),
    FilledButton(onPressed: () {
      final h = parsePositive(height.text, max: 270); final w = parsePositive(weight.text, max: 600);
      final a = parsePositive(age.text, max: 110); final mult = parsePositive(activity.text, max: 2);
      if (h == null || w == null || a == null || a < 13 || mult == null || mult < 1.2 || mult > 2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'enterValid')))); return;
      }
      final bmi = calculateBmi(w, h); final bmr = estimateBmr(weightKg: w, heightCm: h, age: a.round(), male: male);
      final kcal = safeGoalKcal(bmr, mult);
      setState(() => result = '${t(context, 'bmi')}: ${fmt(context, bmi, digits: 1)}\n${t(context, 'tdee')}: $kcal kcal/day');
    }, child: Text(t(context, 'calculate'))),
    if (result.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(result, style: Theme.of(context).textTheme.titleLarge))),
    if (widget.decision) Text(t(context, 'goalsHint')),
  ]);
}

class QuickGoalsPage extends StatelessWidget {
  const QuickGoalsPage({super.key, required this.store}); final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'goalsHint')),
    ...<String, double>{'energy': store.goal.kcal.toDouble(), 'protein': store.goal.protein,
      'carbs': store.goal.carbs, 'fat': store.goal.fat, 'waterMl': store.goal.waterMl}.entries.map((entry) => ListTile(
        title: Text(t(context, entry.key)), trailing: Text(fmt(context, entry.value)),
        onTap: () async {
          final newValue = await numberDialog(context, t(context, entry.key), initial: entry.value.toString(), max: entry.key == 'waterMl' ? 10000 : 8000);
          if (newValue == null || !context.mounted) return;
          final g = store.goal;
          await perform(context, () => store.changeGoal(Goal(
            kcal: entry.key == 'energy' ? newValue.round() : g.kcal,
            protein: entry.key == 'protein' ? newValue : g.protein,
            carbs: entry.key == 'carbs' ? newValue : g.carbs,
            fat: entry.key == 'fat' ? newValue : g.fat,
            waterMl: entry.key == 'waterMl' ? newValue : g.waterMl,
          )));
        },
      )),
  ]);
}

class ExportPage extends StatefulWidget {
  const ExportPage({super.key, required this.store}); final KaloriStore store;
  @override State<ExportPage> createState() => _ExportPageState();
}
class _ExportPageState extends State<ExportPage> {
  final controller = TextEditingController();
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'exportHint')),
    FilledButton.icon(icon: const Icon(Icons.copy), label: Text(t(context, 'share')), onPressed: () async {
      final ok = await confirm(context, body: t(context, 'exportHint'));
      if (!ok || !context.mounted) return;
      await Clipboard.setData(ClipboardData(text: widget.store.exportJson()));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(context, 'success'))));
    }),
    heading(context, t(context, 'import')),
    Text(t(context, 'importHint')),
    TextField(controller: controller, maxLines: 8, maxLength: 5000000, decoration: InputDecoration(labelText: t(context, 'paste'), border: const OutlineInputBorder())),
    FilledButton.tonalIcon(icon: const Icon(Icons.restore), label: Text(t(context, 'pasteImport')), onPressed: () async {
      if (await confirm(context) && context.mounted) await perform(context, () => widget.store.importJson(controller.text));
    }),
  ]);
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, required this.store}); final KaloriStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'dataNotice')),
    const SizedBox(height: 16),
    FilledButton.tonalIcon(icon: const Icon(Icons.file_download_outlined), label: Text(t(context, 'export')),
      onPressed: () => pushPage(context, t(context, 'export'), ExportPage(store: store))),
    const SizedBox(height: 16), Text(t(context, 'eraseWarning')),
    FilledButton.icon(icon: const Icon(Icons.delete_forever_outlined), label: Text(t(context, 'clear')),
      onPressed: () async { if (await confirm(context) && context.mounted) await perform(context, store.reset); }),
  ]);
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t(context, 'proHint')),
    Card(child: ListTile(leading: const Icon(Icons.lock_outline), title: Text(t(context, 'premium')),
      subtitle: Text(t(context, 'menuHelp')))),
  ]);
}