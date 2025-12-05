//
//  WordsWidgetControl.swift
//  WordsWidget
//
//  Created by Developer on 11/10/25.
//

import WidgetKit
import SwiftUI

struct WordsWidgetControl: Widget {
    let kind: String = "WordsWidgetControl"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordsProvider()) { entry in
            WordsWidgetControlView(entry: entry)
        }
        .configurationDisplayName("Words Control Widget")
        .description("Control words display.")
        .supportedFamilies([.systemSmall])
    }
}

struct WordsWidgetControlView: View {
    var entry: WordsEntry

    var body: some View {
        VStack {
            Text("Control")
                .font(.headline)
            Text(entry.word)
                .font(.subheadline)
        }
        .padding()
    }
}
