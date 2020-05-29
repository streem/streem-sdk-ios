# streem-sdk-ios
Example Streem SDK project for IOS

### Example App Requirements

* Xcode 11 with Swift 5
* Cocoapods 1.6 or later
* ARKit compatible device with IOS 12 or later

### Company/App Setup

* Obtain your `company_id` from Streem
* Provide your IOS bundle id for any apps you are going to use the Streem SDK in (later you will be able to do this from a self-service portal)
* Streem will provide you with an `appId`  for each of your IOS apps
* Now that you have your App IDs, follow the steps in the [CallKit Setup Instructions](docs/callkit.md)
* StreemKit expects to be called from a ViewController within a NavigationController, in which it will present its own ViewController.
 
### Installation

Currently Streem supports Cocoapods installation (Carthage, Swift Package Manager, and Manual to come later)

Add a `source` to your `Podfile`:
```
    source 'https://github.com/streem/cocoapods'
```

Then add the `StreemKit` dependency:

```
    pod 'StreemKit'
```

Finally, import the framework where it is used:

```swift
    import StreemKit
```



### Changes to your Info.plist file

You should provide appropriate strings for iOS to present to users the first time that the Streem SDK requests permission to use the camera, the microphone, and the GPS location. For example,

**NSCameraUsageDescription**
`This application is requesting permission to access your camera.`

**NSMicrophoneUsageDescription**
`This application is requesting permission to access your microphone.`

**NSLocationWhenInUseUsageDescription**
`Your location is being requested. We will always ask you first before we share your location with other users.`


### Changes to your AppDelegate code

Inside your `AppDelegate.application(_, didFinishLaunchingWithOptions:)` implementation, initialize the Streem SDK with your App ID:

```swift
    Streem.initialize(delegate: self, appId: "APP_ID") {
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
        // Your app might wish to copy this value to your app preferences,
        // so that when starting future sessions you can restore it
        // (by setting `Streem.sharedInstance.measurementUnit`).
    }
```

Inside your `AppDelegate.application(_, handleEventsForBackgroundURLSession:completionHandler:)` implementation,  call `Streem.setBackgroundURLSession(withIdentifier:, completionHandler:)`:

```swift
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Streem.setBackgroundURLSession(withIdentifier: identifier, completionHandler: completionHandler)
    }
```


### Logging In

Once the user has logged into your app, inform Streem that they are logged in:

```swift
    Streem.sharedInstance.login(
            companyCode: "acme-inc", 
            email: "john.smith600@gmail.com", 
            password: "StreemIsC00l!", 
            avatarUrl: "http://..."
        ) { success in
        
        if success {
            // dismiss login screen, etc.
        } else {
            // present alert, etc.
        }
    }
```

The `companyCode` is a code that Streem will provide your company with; it is the url prefix when using the Steem Web App (`https://{company-code}.swa.dev.streem.cloud`). The `email` and `password` fields are the credentials a user has set up through the Streem Web App.  `avatarUrl` is an optional string containing the url for a profile picture the user would like to be visible during streems.


### Starting a Remote Streem

Through some mechanism in your app, you determine that your logged-in user and another user should be streeming.

