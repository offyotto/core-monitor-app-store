# App Store Audit (version 3.0)

Checked on 2026-10-01 against the App Review Guidelines, the upload requirements in App Store Connect, and the WeatherKit attribution rules.

## Upload requirements

| Requirement | Status |
| --- | --- |
| Built with Xcode 26 or later and a GA SDK (required since 2026-04-28) | Archive with the released Xcode 27 (27A266a). Beta Xcode builds are not accepted for App Store review. |
| No `com.apple.quarantine` attribute in the bundle (required since 2025-02-18) | Strip it with `xattr -cr` before upload. |
| Privacy manifest for required-reason APIs | Not required: the rule applies to iOS, iPadOS, tvOS, visionOS, and watchOS apps. |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO`. The app uses only Apple's system networking. |

## Guideline 2.4.5 (Mac App Store)

| Rule | Status |
| --- | --- |
| (i) Sandboxed | `com.apple.security.app-sandbox`. Verified in a signed run. |
| (ii) Packaged with Xcode, self-contained | Single app bundle, no installer, nothing written to shared locations. |
| (iii) No launch at login without consent | No login item, no background processes after quit. |
| (iv) No downloaded code | None. |
| (v) No root escalation | No helper, no `SMJobBless`, no authorization calls. |
| (vii) Updates only through the App Store | No updater. |

## Guideline 2.5.1 (public APIs)

All system data comes from documented APIs: `host_statistics`, `host_processor_info`, `sysctlbyname`, `getifaddrs`, `statfs`, `getloadavg`, IOKit power sources (`IOPSCopyPowerSourcesInfo`), `IOPMGetThermalWarningLevel`, and `ProcessInfo`. The release binary links no private frameworks and contains no IOKit write calls.

## Guideline 5.1 (privacy)

| Rule | Status |
| --- | --- |
| 5.1.1(i) Privacy policy link in the app | Settings > Privacy Policy. Also set in App Store Connect. |
| 5.1.1(ii) Clear purpose string | "Core-Monitor uses your location to show local weather from Apple Weather. Your location is not stored or shared." |
| 5.1.1(iii) Data minimization | Location is requested only after the person turns on weather in Settings. Weather is off by default. |
| 5.1.1(iv) Respect declined permission | Declining location only disables weather. The page explains how to allow it later. |
| App Privacy label "Data Not Collected" | Accurate. The 2.0 fallback that sent coordinates to Open-Meteo is removed. Weather comes only from Apple WeatherKit, and the city name comes from Apple's geocoder. |

## WeatherKit attribution

The Weather page shows the Apple Weather mark (light and dark variants from `WeatherService.attribution`) and a link to the legal attribution page whenever Apple weather data is on screen.

## Guideline 2.3 (metadata)

The 3.0 interface is new, so upload new screenshots. The 2.0 screenshots show the old layout and a city name in the weather card.

## Scope this edition excludes

Helper tools, fan control, hardware writes, AppleSMC, private frameworks, Touch Bar overlays, shell actions, and updater flows. Exact CPU temperature is not available to sandboxed apps, so the Thermal page shows the thermal state macOS reports.
