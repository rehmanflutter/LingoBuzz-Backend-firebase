//
//  WordsWidgetBundle.swift
//  WordsWidget
//
//  Created by Abdul Rehman on 11/25/25.
//

import WidgetKit
import SwiftUI

@main
struct WordsWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordsWidget()
        WordsWidgetLiveActivity()
    }
}
