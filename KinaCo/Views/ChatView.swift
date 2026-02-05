import SwiftUI

struct ChatView: View {
    @Environment(AuthManager.self) private var authManager
    @StateObject private var viewModel = ChatViewModel()
    @State private var isShowingLogin = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.messages) { msg in
                                MessageRow(message: msg)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages) { _, newValue in
                        withAnimation {
                            proxy.scrollTo(newValue.last?.id, anchor: .bottom)
                        }
                    }
                }
                inputBar
            }
            .navigationTitle("KinaCo AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingLogin = true
                    } label: {
                        if authManager.isSignedIn {
                            Image(systemName: "person.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 22))
                                .foregroundStyle(.pink)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingLogin) {
                LoginView()
            }
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("メッセージを入力...", text: $viewModel.messageText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(25)
            
            Button(action: {
                Task {
                    let token = authManager.isSignedIn ? authManager.idToken : nil
                    await viewModel.sendMessage(idToken: token)
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.messageText.isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.messageText.isEmpty)
        }
        .padding()
    }
}
//#Preview {
//    ChatView()
//        .environment(AuthManager())
//}
