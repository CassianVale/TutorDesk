import Foundation
import AppKit

enum TD {
    // ✅ 全局 UI 语言（由 AppShellView onChange 驱动）
    static var uiLanguage: AppLanguage = .system

    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone.current
        c.firstWeekday = 1 // Sunday
        return c
    }()

    static func locale(for lang: AppLanguage) -> Locale {
        switch lang.resolved() {
        case .zhHans: return Locale(identifier: "zh_Hans_CN")
        case .en: return Locale(identifier: "en_US_POSIX")
        case .system: return Locale.current
        }
    }

    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    static func makeDate(y: Int, m: Int, d: Int) -> Date {
        let comp = DateComponents(calendar: calendar, year: y, month: m, day: d, hour: 0, minute: 0, second: 0)
        return comp.date ?? Date()
    }

    static func addDays(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    // MARK: - Date/Time (localized)

    static func monthTitle(_ date: Date, lang: AppLanguage = TD.uiLanguage) -> String {
        let f = DateFormatter()
        f.locale = locale(for: lang)
        switch lang.resolved() {
        case .zhHans:
            f.dateFormat = "yyyy年 M月"
        case .en, .system:
            f.dateFormat = "MMM yyyy"
        }
        return f.string(from: date)
    }

    static func shortDate(_ date: Date, lang: AppLanguage = TD.uiLanguage) -> String {
        let f = DateFormatter()
        f.locale = locale(for: lang)
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    static func timeHHmm(_ date: Date, lang: AppLanguage = TD.uiLanguage) -> String {
        let f = DateFormatter()
        f.locale = locale(for: lang)
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func weekdaySymbols(lang: AppLanguage = TD.uiLanguage) -> [String] {
        switch lang.resolved() {
        case .zhHans:
            return ["日","一","二","三","四","五","六"]
        case .en, .system:
            return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        }
    }

    static func weekdayName(_ weekday: Int, lang: AppLanguage = TD.uiLanguage) -> String {
        // 1=Sun ... 7=Sat
        switch lang.resolved() {
        case .zhHans:
            let map = [1:"周日",2:"周一",3:"周二",4:"周三",5:"周四",6:"周五",7:"周六"]
            return map[weekday] ?? "—"
        case .en, .system:
            let map = [1:"Sun",2:"Mon",3:"Tue",4:"Wed",5:"Thu",6:"Fri",7:"Sat"]
            return map[weekday] ?? "—"
        }
    }

    // MARK: - Parsing / composing

    /// ✅ 更稳：支持 18:30 / 18：30 / 1830 / 830 / 8:30 / " 18:30 "
    static func parseHHmm(_ s: String) -> (hour: Int, minute: Int) {
        let raw = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return (18, 30) }

        // 统一各种“冒号”
        let normalized = raw
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "﹕", with: ":")
            .replacingOccurrences(of: "∶", with: ":")
            .replacingOccurrences(of: "·", with: ":")
            .replacingOccurrences(of: " ", with: "")

        func clamp(_ h: Int, _ m: Int) -> (Int, Int)? {
            guard (0...23).contains(h), (0...59).contains(m) else { return nil }
            return (h, m)
        }

        // 情况 1：有冒号
        if normalized.contains(":") {
            let parts = normalized.split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                if let ok = clamp(h, m) { return ok }
            }
        }

        // 情况 2：无冒号，提取数字（如 1830 / 830）
        let digits = normalized.filter { $0.isNumber }
        if digits.count == 3 || digits.count == 4 {
            let minStr = String(digits.suffix(2))
            let hourStr = String(digits.prefix(digits.count - 2))
            if let h = Int(hourStr), let m = Int(minStr), let ok = clamp(h, m) {
                return ok
            }
        }

        // 兜底
        return (18, 30)
    }

    /// ✅ 规范化输出为 "HH:mm"
    static func normalizeHHmmString(_ s: String) -> String {
        let (h, m) = parseHHmm(s)
        return String(format: "%02d:%02d", h, m)
    }

    static func minutesFromHHmm(_ s: String) -> Int {
        let (h, m) = parseHHmm(s)
        return h * 60 + m
    }

    static func hhmmFromMinutes(_ minutes: Int) -> String {
        let m = ((minutes % 1440) + 1440) % 1440
        let h = m / 60
        let mm = m % 60
        return String(format: "%02d:%02d", h, mm)
    }

    /// ✅ 把日期 + HH:mm 合成为真正的 Date
    static func composeDateTime(day: Date, hhmm: String) -> Date {
        let (h, m) = parseHHmm(hhmm)
        let base = startOfDay(day)
        return calendar.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }

    /// ✅ 结束时间 = 开始时间 + 时长（分钟）
    static func endHHmm(startHHmm: String, durationMinutes: Int) -> String {
        let start = minutesFromHHmm(startHHmm)
        return hhmmFromMinutes(start + durationMinutes)
    }

    /// ✅ 由“开始 + 结束”反推时长；允许 end < start（视为跨天），最后做范围+步长规范化
    static func durationMinutes(startHHmm: String,
                                endHHmm: String,
                                min: Int = 30,
                                max: Int = 300,
                                step: Int = 10) -> Int {
        let s = minutesFromHHmm(startHHmm)
        var e = minutesFromHHmm(endHHmm)
        if e <= s { e += 1440 }
        let raw = e - s
        return normalizeDuration(raw, min: min, max: max, step: step)
    }

    /// ✅ 把任意分钟数规整到 [min,max] 并按 step 对齐
    static func normalizeDuration(_ minutes: Int,
                                  min: Int = 30,
                                  max: Int = 300,
                                  step: Int = 10) -> Int {
        let clamped = Swift.max(min, Swift.min(max, minutes))
        let rounded = Int((Double(clamped) / Double(step)).rounded()) * step
        return Swift.max(min, Swift.min(max, rounded))
    }

    /// ✅ 模板 timeOptions 解析：例如 "08:30–10:30"
    static func parseTimeRangeOption(_ s: String) -> (start: String, end: String)? {
        let raw = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return nil }

        // 统一分隔符
        let normalized = raw
            .replacingOccurrences(of: "—", with: "–")
            .replacingOccurrences(of: "-", with: "–")
            .replacingOccurrences(of: "~", with: "–")
            .replacingOccurrences(of: "～", with: "–")
            .replacingOccurrences(of: "—", with: "–")
            .replacingOccurrences(of: " ", with: "")

        let parts = normalized.split(separator: "–")
        if parts.count == 2 {
            let a = normalizeHHmmString(String(parts[0]))
            let b = normalizeHHmmString(String(parts[1]))
            return (a, b)
        }
        return nil
    }

    // MARK: - Time range formatting (for UI)

    static func timeRange(startAt: Date, durationMinutes: Int, lang: AppLanguage = TD.uiLanguage) -> String {
        let start = timeHHmm(startAt, lang: lang)
        let endDate = startAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let end = timeHHmm(endDate, lang: lang)
        return "\(start)–\(end)"
    }

    static func timeRangeString(startHHmm: String, durationMinutes: Int) -> String {
        let s = normalizeHHmmString(startHHmm)
        let e = endHHmm(startHHmm: s, durationMinutes: durationMinutes)
        return "\(s)–\(e)"
    }

    // MARK: - System actions

    static func openURL(_ urlString: String) {
        let s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: s), !s.isEmpty else { return }
        NSWorkspace.shared.open(url)
    }

    static func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func money(_ amount: Int, currencyCode: String, lang: AppLanguage = TD.uiLanguage) -> String {
        let f = NumberFormatter()
        f.locale = locale(for: lang)
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