To make a call to user "tom" (see below on how to retrieve a remote user's id), do the following:

```swift
    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteUserId: "tom") { success in
        if !success {
            // present alert, etc.
        }
    }
```

If CallKit has been set up correctly, Tom's device will ring like a phone call, and once answered, both phones will be connected on Streem.

Note: Due to an issue with ARKit, you cannot start a Remote Streem from a view using the camera https://forums.developer.apple.com/message/411888#411888

#### Roles

Roles dictate which side of the streem you're on: whether you are providing or receiving the video feed. They also affect which tools are available to you. The different roles are:

* `LOCAL_CUSTOMER`: The Customer in a two-way streem
* `ONSITE_CUSTOMER`: The Customer in an onsite (one-way) streem 
* `REMOTE_PRO`: The Pro in a two-way streem
* `ONSITE_PRO`: The Pro in an onsite (one-way) streem

In general if you are starting a remote streem you will want the `LOCAL_CUSTOMER` role. 

### Getting Remote User IDs

In order to start a streem with a remote user, your app will need to supply that user's `remoteUserId`. There are two mechanisms available in the SDK for retrieving a `remoteUserId`. The first is through getting a list of recently logged-in users. The second is through an invitation. In addition to these two methods, you can maintain your own list of `remoteUserIds` and supply them to your app however you choose. 

#### Recently Logged In Users

By calling the SDK's `getRecentlyIdentifiedUsers` method on the Streem `sharedInstance` you will receive a list of recently logged in users for your company. You can use this method to filter only experts. You then give this method a callback where you select the remote user through some mechanism and start the streem. 

```swift
    Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
        guard let self = self else { return }

        // Select the user you wish to streem with

        Streem.sharedInstance.startRemoteStreem(
            asRole: .LOCAL_CUSTOMER,
            withRemoteUserId: selectedUser.id) { success in 
                // handle succes of streem
        }
``` 

#### Invitations

If you are utilizing Streem's Pro implementations on the web and/or iOS you will likely have access to invitations. Invitations are communicated via a 9-digit code. This code can be transmitted through SMS, email, or copy and pasted to some other mechanism such as Slack. 

Once you've retrieved this 9-digit code in your app you will follow two steps. 

* Call `login(with invitationCode:avatarUrl:)`  to authenticate the user, retrieve the invitation details, and identify the user in our system.
* Call `startRemoteStreem` with the remote user contained in the invitation. The whole flow looks like:

```swift
    Streem.sharedInstance.login(with: invitationCode) { error, details in
        guard error == nil, let details = details else {
            // An invalid code was used
            return
        }
    
        let invitation = Invitation(
            requesterName: details.name,
            displayName: details.user.displayName,
            code: invitationCode,
            remoteId: details.user.uid,
            referenceId: details.referenceId,
            photoURL: details.user.photoURL,
            companyCode: details.company.companyCode,
            companyName: details.company.name,
            expiresAt: details.expiresAt,
            companyLogoURL: details.company.logoUrl
        )

        Streem.sharedInstance.startRemoteStreem(
            asRole: .LOCAL_CUSTOMER,
            remoteUserId: invitation.remoteId,
            referenceId: invitation.referenceId,
            companyCode: invitation.companyCode
        ) { streemSuccess in
            if streemSuccess {
                // handle streem success
            } else {
                // handle streem error
            }
        }
    }
``` 

### Starting a Local Streem

A Local Streem uses the device's camera, and opens up an AR experience with our arrow and measure tools, and the ability to capture Streemshots.  Open a Local Streem simply by:

```swift
    Streem.sharedInstance.startLocalStreem() { success in
        if !success {
            // present alert, etc.
        }
    }
```

Note: Due to an issue with ARKit, you cannot start a Local Streem from a view using the camera https://forums.developer.apple.com/message/411888#411888

### Fetching the Call Log

You can fetch a list of the logged-in user's previous streems:

```swift
    Streem.sharedInstance.fetchCallLog { callLogEntries in
        // display a Table of the calls, etc.
    }
```

The returned array contains objects of type `StreemCallLogEntry`, which have these properties:

```swift
    startDate: Date            // Session start time.
    endDate: Date?             // Session end time.
    participants: [StreemUser] // Session participants. One for an Onsite Streem, two for a two-way Streem.
    streemshotsCount: Int      // The number of Streemshots captured during the session.
```

### Displaying and Editing Streemshots

Once you have fetched the call log, you may display or edit the Streemshots associated with any of the calls.

First, obtain a `StreemshotManager` for the call:

```swift
    let streemshotManager = Streem.sharedInstance.streemshotManager(forCallLogEntry: entry)
```

As soon as the `StreemshotManager` is created, it will begin to download the call's Streemshots.

You can associate a `UIImageView` with each Streemshot. For example, this might be an image view within a UICollectionViewCell:

```swift
    streemshotManager.register(imageView: cell.streemshotThumbnail, forStreemshotIndex: indexPath.item)
```

When the Streemshot has been downloaded, the `StreemshotManager` will set the `UIImageView`'s `image`.

You can also break this association, by calling:

```swift
    streemshotManager.unregister(imageView: theImageView)
```

For example, if the image view is part of a UICollectionViewCell, you should call `unregister(imageView:)` within the cell's `prepareForReuse()` method.

To present the UI for editing a Streemshot, first confirm that the Streemshot has been fully downloaded, by calling:

```swift
    streemshotManager.canEditStreemshot(atIndex: theIndex)
```
Once that method returns `true`, you can launch a Streemshot-editing session:

```swift
    streemshotManager.editStreemshot(atIndex: theIndex)
```

The `StreemshotManager` will present the Streemshot-editing view controller, loaded with the indicated Streemshot. (The view controller also allows the user to scroll through the other Streemshots associated with the call.)

