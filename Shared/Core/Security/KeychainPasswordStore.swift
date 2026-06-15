//
//  KeychainPasswordStore.swift
//  TheLightUI
//

import Foundation
import Security

protocol PasswordStoring {
    func loadPassword(for account: String) -> String
    func savePassword(_ password: String, for account: String)
    func deletePassword(for account: String)
}

struct KeychainPasswordStore: PasswordStoring {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "TheLightUI") {
        self.service = service
    }

    func loadPassword(for account: String) -> String {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func savePassword(_ password: String, for account: String) {
        guard !password.isEmpty else {
            deletePassword(for: account)
            return
        }

        let data = Data(password.utf8)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery(for: account) as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            var query = baseQuery(for: account)
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func deletePassword(for account: String) {
        SecItemDelete(baseQuery(for: account) as CFDictionary)
    }

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
