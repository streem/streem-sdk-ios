
# streem-sdk-ios
Example Streem SDK project for IOS

## Requirements

* Xcode 12 with Swift 4.2
* Cocoapods 1.9 or later (1.10 for debug symbols)
* ARKit compatible device with IOS 11.0

## Company/App Setup

* Obtain your `company_id` from Streem
* Provide your IOS Bundle ID for any apps you are going to use the Streem SDK in (later you will be able to do this from a self-service portal)
* Streem will provide you with an `appId`  for each of your IOS apps (e.g. you'll need one for development and release, if you use different Bundle IDs)
* Now that you have your App IDs, follow the steps in the [CallKit Setup Instructions](docs/callkit.md)
* StreemKit expects to be called from a ViewController within a NavigationController, in which it will present its own ViewController.

### Note on Universal Links

If you would like to use universal links with Streem invitation links, there is some additional setup required. You will need to coordinate with Streem to have your app's bundle id added to our `apple-app-site-association` file. You will then need to add the Associated Domains entitlement to your app with the domains `<companyCode>.swac.prod-us.streem.cloud` and `<companyCode>.streem.me`. For more details on adding this entitlement please see the "Add the Associated Domains Entitlement to Your App" section of this resource: https://developer.apple.com/documentation/safariservices/supporting_associated_domains.  
 
## Installation

Currently Streem supports Cocoapods installation (Carthage, Swift Package Manager, and Manual to come later)

Add the following  `source` lines to your `Podfile` for Streem and its dependencies:
```
    source 'https://github.com/twilio/cocoapod-specs'
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

Finally, in your code, import the framework where it is used:

```swift
    import StreemKit
```


### Changes to your Info.plist file

You should provide appropriate strings for iOS to present to users the first time that the Streem SDK requests permission to use the camera, the microphone, and the GPS location. For example,

- NSCameraUsageDescription
`This application is requesting permission to access your camera.`

- NSMicrophoneUsageDescription
`This application is requesting permission to access your microphone.`

- NSLocationWhenInUseUsageDescription
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


## Logging In

### Invitation Code Authentication

If a customer is being invited to a remote streem with an invitation code, authentication will happen using the following methods:

```swift
Streem.sharedInstance.login(withInvitationCode: code) { [weak self] error, details, identity in

	 Streem.sharedInstance.identify(with: identity) { [weak self] success in
	 	// the customer is now authenticated
	 }

}
```

### Embedded Auth

If you are embedding the Streem SDK inside an app that already has authentication, you will want to use one of our [Server Side SDK's](#server-side-sdks) to return a `StreemToken` along with your normal auth flow.  When creating a `StreemIdentity`, you will provide a `StreemToken` as well as a method for refreshing the `StreemToken` when it expires.

```swift

let streemToken = yourServerAuthResponse.streemToken

let streemIdentity = StreemIdentity.init(token: StreemToken, name: String, avatarUrl: String?, isExpert: Bool) {
    return { didObtainFreshStreemToken in
        YourServer.refreshStreemToken() { newStreemToken in
            didObtainFreshStreemToken(newStreemToken)
        }
    }
}

Streem.sharedInstance.identify(with: streemIdentity) { [weak self] success in
	if success {
		// you successfully logged in!
	}
}
```


## Starting a Remote Streem

Through some mechanism in your app, you determine that your logged-in user and another user should be streeming.

To make a call to user "tom" (see below on how to retrieve a remote user's id), do the following:

```swift
    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteExternalUserId: "tom") { success in
        if !success {
            // present alert, etc.
        }
    }
```

If CallKit has been set up correctly, Tom's device will ring like a phone call, and once answered, both phones will be connected on Streem.

Note: Due to an issue with ARKit, you cannot start a Remote Streem from a view using the camera https://forums.developer.apple.com/message/411888#411888

### Roles

Roles dictate which side of the streem you're on: whether you are providing or receiving the video feed. They also affect which tools are available to you. The different roles are:

* `LOCAL_CUSTOMER`: The Customer in a two-way streem
* `ONSITE_CUSTOMER`: The Customer in an onsite (one-way) streem 
* `REMOTE_PRO`: The Pro in a two-way streem
* `ONSITE_PRO`: The Pro in an onsite (one-way) streem

In general if you are starting a remote streem you will want the `LOCAL_CUSTOMER` role. 

### Getting Remote User IDs

In order to start a streem with a remote user, your app will need to supply that user's `remoteUserId`. There are two mechanisms available in the SDK for retrieving a `remoteUserId`. The first is through getting a list of recently logged-in users. The second is through an invitation. In addition to these two methods, you can maintain your own list of `remoteUserIds` and supply them to your app however you choose. 

### Recently Logged-In Users

By calling the SDK's `getRecentlyIdentifiedUsers` method on the Streem `sharedInstance` you will receive a list of recently logged-in users for your company. You can use this method to filter only experts. You then give this method a callback where you select the remote user through some mechanism and start the streem. 

```swift
    Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
        guard let self = self else { return }

        // Select the user you wish to streem with

        Streem.sharedInstance.startRemoteStreem(
            asRole: .LOCAL_CUSTOMER,
            withRemoteExternalUserId: selectedUser.id) { success in 
                // handle succes of streem
        }
