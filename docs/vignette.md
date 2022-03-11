&nbsp; &nbsp; &nbsp; &nbsp;
[< The Post-Call Experience](post-call.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Known Issues >](known_issues.md)

## Integrating the Virtual Shopping Experience (or Vignette) into your app

The Virtual Shopping Experience is a single-party journey where the user enters a virtual 3D scene to explore items they may wish to purchase. For example, a user might want to browse through various models of refrigerator, learning about their different features while seeing how they look in a virtual kitchen.

Core to the Virtual Shopping Experience are __vignettes__. A vignette is a data structure that stores all of the information needed to construct one of these virtual scenes. It comprises many layers, from which various levels of detail about the scene can be brought to life.

### Structures used within the vignette

More detailed documentation of these structures can be found in the [documentation for creating a `vignette.json` file](LINK-NEEDED-HERE). Here's a high-level description:

- __Vignette__: The virtual scene and its potential virtual elements (e.g., a kitchen with many appliances)
- __Scene__: The 3D "background" for the vignette, along with its associated metadata (e.g., a kitchen itself -- without appliances)
- __Slot__: A space in the vignette where an element can exist (e.g., a refrigerator-sized space between cabinets)
- __Element__: A specific element that can exist in a particular slot (e.g., a specific model of refrigerator)
- __Finish__: A subcatagory of an element (e.g., the red or black version of a specific model of refrigerator)
- __State__: A runtime-adjustable state in which an element can exist (e.g., open or closed)
- __Catalog Item__: A 3D model asset which can be rendered in the vignette (e.g., a 3D model of a specific refrigerator with a specific finish)
- __Hotspots__: Small icons which can be tapped to perform different actions:
    - __Portal Hotspot__: A way for users to navigate about the scene. When tapped, the user is taken to the portal's associated camera pose.
        + `Scene portals` are typically located on the floor. They are stored in the vignette's `scene`.
        + `Slot portals` are stored in individual `elements`. They provide a closer look at a part of the element.
        + The `initial portal` represents the user's initial view of the vignette.
    - __Modal Hotspot__: A way to provide additional information about a specific part of an element. When tapped, a modal dialog will appear on the screen, providing additional details (text) with an optional photo or video.
- __Hotspot Group__: The way hotspots in elements are stored. In addition to containing multiple hotspots, a hotspot group contains a `focal point` which must be in the user's field-of-view in order for the group's hotspots to be visible.

To start a vignette, you'll need a `vignette.json` file -- either shipped with your app or downloadable on demand -- which contains all of this data.

### StreemVirtualShopping and StreemVirtualShoppingDelegate

`StreemVirtualShopping` and `StreemVirtualShoppingDelegate` are the classes you use to interact with the vignette. Before starting any vignette, make sure you've set `StreemVirtualShopping.shared.delegate` to your implementation of `StreemVirtualShoppingDelegate`.

### Starting a vignette

Once you've [authenticated a user and called `Streem.sharedInstance.identify()`](authenticating.md), you are ready to begin a vignette:
```swift
    // The vignettte's URL can indicate either a local or a downloadable file.
    guard let vignetteUrl = Bundle.main.url(forResource: "my_vignette", withExtension: "json") else {
        print("Unable to load vignette file")
        return
    }

    showLoadingIndicator()

    StreemVirtualShopping.shared.startVignetteExperience(presenter: self, from: vignetteUrl) { result in
        if case .failure(let error) = result {
            presentAlert(message: "Unable to launch the vignette.", error: error)
        } else {
            // success
        }

        hideLoadingIndicator()
    }
```

Once you've started a vignette, there are several user actions that your `StreemVirtualShoppingDelegate` will need to respond to.

### Showing the product details

When a user is looking at a nearby element, the __product details drawer__ will appear at the bottom of the screen. We will ask your `StreemVirtualShoppingDelegate` to provide the appropriate view for the drawer, given the element's `productId` and `finishId`:

```swift
    func viewProductDetails(productId: String, finishId: String?, completion: @escaping (UIView) -> Void) {
        // create your own implementation of a product details view
        let detailsView = MyProductDetailsView(productId: productId, finishId: finishId)
        completion(detailsView)
    }
```

### Presenting the cart

When a user taps on "Cart" in the vignette's menu, the vignette will instantly be dismissed and your `StreemVirtualShoppingDelegate` will be asked to present a cart:

```swift
    func shouldPresentCart() {
        let cartViewController = MyCartViewController()
        cartViewController.modalPresentationStyle = .fullScreen
        self.present(cartViewController, animated: false)
    }
```

At this point the vignette is still in memory, but dismissed from the current view hierarchy. In order to return to the vignette (e.g., when the user taps a `Close` button on your cart), simply call `StreemVirtualShopping.shared.startVignetteExperience()` again with its original parameters.

If your cart allows the user to navigate elsewhere in your app, or to start a different vignette, you may want to free the memory used by the original vignette. To do so, call `StreemVirtualShopping.shared.exitVignette()`. This will return a `Data` object that can later be used to restore the vignette, should the user eventually decide to re-enter it.

To subsequently restore the vignette:

```swift
    StreemVirtualShopping.shared.restoreVignetteFromData(vignetteData, url: vignetteUrl) { _ in
        print("vignette restored from data")
    }
```

where `vignetteData` is the `Data` object you had received from `exitVignette()`.

To avoid the delay of a `Loading…` indicator, we recommend restoring the vignette before the user actually re-enters it. For example, you can restore the vignette when the user returns to the cart, even if they haven't pressed its `Close` button and you don't yet intend for the vignette to appear.

Once the user is then ready to re-enter the experience, call `StreemVirtualShopping.shared.startVignetteExperience()` again, with its original parameters.

### Requesting expert services

If the user taps on the vignette's menu item "Request Expert Services", the vignette will instantly be dismissed and your `StreemVirtualShoppingDelegate` will be asked to present a view controller where the user can request expert services. This will be done through the delegate callback `shouldPresentExpertServices()` and functions exactly the same as `shouldPresentCart()`. See the above [cart documentation](#presenting-the-cart) for details on subsequently restoring the vignette.

### Saving and restoring the experience

If the user leaves your app backgrounded for a long time and iOS terminates the app, you may want to save the vignette for subsequent restoration. If so, make sure to call `StreemVirtualShopping.shared.exitVignette()` in your AppDelegate's `applicationWillResignActive()` and persist the returned `Data` to your app's storage. Then the next time the user opens the app, you can restore the experience by calling:

```swift
    StreemVirtualShopping.shared.restoreVignetteFromData(vignetteData, url: vignetteUrl) { result in
        // handle result
        StreemVirtualShopping.shared.startVignetteExperience(presenter: self, from: vignetteUrl) { result in
            // handle result
        }
    }
```

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< The Post-Call Experience](post-call.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Known Issues >](known_issues.md)
