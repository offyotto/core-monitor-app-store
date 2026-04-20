# Store Metadata Draft

## App Name

Core-Monitor

## Subtitle

Read-only Mac system monitor

## Promotional Text

Clean, read-only system monitoring for modern Macs, optimized for Apple silicon. Fast, minimal, and local-first.

## Keywords

cpu,memory,battery,storage,network,uptime,weather,thermal,apple silicon,menu bar

## URLs

- Marketing URL: https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/
- Support URL: https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/support/
- Privacy Policy URL: https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/privacy/

## Description

Core-Monitor is the sandboxed, read-only Mac App Store edition of the Core-Monitor project. It shows CPU activity and per-core load, memory pressure, storage usage, network throughput, battery status, system thermal state, uptime, and local weather after the user taps Enable Location in the Weather card.

It does not install helper tools, control fans, access AppleSMC, change system behavior, or require an account.

## Feature List

- Watch overall CPU activity and per-core load at a glance.
- Check memory use, compression, and available headroom.
- Track current download and upload throughput.
- View startup disk usage, uptime, and load averages.
- Monitor battery charge and charging state on supported Macs.
- Follow system thermal state and warning level.
- See local weather with WeatherKit after granting location access.
- Keep a live summary in the menu bar.

## Review Notes

This submission is for the sandboxed Mac App Store edition only.

Submitted target: core-monitor-app-store
Bundle ID: CoreAPPStore.Core-Monitor

This build is read-only and does not include helper tools, XPC services, fan control, AppleSMC access, Touch Bar overlays, or shell-backed actions.

It uses App Sandbox and documented Apple APIs only. Location is requested only after the user taps Enable Location in the Weather card. Weather data uses WeatherKit and the app displays Apple Weather attribution and legal links in-app.

The broader Core-Monitor project also has a separate direct-download non-App-Store build with additional capabilities, but those features are not part of this submission. The Marketing URL, Support URL, and Privacy Policy URL for this submission remain scoped to the Mac App Store edition and do not route reviewers to the separate build.

## Notes

- Weather requires location approval and a signed build with WeatherKit enabled.
- The thermal card uses system thermal signals because exact CPU temperature is not exposed through the system frameworks used by this edition.
- The app now exposes direct in-app links to the App Store edition privacy policy and support pages from both the dashboard and the menu bar.
- The public support and privacy pages identify Nazish Faizan as the legal owner and support contact for this App Store edition.
- The public App Store edition pages no longer link outward to the separate direct-download build, so the review surface stays within this submission scope.
