# core-monitor-app-store

`core-monitor-app-store` is the source code for the sandboxed Core-Monitor edition [available free on the Mac App Store](https://apps.apple.com/us/app/core-monitor/id6762558526).

## What it includes

- live CPU activity with performance/efficiency splits
- per-core monitoring
- memory usage and pressure
- thermal state and thermal warning level
- network throughput
- startup disk usage
- uptime and load averages
- battery and power-source status on supported Macs
- local weather when the user grants location access
- a SwiftUI dashboard and menu bar extra

## What it excludes

- helper tools and XPC services
- fan control and hardware write paths
- AppleSMC access and private frameworks
- Touch Bar overlays and custom Touch Bar widgets
- shell-backed actions
- updater flows
- diagnostics tied to privileged components

## Project layout

- [core-monitor-app-store.xcodeproj](./core-monitor-app-store.xcodeproj)
- [Sources](./Sources)
- [Resources](./Resources)
- [docs/APP_STORE_AUDIT.md](./docs/APP_STORE_AUDIT.md)
- [docs/APP_STORE_READINESS_CHECKLIST.md](./docs/APP_STORE_READINESS_CHECKLIST.md)
- [docs/APP_STORE_METADATA.md](./docs/APP_STORE_METADATA.md)
- [docs/PRIVACY_POLICY.md](./docs/PRIVACY_POLICY.md)

## Build

From this directory:

```bash
./script/build_and_run.sh --verify
```

Or directly:

```bash
xcodebuild -project core-monitor-app-store.xcodeproj -scheme core-monitor-app-store -configuration Debug -allowProvisioningUpdates build
```

## Notes

- Weather uses a signed WeatherKit path first and falls back to a forecast fetch when Apple Weather auth is unavailable on the local machine.
- Exact CPU temperature is not available through the system frameworks used here, so the thermal card relies on the thermal signals macOS publishes instead.
