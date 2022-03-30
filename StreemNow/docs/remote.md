&nbsp; &nbsp; &nbsp; &nbsp;
[< User Authentication](authenticating.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Starting a Local Streem >](local.md)

## Starting a Remote Streem

Through some mechanism in your app, you determine that your logged-in user and another user should start a Streem call.

To make a call to user "tom" (see below on how to retrieve a remote user's id), do the following:

```swift
    let remoteUser = StreemRemoteUser(role: .REMOTE_PRO, streemUserId: "tom")

    Streem.sharedInstance.startRemoteStreemWithUser(
        remoteUser: remoteUser,
        localRole: .LOCAL_CUSTOMER
    ) { result in
        if case .failure(let error) = result {
            // present alert, etc.
        }
    }
```

If CallKit has been set up correctly, Tom's device will ring like a phone call, and once answered, both phones will be connected on Streem.

Note: Due to an issue with ARKit, you cannot start a remote Streem call from a view using the camera. See  [https://developer.apple.com/forums/thread/677731](https://developer.apple.com/forums/thread/677731)

### Roles

Roles dictate which side of the Streem call you're on: whether you are providing or receiving the video feed. They also affect which tools are available to you. The different roles are:

* `LOCAL_CUSTOMER`: The Customer in a two-way Streem call
* `ONSITE_CUSTOMER`: The Customer in an Onsite (one-way) Streem call
* `REMOTE_PRO`: The Expert in a two-way Streem call
* `ONSITE_PRO`: The Expert in an Onsite (one-way) Streem call

In general, when starting a remote Streem call you will want the `LOCAL_CUSTOMER` role.

### Getting Remote User IDs

In order to start a Streem call with a remote user, your app will need to supply that user's `remoteUserId`. There are two mechanisms available in StreemKit for retrieving a `remoteUserId`:
* Choose from a list of recently logged-in users.
* Respond to an invitation.

In addition to these two approaches, you can maintain your own list of `remoteUserIds` and supply them to your app however you choose.

#### Choose from a list of recently logged-in users.

_This approach can be helpful during app development. It is not intended for use in production._

By calling StreemKit's `getRecentlyIdentifiedUsers` method on `Streem.sharedInstance` you will receive a list of recently logged-in users for your company, optionally filtered to only Experts. In the method's closure you then choose the desired remote user and start the Streem call.

```swift
    Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
        guard let self = self else { return }

        // Select the user you wish to call

        let remoteUser = StreemRemoteUser(role: .REMOTE_PRO, streemUserId: selectedUser.id)

        Streem.sharedInstance.startRemoteStreemWithUser(
            remoteUser: remoteUser,
            localRole: .LOCAL_CUSTOMER) { result in
                // handle result of Streem call
        }
```

#### Respond to an invitation

Having received an invitation code from an Expert, follow the steps shown [here](authenticating.md#invitation-flow) to log in, identify, and start the Streem call.

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< User Authentication](authenticating.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Starting a Local Streem >](local.md)
