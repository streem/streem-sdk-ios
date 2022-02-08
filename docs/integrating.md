&nbsp; &nbsp; &nbsp; &nbsp;
[< Company/App Setup](company_app.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[User Authentication >](authenticating.md)

## Integrating StreemKit into your app

_**StreemKit currently supports installation via Cocoapods.** Other integrations might be added in the future._

Add the following `source` line to your `Podfile` for Streem and its dependencies:

```
    source 'https://github.com/CocoaPods/Specs.git'
```

Then add the `StreemKit` dependency to your `target`:

```
    pod 'StreemKit', :source => 'https://github.com/streem/cocoapods'
```

Load and run the `configure_streemkit.rb` script and function from within your `post_install` block:

```ruby
    post_install do |installer|
        ...
        load './Pods/StreemKit/configure_streemkit.rb'
        configure_streemkit(installer)
        ...
    end
```

Tell CocoaPods to build your project:

```ruby
    pod install
```

Finally, in your code, import the framework in any source file where it is used:

```swift
    import StreemKit
```

### Changes to your `Info.plist` file

You should provide appropriate strings for iOS to present to users the first time that StreemKit requests permission to use the camera, the microphone, and the GPS location. For example,

-   **`NSCameraUsageDescription`**</br>
    `This application is requesting permission to access your camera.`

-   **`NSMicrophoneUsageDescription`**</br>
    `This application is requesting permission to access your microphone.`

-   **`NSLocationWhenInUseUsageDescription`**</br>
    `Your location is being requested. We will always ask you first before we share your location with other users.`

### Changes to your `AppDelegate` code

Inside your `AppDelegate.application(_, didFinishLaunchingWithOptions:)` implementation, initialize StreemKit with your Streem App ID and the Streem domain corresponding to your intended Streem environment (e.g., `sandbox-us` or `prod-us`):

```swift
    Streem.initialize(delegate: self, appId: "APP_ID", streemDomain: "sandbox-us.streem.cloud") {
        // Your app might wish to set up default measurement units here,
        // by setting `Streem.sharedInstance.measurementUnitsToChooseFrom` and
        // `Streem.sharedInstance.measurementUnit`.
    }
```

Implement the `StreemDelegate` methods -- these are optional, but usually you will want to implement them:

```swift
    public func currentUserDidChange(user: StreemUser?) {
        // As necessary, update your stored and/or displayed `user.name` and `user.id`
    }

    public func func measurementUnitDidChange(measurementUnit: UnitLength) {
        // The unit used for Streem measurements -- cm, inch, etc.
        // Your app might wish to copy this value to your app preferences,
        // so that when starting future sessions you can restore it
        // (by setting `Streem.sharedInstance.measurementUnit`).
    }
```

Inside your `AppDelegate.application(_, handleEventsForBackgroundURLSession:completionHandler:)` implementation, call `Streem.setBackgroundURLSession(withIdentifier:, completionHandler:)`:

```swift
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Streem.setBackgroundURLSession(withIdentifier: identifier, completionHandler: completionHandler)
    }
```

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< Company/App Setup](company_app.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[User Authentication >](authenticating.md)
