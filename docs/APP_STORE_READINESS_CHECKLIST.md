# Release Readiness Checklist

| Item | Status | Notes |
| --- | --- | --- |
| App Sandbox enabled | PASS | `com.apple.security.app-sandbox` is enabled. |
| Network client entitlement enabled | PASS | Required for weather and attribution fetches. |
| Location entitlement enabled | PASS | Used only for the weather feature. |
| WeatherKit entitlement enabled | PASS | Required for WeatherKit in signed builds. |
| Helper code removed from this variant | PASS | No helper target or helper embedding exists here. |
| Hardware write paths removed | PASS | No fan control or writeback behavior remains. |
| AppleSMC access removed | PASS | The variant does not use AppleSMC. |
| Touch Bar code removed | PASS | No Touch Bar surfaces remain in this target. |
| Shell execution removed from the app UI | PASS | The remaining shell script is a developer build script outside the app bundle. |
| Weather purpose string present | PASS | `Info.plist` includes the weather/location message. |
| Weather permission flow implemented | PASS | The dashboard requests location when the user enables weather. |
| Exact CPU temperature not claimed | PASS | The UI explains that it uses system thermal signals instead. |
| Metadata matches the feature set | PASS | Docs now describe weather, storage, uptime, and per-core monitoring. |
| Privacy policy matches current behavior | PASS | Privacy text includes location and network use for weather. |
| Clean local build | PASS | Verified with a signed debug build using `xcodebuild ... -allowProvisioningUpdates build`. |
| Launch and signed-weather verification | NEEDS MANUAL REVIEW | Confirm on a signed desktop build with WeatherKit enabled. |
| Published App Store listing | PASS | Core-Monitor version 2.0 is available at [Apple app ID 6762558526](https://apps.apple.com/us/app/core-monitor/id6762558526). |
