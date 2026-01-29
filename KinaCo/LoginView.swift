//
//  LoginVies.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/18.
//

import SwiftUI

struct LoginView: View {
    var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 25) {
            Text("KinaCo")
                .font(.system(size: 45, weight: .bold, design: .rounded))
            Text("AI Chat Bot")
                .font(.system(size: 17, weight: .bold, design: .rounded))
            
            VStack(alignment: .leading, spacing: 10) {
                TextField("ユーザー名", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            Button {
                Task {
                    await authManager
                        .signIn(username: username, password: password)
                }
            } label: {
                Text("ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}
