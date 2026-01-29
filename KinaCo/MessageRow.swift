//
//  Message.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/30.
//
import SwiftUI

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUser {
                // KinaCoのアイコン
                iconView
            } else {
                Spacer(minLength: 50)
            }
            
            // 吹き出し
            bubbleText
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // アイコン部分を切り出して見やすく
    private var iconView: some View {
        KinacoFaceView()
            .frame(width: 45, height: 45)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
    
    // 吹き出し部分を切り出して見やすく
    private var bubbleText: some View {
        Text(message.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isUser ? Color.blue : Color(.systemGray5))
            .foregroundColor(message.isUser ? .white : .primary)
        // 💡 ユーザー側かAI側かで角丸の形を変えるとよりチャットらしくなります
            .clipShape(
                RoundedCorner(
                    radius: 18,
                    corners: message.isUser ? [.topLeft, .bottomLeft, .bottomRight] : [
                        .topRight,
                        .bottomLeft,
                        .bottomRight
                    ]
                )
            )
    }
}

// 💡 特定の角だけ丸くするための便利なカスタム形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
