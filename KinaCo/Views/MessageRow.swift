//
//  Message.swift
//  KinaCo
//
import SwiftUI

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUser {
                iconView
            } else {
                Spacer(minLength: 50)
            }
            
            bubbleText
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var iconView: some View {
        KinacoFaceView()
            .frame(width: 45, height: 45)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
    
  
    private var bubbleText: some View {
        Text(message.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "E0C3FC"),
                                Color(hex: "FF9A9E")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .foregroundColor(message.isUser ? .white : .black)
            .cornerRadius(16)
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
