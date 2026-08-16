import WidgetKit
import SwiftUI

/// Standalone WidgetKit source. Add an iOS Widget Extension target in Xcode.
struct SpendPingQuickAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpendPingQuickAdd", provider: QuickAddProvider()) { _ in
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY").font(.caption.weight(.bold))
                Text("Add spend").font(.title3.weight(.bold))
                Link("Add spend", destination: URL(string: "spendping://compose")!)
            }
            .padding()
        }
        .configurationDisplayName("SpendPing Quick Add")
        .description("Opens amount + Save on iOS. Android saves from the widget sheet without opening the app.")
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
