//
//  AnthManager.swift
//  KinaCo
//
import Foundation
import SwiftUI
import LocalAuthentication

@Observable
class AuthManager {
    var isSignedIn: Bool = false
    var idToken: String? = nil
    
    private var region: String {
        Bundle.main
            .object(
                forInfoDictionaryKey: "AWS_REGION"
            ) as? String ?? "us-east-1"
    }
    private let clientId = Bundle.main.object(
        forInfoDictionaryKey: "COGNITO_CLIENT_ID"
    ) as? String ?? ""
    
    
    @MainActor
    func signIn(username: String, password: String) async {
        let url = URL(string: "https://cognito-idp.\(region).amazonaws.com/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request
            .addValue(
                "application/x-amz-json-1.1",
                forHTTPHeaderField: "Content-Type"
            )
        request
            .addValue(
                "AWSCognitoIdentityProviderService.InitiateAuth",
                forHTTPHeaderField: "X-Amz-Target"
            )
        
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": clientId,
            "AuthParameters": ["USERNAME": username, "PASSWORD": password]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let authResult = json["AuthenticationResult"] as? [String: Any],
               let token = authResult["IdToken"] as? String {
                self.idToken = token
                self.saveTokenToKeychain(token: token)
                self.isSignedIn = true
            }
        } catch { print("Error: \(error)") }
    }
}
extension AuthManager {
    
    func saveTokenToKeychain(token: String) {
        if let data = token.data(using: .utf8) {
            KeychainHelper.standard.save(data, account: "kinaco-id-token")
        }
    }
    
    @MainActor
    func checkFaceIDAndLogin() async {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "KinaCoをログインするために認証してください"
                )
                
                if success {
                    if let data = KeychainHelper.standard.read(account: "kinaco-id-token"),
                       let savedToken = String(data: data, encoding: .utf8) {
                        self.idToken = savedToken
                        self.isSignedIn = true
                        print("業務ログ：Face IDで自動ログイン成功")
                    }
                }
            } catch {
                print("業務ログ：Face ID認証失敗: \(error.localizedDescription)")
            }
        }
    }
}
