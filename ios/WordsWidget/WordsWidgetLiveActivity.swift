//
//  WordsWidgetLiveActivity.swift
//  WordsWidget
//
//  Created by Abdul Rehman on 11/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WordsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WordsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WordsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WordsWidgetAttributes {
    fileprivate static var preview: WordsWidgetAttributes {
        WordsWidgetAttributes(name: "World")
    }
}

extension WordsWidgetAttributes.ContentState {
    fileprivate static var smiley: WordsWidgetAttributes.ContentState {
        WordsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WordsWidgetAttributes.ContentState {
         WordsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WordsWidgetAttributes.preview) {
   WordsWidgetLiveActivity()
} contentStates: {
    WordsWidgetAttributes.ContentState.smiley
    WordsWidgetAttributes.ContentState.starEyes
}
