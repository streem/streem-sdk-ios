&nbsp; &nbsp; &nbsp; &nbsp;
[< The Post-Call Experience](post-call.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)

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

If running the camera on a non-AR device (i.e., iPhone 6 or earlier), our laser and draw tools do not properly render on the screen.

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< The Post-Call Experience](post-call.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
