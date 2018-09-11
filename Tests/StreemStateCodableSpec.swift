//
//  StreemStateCodableSpec.swift
//  StreemNow_Tests
//
//  Created by Sean Adkinson on 7/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import Streem
@testable import StreemShared

class StreemStateCodableSpec: QuickSpec {
    
    override func spec() {
        describe("StreemStateCodable") {

            describe("Encoder") {
                it("can do simple top level encoding") {
                    let state = StreemState(streemId: 123)
                    let data = try! JSONEncoder().encode(state)
                    let json = String(data: data, encoding: .utf8)
                    expect(json) == "{\"participants\":{},\"streemId\":123}"
                }
            }

            describe("Decoder") {
                it("can do simple top level decoding") {
                    let json = Data("{\"streemId\":123,\"participants\":{}}".utf8)
                    let state = try! JSONDecoder().decode(StreemState.self, from: json)
                    expect(state.streemId) == 123
                }

                it("requires empty participants array unfortunately") {
                    let json = Data("{\"id\":\"abc123\"}".utf8)

                    expect {
                        try JSONDecoder().decode(StreemState.self, from: json)
                    }.to(throwError { (error: DecodingError) in
                        if case .keyNotFound(let key, _) = error {
                            expect(key.stringValue) == "participants"
                        } else {
                            fail("Not DecodingError.keyNotFound")
                        }
                    })
                }

                it("can decode an account") {
                    let json = Data("{\"id\":1,\"code\":\"adkinson\",\"name\":\"Adkinson\"}".utf8)
                    let account = try! JSONDecoder().decode(Account.self, from: json)
                    expect(account.id) == 1
                }
            }

        }
    }

}
