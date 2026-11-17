import 'package:flutter/material.dart';
import 'core/strings.dart';
import 'core/store.dart';
import 'ui/helpers.dart';
import 'ui/modules.dart';
import 'ui/tabs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Kalori360App());
}

class Kalori360App extends StatefulWidget {
  const Kalori360App({super.key, this.initialStore});
  final KaloriStore? initialStore;
  @override State<Kalori360App> createState() => _Kalori360AppState();
}

class _Kalori360AppState extends State<Kalori360App> {
  late final KaloriStore store;
  @override void initState() {
    super.initState();
    store = widget.initialStore ?? KaloriStore();
    if (!store.initialized) store.load();
  }
  @override void dispose() {
    store.dispose();
    super.dispose();
  }
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Kalori 360',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E65))),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF57CAA6), brightness: Brightness.dark)),
    themeMode: ThemeMode.system,
    supportedLocales: Texts.locales,
    localizationsDelegates: Texts.delegates,
    home: AnimatedBuilder(animation: store, builder: (context, _) {
      if (!store.initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (store.loadError != null) return Scaffold(appBar: AppBar(title: Text(t(context, 'app'))), body: Center(child: Padding(
        padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, size: 48), const SizedBox(height: 12),
          Text(t(context, 'errorLoad'), textAlign: TextAlign.center),
          const SizedBox(height: 12), FilledButton(onPressed: store.load, child: Text(t(context, 'retry'))),
        ]))));
      return KaloriHome(store: store);
    }),
  );
}

class KaloriHome extends StatefulWidget {
  const KaloriHome({super.key, required this.store});
  final KaloriStore store;
  @override State<KaloriHome> createState() => _KaloriHomeState();
}
class _KaloriHomeState extends State<KaloriHome> {
  int selected = 0;
  @override Widget build(BuildContext context) {
    final pages = [
      DashboardTab(store: widget.store), FoodLogTab(store: widget.store),
      FoodsTab(store: widget.store), PlannerTab(store: widget.store), MoreTab(store: widget.store),
    ];
    final labels = ['dashboard', 'log', 'foods', 'planner', 'more'];
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'app')), actions: [
        IconButton(tooltip: t(context, 'privacy'), icon: const Icon(Icons.shield_outlined),
          onPressed: () => pushPage(context, t(context, 'privacy'), PrivacyPage(store: widget.store))),
      ]),
      body: SafeArea(child: IndexedStack(index: selected, children: pages)),
      bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: (index) => setState(() => selected = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: t(context, labels[0])),
          NavigationDestination(icon: const Icon(Icons.restaurant_outlined), label: t(context, labels[1])),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: t(context, labels[2])),
          NavigationDestination(icon: const Icon(Icons.event_note_outlined), label: t(context, labels[3])),
          NavigationDestination(icon: const Icon(Icons.apps_outlined), label: t(context, labels[4])),
        ],
      ),
    );
  }
}