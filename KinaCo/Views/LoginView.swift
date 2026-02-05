//
//  LoginVies.swift
//  KinaCo
//
import SwiftUI
import Combine

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                HStack {
                    Text("KinaCo")
                        .font(
                            .system(size: 40, weight: .black, design: .rounded)
                        )
                        .foregroundColor(.primary)
                    KinacoFaceView()
                        .frame(width: 45, height: 45)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.gray.opacity(1), lineWidth: 1)
                        )
                }
                Text("AI Chatbot")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Button(action: {
                    Task {
                        await authManager.signIn(username: email, password: password)
                    }
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.pink)
                        .cornerRadius(12)
                        .shadow(
                            color: Color.pink.opacity(0.3),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
    }
}
