//
//  WordyWidget.swift
//  WordyWidgetExtension
//

import WidgetKit
import SwiftUI

struct WordyWidget: Widget {
    let kind: String = "WordyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Wordy Словник")
        .description("Вивчайте нові слова щодня")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
