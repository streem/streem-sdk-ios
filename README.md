# streem-sdk-ios (`StreemKit`)
Example Streem SDK project for iOS, plus instructions for integrating the Streem iOS SDK (`StreemKit`) into your own app.

### StreemKit

`StreemKit` is an iOS framework implementing [Streem's augmented-reality platform](https://www.streem.com/platform/sdk) for local and remote live-video consultation.

At this time, integration of `StreemKit` requires CocoaPods.

### StreemNow

StreemNow is a small sample app that integrates `StreemKit`. Its features include:
* Remote (two-person) AR-enhanced video calls.
* Onsite (one-person) AR-enhanced video scanning.
* Subsequent review of all calls, including access to call recordings and other artifacts.

### Requirements

* Xcode 12.0 or newer
* Cocoapods 1.10 or newer
* ARKit-compatible device with iOS 11.0 or newer
  - Note: making a Streem call requires an actual device, rather than the Simulator.

### [Company/App Setup](docs/company_app.md)

### [Integrating StreemKit into your app](docs/integrating.md)

### [User Authentication, via Log-in or Invitation](docs/authenticating.md)

### [Starting a Remote Streem](docs/remote.md)

### [Starting a Local Streem](docs/local.md)

### [The Post-Call Experience](docs/post-call.md)

### [Known Issues](docs/known_issues.md)
