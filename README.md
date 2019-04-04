# streem-sdk-ios
Example Streem SDK project for IOS


## Streem Functions

| Core Functionality                                | Streem App        | SDK Status        |
| ------------------------------------------------- | ----------------- | ----------------- |
| Non-AR remote streeming                           | ✅ 				| ✅                |
| Non-AR onsite streeming                           | ✅ 				| ✅                |
| Pro-to-Pro calling                                | ❌ 				| ✅                |
| Pro CallKit integration                           | ✅ 				| ✅                |
| Customer CallKit integration                      | ❌ 				| ✅                |
| Laser tool                                        | ✅ 				| ✅                |
| Landscape Support                                 | ❌ 				| ✅                |
| iPad Support                                      | ✅ 				| ✅                |
| API Access (GET /streems)                         | ❌ 				| ✅                |
| AR Remote Streem                                  | ✅ 				| ✅                |
| AR Onsite Streem                                  | ✅ 				| ✅                |
| AR Arrow Tool                                     | ✅ 				| ✅                |
| Remote Streemshot                                 | ✅ 				| ✅                |
| Onsite Streemshot                           	    | ✅ 				| ✅                |
| Streemshot Editing                                | ✅					|                   |
| Streemshot Processing                             | ✅					|                   |
| Onsite Recording                           	    | ✅ 				|                   |
| Remote Recording                                  | ✅ 				| ✅                |


### Company/App Setup

* Obtain your `company_id` from Streem
* Provide your IOS bundle id for any apps you are going to use the Streem SDK in (later you will be able to do this from a self-service portal)
* Streem will provide you with an `appId` and `appSecret` for each of your IOS apps
* Now that you have your App IDs, follow the steps in the [CallKit Setup Instructions](docs/callkit.md)

### Installation

Currently Streem supports Cocoapods installation (Carthage, Swift Package Manager, and Manual to come later)

```
    pod 'Streem'
```

Then simply import the framework where it is used:

```swift
    import Streem
```


### Logging In

Before identifying the currently logged in user, initialize the SDK with your App ID and secret:

```swift
    Streem.initialize(delegate: self, appId: "APP_ID", appSecret: "APP_SECRET")
```

Implement the two required `StreemDelegate` methods:

```swift
    public func initializationDidFail() {
        // present alert, etc. in the rare event that Streem initialization fails
    }

    public func currentUserDidChange(user: StreemUser?) {
        // as necessary, update your stored and/or displayed `user.name` and `user.id`
    }
```

Next, once the user has logged into your app, inform Streem that they are logged in:

```swift
    Streem.sharedInstance.identify(
        userId: "john", 
        name: "John Smith", 
        avatarUrl: "http://..."
        ) { success in
            if success {
                // dismiss login screen, etc.
            } else {
                // present alert, etc.
            }
        }
```


### Starting a Remote Streem

Through some mechanism in your app, you determine that two users should be streeming.

To make a call to user "tom", do the following:

```swift
    Streem.sharedInstance.startRemoteStreem(
        asRole: .LOCAL_CUSTOMER,
        withRemoteUserId: "tom") { success in
            if !success {
                // present alert, etc.
                }
    }
```

If CallKit has been set up correctly, Tom's device will ring like a phone call, and once answered, both phones will be connected on Streem.


### Starting a Local Streem

A Local Streem uses the device's camera, and opens up an AR experience with our arrow and measure tools, and the ability to capture streemshots.  Open a Local Streem simply by:

```swift
    Streem.sharedInstance.startLocalStreem() { success in
        if !success {
            // present alert, etc.
        }
    }
```


## Future Features

* [ ] Customizable UI
* [ ] Lifecycle Callbacks
* [ ] Custom Tools

Please submit any other requests, and we'll evaluate and add to this list. 
