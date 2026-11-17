# Privacy & safety — Kalori 360

The food, weight, water, goals, notes and household list live in the device's OS-secured key/value storage (Android encrypted shared preferences / iOS keychain via `flutter_secure_storage`). No analytics, authentication, cloud sync or telemetry are implemented in this draft.

Users can export personal data to JSON. **This JSON is NOT encrypted**; clipboard contents can be read by other apps depending on the platform. A confirmation dialog precedes clipboard export; users should handle the backup as sensitive personal information. Import replaces all locally stored data only after validation and an explicit confirmation. `Delete all data` calls the secure backend delete action.

Nutrition data is approximate and not intended for medical purposes. The app does not diagnose or prescribe. On-screen local rules are not background alarm notifications. The community and market screens are offline-first personal discovery/reflection; no online content or transactions. "Assistant" is a transparent deterministic rule-based coach, not a cloud AI agent. No premium purchases are activated without server-side purchase verification.

Before any store release: complete Android/iOS privacy manifests, data safety forms, retention disclosure, test on real devices, independent cryptographic review, store product provisioning, server-side IAP verification, and consent-compliant advertising configuration. Do not advertise the prototype as clinically validated or publish the app until these checks pass.