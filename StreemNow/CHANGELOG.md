### 0.34.1 March 13, 2023
- Added logs for call quality stats
- Removed support for AR 
- Various stability improvements and bug fixes

### 0.34.0 February 13, 2023

- Added ability to set AppTheme
- Added support for Expert Bios

### 0.33.0 - December 14, 2022

- Add ability to add integrationId when starting a Streem
- Additional logging
- Bug fixes

### 0.32.1 - September 7, 2022

- Stability improvements and bug fixes

### 0.32.0 - September 6, 2022

- Updated TwilioVideo to 5.0
- Updated minimum Xcode to 13.4.1
- Stability improvements and bug fixes

### 0.31.0 - May 11, 2022

-   Updated pod versions
-   Bug fixes

### 0.30.1 - Apr 27, 2022

-   Stability improvements 

### 0.30.0 - March 11, 2022

-   Stability improvements 
    
### 0.29.0 - February 10, 2022

-   Updated Universal Link API to prevent a crashing error
    -   `Streem.sharedInstance.parseUniversalLink(incomingURL)` changed to `Streem.parseUniversalLink(incomingURL)`
    -   Updated URL Parsing documentation

### 0.28.1 - January 18, 2022

-   Updated TwilioSyncClient version to resolve connection issue
-   **** Please remove `source https://github.com/twilio/cocoapod-specs` from your Podfile ****

### 0.28.0 - January 13, 2022

-   Fixed a bug where the video was not rotating with the device
-   Updated minimum Xcode version to 13.2.1

### 0.27.0 - December 13, 2021

-   iOS minimum version updated to 13.0
-   Disabled mesh visualization and PiP
-   Fixed a bug where iOS Expert kept ringing after customer had declined to join

### 0.26.0 - November 15, 2021

-   Fixed a bug impacting OnSite recordings
-   Improved testing capabilities
-   Updated domains

### 0.25.0 - October 18, 2021

-   Updates necessary to ensure smooth operation on iOS 15 devices

### 0.24.0 - September 24, 2021

-   [API changes to startRemoteStreem](docs/remote.md)
-   Renamespacing of all WebRTC objective C types
-   RxCocoa and RxGesture dependencies vendored from source
-   Bug fixes & stability improvements

### 0.23.0 - August 19, 2021

-   UI improvements to sample app
-   Documentation improvements
-   Bug fixes

### 0.22.2 - July 20, 2021

-   Bug fixes

### 0.22.1 - July 12, 2021

-   Bug fixes

### 0.22.0 - June 30, 2021

-   Built with Xcode 12.3
-   Uses RxSwift CocoaPods
-   Bug fixes

### 0.21.0 - June 17, 2021

-   Added OnSite GPS request
-   Removed RxSwift CocoaPods
-   Removed GzipSwift CocoaPod

### 0.20.0 - May 13, 2021

-   Added customer lobby
-   Improve tool selection
-   Better CocoaPod security
-   Usability fixes

### 0.19.0 April 10th, 2021

-   Logging additions
-   Bug fixes
-   Removed WebRTC external dependency

### 0.18.0 - March 18, 2021

-   Fixed speaker button
-   Measurement fixes

### 0.17.0 - February 25, 2021

-   Added support for Single Sign-On

### 0.16.0 - February 24, 2021

-   Now publishing StreemKit as an `xcframework` with support for simulator and iOS devices in one package
-   Removed `PromiseKit` as a dependency
-   Automatic cocoapods `postinstall` configuration by running `configure_streemkit.rb` script

### 0.15.1 - December 4, 2020

-   Fixed issue with measurement labels not sticking to their measurement lines

### 0.15.0 - September 20, 2020

-   Updated login methods
-   Added support for Universal Links
