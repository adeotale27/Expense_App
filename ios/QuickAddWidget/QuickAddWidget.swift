import WidgetKit
import SwiftUI

/// Standalone WidgetKit source. Add an iOS Widget Extension target in Xcode
/// and include this file so users can pin a home-screen quick-add widget.
/// The host app already handles `spendping://add` deep links.
struct SpendPingQuickAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpendPingQuickAdd", provider: QuickAddProvider()) { _ in
            VStack(alignment: .leading, spacing: 8) {
                Text("SpendPing").font(.headline)
                Text("Record spend").font(.caption)
                HStack {
                    Link("₹100", destination: URL(string: "spendping://add?amount=10000")!)
                    Link("₹200", destination: URL(string: "spendping://add?amount=20000")!)
                    Link("₹500", destination: URL(string: "spendping://add?amount=50000")!)
                    Link("Add", destination: URL(string: "spendping://add")!)
                }
            }
            .padding()
        }
        .configurationDisplayName("SpendPing Quick Add")
        .description("Record a familiar expense without opening the full app.")
        .supportedFamilies([.systemMedium])
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
