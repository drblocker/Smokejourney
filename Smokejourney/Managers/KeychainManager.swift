import Foundation
import Security

/// A service for securely storing and retrieving data from the iOS Keychain
final class KeychainManager {
    /// Shared instance for accessing the keychain
    static let shared = KeychainManager()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Stores a string value in the keychain
    /// - Parameters:
    ///   - value: The string to store
    ///   - key: The key to associate with the stored string
    func set(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieves a string value from the keychain
    /// - Parameter key: The key associated with the stored string
    /// - Returns: The stored string, if found
    func string(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Removes a value from the keychain
    /// - Parameter key: The key of the value to remove
    func remove(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Errors that can occur during keychain operations
    enum KeychainError: LocalizedError {
        case encodingFailed
        case unhandledError(status: OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode data for keychain storage"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
} 