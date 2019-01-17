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
| AR Remote Streem                                  | ✅ 				|                   |
| AR Onsite Streem                                  | ✅ 				|                   |
| AR Arrow Tool                                     | ✅ 				|                   |
| Remote Streemshot                                 | ✅ 				| ✅                |
| Onsite Streemshot                           	    | ✅ 				| ✅                |
| Streemshot Measure tool                           | ✅					|                   |
| Onsite Recording                           	    | ✅ 				|                   |
| Remote Recording                                  | ✅ 				|                   |


### Account/App Setup

* Obtain your `account_id` from Streem
* Provide your IOS bundle id for any apps you are going to use the Streem SDK in (later you will be able to do this from a self-service portal)
* Streem will provide you with an `appId` and `appSecret` for each of your IOS apps
* If you are going to use CallKit (recommended), refer to the [CallKit Setup Instructions](docs/callkit.md) now that you have your App IDs

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

If you are using CallKit, you should also initialize `StreemCalls`, so that you can make and receive phone calls:

```swift
    Streem.initialize(delegate: self, appId: "APP_ID", appSecret: "APP_SECRET") {
        StreemCalls.initialize()
    }
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

Through some mechanism in your app, you determine what two users should be streeming.

To make a call to user "tom", do the following:

```swift
    let user = StreemUser(name: "Tom Smith", id: "tom")
    Streem.sharedInstance.startCustomerStreem(withPro: user) { success in
        if !success {
            // present alert, etc.
        }
    }
```

If CallKit has been setup, this will make a phone call to Tom's device.


### Joining a Remote Streem (non-CallKit)

From the remote device, when the call is ready to be answered, you can join the streem with the following:

```swift
    let remoteUser = StreemUser(name: userName, id: userId)
    Streem.sharedInstance.startRemoteStreem(
        fromCustomer: remoteUser,
        roomId: roomId,
        fromInvitationId: invitationId) { success in
        if !success {
            // present alert, etc.
        }
    }
```

Note that this part is not needed if using `StreemCalls`, as this is done for you using CallKit integration.


### Starting an Onsite Streem

Similar to starting a remote Streem, but no need to specify a remote user:

```swift
    Streem.sharedInstance.startOnsiteStreem() { success in
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
