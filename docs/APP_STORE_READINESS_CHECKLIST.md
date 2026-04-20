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
| Privacy policy and support links exposed in-app | PASS | The dashboard and menu bar both link to the App Store edition privacy and support pages. |
| Exact CPU temperature not claimed | PASS | The UI explains that it uses system thermal signals instead. |
| Metadata matches the feature set | PASS | Docs now describe weather, storage, uptime, and per-core monitoring. |
| Public App Store pages stay within submission scope | PASS | The App Store marketing, support, and privacy pages no longer route reviewers to the separate direct-download build. |
| Apple silicon wording is aligned with the build | PASS | Submission copy now says the app is optimized for Apple silicon instead of implying an Apple-silicon-only binary. |
| Review notes prepared | PASS | `docs/APP_STORE_METADATA.md` includes ready-to-paste Notes for Review text that explains the App Store-only scope. |
| Privacy policy matches current behavior | PASS | Privacy text includes location, network use for weather/geocoding, and limited on-device history retention. |
| Clean local build | PASS | Verified with a signed debug build using `xcodebuild ... -allowProvisioningUpdates build`. |
| Launch and signed-weather verification | NEEDS MANUAL REVIEW | Confirm on a signed desktop build with WeatherKit enabled. |
| Final submission review outcome | NEEDS MANUAL REVIEW | Final review still depends on the signed archive and submission date. |
