&nbsp; &nbsp; &nbsp; &nbsp;
[< Integrating StreemKit](integrating.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Starting a Remote Streem >](remote.md)

## User Authentication, via Log-in or Invitation

Users must authenticate their identity with Streem's server prior to starting a Streem call or accessing the post-call experience.

User authentication is a three-step process:

* Obtain a **Streem Token** representing the user. The ways your app can do this are discussed below.

* Include that **Streem Token** in a **`StreemIdentity`** struct.

* Pass that **`StreemIdentity`** struct to StreemKit via the `identify(with identity:)` API.

Users can obtain a **Streem Token** by logging in. Alternatively, they can bypass explicitly logging in by accepting an **invitation** to a two-person Streem call.

### Invitations

An Expert can use Streem's website or mobile apps to create an **invitation** for a specific Customer.

An invitation is represented by a 9-digit code, which can be transmitted to the Customer through SMS, email, or any other mechanism. Your app should allow a user to manually enter the code; in addition, your app can register for [universal links](company_app.md#note-on-universal-links) so that it will respond to a user tapping an invitation link received via SMS or email.

Once your app has an invitation code, make these three calls:

* `login(with invitationCode:)` to obtain a **`StreemIdentity`** struct and retrieve the invitation details;

* `identify(with identity:)` to identify the user to Streem;

* `startRemoteStreemWithUser()` to start the Streem call.

The whole flow looks like:

```swift
    Streem.sharedInstance.login(with: invitationCode) { error, details, identity in
        guard error == nil, let details = details, let identity = identity else {
            // the invitation code was invalid
            return
        }

        Streem.sharedInstance.identify(with: identity) { success in
            guard success else {
                // identity was not correct
                return
            }

            let remoteUser = StreemRemoteUser(role: .REMOTE_PRO, streemUserId: details.user.uid)

            Streem.sharedInstance.startRemoteStreemWithUser(
                remoteUser: remoteUser,
                referenceId: details.referenceId,
                localRole: .LOCAL_CUSTOMER
            ) { result in
                switch result {
                case .failure(let error):
                    // handle Streem call error
                case .success(_):
                    // handle Streem call success
                }
            }
        }
    }
```

### Logging In

If your app already performs its own authentication, logging into Streem is straightforward.

Otherwise -- particularly when you are just starting to integrate StreemKit and have not yet made any changes to your servers -- Streem's own servers support authentication via [**OpenID**](https://openid.net/what-is-openid/).

#### App-based Authentication

If you are embedding StreemKit inside an app that already implements user authentication, then along with your normal authentication flow your server will use one of our [Server Side SDK's](company_app.md#server-side-sdks) to obtain a **Streem Token**.

Your app will also need the ability to ask your server to *refresh* an expired **Streem Token**.

```swift
let streemToken = yourServer.fetchStreemToken()

let streemIdentity = StreemIdentity(token: streemToken,
                                    name: userName,
                                    avatarUrl: optionalUrlToUserAvatarImage,
                                    isExpert: isUserAnExpert,
                                    tokenRefresher:  { didObtainFreshStreemToken in
                                        // StreemKit will call this closure whenever the
                                        // StreemToken expires.

                                        yourServer.refreshStreemToken() { newStreemToken in
                                            didObtainFreshStreemToken(newStreemToken)
                                        }
                                    })

Streem.sharedInstance.identify(with: streemIdentity) { success in
    if success {
        // you have successfully logged in!
    }
}
```

#### OpenID Login

While you are just starting to integrate StreemKit into your app, your server may not be ready to communicate with Streem's servers to obtain and refresh **Streem Tokens**. In this situation your app can instead communicate directly with Streem's servers via [**OpenID**](https://openid.net/what-is-openid/).

Our sample app, `StreemNow`, follows this approach. It uses the [**AppAuth**](https://appauth.io) library to handle the OpenID work; we have wrapped the relevant calls to AppAuth in a class named `OpenIDHelper`.

StreemKit's `getOpenIdConfiguration(forCompanyCode: companyCode)` API provides your app with the endpoints necessary for OpenID sign-on.

```swift
Streem.sharedInstance.getOpenIdConfiguration(forCompanyCode: companyCode) {
    [weak self] error, clientId, tokenEndpoint, authorizationEndpoint, logoutEndpoint in

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

Internally, `loginViaOpenId(…)` takes the **Access Token** obtained via OpenID and passes it to StreemKit in order to fetch a **Streem Token**:

```swift
Streem.sharedInstance.streemToken(forAccessToken: accessToken) { error, streemToken in
    guard error == nil, let streemToken = streemToken else {
        // error exchanging Access Token for Streem Token
        return
    }

    // return a StreemIdentity struct containing streemToken, userName, etc.
}
```

Please refer to [our sample code](https://github.com/streem/streem-sdk-ios) for more details.

### Logging Out

Regardless of the method used to authenticate the user, when your app wishes to log the user out of Streem it should call:

```swift
    Streem.sharedInstance.logout()
```

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< Integrating StreemKit](integrating.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Starting a Remote Streem >](remote.md)
