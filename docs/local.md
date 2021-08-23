&nbsp; &nbsp; &nbsp; &nbsp;
[< Starting a Remote Streem](remote.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Post-Call Experience >](post-call.md)

## Starting a Local Streem call

A local Streem call uses the device's camera to launch a one-person AR experience that includes StreemKit's arrow and measure tools, and the ability to capture Streemshots.  Open a local Streem call simply by:

```swift
    Streem.sharedInstance.startLocalStreem() { success in
        if !success {
            // present alert, etc.
        }
    }
```

Note: Due to an issue with ARKit, you cannot start a local Streem call from a view using the camera. See  [https://developer.apple.com/forums/thread/677731](https://developer.apple.com/forums/thread/677731)

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< Starting a Remote Streem](remote.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Post-Call Experience >](post-call.md)
