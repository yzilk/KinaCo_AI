//
//  KinacoFaceView.swift
//  KinaCo
//
import SwiftUI
import Combine
struct KinacoFaceView: View {
    @State private var isBlinking = false
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.white
            Image(isBlinking ? "eye_closed" : "eye_open")
                .resizable()
                .scaledToFit()
//                .colorMultiply(Color(white: 0.98))
            Color.white.opacity(0.1)
        }
        .frame(width: 45, height: 45)
        .onReceive(timer) { _ in
            executeBlink()
        }
    }
    
    private func executeBlink() {
        withAnimation(.easeInOut(duration: 0.05)) {
            isBlinking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.05)) {
                isBlinking = false
            }
        }
    }
}
