# APP-005 — packaging acceptance gates

**Status: DRAFT; DO NOT PUSH AS A COMPLETED APP.** GitHub package delivery is deliberately withheld until all gates have positive evidence. Only local static checks were run in this environment.

## Runtime, QA and release

- [x] Source files for calorie/food/hydration tracking, recipes, meal planning, trends, local challenges, lessons, private notes, tasks and data controls.
- [x] Turkish, English and Arabic labels / basic RTL via Flutter Material internationalization.
- [x] Data model validation, secure-storage abstraction, serialized writes, backup import validation and deletion logic.
- [x] Flutter widget and unit tests written.
- [ ] Flutter SDK `dart format`, `flutter analyze`, `flutter test --coverage` actually run and pass.
- [ ] Android APK/AAB signed build and native device end-to-end tests.
- [ ] iOS simulator/device tests, signing and archive.
- [ ] Secure storage review on Android and iOS, including backup migration and uninstall behavior.
- [ ] Localization reviews, accessibility scans, screen-size adaptation and dynamic type tests.
- [ ] App Store / Play Console metadata, screenshot assets, privacy labels and support/privacy URL.

## Catalog feature and external-service gaps

- [ ] Real multi-profile household tracking and secure user consent.
- [ ] Moderated online community service (currently local personal reflections only).
- [ ] Live discovery marketplace with merchant inventory and transactions (currently offline curated food/recipes).
- [ ] Cloud-connected AI assistant with privacy notice and service credentials (currently explicitly local rule-based coach).
- [ ] Background reminders with notification permissions and scheduling (currently app-screen alerts).
- [ ] Real premium entitlement state with backend receipt validation and App Store/Google Play product setup (currently a disclosure-only page).
- [ ] Advertising consent/SDK setup and production ad unit configuration if ads are part of the approved scope.
- [ ] Full original product catalogue / UX acceptance for every one of the 20 modules.

## Delivery condition

Do not upload a consolidated application package as “complete” to the private GitHub repository until all required checklist items above are verified, or changes are explicitly agreed in the product scope. API credentials, ads, purchase products, signing and store account configuration cannot safely be fabricated.