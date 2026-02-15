//
//  KinacoLiveActivityView.swift 
//  KinaCo
//
import ActivityKit
import WidgetKit
import SwiftUI

struct KinacoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KinacoAttributes.self) { context in
            // ロック画面用のビュー
            VStack(spacing: 8) {
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(context.state.message)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .activityBackgroundTint(Color.orange.opacity(0.3))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // 長押しで広がった時
                DynamicIslandExpandedRegion(.leading) {
                    Image("eye_open")
                        .resizable()
                        .scaledToFit() // 👈 Fitに変えることで全体を表示
                        .padding(2)    // 👈 少し余白を作って円の中に収める
                        .frame(width: 26, height: 26)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1.5) // 👈 黒い縁取りに変更
                        )
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.message)
                        .foregroundColor(.orange)
                }
            } compactLeading: {
                Image("eye_open")
                    .resizable()
                    .scaledToFit() // 👈 Fitに変えることで全体を表示
                    .padding(2)    // 👈 少し余白を作って円の中に収める
                    .frame(width: 26, height: 26)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: 1.5) // 👈 黒い縁取りに変更
                    )
            } compactTrailing: {
                Text("AI")
            } minimal: {
                // 最小状態
                Image("eye_open")
                    .resizable()
                    .scaledToFit() // 👈 Fitに変えることで全体を表示
                    .padding(2)    // 👈 少し余白を作って円の中に収める
                    .frame(width: 26, height: 26)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: 1.5) // 👈 黒い縁取りに変更
                    )
            }
        }
    }
}

