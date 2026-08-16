import WidgetKit
import SwiftUI

/// Standalone WidgetKit source. Add an iOS Widget Extension target in Xcode
/// and include this file so users can pin a home-screen quick-add widget.
struct SpendPingQuickAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpendPingQuickAdd", provider: QuickAddProvider()) { _ in
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY").font(.caption.weight(.bold))
                Text("Amount, then what").font(.caption2)
                HStack {
                    Link("₹50", destination: URL(string: "spendping://add?amount=5000")!)
                    Link("₹100", destination: URL(string: "spendping://add?amount=10000")!)
                    Link("₹200", destination: URL(string: "spendping://add?amount=20000")!)
                    Link("₹500", destination: URL(string: "spendping://add?amount=50000")!)
                }
                HStack {
                    Link("Food", destination: URL(string: "spendping://quick?amount=10000&what=Food")!)
                    Link("Travel", destination: URL(string: "spendping://quick?amount=10000&what=Travel")!)
                    Link("Other", destination: URL(string: "spendping://quick?amount=10000&what=Other")!)
                    Link("Type", destination: URL(string: "spendping://add")!)
                }
            }
            .padding()
        }
        .configurationDisplayName("SpendPing Quick Add")
        .description("Tap amount, then what. It shows up in today's spends.")
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
