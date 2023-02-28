// Copyright © 2021 Streem, Inc. All rights reserved.

import StreemGuidedScanKit
import SceneKit

/// Guided Scan Customizations - this performs a set of really NOTICEABLE (e.g., not pretty)
/// color and other customizations to demonstrate the customization/themeing API.
/// TO use, simply call `GuidedScanCustomizations.performCustomizationSetup()` before invoking any GuidedScanKit presentation apis.
struct GuidedScanCustomizations {

    static func performCustomizationSetup() {
        let guidedScanThemeConfig =
        GuidedScanThemeConfig(
            customColorConfig: generateCustomColors(),
            captureAsset: generateCaptureAsset(),
            getCloserAsset: generateGetCloserAsset(),
            customAnimationConfig: generateCustomAnimation(),
            customImageConfig: generateCustomImageConfig(),
            customButtonStyleConfig: generateCustomButtonStyle(),
            customAdditionalFloorLayoutButtons: generateAdditionalButtons(),
            isSharingEnabled: true,
            customInstructionAnimationsConfig: generateCustomInstructionAnimationsConfig(),
            customGeneratingFloorplanAnimationsConfig: generateCustomGeneratingFloorplanAnimationsConfig())

        StreemGuidedScan.shared.guidedScanThemeConfig = guidedScanThemeConfig
    }

    static private func generateCustomColors() -> CustomColorConfig {

        let navigationBarBackgroundColor = UIColor.brown
        let navigationBarColors = CustomColorConfig.NavigationBarColors(background: navigationBarBackgroundColor,
                                                                        titleText: .white,
                                                                        primaryAction: .yellow,
                                                                        positiveAction: .yellow,
                                                                        negativeAction: .purple,
                                                                        buttonBackground: .black,
                                                                        buttonForeground: navigationBarBackgroundColor)
        return CustomColorConfig(
            primaryText: .purple, secondaryText: .createDarkModeCompatibleColor(with: .green, and: .blue),
            primaryAction: .cyan, positiveAction: .systemPink, negativeAction: .brown, navigationBar: navigationBarColors)
    }

    static private func generateCaptureAsset() -> CaptureAsset {
        let animationHandler: (CaptureStatus) -> SCNAction? = { status in
            switch status {
            case .readyToCapture:
                var combinedActions: [SCNAction] = []
                if let defaultAction = CaptureAsset.defaults.animationHandler(status) {
                    combinedActions.append(defaultAction)
                }

                let spinAction = SCNAction.repeatForever(
                    SCNAction.rotate(by: .pi, around: .init(x: 0, y: 1, z: 0), duration: 5))
                combinedActions.append(spinAction)

                return SCNAction.sequence(combinedActions)
            default:
                return CaptureAsset.defaults.animationHandler(status)
            }
        }

        return CaptureAsset(
            icon: UIImage(named: "faucet-icon"),
            url: Bundle.main.url(forResource: "faucet1-small", withExtension: "usdz"),
            animationHandler: animationHandler)
    }

    static private func generateAdditionalButtons() -> [CustomButtonConfig] {
        var buttons: [CustomButtonConfig] = []
        let customColors = generateCustomColors()

        buttons.append(
            CustomButtonConfig(
                viewConfig: CustomButtonConfig.CustomButtonViewConfig(title: "Oops",
                                                                      padding: 16,
                                                                      buttonStyle: CustomButtonStyleConfig(titleFont: UIFont.boldSystemFont(ofSize: 12),
                                                                                                           cornerRadius: 20),
                                                                      colorConfig: customColors,
                                                                      action: {
                                                                          print("Oops")
                                                                      }),
                colorConfig: customColors,
                drawerVisibility: .always,
                buttonVisibility: .always
            )
        )

        buttons.append(
            CustomButtonConfig(
                viewConfig: CustomButtonConfig.CustomButtonViewConfig(
                    title: "Testing",
                    padding: 8,
                    buttonStyle: CustomButtonStyleConfig(titleFont: UIFont.boldSystemFont(ofSize: 14),
                                                         cornerRadius: 12),
                    colorConfig: customColors,
                    action: {
                        print("Testing")
                    }),
                colorConfig: customColors,
                drawerVisibility: .always,
                buttonVisibility: .fromScanList)
        )

        buttons.append(
            CustomButtonConfig(
                viewConfig: CustomButtonConfig.CustomButtonViewConfig(
                    title: "1,2,3",
                    padding: 20,
                    buttonStyle: CustomButtonStyleConfig(titleFont: UIFont.boldSystemFont(ofSize: 20),
                                                         cornerRadius: 24),
                    colorConfig: customColors,
                    action: {
                        print("1,2,3")
                    }
                ),
                colorConfig: customColors
            )
        )

        return buttons
    }

    static private func generateGetCloserAsset() -> CaptureAsset {
        CaptureAsset(icon: nil, url: Bundle.main.url(forResource: "faucet1-small", withExtension: "usdz"), animationHandler: { status in
            switch status {
            case .readyToCapture:
                var combinedActions: [SCNAction] = []
                if let defaultAction = CaptureAsset.defaults.animationHandler(status) {
                    combinedActions.append(defaultAction)
                }

                let spinAction = SCNAction.repeatForever(
                    SCNAction.rotate(by: .pi, around: .init(x: 0, y: 1, z: 0), duration: 5))
                combinedActions.append(spinAction)

                return SCNAction.sequence(combinedActions)
            default:
                return CaptureAsset.defaults.animationHandler(status)
            }
        })
    }

    static private func generateCustomAnimation() -> CustomAnimationConfig {
        return CustomAnimationConfig(with: "light-mode-test", darkModeName: "dark-mode-test", and: Bundle.main)
    }

    static private func generateCustomButtonStyle() -> CustomButtonStyleConfig {
        return CustomButtonStyleConfig(titleFont: UIFont.boldSystemFont(ofSize: 34), cornerRadius: 2)
    }

    static private func generateCustomImageConfig() -> CustomImageConfig {
        CustomImageConfig(meshIcon: UIImage(named: "test-mesh-icon"), layoutEstimationIcon: UIImage(named: "test-layout-icon"))
    }

    static private func generateCustomInstructionAnimationsConfig() -> CustomScanInstructionAnimationsConfig {
        // Two free animations found on lottiefiles.com - we're using the disc animation for light mode, the boxes for dark
        let placeholderAnimation = CustomAnimationConfig(with: "loading-disc", darkModeName: "loading-boxes", and: Bundle.main)
        return CustomScanInstructionAnimationsConfig(introduction: nil, step1: placeholderAnimation, step2: placeholderAnimation, step3: placeholderAnimation, step4: placeholderAnimation)
    }

    static private func generateCustomGeneratingFloorplanAnimationsConfig() -> CustomGeneratingFloorplanAnimationsConfig {
        // Two free animations found on lottiefiles.com - we're using the disc animation for light mode, the boxes for dark
        let placeholderAnimation = CustomAnimationConfig(with: "loading-disc", darkModeName: "loading-boxes", and: Bundle.main)
        let backgroundImage = UIImage(named: "wireframe-duck", in: Bundle.main, with: nil)
        return CustomGeneratingFloorplanAnimationsConfig(step1: placeholderAnimation,
                                                         step1Background: backgroundImage,
                                                         step2: placeholderAnimation,
                                                         step2Background: backgroundImage,
                                                         step3: placeholderAnimation,
                                                         step3Background: backgroundImage,
                                                         step4: placeholderAnimation,
                                                         step4Background: backgroundImage,
                                                         step5: placeholderAnimation,
                                                         step5Background: backgroundImage)
    }

}
