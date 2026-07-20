# Agri AI Assistant — Mobile App

Flutter app (Android + iOS) for the Agriculture AI Assistant, branded **உழவனின் நண்பன்** (Uzhavanin Nanban — "Farmer's Friend"). See [../docs/architecture](../docs/architecture/ARCHITECTURE.md) for the full system design.

## Status

Well past the original UI-only scaffold — most core flows are wired to the real backend (`../backend`) and have been exercised live, not just written:

- **Auth**: phone-number + OTP login (mock SMS — any correct 6-digit code from the printed debug log works, since no SMS provider is wired up), with session and profile persisted locally per phone number so returning users skip re-entering their name.
- **Farms**: create via GPS or a cascading Country→State→District→Village search (real geocoding via OpenStreetMap Nominatim, no API key needed), edit name/area, add/edit/remove a soil test report, delete. Farms sync in the background to a real **PostgreSQL**-backed `farm_registry` service (via the gateway) — offline-first, sync is best-effort and never blocks the UI.
- **Dashboard**: live Land Health Score, 7-day weather, and ranked crop recommendations pulled from the real backend for the selected farm (soil report, if present, is used instead of the satellite estimate). Market prediction is still sample data (that service isn't built).
- **Diagnose a crop problem**: photo capture/upload + symptom description, searches a real RAG pipeline (BGE-M3 embeddings + Qdrant) over a curated organic-treatment knowledge base. See caveats below — photo *upload* works, automated photo *analysis* doesn't yet (no vision LLM key configured on the backend).
- **AI Chat**: still canned keyword-matched replies — not yet wired to a real LLM.
- **Localization**: full English + Tamil translation (`core/localization/app_strings.dart`) covering every screen, switchable live from Profile → Language without restarting. Hindi is scaffolded but not translated yet.

None of this has a cloud deployment — the backend runs on a developer machine on the local network, and the app points at that machine's LAN IP (`core/config/app_config.dart`). See `../backend/README.md` for what's actually been verified running vs. just written.

## Getting started

```bash
flutter pub get
flutter run
```

Building an installable APK on Windows needs the Android SDK/NDK and a JDK — see `../backend/README.md`'s sibling notes if starting from scratch; this was set up and verified working during development (`flutter build apk --debug`, sideloaded via USB/file transfer since no working `adb` device connection was available).

**Before running against the backend**: update `core/config/app_config.dart`'s `gatewayBaseUrl` to whatever machine is currently running `backend/services/gateway` — it's a plain LAN IP, not a stable hostname, so it goes stale whenever the backend host changes networks.

## Structure

```
lib/
  core/
    config/        backend base URL (LAN IP — update per environment)
    localization/   AppStrings (EN/TA) + language_provider (device-level, pre-login)
    network/        shared Dio client
    routing/        go_router config, auth-gated redirects
    theme/          colors, typography (bundled fonts, no network font-fetch)
    widgets/        shared building blocks (PrimaryButton, ConfidenceBadge, ...)
  features/
    auth/           login, OTP, profile setup — MockAuthRepository (local session, real backend user sync)
    shell/          bottom-nav app shell (go_router StatefulShellRoute)
    dashboard/      farm banner, Land Health, weather, crop recommendations (live), market (mock), Compare Crops
    farms/          farm list, add-farm (GPS / location search), edit, soil report, PostgreSQL sync
    diagnose/       photo/symptom crop disease diagnosis (organic RAG + chemical-guidance fallback)
    weather/        7-day forecast detail
    market/         price prediction + nearby mandi detail (mock data)
    chat/           AI chat (canned keyword responses — not yet LLM-backed)
    profile/        account settings, language picker, sign out
```

State management is Riverpod, navigation is go_router. Each `features/<x>/presentation/screens` folder is a UI slice; `features/<x>/data/` holds the repository/API client for that feature.

## Known gaps (stated plainly, not hidden)

- **No real SMS OTP** — `MockAuthRepository` accepts a fixed debug code.
- **No cloud backend** — everything points at a LAN IP; there is no deployed environment.
- **AI Chat isn't RAG/LLM-grounded** — canned replies only, despite `disease_kb`'s RAG pipeline existing for the Diagnose feature specifically.
- **Photo-based disease detection isn't automated** — the upload pipeline is real and tested, but analyzing the photo needs a vision-capable LLM API key on the backend (`ANTHROPIC_API_KEY`), which isn't configured. Text/symptom-based search works fully today.
- **Chemical/pesticide guidance is deliberately unimplemented** — recommending a specific product without a verified government-approved-pesticide dataset was judged too risky to fabricate; farmers are pointed to the Kisan Call Centre / local KVK instead.
- **Single-device farm sync** — no real multi-device merge/conflict resolution if the same account is used on two phones.

## Regenerating the app icon

The launcher icon (Tamil "உ" monogram) is generated, not hand-drawn, by `tools/generate_icon.py` → `assets/icons/`. Edit the script and rerun `python tools/generate_icon.py`, then `dart run flutter_launcher_icons` to regenerate all platform sizes.

## Tests

```bash
flutter analyze
flutter test
```
Both pass clean as of the last change in this README.