``` 

### Invitations

If you are utilizing Streem's Pro implementations on the web and/or iOS you will likely have access to invitations. Invitations are communicated via a 9-digit code. This code can be transmitted through SMS, email, or copy and pasted to some other mechanism such as Slack. 

Once you've retrieved this 9-digit code in your app you will follow two steps. 

* Call `login(with invitationCode:avatarUrl:)`  to authenticate the user, retrieve the invitation details, and identify the user in our system.
* Call `startRemoteStreem` with the remote user contained in the invitation. The whole flow looks like:

```swift
    Streem.sharedInstance.login(with: invitationCode) { error, details, identity in
        guard error == nil, let details = details else {
            // An invalid code was used
            return
        }
		
		Streem.sharedInstance.identify(with: identity) { success in
			guard success else {
			// identity was not correct
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
	            withRemoteExternalUserId: invitation.remoteId,
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
    }
``` 

## Starting a Local Streem

A Local Streem uses the device's camera, and opens up an AR experience with our arrow and measure tools, and the ability to capture Streemshots.  Open a Local Streem simply by:

```swift
    Streem.sharedInstance.startLocalStreem() { success in
        if !success {
            // present alert, etc.
        }
    }
```

Note: Due to an issue with ARKit, you cannot start a Local Streem from a view using the camera https://forums.developer.apple.com/message/411888#411888

## Pro Implementation
The above is sufficient to implement the Customer side of streems (the caller). If you want to implement the Pro side of streems (the callee) the following will get you started.

### OpenID Login
Before you can start doing Pro things you'll need to login as a Pro. A user which is created with Streem can be designated as a Pro through the admin portal. Once designated, the user should login using OpenId:

```swift

Streem.sharedInstance.getOpenIdConfiguration(forCompanyCode: companyCode) { [weak self] error, clientId, tokenEndpoint, authorizationEndpoint, logoutEndpoint in

    OpenIDHelper.loginViaOpenId(withCompanyCode: companyCode,
                                 clientId: clientId,
                                 tokenEndpoint: tokenEndpoint,
                                 authorizationEndpoint: authorizationEndpoint,
                                 appDelegate: self.appDelegate,
                                 presentingViewController: self) { streemIdentity, errorMessage in
        completion(true, streemIdentity, errorMessage)
    }

}
```

### OpenID Logout
Once your user is ready to logout you need to call `logout` on the `sharedInstance`:

```swift
    Streem.sharedInstance.logout()
```

### The Post Call Experience
The SDK provides a number of items for constructing a post call experience which allows a Pro user to review their calls, add notes, edit streemshots, and interact with a mesh from calls with that enabled. The collection of items made available after streems are called `artifacts` and to retrieve them from the SDK you use an `ArtifactManager`.

### Fetching the Call Log

You can fetch a list of the logged-in user's previous streems:

```swift
    Streem.sharedInstance.fetchCallLog { callLogEntries in
        // display a Table of the calls, etc.
    }
```

The returned array contains objects of type `StreemCallLogEntry`, which have these properties and method:

```swift
    id: String                                         // A unique id for the call log
    startDate: Date                                    // Session start time
    endDate: Date?                                     // Session end time
    participants: [StreemUser]                         // Session participants. One for an Onsite Streem, two for a two-way Streem.
    hasMesh: Bool                                      // Whether the streem has a mesh with it or not
    isOnsite: Bool                                     // Whether the streem was an onsite streem or not
    latestDetectedAddress: String                      // The latest detected address for the streem
    latestDetectedCoordinates: CLLocationCoordinate2D  // The latest GPS coordinates for the streem
    notes: String                                      // The notes for the streem
    maximumNotesCharacters: Int                        // Maximum allowable length of Call Notes -- expressed in characters, not bytes
    referenceId: String                                // The reference ID of the streem
    shareUrl: String                                   // The URL for sharing the call details
    isMissed: Bool                                     // Whether the streem call was missed or not
    
    // The number of available artifacts of the specified type.
    func artifactCount(type: StreemArtifactType) -> Int
```

### Displaying and Editing Artifacts

Once you have fetched the call log, you may display or edit the artifacts associated with any of the calls.

First, obtain an `ArtifactManager` for the call. The call to `artifactManager` takes a callback which will provide, for each artifact associated with the call, the type and index of the artifact, as well as whether that artifact was retrieved successfully:
```swift
    let artifactManager = Streem.sharedInstance.artifactManager(forCallLogEntry: entry) { [weak self] artifactType, artifactIndex, success in
        switch artifactType {
        case .callNote:
            handleCallNoteLoading(success)
        case .streemshot: 
            handleStreemshotLoading(artifactIndex, success)
        case .recording:
            handleRecordingLoading(artifactIndex, success)
        case .mesh:
            handleMeshLoading(artifactIndex, success)
        }
    }
```

As soon as the `ArtifactManager` is created, it will begin to download the call's Artifacts.

Your `handleArtifactLoading` methods from above should check for success and then retrieve the note, image, recording, or provide a representation of the mesh. 

```swift
    func handleCallNoteLoading(success: Bool) {
        self.noteCell?.isReadOnly = !artifactManager.canEditCallNote()
        artifactManager.callNote() { noteText in
            // Do something with the note text
        }
    }

    func handleStreemshotLoading(index: Int, success: Bool) {
        if success {
            let image = artifactManager.streemshotImage(at: index)
            // Do something with the image
        } else {
            // handle failure
        }
    }

    func handleRecordingLoading(index: Int, success: Bool) {
        if success {
            // The recording artifact will be a downloaded, playable movie file which can be retrieved via its URL
            let url = artifactManager.recordingUrl(at: index)
            let asset = AVURLAsset(url: url, options: nil)
            // Do something with the AV Asset

            // Or if you simply want to play the video
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: url)
            // Present vc
        } else {
            // handle failure
        }
    }

    func handleMeshLoading(index: Int, success: Bool) {
       if success {
           // Do something to display mesh
       } else {
           // handle failure
       } 
    }
```

When presenting Streemshots you may want to display if a Streemshot has a note. To check if it has one call:

```swift
    if artifactManager.streemshotHasNote(at: index) {
        // Display that Streemshot has a note
    }
```

To present the UI for presenting and editing a Streemshot, first confirm that the Streemshot has been fully downloaded, by calling:

```swift
    artifactManager.canAccessStreemshot(atIndex: theIndex)
```
Once that method returns `true`, you can launch a Streemshot-editing session:

```swift
    artifactManager.accessStreemshot(atIndex: theIndex)
```

The `ArtifactManager` will present the Streemshot-editing view controller, loaded with the indicated Streemshot. (The view controller also allows the user to scroll through the other Streemshots associated with the call.)

To enter into the mesh editor you follow a similar set of steps. First check to see that the mesh is ready and presentable:

```swift
    artifactManager.canAccessMeshScene()
```

If that returns `true`, you can launch the mesh scene editing session:

```swift
    artifactManager.accessMeshScene()
```

## Server Side SDK's
If you are embedding the Streem SDK into an app that already has authentication, you will want to implement one of the following server side SDK's to return a `StreemToken` along with your normal auth flow.  Your app will then use that token to authenticate with the Streem servers

- [https://github.com/streem/streem-sdk-node](https://github.com/streem/streem-sdk-node)
- [https://github.com/streem/streem-sdk-ruby](https://github.com/streem/streem-sdk-ruby)

## Known Issues

### iOS 12 Storyboard Crash

There is a certain configuration that can cause iOS 12 to crash, if ALL of the following conditions are met:
* Your app and StreemKit share a cocoapod dependency
* You have a `ViewController` with a non-frozen  `struct` or `enum` as a stored property, from either `StreemKit` or a shared dependency
* You instantiate the `ViewController` from a Storyboard

More details on this issue can be found [here](https://bugs.swift.org/browse/SR-11969).

The reason this happens is that StreemKit is published as a binary swift framework with [Library Evolution Support](https://swift.org/blog/library-evolution/).  It also means that our direct dependencies must also have Library Evolution Support.  When a non-frozen `struct` or `enum` from one of these libraries is stored in a class, and that class is dynamically created using `NSClassFromString` (which includes storyboards), the `objc` runtime must be able handle these "open memory layout" objects.  iOS 12 did not ship with an `objc` runtime capable of handling these objects, so the class fails to instantiate, and you get a crash.

The bug typically manifests as something like the following:
```
2019-12-10 11:51:54.379859+0530 SampleApp[860:373730] Unknown class _TtC9SampleApp11OrderPageVC in Interface Builder file.

2019-12-10 11:51:54.477752+0530 SampleApp[860:373730] *** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<UIViewController 0x13be59400> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key amountTextField.'
```

We are working to get our transitive dependency list down in order to minimize the potential for this bug to be caused by integrating StreemKit.  If you experience this issue, please reach out so we can work together to get past it. 


### Laser/Draw functionality not available in non-AR sessions

Currently if running the camera on a non-AR devices (such as iPhone 6 and below), our laser and draw tools do not render on the screen properly.
