# core-monitor-app-store

`core-monitor-app-store` is the source code for the sandboxed Core-Monitor edition [available free on the Mac App Store](https://apps.apple.com/us/app/core-monitor/id6762558526).

## What it includes

- a sidebar window with a page for each subsystem: CPU, memory, storage, network, power, thermal, and weather
- three minutes of live history in Swift Charts
- CPU usage split by performance and efficiency cores, per-core load, load averages, and uptime
- memory usage, pressure, and breakdown
- startup disk usage
- download and upload rates
- battery charge, health, and time remaining on Mac laptops
- the thermal state macOS reports
- optional local weather from Apple WeatherKit, off by default
- a menu bar extra with configurable readouts

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

- Weather is off until it is turned on in Settings. It needs a signed build with the WeatherKit capability, and Apple WeatherKit is its only source.
- Exact CPU temperature is not available to sandboxed apps, so the Thermal page shows the thermal state macOS reports.
