# Variant Audit

## Scope

This audit covers the standalone `core-monitor-app-store/` variant only.

The legacy `Core-Monitor` target in the repository still contains helper-driven and lower-level monitoring features that are outside the scope of this variant.

## What this variant keeps

- CPU activity from host statistics
- per-core usage sampling
- memory usage and pressure classification
- battery and power-source status
- thermal state and thermal warning level
- network throughput
- startup disk usage
- uptime and load averages
- local weather through WeatherKit when the user grants location access
- a single dashboard window and a menu bar extra

## What this variant excludes

- helper installation and helper communication
- fan control and hardware write paths
- AppleSMC access
- private frameworks
- Touch Bar overlays and custom Touch Bar widgets
- shell-backed actions
- updater flows
- diagnostics that depend on privileged components

## Entitlements and protected resources

- `com.apple.security.app-sandbox = true`
- `com.apple.security.network.client = true`
- `com.apple.security.personal-information.location = true`
- `com.apple.developer.weatherkit = true`

`Info.plist` includes the location purpose string:

- `Core-Monitor requires your location to display local weather.`

## Manual review items that still remain

- final signing identity and provisioning profile
- local archive and organizer validation in Xcode
- release metadata review
- signed WeatherKit verification on the submission machine

## Notes

- Exact CPU temperature is not exposed through the system frameworks used by this variant, so the thermal card relies on the thermal signals macOS provides instead.
- Weather requires both location approval and a signed build with WeatherKit enabled.
- The dashboard and menu bar expose direct Privacy Policy and Support links for the App Store edition site.
- The public App Store edition site now stays inside App Store-specific pages and no longer routes reviewers to the broader direct-download build.
