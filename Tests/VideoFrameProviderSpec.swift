//
//  VideoFrameProviderSpec.swift
//  StreemNow_Tests
//
//  Created by Sean Adkinson on 8/23/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Quick
import Nimble
import RxSwift
import RxCocoa
import CoreMedia
@testable import Streem
@testable import StreemShared
@testable import StreemJob

class VideoFrameProviderSpec: QuickSpec {

    override func spec() {
        describe("VideoFrameProvider") {
            it("render 9:16 portrait video with aspect fill on portrait ipad") {

                // Portrait 720p video rendered on a portrait ipad
                let frameProvider = VideoFrameProvider(
                    videoDimensions: Dimensions.portrait720p,
                    interfaceOrientation: Orientations.portrait,
                    viewSize: Screens.portraitIpad)

                // Fitting a 720x1280 portrait video onto a screen that is 768x1024
                // This means we will crop the top and bottom of the video off the screen,
                // and fill the width.
                //
                // Scale = 768 / 720 = 1.066666667
                // Width = 720 * Scale = 768
                // Height = 1280 * Scale = 1365.33333376
                frameProvider.shouldProduce(
                    expectedSize: CGSize(width: 768, height: 1365.33333376)
                )
            }

            it("renders 16:9 landscape video in center of portrait iphone X") {

                // Landscape 720p video rendered on a portrait iphone X
                let frameProvider = VideoFrameProvider(
                    videoDimensions: Dimensions.landscape720p,
                    interfaceOrientation: Orientations.portrait,
                    viewSize: Screens.portraitIphoneX)

                // Fitting a 1280x720 landscape video onto a screen that is 375x812
                // This means we will pillarbox the top and bottom of the video, and show
                // the landscape video in the center
                //
                // Scale = 375 / 1280 = 0.29296875
                // Width = 1280 * Scale = 375
                // Height = 720 * Scale = 210.9375
                frameProvider.shouldProduce(
                    expectedSize: CGSize(width: 375, height: 210.9375)
                )
            }

            it("renders 9:16 portrait video with aspect fit when ipad is landscape") {

                // Portrait 720p video rendered on a landscape ipad
                let frameProvider = VideoFrameProvider(
                    videoDimensions: Dimensions.portrait720p,
                    interfaceOrientation: Orientations.landscape,
                    viewSize: Screens.landscapeIpad)

                // Fitting a 720x1280 portrait video onto a screen that is 1024x768
                // This means we will pillarbox the left and right of the video, and show
                // the portrait video in the center
                //
                // Scale = 768 / 1280 = 0.6
                // Width = 720 * Scale = 432
                // Height = 1280 * Scale = 768
                // X = (1024 - Width) / 2 = 296
                // Y = 0
                frameProvider.shouldProduce(
                    expectedSize: CGSize(width: 432, height: 768)
                )
            }

            it("renders 16:9 landscape video with aspect fill when iphone X is landscape") {

                // Portrait 720p video rendered on a landscape iphone X
                let frameProvider = VideoFrameProvider(
                    videoDimensions: Dimensions.landscape720p,
                    interfaceOrientation: Orientations.landscape,
                    viewSize: Screens.landscapeIphoneX)

                // Fitting a 1280x720 landscape video onto a screen that is 812x375
                // This means we will crop the top and bottom of the video off the screen,
                // and fill the width
                //
                // Scale = 812 / 1280 = 0.634375
                // Width = 1280 * Scale = 812
                // Height = 720 * Scale = 456.75
                frameProvider.shouldProduce(
                    expectedSize: CGSize(width: 812, height: 456.75)
                )
            }

            it("renders 16:9 landscape video with aspect fill when iPad is landscape") {

                // Portrait 720p video rendered on a landscape ipad
                let frameProvider = VideoFrameProvider(
                    videoDimensions: Dimensions.landscape720p,
                    interfaceOrientation: Orientations.landscape,
                    viewSize: Screens.landscapeIpad)

                // Fitting a 1280x720 landscape video onto a screen that is 1024x768
                // This means we will crop the left and right of the video off the screen,
                // and fill the height
                //
                // Scale = 768 / 720 = 1.066666667
                // Width = 1280 * Scale = 1365.33333376
                // Height = 720 * Scale = 768
                frameProvider.shouldProduce(
                    expectedSize: CGSize(width: 1365.33333376, height: 768)
                )
            }
        }
    }
    
}

extension VideoFrameProvider {
    func shouldProduce(expectedSize: CGSize) {
        waitUntil(timeout: 3) { done in
            let disposeBag = DisposeBag()

            self.videoSize
                .subscribe(onNext: { size in
                    assertSize(size, isRoughly: expectedSize)
                    done()
                })
                .disposed(by: disposeBag)
        }
    }
}

class Dimensions {
    static let portrait720p = Observable.just(CMVideoDimensions(width: 720, height: 1280))
    static let landscape720p = Observable.just(CMVideoDimensions(width: 1280, height: 720))
}

class Orientations {
    static let portrait = Observable.just(UIInterfaceOrientation.portrait)
    static let landscape = Observable.just(UIInterfaceOrientation.landscapeLeft)
}

class Screens {
    static let portraitIpad = Observable.just(CGSize(width: 768, height: 1024))
    static let portraitIphoneX = Observable.just(CGSize(width: 375, height: 812))
    static let landscapeIpad = Observable.just(CGSize(width: 1024, height: 768))
    static let landscapeIphoneX = Observable.just(CGSize(width: 812, height: 375))
}

func assertSize(_ size: CGSize, isRoughly target: CGSize) {
    expect(size.width).to(beCloseTo(target.width, within: 0.1))
    expect(size.height).to(beCloseTo(target.height, within: 0.1))
}
