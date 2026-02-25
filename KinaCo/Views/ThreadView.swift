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
                    Section {
                        ForEach(thread.items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top) {
                                    Image(systemName: item.confirmed ? "bubble.left.fill" : "ellipsis.bubble")
                                        .font(.system(size: 14))
                                        .foregroundColor(item.confirmed ? .blue : .orange)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.content)
                                            .font(.body)
                                            .foregroundColor(item.confirmed ? .primary : .secondary)
                                            .lineLimit(2) 
                                        if !item.confirmed {
                                            Text("送信中または未確定...")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                                .italic()
                                        }
                                    }
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(.systemGray4))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text(thread.category)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, -10)
                    }
                }
            }
            .listStyle(.insetGrouped) 
            .navigationTitle("KinaCoのきろく 🧸")
            .task {
                if viewModel.shouldRefresh {
                    await viewModel.loadThreads(authManager: authManager)
                }
            }
        }
    }
}
