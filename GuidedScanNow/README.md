# GuidedScanNow

This app demonstrates the use of the `GuidedScanKit` APIs to scan a space, generate floorplans, as well as to view and edit them.

## Requirements

* Xcode 13.2.1 or newer
* Cocoapods 1.10 or newer
* ARKit-compatible device with lidar camera and iOS 13.4 or newer
  - Note: Starting a Guided Scan requires a real device.
  
## Company/App Setup

* Obtain your `company_code` from Streem
* Provide any iOS Bundle IDs you are going to use for StreemGuidedScanKit in, along with the corresponding environment -- e.g., `sandbox`, `prod` or `prod-us`.
* Streem will provide you with an `appId` for each of your iOS apps -- e.g. you'll need one each for development and release, if you use different Bundle IDs.
* Now that you have your App IDs, you can place it GuidedScanNow's `StreemInitializer`:
```
    private let appId = "*** YOUR APP-ID GOES HERE ***"
```
* You should be good to run the app and install on your device for testing.
