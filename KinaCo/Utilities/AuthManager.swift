//
//  AnthManager.swift
//  KinaCo
//
import Foundation
import SwiftUI

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
                self.isSignedIn = true
            }
        } catch { print("Error: \(error)") }
    }
}
