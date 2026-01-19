// BookingView.swift
import SwiftUI

struct BookingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search: String = ""

    // ✅ 用自定义 Binding 同步 selectedStudentID，避免“看的是A报名，但selectedStudent还是B”
    private var enrollmentSelection: Binding<UUID?> {
        Binding(
            get: { store.selectedEnrollmentID },
            set: { newID in
                store.selectedEnrollmentID = newID
                if let e = store.enrollment(by: newID) {
                    store.selectedStudentID = e.studentID
                }
            }
        )
    }

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField(L.t(.searchStudentEnrollment, lang: lang), text: $search)
                    .textFieldStyle(.roundedBorder)

                Menu(L.t(.newMenu, lang: lang)) {
                    Button(L.t(.newStudent, lang: lang)) { store.quickAddStudent() }

                    Button(L.t(.enrollmentFromWinterTemplate, lang: lang)) {
                        guard let sid = store.selectedStudentID ?? store.state.students.first?.id else { return }
                        let t = store.state.templates.first(where: { $0.title.contains("Winter") })
                        _ = store.addEnrollment(for: sid, from: t)
                    }

                    Button(L.t(.enrollmentFromSpringTemplate, lang: lang)) {
                        guard let sid = store.selectedStudentID ?? store.state.students.first?.id else { return }
                        let t = store.state.templates.first(where: { $0.title.contains("Spring") })
                        _ = store.addEnrollment(for: sid, from: t)
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding(12)

            Divider()

            List(selection: enrollmentSelection) {
                Section(L.t(.enrollmentsSection, lang: lang)) {
                    ForEach(filteredEnrollments) { e in
                        EnrollmentRow(e: e)
                            .tag(Optional(e.id)) // selection 是 UUID?
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var filteredEnrollments: [Enrollment] {
        // ✅ 稳定排序：title 相同时按 id 兜底，避免“删完乱跳”
        let all = store.state.enrollments.sorted {
            if $0.title != $1.title { return $0.title < $1.title }
            return $0.id.uuidString < $1.id.uuidString
        }

        let key = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key.isEmpty { return all }

        return all.filter { e in
            let studentName = store.student(by: e.studentID)?.name.lowercased() ?? ""
            return e.title.lowercased().contains(key) || studentName.contains(key)
        }
    }
}

private struct EnrollmentRow: View {
    @EnvironmentObject private var store: AppStore
    let e: Enrollment

    var body: some View {
        let lang = store.state.settings.appLanguage

        let studentName = store.student(by: e.studentID)?.name ?? "—"
        let left = store.remainingLessons(e)
        let remainAmt = store.remainingAmount(e)

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(studentName)
                    .font(.system(size: 13, weight: .semibold))
                Text(e.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Tag(text: L.f(.lessonsLeftTag, lang: lang, left), emphasis: left <= 2)
            Tag(text: TD.money(remainAmt, currencyCode: store.state.settings.currencyCode, lang: lang), emphasis: remainAmt > 0)
        }
        .padding(.vertical, 4)
    }

    private struct Tag: View {
        let text: String
        var emphasis: Bool = false
        var body: some View {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(emphasis ? Color.orange.opacity(0.18) : Color.primary.opacity(0.06))
                .cornerRadius(999)
        }
    }
}

// MARK: - Detail

struct BookingDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        if let eid = store.selectedEnrollmentID, let e = store.enrollment(by: eid) {
            EnrollmentDetailEditor(enrollment: e)
                .id(eid)
                .padding(16)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(L.t(.selectEnrollment, lang: lang))
                    .font(.system(size: 16, weight: .semibold))
                Text(L.t(.createStudentsEnrollmentsTip, lang: lang))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(16)
        }
    }
}

private struct EnrollmentDetailEditor: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: Enrollment
    @State private var showAddSession = false
    @State private var showAlert = false
    @State private var alertText = ""

    init(enrollment: Enrollment) {
        _draft = State(initialValue: enrollment)
    }

    private var windowsSorted: [DateWindow] {
        draft.windows.sorted { $0.start < $1.start }
    }

    private var selectedWindow: DateWindow? {
        guard let wid = draft.selectedWindowID else { return nil }
        return draft.windows.first(where: { $0.id == wid })
    }

    private var displayStart: Date {
        if let w = selectedWindow { return w.start }
        if let first = windowsSorted.first { return first.start }
        return draft.startDate ?? Date()
    }

    private var displayEnd: Date {
        if let w = selectedWindow { return w.end }
        if let last = windowsSorted.last { return last.end }
        return draft.endDate ?? Date()
    }

    private var startTimeDateBinding: Binding<Date> {
        let lang = store.state.settings.appLanguage
        return Binding(
            get: { TD.composeDateTime(day: Date(), hhmm: draft.timeHHmm) },
            set: { newValue in
                draft.timeHHmm = TD.timeHHmm(newValue, lang: lang)
                draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm)
            }
        )
    }

    private var endHHmmTextBinding: Binding<String> {
        Binding(
            get: { TD.endHHmm(startHHmm: draft.timeHHmm, durationMinutes: draft.durationMinutes) },
            set: { newEnd in
                let start = TD.normalizeHHmmString(draft.timeHHmm)
                let end = TD.normalizeHHmmString(newEnd)
                draft.timeHHmm = start
                draft.durationMinutes = TD.durationMinutes(startHHmm: start, endHHmm: end, min: 30, max: 300, step: 10)
            }
        )
    }

    private var endTimeDateBinding: Binding<Date> {
        let lang = store.state.settings.appLanguage
        return Binding(
            get: {
                let end = TD.endHHmm(startHHmm: draft.timeHHmm, durationMinutes: draft.durationMinutes)
                return TD.composeDateTime(day: Date(), hhmm: end)
            },
            set: { newValue in
                let end = TD.timeHHmm(newValue, lang: lang)
                let start = TD.normalizeHHmmString(draft.timeHHmm)
                draft.durationMinutes = TD.durationMinutes(startHHmm: start, endHHmm: end, min: 30, max: 300, step: 10)
            }
        )
    }

    var body: some View {
        let lang = store.state.settings.appLanguage

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                summaryCards
                enrollmentBox
                windowsBox
                weekdaysBox
                actions
                sessionsList
                Spacer(minLength: 20)
            }
        }
        .onDisappear {
            // ✅ 防复活关键：如果 enrollment 已经被删，就不要再 upsert 了
            draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm)
            if store.enrollment(by: draft.id) != nil {
                store.upsertEnrollment(draft)
            }
        }
        .alert(L.t(.resultTitle, lang: lang), isPresented: $showAlert) {
            Button(L.t(.ok, lang: lang)) {}
        } message: {
            Text(alertText)
        }
        .sheet(isPresented: $showAddSession) {
            AddSessionSheet(enrollment: draft)
        }
    }

    private var header: some View {
        let lang = store.state.settings.appLanguage
        let studentName = store.student(by: draft.studentID)?.name ?? "—"
        return VStack(alignment: .leading, spacing: 6) {
            Text(studentName).font(.system(size: 18, weight: .semibold))
            Text(L.t(.bookingCheckin, lang: lang)).foregroundStyle(.secondary)
        }
    }

    private var summaryCards: some View {
        let lang = store.state.settings.appLanguage
        let left = store.remainingLessons(draft)

        let remainValue = store.remainingAmount(draft)
        let unpaid = store.unpaidAmount(draft)
        let total = store.totalPrice(draft)
        let moneyCode = store.state.settings.currencyCode

        let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 10) {
            SummaryCard(title: L.t(.remainingLessons, lang: lang), value: "\(left)")
            SummaryCard(title: L.t(.remainingAmount, lang: lang),
                        value: TD.money(remainValue, currencyCode: moneyCode, lang: lang))
            SummaryCard(title: L.t(.unpaidAmount, lang: lang),
                        value: TD.money(unpaid, currencyCode: moneyCode, lang: lang))
            SummaryCard(title: L.t(.totalPackage, lang: lang),
                        value: TD.money(total, currencyCode: moneyCode, lang: lang))
        }
    }

    private var enrollmentBox: some View {
        let lang = store.state.settings.appLanguage
        return GroupBox(L.t(.enrollmentBox, lang: lang)) {
            VStack(alignment: .leading, spacing: 10) {
                TextField(L.t(.titleField, lang: lang), text: $draft.title)

                HStack {
                    Stepper(value: $draft.pricePerLesson, in: 0...9999) {
                        Text("\(L.t(.pricePerLessonLabel, lang: lang)): \(draft.pricePerLesson)")
                    }
                    Spacer()
                    Stepper(value: $draft.plannedLessons, in: 0...500) {
                        Text("\(L.t(.plannedLessonsLabel, lang: lang)): \(draft.plannedLessons)")
                    }
                }

                HStack {
                    Stepper(value: $draft.durationMinutes, in: 30...300, step: 10) {
                        Text("\(L.t(.durationLabel, lang: lang)): \(draft.durationMinutes) \(L.t(.minutesUnit, lang: lang))")
                    }
                    Spacer()
                    Stepper(value: $draft.totalPaid, in: 0...999999) {
                        Text("\(L.t(.totalPaidLabel, lang: lang)): \(draft.totalPaid)")
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Text(L.t(.timeHHmmLabel, lang: lang))

                    DatePicker("", selection: startTimeDateBinding, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .frame(width: 120)

                    TextField("18:30", text: $draft.timeHHmm)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .onSubmit { draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm) }

                    Spacer()

                    Toggle(L.t(.skipHolidays, lang: lang), isOn: $draft.skipHolidays)
                }

                HStack(spacing: 10) {
                    Text(lang.resolved() == .zhHans ? "结束时间" : "End")

                    DatePicker("", selection: endTimeDateBinding, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .frame(width: 120)

                    TextField("20:30", text: endHHmmTextBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    Spacer()

                    Text(TD.timeRangeString(startHHmm: draft.timeHHmm, durationMinutes: draft.durationMinutes))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text(L.t(.meetingLink, lang: lang))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextEditor(text: $draft.meetingLink)
                    .font(.system(size: 12))
                    .frame(minHeight: 90)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Button(L.t(.copy, lang: lang)) { TD.copyToPasteboard(draft.meetingLink) }
                            Button(L.t(.open, lang: lang)) { TD.openURL(draft.meetingLink) }
                        }
                        .buttonStyle(.bordered)
                        .padding(8)
                    }
            }
            .padding(10)
        }
    }

    private var windowsBox: some View {
        let lang = store.state.settings.appLanguage
        return GroupBox(L.t(.schedulingWindowsOptional, lang: lang)) {
            VStack(alignment: .leading, spacing: 10) {
                if draft.windows.isEmpty {
                    Text(L.t(.noWindowsSetTip, lang: lang))
                        .foregroundStyle(.secondary)
                } else {
                    let allTitle = (lang.resolved() == .zhHans) ? "全部日期窗口" : "All windows"

                    Button { draft.selectedWindowID = nil } label: {
                        HStack(spacing: 10) {
                            Image(systemName: draft.selectedWindowID == nil ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(draft.selectedWindowID == nil ? .blue : .secondary)
                            Text(allTitle).font(.system(size: 12, weight: .semibold))
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.vertical, 4)

                    ForEach(windowsSorted) { w in
                        Button { draft.selectedWindowID = w.id } label: {
                            HStack(spacing: 10) {
                                Image(systemName: draft.selectedWindowID == w.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(draft.selectedWindowID == w.id ? .blue : .secondary)

                                Text(w.name)
                                    .frame(width: 40, alignment: .leading)
                                    .font(.system(size: 12, weight: .semibold))

                                Text("\(TD.shortDate(w.start, lang: lang)) – \(TD.shortDate(w.end, lang: lang))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    DatePicker(L.t(.startDate, lang: lang), selection: Binding(
                        get: { draft.windows.isEmpty ? (draft.startDate ?? Date()) : displayStart },
                        set: { draft.startDate = $0 }
                    ), displayedComponents: [.date])

                    DatePicker(L.t(.endDate, lang: lang), selection: Binding(
                        get: { draft.windows.isEmpty ? (draft.endDate ?? Date()) : displayEnd },
                        set: { draft.endDate = $0 }
                    ), displayedComponents: [.date])
                }
                .disabled(!draft.windows.isEmpty)
            }
            .padding(10)
        }
    }

    private var weekdaysBox: some View {
        let lang = store.state.settings.appLanguage
        return GroupBox("\(L.t(.weekdaysTitle, lang: lang)) \(L.t(.weekdaysAnyDayTip, lang: lang))") {
            WeekdayPicker(selected: $draft.weekdays)
                .padding(10)
        }
    }

    private var actions: some View {
        let lang = store.state.settings.appLanguage

        return HStack(spacing: 10) {
            Button(L.t(.save, lang: lang)) {
                draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm)
                store.upsertEnrollment(draft)
            }
            .buttonStyle(.borderedProminent)

            Button(L.t(.addSession, lang: lang)) {
                draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm)
                showAddSession = true
            }
            .buttonStyle(.bordered)

            Button(L.t(.generateSessions, lang: lang)) {
                draft.timeHHmm = TD.normalizeHHmmString(draft.timeHHmm)
                store.upsertEnrollment(draft)

                let result = store.generateSessions(for: draft.id)
                alertText = result.exhausted
                    ? L.f(.addedSessionsExhausted, lang: lang, result.added)
                    : L.f(.addedSessions, lang: lang, result.added)
                showAlert = true
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(role: .destructive) {
                store.deleteEnrollment(draft.id)
            } label: {
                Text(L.t(.deleteEnrollment, lang: lang))
            }
        }
    }

    private var sessionsList: some View {
        let lang = store.state.settings.appLanguage
        let sessions = store.sessions(forEnrollmentID: draft.id)

        return GroupBox(L.t(.sessionsTitle, lang: lang)) {
            if sessions.isEmpty {
                Text(L.t(.noSessionsYet, lang: lang))
                    .foregroundStyle(.secondary)
                    .padding(10)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions) { ss in
                        HStack(spacing: 10) {
                            Text("\(TD.shortDate(ss.startAt, lang: lang)) \(TD.timeRange(startAt: ss.startAt, durationMinutes: ss.durationMinutes, lang: lang))")
                                .font(.system(size: 12, weight: .semibold))

                            Text(L.t(ss.status.titleKey, lang: lang))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ss.status == .attended ? Color.blue.opacity(0.18) : Color.primary.opacity(0.06))
                                .cornerRadius(999)

                            Spacer()

                            Button(ss.status == .attended ? L.t(.undo, lang: lang) : L.t(.checkIn, lang: lang)) {
                                store.toggleAttendance(ss.id)
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) { store.deleteSession(ss.id) } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(10)
                    }
                }
                .padding(10)
            }
        }
    }

    private struct SummaryCard: View {
        let title: String
        let value: String
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 14, weight: .semibold))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .cornerRadius(14)
        }
    }
}

