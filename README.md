# core-monitor-app-store

`core-monitor-app-store` is the sandboxed Mac App Store edition of Core-Monitor.

## What it includes

- live CPU activity
- per-core monitoring
- memory usage and pressure
- thermal state
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

- Weather uses WeatherKit in a signed build and surfaces setup issues directly when Apple Weather authentication fails.
- Weather attribution follows the WeatherKit `WeatherAttribution` surface, including the Apple Weather mark, legal link, and legal attribution text.
- The dashboard and menu bar both expose in-app links to the App Store edition [Privacy Policy](https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/privacy/) and [Support](https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/support/) pages.
- The App Store target avoids AppleSMC, private frameworks, private selectors, and undocumented chip or perf-level probes.
- Exact CPU temperature is not available through the system frameworks used here, so the thermal card relies on the thermal signals macOS publishes instead.
- Final archive, signing, and release validation still need to happen in Xcode.
