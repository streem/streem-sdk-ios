//
//  StreemSessionObservablesSpec.swift
//  StreemNow_Tests
//
//  Created by Sean Adkinson on 8/13/18.
//  Copyright © 2018 Streem, Inc. All rights reserved.
//

import XCTest

import Quick
import Nimble
import RxSwift
@testable import Streem
@testable import StreemShared

class StreemSessionObservablesSpec: QuickSpec {

    override func spec() {
        describe("StreemSessionObservables.callStatusChanges") {
            it("fires when a call status changes") {

                let callUuid = UUID()
                let account = Account(id: 1, code: "test", name: "Test")
                let user1 = User(accountId: account.id, userId: "user1", email: "user@one.com", name: "User One", avatarUrl: nil)
                let user2 = User(accountId: account.id, userId: "user2", email: "user@two.com", name: "User Two", avatarUrl: nil)
                let streem = StreemInstance(id: 1, accountId: account.id, uuid: UUID(), createdByUserId: user1.userId)
                let call = StreemCall(id: 1, streemId: streem.id, accountId: account.id, uuid: callUuid, status: .pending, fromUserId: user1.userId, fromDeviceId: "abc-123", toUserId: user2.userId, toDeviceId: "def-456")

                let callData = StreemCallData(streem: streem, call: call, fromUser: user1, toUser: user2)

                waitUntil(timeout: 3) { done in
                    let disposeBag = DisposeBag()

                    StreemSessionObservables.callStatusChanges
                        .skip(1)
                        .take(1)
                        .subscribe(onNext: { callData in
                            expect(callData.call.status) == .answered
                            done()
                        })
                        .disposed(by: disposeBag)

                    // First call, pending status
                    StreemSession.shared.currentCalls.onNext([callData])

                    // Update call to answered status
                    let updatedCall = StreemCall(id: call.id, streemId: call.streemId, accountId: call.accountId, uuid: call.uuid, status: .answered, fromUserId: call.fromUserId, fromDeviceId: call.fromDeviceId, toUserId: call.toUserId, toDeviceId: call.toDeviceId)

                    // Send the updated call data through
                    let updatedCallData = StreemCallData(streem: streem, call: updatedCall, fromUser: user1, toUser: user2)
                    StreemSession.shared.currentCalls.onNext([updatedCallData])
                }
            }
        }
    }

}
