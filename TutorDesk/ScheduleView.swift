import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var store: AppStore
    @State private var tab: Int = 0

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text(L.t(.calendarTab, lang: lang)).tag(0)
                Text(L.t(.templatesTab, lang: lang)).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            if tab == 0 {
                CalendarMonthView()
            } else {
                TemplatesListView()
            }
        }
    }
}

// MARK: - Month Calendar

private struct CalendarMonthView: View {
    @EnvironmentObject private var store: AppStore
    @State private var monthAnchor: Date = Date()
    @State private var selectedDay: Date = Date()

    private let columns = Array(repeating: GridItem(.flexible(minimum: 24), spacing: 6), count: 7)

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(spacing: 12) {
            header(lang: lang)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            weekdayHeader(lang: lang)
                .padding(.horizontal, 14)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(dayCells(for: monthAnchor), id: \.selfIndex) { cell in
                    dayCell(cell.date, lang: lang)
                }
            }
            .padding(.horizontal, 14)

            Divider().padding(.top, 4)

            List {
                let sessions = store.sessions(on: selectedDay)
                if sessions.isEmpty {
                    Text(L.t(.noSessionsOnThisDay, lang: lang))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { ss in
                        SessionRow(ss: ss)
                            .contextMenu {
                                Button(ss.status == .attended ? L.t(.markAsPlanned, lang: lang) : L.t(.checkInAttended, lang: lang)) {
                                    store.toggleAttendance(ss.id)
                                }
                                Button(L.t(.delete, lang: lang)) { store.deleteSession(ss.id) }
                            }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func header(lang: AppLanguage) -> some View {
        HStack {
            Button {
                monthAnchor = TD.calendar.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(.thinMaterial)
            .cornerRadius(8)

            Text(TD.monthTitle(monthAnchor, lang: lang))
                .font(.system(size: 16, weight: .semibold))

            Button {
                monthAnchor = TD.calendar.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(.thinMaterial)
            .cornerRadius(8)

            Spacer()

            Button(L.t(.today, lang: lang)) {
                selectedDay = Date()
                monthAnchor = Date()
            }
            .buttonStyle(.bordered)
        }
    }

    private func weekdayHeader(lang: AppLanguage) -> some View {
        let names = TD.weekdaySymbols(lang: lang)
        return HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                Text(names[i])
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ date: Date?, lang: AppLanguage) -> some View {
        Group {
            if let date {
                let isToday = TD.startOfDay(date) == TD.startOfDay(Date())
                let isSelected = TD.startOfDay(date) == TD.startOfDay(selectedDay)
                let count = store.sessions(on: date).count

                Button { selectedDay = date } label: {
                    VStack(spacing: 4) {
                        Text("\(TD.calendar.component(.day, from: date))")
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Spacer(minLength: 0)

                        if count > 0 {
                            HStack(spacing: 3) {
                                Circle().frame(width: 5, height: 5)
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? .white : .blue)
                            .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        }
                    }
                    .padding(8)
                    .frame(height: 44)
                    .background(background(isSelected: isSelected, isToday: isToday))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(height: 44)
            }
        }
    }

    private func background(isSelected: Bool, isToday: Bool) -> some View {
        if isSelected { return AnyView(Color.blue.opacity(0.85)) }
        if isToday { return AnyView(Color.blue.opacity(0.12)) }
        return AnyView(Color.primary.opacity(0.03))
    }

    private func dayCells(for anchor: Date) -> [DayCell] {
        let cal = TD.calendar
        let comp = cal.dateComponents([.year, .month], from: anchor)
        let first = cal.date(from: comp) ?? anchor
        let range = cal.range(of: .day, in: .month, for: first) ?? 1..<29
        let firstWeekday = cal.component(.weekday, from: first) // 1..7 (Sun..Sat)

        var cells: [DayCell] = []
        let leading = firstWeekday - 1
        for _ in 0..<leading { cells.append(DayCell(date: nil)) }

        for day in range {
            let d = cal.date(byAdding: .day, value: day - 1, to: first)!
            cells.append(DayCell(date: d))
        }
        while cells.count % 7 != 0 { cells.append(DayCell(date: nil)) }
        return cells
    }

    private struct DayCell: Hashable {
        let date: Date?
        let selfIndex = UUID()
    }
}

// MARK: - Templates list

private struct TemplatesListView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        List {
            ForEach(store.state.templates) { t in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(t.title).font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(t.subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                    }

                    if !t.windows.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.t(.windowsLabel, lang: lang))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            ForEach(t.windows) { w in
                                HStack {
                                    Text(w.name).frame(width: 36, alignment: .leading)
                                    Text("\(TD.shortDate(w.start, lang: lang)) – \(TD.shortDate(w.end, lang: lang))")
                                    Spacer()
                                }
                                .font(.system(size: 12))
                            }
                        }
                    }

                    if !t.timeOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.t(.timeOptionsLabel, lang: lang))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            FlowWrap(items: t.timeOptions) { s in
                                TagPill(text: s)
                            }
                        }
                    }

                    if !t.weekdayAvailability.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.t(.weeklyAvailabilityLabel, lang: lang))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            ForEach(t.weekdayAvailability) { a in
                                HStack(alignment: .top) {
                                    Text(TD.weekdayName(a.weekday, lang: lang))
                                        .frame(width: 48, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(a.timeRanges, id: \.self) { r in
                                            Text(r).font(.system(size: 12, weight: .medium))
                                        }
                                        Text(a.note).font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    TagPill(text: a.status)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    HStack {
                        TagPill(text: L.f(.pricePerLessonTag, lang: lang, t.suggestedPricePerLesson))
                        TagPill(text: L.f(.lessonsCountTag, lang: lang, t.suggestedLessons))
                        TagPill(text: L.f(.minutesCountTag, lang: lang, t.suggestedDurationMinutes))
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Detail column for schedule

struct ScheduleDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(alignment: .leading, spacing: 12) {
            Text(L.t(.quickSummary, lang: lang))
                .font(.system(size: 16, weight: .semibold))

            let upcoming = store.state.sessions
                .filter { $0.startAt >= Date().addingTimeInterval(-3600) }
                .sorted { $0.startAt < $1.startAt }
                .prefix(10)

            if upcoming.isEmpty {
                Text(L.t(.noUpcomingSessionsTip, lang: lang))
                    .foregroundStyle(.secondary)
            } else {
                List(Array(upcoming)) { ss in
                    SessionRow(ss: ss)
                }
                .listStyle(.inset)
            }

            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Small UI Components

private struct SessionRow: View {
    @EnvironmentObject private var store: AppStore
    let ss: Session

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // ✅ 改这里：显示时间段
                Text("\(TD.shortDate(ss.startAt, lang: lang)) \(TD.timeRange(startAt: ss.startAt, durationMinutes: ss.durationMinutes, lang: lang))")
                    .font(.system(size: 12, weight: .semibold))

                TagPill(text: L.t(ss.status.titleKey, lang: lang), isEmphasis: ss.status == .attended)

                Spacer()

                if let name = store.student(by: ss.studentID)?.name {
                    Text(name).foregroundStyle(.secondary)
                }
            }
            if !ss.meetingLink.isEmpty {
                Text(ss.meetingLink)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TagPill: View {
    let text: String
    var isEmphasis: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isEmphasis ? Color.blue.opacity(0.22) : Color.primary.opacity(0.06))
            .cornerRadius(999)
    }
}

private struct FlowWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { it in content(it) }
        }
    }
}
