//
//  KeychainHelper.swift
//  KinaCo
//
import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private let service = "com.bbitbear.KinaCo"
    
    func save(_ data: Data, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary) 
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func read(account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as [String: Any]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}

