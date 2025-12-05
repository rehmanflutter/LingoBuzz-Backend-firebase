import WidgetKit
import SwiftUI

// MARK: - Circular Lock Screen Widget
struct LockScreenCircularWidget: Widget {
    let kind: String = "LockScreenCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenCircularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Word Circle")
        .description("Shows word initial")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenCircularView: View {
    var entry: WordsEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Text(entry.word.prefix(1).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .minimumScaleFactor(0.5)

                Text(entry.word.count > 4 ? String(entry.word.prefix(4)) : entry.word)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

// MARK: - Rectangular Lock Screen Widget
struct LockScreenRectangularWidget: Widget {
    let kind: String = "LockScreenRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenRectangularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Word Rectangle")
        .description("Shows word and translation")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenRectangularView: View {
    var entry: WordsEntry

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.word)
                    .font(.system(size: 23, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(entry.translation)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Image("bee_logo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 40, height: 50)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Inline Lock Screen Widget
struct LockScreenInlineWidget: Widget {
    let kind: String = "LockScreenInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenInlineView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Word Inline")
        .description("Shows word inline")
        .supportedFamilies([.accessoryInline])
    }
}

struct LockScreenInlineView: View {
    var entry: WordsEntry

    var body: some View {
        HStack(spacing: 4) {
            Image("bee_logo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(entry.word)
                .font(.system(size: 14, weight: .medium))

            Text("·")
                .foregroundColor(.secondary)

            Text(entry.translation)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
    }
}

// MARK: - Shared Provider for Lock Screen Widgets
struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordsEntry {
        loadCurrentWordOrDefault()
    }

    func getSnapshot(in context: Context, completion: @escaping (WordsEntry) -> Void) {
        let entry = loadCurrentWordOrDefault()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordsEntry>) -> Void) {
        print("🔄 LockScreen: Building timeline at \(Date())")

        guard let defaults = UserDefaults(suiteName: "group.com.lingobuzz.app") else {
            print("⚠️ LockScreen: Failed to access app group")
            let entry = WordsEntry(date: Date(), word: "Bonjour", translation: "Hello", language: "French")
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
            return
        }

        let isSetupDone = defaults.bool(forKey: "isSetupDone")
        if !isSetupDone {
            print("⚠️ LockScreen: Setup not done")
            let entry = WordsEntry(date: Date(), word: "Setup", translation: "Required", language: "")
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
            return
        }

        guard let wordsData = defaults.array(forKey: "daily_words") as? [[String: Any]],
              !wordsData.isEmpty else {
            print("⚠️ LockScreen: No daily words found")
            let currentEntry = loadCurrentWordOrDefault()
            let timeline = Timeline(entries: [currentEntry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
            return
        }

        let sourceLang = defaults.string(forKey: "sourceLang") ?? "german"
        let targetLang = defaults.string(forKey: "targetLang") ?? "english"
        let displayTime = defaults.string(forKey: "displayTime")

        print("📚 LockScreen: Loaded \(wordsData.count) words")

        var entries: [WordsEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let timeRange = parseDisplayTime(displayTime)

        if let timeRange = timeRange {
            let startHour = timeRange.start
            let endHour = timeRange.end

            let activeDuration: Double
            if endHour >= startHour {
                activeDuration = endHour - startHour
            } else {
                activeDuration = (24 - startHour) + endHour
            }

            let slotDuration = activeDuration / Double(wordsData.count)

            for i in 0..<wordsData.count {
                let wordData = wordsData[i]
                let sourceWord = getWordByLang(wordData, lang: sourceLang)
                let targetWord = getWordByLang(wordData, lang: targetLang)
                let wordId = wordData["id"] as? String ?? ""

                if sourceWord.isEmpty || targetWord.isEmpty {
                    continue
                }

                var slotStart = startHour + (Double(i) * slotDuration)
                if slotStart >= 24 { slotStart -= 24 }

                var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                components.hour = Int(slotStart)
                components.minute = Int((slotStart - Double(Int(slotStart))) * 60)

                guard var slotDate = calendar.date(from: components) else { continue }

                if slotDate < currentDate {
                    slotDate = calendar.date(byAdding: .day, value: 1, to: slotDate) ?? slotDate
                }

                entries.append(WordsEntry(
                    date: slotDate,
                    word: sourceWord,
                    translation: targetWord,
                    language: sourceLang,
                    wordId: wordId
                ))
            }
        } else {
            let slotDuration = 24.0 / Double(wordsData.count)

            for i in 0..<wordsData.count {
                let wordData = wordsData[i]
                let sourceWord = getWordByLang(wordData, lang: sourceLang)
                let targetWord = getWordByLang(wordData, lang: targetLang)
                let wordId = wordData["id"] as? String ?? ""

                if sourceWord.isEmpty || targetWord.isEmpty {
                    continue
                }

                let slotStart = Double(i) * slotDuration

                var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                components.hour = Int(slotStart)
                components.minute = Int((slotStart - Double(Int(slotStart))) * 60)

                guard var slotDate = calendar.date(from: components) else { continue }

                if slotDate < currentDate {
                    slotDate = calendar.date(byAdding: .day, value: 1, to: slotDate) ?? slotDate
                }

                entries.append(WordsEntry(
                    date: slotDate,
                    word: sourceWord,
                    translation: targetWord,
                    language: sourceLang,
                    wordId: wordId
                ))
            }
        }

        entries.sort { $0.date < $1.date }

        if entries.isEmpty {
            let currentEntry = loadCurrentWordOrDefault()
            entries.append(currentEntry)
        }

        // Add refresh entry for next day
        if let lastDate = entries.last?.date {
            let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate)
            var refreshEntry = entries.last!
            refreshEntry.date = nextMidnight
            entries.append(refreshEntry)
        }

        print("✅ LockScreen: Timeline built with \(entries.count) entries")

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: - Helper Methods

    private func loadCurrentWordOrDefault() -> WordsEntry {
        guard let defaults = UserDefaults(suiteName: "group.com.lingobuzz.app") else {
            return WordsEntry(date: Date(), word: "Bonjour", translation: "Hello", language: "French")
        }

        if let word = defaults.string(forKey: "word"),
           let translation = defaults.string(forKey: "translation"),
           !word.isEmpty, !translation.isEmpty {
            let language = defaults.string(forKey: "language") ?? "French"
            let wordId = defaults.string(forKey: "word_id") ?? ""
            return WordsEntry(date: Date(), word: word, translation: translation, language: language, wordId: wordId)
        }

        if let wordsData = defaults.array(forKey: "daily_words") as? [[String: Any]],
           !wordsData.isEmpty {
            let sourceLang = defaults.string(forKey: "sourceLang") ?? "german"
            let targetLang = defaults.string(forKey: "targetLang") ?? "english"

            let firstWord = wordsData[0]
            let sourceWord = getWordByLang(firstWord, lang: sourceLang)
            let targetWord = getWordByLang(firstWord, lang: targetLang)

            if !sourceWord.isEmpty && !targetWord.isEmpty {
                return WordsEntry(
                    date: Date(),
                    word: sourceWord,
                    translation: targetWord,
                    language: sourceLang,
                    wordId: firstWord["id"] as? String ?? ""
                )
            }
        }

        return WordsEntry(date: Date(), word: "Bonjour", translation: "Hello", language: "French")
    }

    private func parseDisplayTime(_ displayTime: String?) -> (start: Double, end: Double)? {
        guard let displayTime = displayTime, !displayTime.isEmpty else { return nil }

        let parts = displayTime.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        guard let start = parseTimeToHour(String(parts[0])),
              let end = parseTimeToHour(String(parts[1])) else {
            return nil
        }

        return (start, end)
    }

    private func parseTimeToHour(_ time: String) -> Double? {
        let cleaned = time.uppercased()
        let isAM = cleaned.contains("AM")
        let isPM = cleaned.contains("PM")

        guard isAM || isPM else { return nil }

        let timePart = cleaned.replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .trimmingCharacters(in: .whitespaces)

        let components = timePart.split(separator: ":")
        guard !components.isEmpty else { return nil }

        var hour = Int(components[0]) ?? 0
        let minute = components.count > 1 ? (Int(components[1]) ?? 0) : 0

        if isPM && hour != 12 { hour += 12 }
        if isAM && hour == 12 { hour = 0 }

        return Double(hour) + (Double(minute) / 60.0)
    }

    private func getWordByLang(_ wordData: [String: Any], lang: String) -> String {
        switch lang.lowercased() {
        case "german": return wordData["german"] as? String ?? ""
        case "english": return wordData["english"] as? String ?? ""
        case "french": return wordData["french"] as? String ?? ""
        case "italian": return wordData["italian"] as? String ?? ""
        case "spanish": return wordData["spanish"] as? String ?? ""
        case "chinese": return wordData["chinese"] as? String ?? ""
        case "korean": return wordData["korean"] as? String ?? ""
        case "portuguese": return wordData["portuguese"] as? String ?? ""
        case "japanese": return wordData["japanese"] as? String ?? ""
        default: return ""
        }
    }
}

// MARK: - Previews
struct LockScreenWidgets_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = WordsEntry(
            date: Date(),
            word: "Bonjour",
            translation: "Hello",
            language: "French"
        )

        Group {
            LockScreenCircularView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")

            LockScreenRectangularView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")

            LockScreenInlineView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
        }
    }
}