# APP-005 — Kalori 360 (work in progress, **not delivered**)

Offline-first Flutter nutrition tracker with five primary tabs and 20 discovery/management modules. Android/iOS app target. Turkish, English and Arabic labels with RTL support; native locale number parsing for Latin, Arabic and Persian numerals.

Features being implemented: food catalog and custom foods, nutritional calculation, meals, daily diary, recipe builder, meal planning and logging, calorie/macronutrient/hydration goals, weight entry, seven-day dashboard and trends, coach tips, habit challenges, learning mini courses and points, journal/reflections, project and checklist management, on-screen automation rules, family household list, offline food discovery, decision-support BMI/BMR estimates, privacy export/import/erase, encrypted local storage and the premium feature information screen.

**This is NOT complete or publishable**: the design explicitly does not offer live community, remote AI, cloud marketplace, store-ready IAP or live ads. Native project platforms must be generated with `flutter create --platforms=android,ios --project-name kalori_360 .`, and Android/iOS signing, purchases, ad consent and deployment require developer account configuration. The exact product scope for 20 modules needs acceptance against the original catalogue. All CI results are unverified until actually run.

## Local development

```sh
flutter create --platforms=android,ios --project-name kalori_360 .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Safety

The default food values are estimates; portion counts have no medical interpretation. Data is local encrypted at rest; JSON exported by the user is unencrypted. Do not store API keys or production advertising IDs in the repo. The app does not send nutrition data to external services.