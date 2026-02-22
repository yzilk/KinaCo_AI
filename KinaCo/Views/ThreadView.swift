//
//  ThreadView.swift
//  KinaCo
//

import SwiftUI

struct ThreadView: View {
    @Environment(AuthManager.self) var authManager
    @StateObject private var viewModel = ThreadViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.threads) { thread in
                    Section(header: Text(thread.category)) {
                        ForEach(thread.items) { item in
                            HStack {
                                Text(item.content)
                                    .foregroundColor(item.confirmed ? .primary : .orange)
                                Spacer()
                                if !item.confirmed {
                                    Image(systemName: "circle.dotted")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("KinaCoのきろく 🧸")
            .task {
                if viewModel.shouldRefresh {
                    await viewModel.loadThreads(authManager: authManager)
                }
            }
        }
    }
}
