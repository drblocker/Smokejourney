import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    let userIdKey = "com.smokejourney.userId"
    
    func saveUserIdentifier(_ userId: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey,
            kSecValueData as String: Data(userId.utf8)
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            try await updateUserIdentifier(userId)
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func getUserIdentifier() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let userId = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return userId
    }
    
    private func updateUserIdentifier(_ userId: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: Data(userId.utf8)
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status != errSecSuccess {
            throw KeychainError.updateFailed(status)
        }
    }
    
    func clearUserIdentifier() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case updateFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
} 