&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Integrating StreemKit >](integrating.md)

## Company/App Setup

* Obtain your `company_code` from Streem
* Provide your iOS Bundle ID for any apps you are going to use StreemKit in, along with the corresponding environment -- e.g., `sandbox`, `prod` or `prod-us`.
* Streem will provide you with an `appId`  for each of your iOS apps -- e.g. you'll need one each for development and release, if you use different Bundle IDs.
* Now that you have your App IDs, follow the steps in the [CallKit Setup Instructions](docs/callkit.md)
* StreemKit expects to be called from a ViewController within a NavigationController, in which it will present its own ViewController.

### Note on Universal Links

If you would like to use universal links to handle Streem **invitation links**, there is some additional setup required:

* You will need to coordinate with Streem to have your app's Bundle ID added to our `apple-app-site-association` file.

* You will then need to add the Associated Domains entitlement to your app with the following domains (replacing `<company_code>` with your own `company_code`):

  - `<company_code>.cv.prod.streem.cloud`
  - `<company_code>.streem.us`
  - and, if you will develop/test using the `sandbox` environment:
    - `<company_code>.cv.sandbox.streem.cloud`

* For more details on adding this entitlement please see the "Add the Associated Domains Entitlement to Your App" section of this resource: https://developer.apple.com/documentation/safariservices/supporting_associated_domains.

### Server-Side SDKs

If you are embedding StreemKit into an app that already has authentication, you will want to implement one of the following server-side SDKs to return a `StreemToken` along with your normal auth flow.  Your app will then use that token to authenticate with the Streem servers.

- [https://github.com/streem/streem-sdk-go](https://github.com/streem/streem-sdk-go)
- [https://github.com/streem/streem-sdk-node](https://github.com/streem/streem-sdk-node)
- [https://github.com/streem/streem-sdk-ruby](https://github.com/streem/streem-sdk-ruby)

### Parse Universal Links

To parse the app universal links, use the following method: `Streem.parseUniversalLink(incomingURL: )` in `AppDelegate`.

```
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL
        else {
            // handle invalid link
            return false
        }

        guard let linkType = Streem.parseUniversalLink(incomingURL: incomingURL) else {
            // handle invalid link
            return false
        }

        // handle valid link
        return false
    }
```

StreemKit recognizes 3 types of links shown below:

```
    public enum StreemLinkType {
        case callLogEntry(companyCode: String, callLogId: String)
        case sharedCallLogEntry(companyCode: String, token: String, callLogId: String)
        case invitation(companyCode: String, invitationCode: String)
    }
```

* The `invitation` link is the link the customer uses to start a call with the expert. Refer to [User Authentication via Invitation](../authenticating.md) for more details.
* The `sharedCallLogEntry` link is the link the expert uses to share the call-log-entry-details with someone with a ready-only access.
* The `callLogEntry` link is a link to a specific call-log-entry in the expert side.

After parsing the link, `parseUniversalLink(incomingURL: )` will return one of with the types above if the link is valid and it could be handled as needed.

```
    switch linkType {
    case .callLogEntry(companyCode: let companyCode, callLogId: let callLogId):
        // handle the callLogEntry link
    case .invitation(companyCode: let companyCode, invitationCode: let invitationCode):
        // handle the invitation link
    case .sharedCallLogEntry(companyCode: let companyCode, token: let token, callLogId: let callLogId):
        // handle the shared link
    default:
        // handle invalid link
    }
```

These are examples of `.callLogEntry`, `.invitation`, and `.sharedCallLogEntry` links respectively:

* https://company-code.streempro.app/mycalls/rm_5VWaUGNnAo6RI9hg8mTaB7
* https://company-code.streem.us/i/728997568
* https://company-code.streempro.app/share/api_61lWyqxvXiIoAKVzmp6k8/details/rm_62yXOL31mzf4okYRHlI5Cz

* Note: to avoid crashes, make sure you handle the link in the completion handler of `Streem.initialize` to make sure the instance is initialized before you use other SDK methods.

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Integrating StreemKit >](integrating.md)
