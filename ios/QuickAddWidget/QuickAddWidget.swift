import WidgetKit
import SwiftUI

/// Standalone WidgetKit source. Add an iOS Widget Extension target in Xcode.
struct SpendPingQuickAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpendPingQuickAdd", provider: QuickAddProvider()) { _ in
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY").font(.caption.weight(.bold))
                Text("Type amount, then save").font(.caption2)
                Link("Add spend", destination: URL(string: "spendping://compose")!)
            }
            .padding()
        }
        .configurationDisplayName("SpendPing Quick Add")
        .description("Opens a box to type amount, Food or Fuel, then Save.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickAddEntry: TimelineEntry {
    let date: Date
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry { QuickAddEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(QuickAddEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        completion(Timeline(entries: [QuickAddEntry(date: Date())], policy: .never))
    }
}
