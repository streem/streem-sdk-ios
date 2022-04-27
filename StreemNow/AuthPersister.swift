// Copyright © 2020 Streem, Inc. All rights reserved.

import Foundation
import AppAuth

class AuthPersister {

    static let persistedAccountKey = "StreemNow"
    static let persistedServiceKey = "PersistedAuth"
    
    static func clearAuth() {
        let item = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: persistedAccountKey,
            kSecAttrService as String: persistedServiceKey,
        ] as CFDictionary
        
        let status = SecItemDelete(item)
        
        if status == errSecSuccess {
            print("Cleared persistent authState from keychain")
        } else if status == errSecItemNotFound {
            print("No persisted authState to clear from keychain")
        } else {
            print("Unable to clear persisted authState; keychain error: \(status)")
        }
    }
    
    static func persist(authState: OIDAuthState) {
        let archivedAuthState = NSKeyedArchiver.archivedData(withRootObject: authState)
        
        let item = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: persistedAccountKey,
            kSecAttrService as String: persistedServiceKey,
            kSecValueData: archivedAuthState
        ] as CFDictionary
        
        clearAuth()
        
        let status = SecItemAdd(item, nil)
        
        if status == errSecSuccess {
            print("Persisted authState to keychain")
        } else {
            print("Unable to persist authState to keychain")
        }
    }
    
    static func retrieveAuth() -> OIDAuthState? {
        let item = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: persistedAccountKey,
            kSecAttrService as String: persistedServiceKey,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(item, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let authState = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? OIDAuthState
        else {
            if status == errSecItemNotFound {
                print("No persisted authState to retrieve from keychain")
            } else if status !=  errSecSuccess{
                print("Unable to retrieve persisted authState; keychain error: \(status)")
            } else {
                print("Unable to deserialize persisted authState")
            }
            return nil
        }
        
        print("Retrieved authState from keychain")
        return authState
    }
    
}