private struct WeekdayPicker: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selected: Set<Int>

    var body: some View {
        let lang = store.state.settings.appLanguage.resolved()
        let itemsEN: [(Int, String)] = [(2,"Mon"),(3,"Tue"),(4,"Wed"),(5,"Thu"),(6,"Fri"),(7,"Sat"),(1,"Sun")]
        let itemsZH: [(Int, String)] = [(2,"周一"),(3,"周二"),(4,"周三"),(5,"周四"),(6,"周五"),(7,"周六"),(1,"周日")]
        let items = (lang == .zhHans) ? itemsZH : itemsEN

        HStack(spacing: 8) {
            ForEach(items, id: \.0) { w in
                let isOn = selected.contains(w.0)
                Button {
                    if isOn { selected.remove(w.0) } else { selected.insert(w.0) }
                } label: {
                    Text(w.1)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Color.blue.opacity(0.2) : Color.primary.opacity(0.06))
                        .cornerRadius(999)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(L.t(.clear, lang: store.state.settings.appLanguage)) { selected.removeAll() }
                .buttonStyle(.bordered)
        }
    }
}

private struct AddSessionSheet: View {
    @EnvironmentObject private var store: AppStore
    let enrollment: Enrollment

    @Environment(\.dismiss) private var dismiss
    @State private var day: Date = Date()
    @State private var hhmm: String = "18:30"
    @State private var duration: Int = 120

