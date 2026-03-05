# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# Install debug APK on connected device/emulator
./gradlew installDebug

# Run lint checks
./gradlew lint

# Run all tests
./gradlew test

# Run a single test class
./gradlew test --tests "com.myradio.ExampleTest"
```

## Architecture

Single-module Android app (`app/`) using the Media3 library for background audio playback.

**Playback architecture** uses the Media3 `MediaSessionService` pattern:
- `RadioService` (a `MediaSessionService`) owns an `ExoPlayer` instance and a `MediaSession`, runs as a foreground service with a system media notification.
- `MainActivity` connects to `RadioService` via `MediaController` (bound through `SessionToken`) and sends playback commands over it.
- Station selection is communicated via a custom `SessionCommand` (`COMMAND_PLAY_STATION`) with the station ID passed as a `Bundle` argument — not via standard Media3 playlist commands. This means `RadioService.MediaSessionCallback.onCustomCommand` is the entry point for all playback changes.

**Data model** — `RadioStation` is a plain data class; the base station list is a hardcoded top-level `val RADIO_STATIONS` (a `mutableListOf`) in `RadioStation.kt`. At startup, `StationRepository` fetches additional nearby stations from the Radio Browser API (`radio-browser.info`) using device location (or locale fallback) and appends them to `RADIO_STATIONS`.

**UI** — `MainActivity` hosts a `RecyclerView` (via `StationAdapter`) and a "now playing" bar at the bottom. `StationAdapter` toggles each row's button between play/stop icons based on `playingId`. There is no ViewModel or state holder; UI state is held directly in `MainActivity` fields (`currentStation`, `controllerFuture`).

## Key Files

| File | Purpose |
|------|---------|
| `RadioStation.kt` | Data class + hardcoded base station list — edit here to add/remove static stations |
| `StationRepository.kt` | Fetches nearby stations from Radio Browser API using device location/locale |
| `RadioService.kt` | Background playback service; handles `COMMAND_PLAY_STATION` custom command |
| `MainActivity.kt` | UI entry point; binds to `RadioService` via `MediaController` |
| `StationAdapter.kt` | RecyclerView adapter; play/stop button state per row |
| `gradle/libs.versions.toml` | Version catalog — update dependency versions here |

## Notes

- `minSdk = 26` (Android 8.0); `targetSdk = 34`.
- `network_security_config.xml` controls which HTTP hosts are permitted — update it when adding streams that require cleartext traffic.
- Notification permission (`POST_NOTIFICATIONS`) is requested at runtime on Android 13+ but the app functions without it (the foreground service still runs; only the notification is suppressed).
- Location permission (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`) is requested at startup to improve nearby station discovery; falls back to system locale if denied.
