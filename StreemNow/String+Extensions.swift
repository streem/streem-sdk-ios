// Copyright © 2021 Streem, Inc. All rights reserved.

import Foundation

extension String {
    func formattedAsInvitationCode() -> String {
        var code = self
        var sections: [String] = []
        while !code.isEmpty {
            sections.append(String(code.prefix(3)))
            code.removeFirst(min(3, code.count))
        }
        
        return sections.joined(separator: "-")
    }
}
