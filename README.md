# streem-now-ios
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
| API Access (GET /streems)                         | ❌ 				|                   |
| AR Remote Streem                                  | ✅ 				|                   |
| AR Onsite Streem                                  | ✅ 				|                   |
| AR Arrow Tool                                     | ✅ 				|                   |
| Remote Streemshot                                 | ✅ 				|                   |
| Onsite Streemshot                           	    | ✅ 				|                   |
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
    pod 'StreemCalls'  // For CallKit, requires IOS 10+
```

Then simply import the frameworks where they are used:

```swift
    import Streem
    import StreemCalls
```


### Logging In

Before identifying the currently logged in user, initialize the SDK with your App ID and secret:

```swift
    Streem.initialize(appId: "APP_ID", appSecret: "APP_SECRET")
```

If you are using CallKit, you should also initialize `StreemCalls` as well, so that you can make and receive phone calls:

```swift
    StreemCalls.initialize()
```

Next, once the user has logged into your app, inform Streem that they are logged in:

```swift
    Streem.identify(
        userId: "john", 
        name: "John Smith", 
        avatarUrl: "http://..."
    )
```


### Starting a Remote Streem

Through some mechanism in your app, you determine what two users should be streeming.

To make a call to user "tom", do the following:

```swift
   let state = StreemStateBuilder()
        .with(myRole: .LOCAL_CUSTOMER)
        .with(remoteUserId: "tom", andRole: .REMOTE_PRO)
        .build()

    Streem.openStreem(state)
```

If CallKit has been setup, this will make a phone call to Tom's device.


### Joining a Remote Streem (non-CallKit)

From the remote device, when the call is ready to be answered, you can join the streem with the following:

```swift
    let state = StreemStateBuilder()
        .with(myRole: .REMOTE_PRO)
        .with(remoteUserId: fromUserId, andRole: .LOCAL_CUSTOMER)
        .joining(streemId: streemId, fromCallId: callId)
        .build()

    Streem.openStreem(state)
```

Note that this part is not needed if using `StreemCalls`, as this is done for you using CallKit integration.


### Starting an Onsite Streem

Similar to starting a remote Streem, but don't specify a remote user, and use the LOCAL_PRO role

```swift
    let state = StreemStateBuilder()
	    .with(myRole: .LOCAL_PRO)
	    .build()

    Streem.openStreem(state)
```


## Future Features

* [ ] Customizable UI
* [ ] Lifecycle Callbacks
* [ ] Custom Tools

Please submit any other requests, and we'll evaluate and add to this list. 
