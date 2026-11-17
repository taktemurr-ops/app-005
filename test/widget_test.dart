import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori_360/main.dart';
import 'package:kalori_360/core/store.dart';

void main() {
  testWidgets('dashboard shows food and water tracking', (tester) async {
    final store = KaloriStore(backend: MemoryBackend());
    await store.load();
    await tester.pumpWidget(Kalori360App(initialStore: store));
    await tester.pumpAndSettle();
    expect(find.text('Kalori 360'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.byIcon(Icons.water_drop_outlined), findsWidgets);
  });
  testWidgets('food log is available from primary navigation', (tester) async {
    final store = KaloriStore(backend: MemoryBackend());
    await store.load();
    await tester.pumpWidget(Kalori360App(initialStore: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.restaurant_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });
  testWidgets('discover exposes module navigation', (tester) async {
    final store = KaloriStore(backend: MemoryBackend());
    await store.load();
    await tester.pumpWidget(Kalori360App(initialStore: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.apps_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
  });
}