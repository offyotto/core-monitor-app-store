# Release Readiness Checklist (3.0)

| Item | Status | Notes |
| --- | --- | --- |
| Clean Debug and Release builds | PASS | No errors or warnings. |
| Signed sandboxed run | PASS | Automatic signing with the team profile. All metrics read inside the sandbox. |
| Weather opt-in flow | PASS | Off by default. The location prompt appears only after weather is turned on. |
| Weather data and attribution with location allowed | NEEDS MANUAL REVIEW | Allow location once on the release machine and confirm the Apple Weather mark and Legal Attribution link. |
| Release binary scan | PASS | No private frameworks, debug hooks, helper, or third-party network endpoints. |
| Privacy policy link in app | PASS | Settings > Privacy Policy. |
| Archive with released Xcode | NEEDS MANUAL REVIEW | Requires Xcode 27 (27A266a), not the beta. |
| New screenshots | NEEDS MANUAL REVIEW | Upload the 3.0 screenshots in App Store Connect. |
