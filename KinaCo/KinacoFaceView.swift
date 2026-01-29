//
//  KinacoFaceView.swift
//  KinaCo
//
//  Created by Yugo Noji on 2026/01/29.
//
import SwiftUI
import Combine
struct KinacoFaceView: View {
    @State private var isBlinking = false
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 1. 土台の背景を「真っ白」に固定
            Color.white
            
            // 2. 目（画像）
            Image(isBlinking ? "eye_closed" : "eye_open")
                .resizable()
                .scaledToFit()
            // 3. 若干の色の違いを馴染ませるために「白」を少し混ぜる
            // .colorMultiply(Color(white: 0.98)) // 必要なら有効化
            	
            // 上から薄い白のベールをかけて色の段差を消す
            Color.white.opacity(0.1)
        }
        // ここでアイコン全体のサイズを確定
        .frame(width: 45, height: 45)
        .onReceive(timer) { _ in
            executeBlink()
        }
    }
    
    private func executeBlink() {
        withAnimation(.easeInOut(duration: 0.05)) {
            isBlinking = true
        }
        // 瞬きしている時間（0.15秒後に戻す）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.05)) {
                isBlinking = false
            }
        }
    }
}
