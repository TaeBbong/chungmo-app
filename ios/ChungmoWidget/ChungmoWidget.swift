import SwiftUI
import WidgetKit

/// Renders the upcoming-wedding widget from the App Group store
/// HomeWidgetService fills. Keys mirror lib/core/utils/constants.dart.
private enum Store {
    static let appGroupId = "group.com.taebbong.chungmoapp"
    static let hasScheduleKey = "widget_has_schedule"
    static let coupleKey = "widget_couple"
    static let dateTextKey = "widget_date_text"
    static let locationKey = "widget_location"
    static let dateMillisKey = "widget_date_millis"
}

struct WeddingSnapshot {
    let couple: String
    let dateText: String
    let location: String
    let weddingDate: Date

    static func load() -> WeddingSnapshot? {
        guard let defaults = UserDefaults(suiteName: Store.appGroupId),
            defaults.bool(forKey: Store.hasScheduleKey),
            let millis = defaults.object(forKey: Store.dateMillisKey) as? NSNumber
        else { return nil }
        return WeddingSnapshot(
            couple: defaults.string(forKey: Store.coupleKey) ?? "",
            dateText: defaults.string(forKey: Store.dateTextKey) ?? "",
            location: defaults.string(forKey: Store.locationKey) ?? "",
            weddingDate: Date(timeIntervalSince1970: millis.doubleValue / 1000)
        )
    }

    /// Calendar-day distance seen from [reference], mirroring Dart's
    /// DateExtension.daysLeft: a wedding later that day is 0.
    func daysLeft(from reference: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: reference),
            to: calendar.startOfDay(for: weddingDate)
        ).day ?? 0
    }
}

struct WeddingEntry: TimelineEntry {
    let date: Date
    let snapshot: WeddingSnapshot?
}

struct WeddingTimelineProvider: TimelineProvider {
    private static let previewSnapshot = WeddingSnapshot(
        couple: "김철수 & 이영희",
        dateText: "10월 24일(토) 13시",
        location: "그랜드홀 3층",
        weddingDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    )

    func placeholder(in context: Context) -> WeddingEntry {
        WeddingEntry(date: Date(), snapshot: Self.previewSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeddingEntry) -> Void) {
        let snapshot = context.isPreview ? Self.previewSnapshot : WeddingSnapshot.load()
        completion(WeddingEntry(date: Date(), snapshot: snapshot))
    }

    /// One entry now plus one per upcoming midnight, so the D-day rolls
    /// over with the calendar day without the app running. Each entry
    /// re-reads nothing — it re-renders the same snapshot as seen from its
    /// own date, which is what moves the count.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeddingEntry>) -> Void) {
        let snapshot = WeddingSnapshot.load()
        let calendar = Calendar.current
        let now = Date()
        var entries = [WeddingEntry(date: now, snapshot: snapshot)]
        let startOfToday = calendar.startOfDay(for: now)
        for day in 1...14 {
            if let midnight = calendar.date(byAdding: .day, value: day, to: startOfToday) {
                entries.append(WeddingEntry(date: midnight, snapshot: snapshot))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

/// Palette mirroring lib/presentation/theme/palette.dart; the accent
/// lightens to burgundy200 on dark for contrast, like the Android widget.
private extension Color {
    static let widgetAccent = Color(
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.88, green: 0.66, blue: 0.70, alpha: 1) : UIColor(red: 0.50, green: 0.00, blue: 0.13, alpha: 1) })
    static let widgetBackground = Color(
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor.white })
    static let widgetTextPrimary = Color(
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.98, alpha: 1) : UIColor(white: 0.07, alpha: 1) })
    static let widgetTextSecondary = Color(
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.72, alpha: 1) : UIColor(white: 0.47, alpha: 1) })
}

struct ChungmoWidgetEntryView: View {
    let entry: WeddingEntry

    var body: some View {
        // iOS 17 pads via its own content margins; earlier versions get the
        // same breathing room manually.
        if #available(iOSApplicationExtension 17.0, *) {
            content
        } else {
            content.padding(14)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot, snapshot.daysLeft(from: entry.date) >= 0 {
            schedule(snapshot, daysLeft: snapshot.daysLeft(from: entry.date))
        } else {
            empty
        }
    }

    private func schedule(_ snapshot: WeddingSnapshot, daysLeft: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(daysLeft == 0 ? "D-DAY" : "D-\(daysLeft)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.widgetAccent)
            Spacer(minLength: 4)
            Text(snapshot.couple)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.widgetTextPrimary)
                .lineLimit(1)
            Text(snapshot.dateText)
                .font(.system(size: 12))
                .foregroundColor(.widgetTextSecondary)
                .lineLimit(1)
            Text(snapshot.location)
                .font(.system(size: 12))
                .foregroundColor(.widgetTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var empty: some View {
        Text("다가오는 예식이 없어요")
            .font(.system(size: 13))
            .foregroundColor(.widgetTextSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

@main
struct ChungmoWidget: Widget {
    /// Must match HomeWidgetService's iOS widget name — updateWidget reloads
    /// timelines of this kind.
    let kind = "ChungmoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeddingTimelineProvider()) { entry in
            ChungmoWidgetEntryView(entry: entry)
                .widgetBackground(.widgetBackground)
        }
        .configurationDisplayName("청모 D-day")
        .description("다가오는 예식의 D-day를 보여줘요")
        .supportedFamilies([.systemSmall])
    }
}