    private var startTimeDateBinding: Binding<Date> {
        let lang = store.state.settings.appLanguage
        return Binding(
            get: { TD.composeDateTime(day: Date(), hhmm: hhmm) },
            set: { newValue in
                hhmm = TD.timeHHmm(newValue, lang: lang)
                hhmm = TD.normalizeHHmmString(hhmm)
            }
        )
    }

    private var endTimeDateBinding: Binding<Date> {
        let lang = store.state.settings.appLanguage
        return Binding(
            get: {
                let end = TD.endHHmm(startHHmm: hhmm, durationMinutes: duration)
                return TD.composeDateTime(day: Date(), hhmm: end)
            },
            set: { newValue in
                let end = TD.timeHHmm(newValue, lang: lang)
                let start = TD.normalizeHHmmString(hhmm)
                duration = TD.durationMinutes(startHHmm: start, endHHmm: end, min: 30, max: 300, step: 10)
            }
        )
    }

    private var endHHmmTextBinding: Binding<String> {
        Binding(
            get: { TD.endHHmm(startHHmm: hhmm, durationMinutes: duration) },
            set: { newEnd in
                let start = TD.normalizeHHmmString(hhmm)
                let end = TD.normalizeHHmmString(newEnd)
                hhmm = start
                duration = TD.durationMinutes(startHHmm: start, endHHmm: end, min: 30, max: 300, step: 10)
            }
        )
    }

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(alignment: .leading, spacing: 12) {
            Text(L.t(.addSessionTitle, lang: lang))
                .font(.system(size: 16, weight: .semibold))

            DatePicker(L.t(.dateLabel, lang: lang), selection: $day, displayedComponents: [.date])

            HStack(spacing: 10) {
                Text(L.t(.timeLabel, lang: lang))

                DatePicker("", selection: startTimeDateBinding, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(width: 120)

                TextField("18:30", text: $hhmm)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .onSubmit { hhmm = TD.normalizeHHmmString(hhmm) }

                Spacer()

                Text(lang.resolved() == .zhHans ? "结束" : "End")

                DatePicker("", selection: endTimeDateBinding, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(width: 120)

                TextField("20:30", text: endHHmmTextBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }

            HStack {
                Stepper(value: $duration, in: 30...300, step: 10) {
                    Text("\(L.t(.durationLabel, lang: lang)) \(duration) \(L.t(.minutesUnit, lang: lang))")
                }
                Spacer()
                Text(TD.timeRangeString(startHHmm: hhmm, durationMinutes: duration))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(L.t(.cancel, lang: lang)) { dismiss() }
                Spacer()
                Button(L.t(.add, lang: lang)) {
                    let norm = TD.normalizeHHmmString(hhmm)
                    _ = store.addSession(studentID: enrollment.studentID,
                                         enrollmentID: enrollment.id,
                                         day: day,
                                         hhmm: norm,
                                         duration: duration)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 520)
        .onAppear {
            hhmm = TD.normalizeHHmmString(enrollment.timeHHmm)
            duration = enrollment.durationMinutes
        }
    }
}
