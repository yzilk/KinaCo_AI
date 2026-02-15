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
                DynamicIslandExpandedRegion(.leading) {
                    Text("🐶")
                        .font(.title)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("AI")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.message)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } compactLeading: {
                Text("🐶")
            } compactTrailing: {
                Text("AI")
                    .font(.caption2)
            } minimal: {
                Text("🐶")
            }
        }
    }
}
