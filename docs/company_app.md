&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Integrating StreemKit >](integrating.md)

## Company/App Setup

* Obtain your `company_id` from Streem
* Provide your iOS Bundle ID for any apps you are going to use StreemKit in, along with the corresponding environment -- e.g., `sandbox` or `prod-us`.
* Streem will provide you with an `appId`  for each of your iOS apps -- e.g. you'll need one each for development and release, if you use different Bundle IDs.
* Now that you have your App IDs, follow the steps in the [CallKit Setup Instructions](docs/callkit.md)
* StreemKit expects to be called from a ViewController within a NavigationController, in which it will present its own ViewController.

### Note on Universal Links

If you would like to use universal links to handle Streem **invitation links**, there is some additional setup required:

* You will need to coordinate with Streem to have your app's Bundle ID added to our `apple-app-site-association` file.

* You will then need to add the Associated Domains entitlement to your app with the following domains (replacing `<company_id>` with your own `company_id`):

  - `<company_id>.swac.prod-us.streem.cloud`
  - `<company_id>.cv.prod-us.streem.cloud`
  - `<company_id>.streem.me`
  - `<company_id>.streem.us`
  - and, if you will develop/test using the `sandbox` environment:
    - `<company_id>.swac.sandbox.streem.cloud`
    - `<company_id>.cv.sandbox.streem.cloud`

* For more details on adding this entitlement please see the "Add the Associated Domains Entitlement to Your App" section of this resource: https://developer.apple.com/documentation/safariservices/supporting_associated_domains.

### Server-Side SDKs

If you are embedding StreemKit into an app that already has authentication, you will want to implement one of the following server-side SDKs to return a `StreemToken` along with your normal auth flow.  Your app will then use that token to authenticate with the Streem servers.

- [https://github.com/streem/streem-sdk-go](https://github.com/streem/streem-sdk-go)
- [https://github.com/streem/streem-sdk-node](https://github.com/streem/streem-sdk-node)
- [https://github.com/streem/streem-sdk-ruby](https://github.com/streem/streem-sdk-ruby)

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Integrating StreemKit >](integrating.md)
s
