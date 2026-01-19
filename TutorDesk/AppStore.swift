// AppStore.swift
import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published private(set) var state: AppState = AppState()

    // UI selections
    @Published var sidebar: SidebarItem = .schedule
    @Published var selectedStudentID: UUID? = nil
    @Published var selectedEnrollmentID: UUID? = nil
    @Published var selectedSessionID: UUID? = nil
    @Published var selectedTeacherID: UUID? = nil

    private var cancellables = Set<AnyCancellable>()
    private let io = Persistence()

    init() {
        load()

        // autosave debounce
        $state
            .dropFirst()
            .debounce(for: .milliseconds(450), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    func updateState(_ mutate: (inout AppState) -> Void) {
        var s = state
        mutate(&s)
        state = s
    }

    // MARK: - Persistence

    func load() {
        if let loaded: AppState = io.load(AppState.self) {
            state = loaded
            normalizeSelections()
        } else {
            state = SeedData.makeDefault()
            normalizeSelections()
            save()
        }
    }

    func save() { io.save(state) }

    private func normalizeSelections() {
        if selectedTeacherID == nil, let t = state.teachers.first?.id {
            selectedTeacherID = t
        }
        if selectedStudentID == nil, let s = state.students.first?.id {
            selectedStudentID = s
        }
        if selectedEnrollmentID == nil, let e = state.enrollments.first?.id {
            selectedEnrollmentID = e
        }
        if selectedSessionID == nil, let ss = state.sessions.first?.id {
            selectedSessionID = ss
        }
    }

    // MARK: - Find helpers

    func teacher(by id: UUID?) -> Teacher? {
        guard let id else { return nil }
        return state.teachers.first(where: { $0.id == id })
    }

    func student(by id: UUID?) -> Student? {
        guard let id else { return nil }
        return state.students.first(where: { $0.id == id })
    }

    func enrollment(by id: UUID?) -> Enrollment? {
        guard let id else { return nil }
        return state.enrollments.first(where: { $0.id == id })
    }

    func sessions(forStudentID studentID: UUID) -> [Session] {
        state.sessions
            .filter { $0.studentID == studentID }
            .sorted { $0.startAt < $1.startAt }
    }

    func sessions(forEnrollmentID enrollmentID: UUID) -> [Session] {
        state.sessions
            .filter { $0.enrollmentID == enrollmentID }
            .sorted { $0.startAt < $1.startAt }
    }

    func sessions(on day: Date) -> [Session] {
        let d0 = TD.startOfDay(day)
        let d1 = TD.addDays(d0, 1)
        return state.sessions
            .filter { $0.startAt >= d0 && $0.startAt < d1 }
            .sorted { $0.startAt < $1.startAt }
    }

    // MARK: - Stable ordering (important for “delete then select nearby”)

    private func enrollmentLess(_ a: Enrollment, _ b: Enrollment) -> Bool {
        if a.title != b.title { return a.title < b.title }
        // 同标题时用 id 兜底，保证排序稳定，避免“乱跳”
        return a.id.uuidString < b.id.uuidString
    }

    private func orderedEnrollments(_ list: [Enrollment]) -> [Enrollment] {
        list.sorted(by: enrollmentLess(_:_:))
    }

    // MARK: - Computed business

    func usedLessons(enrollmentID: UUID) -> Int {
        sessions(forEnrollmentID: enrollmentID).filter { $0.status == .attended }.count
    }

    func plannedCount(enrollmentID: UUID) -> Int {
        sessions(forEnrollmentID: enrollmentID).filter { $0.status != .canceled }.count
    }

    func remainingLessons(_ e: Enrollment) -> Int {
        max(0, e.plannedLessons - usedLessons(enrollmentID: e.id))
    }

    func totalPrice(_ e: Enrollment) -> Int {
        e.plannedLessons * e.pricePerLesson
    }

    func remainingAmount(_ e: Enrollment) -> Int {
        let left = remainingLessons(e)
        return max(0, left * e.pricePerLesson)
    }

    func unpaidAmount(_ e: Enrollment) -> Int {
        max(0, totalPrice(e) - e.totalPaid)
    }

    // MARK: - CRUD: Teacher

    func upsertTeacher(_ t: Teacher) {
        var s = state
        if let idx = s.teachers.firstIndex(where: { $0.id == t.id }) {
            s.teachers[idx] = t
        } else {
            s.teachers.append(t)
        }
        state = s
        selectedTeacherID = t.id
    }

    // MARK: - CRUD: Student

    func addStudent(name: String) -> Student {
        var s = state
        let st = Student(name: name, teacherID: selectedTeacherID)
        s.students.append(st)
        state = s
        selectedStudentID = st.id
        sidebar = .students
        return st
    }

    func upsertStudent(_ st: Student) {
        var s = state
        if let idx = s.students.firstIndex(where: { $0.id == st.id }) {
            s.students[idx] = st
        } else {
            s.students.append(st)
        }
        state = s
    }

    /// ✅ 删除学生（你已经做得不错：就近选中 + 清理关联数据）
    func deleteStudent(_ id: UUID) {
        var s = state
        let oldStudents = s.students
        let oldIndex = oldStudents.firstIndex(where: { $0.id == id })

        let removedEnrollmentIDs = Set(s.enrollments.filter { $0.studentID == id }.map { $0.id })
        let removedSessionIDs = Set(s.sessions.filter { $0.studentID == id }.map { $0.id })

        s.students.removeAll { $0.id == id }
        s.enrollments.removeAll { $0.studentID == id }
        s.sessions.removeAll { $0.studentID == id }

        state = s

        if selectedStudentID == id {
            if s.students.isEmpty {
                selectedStudentID = nil
            } else if let oldIndex {
                let nextIndex = min(oldIndex, s.students.count - 1)
                selectedStudentID = s.students[nextIndex].id
            } else {
                selectedStudentID = s.students.first?.id
            }
        }

        if let eid = selectedEnrollmentID, removedEnrollmentIDs.contains(eid) {
            if let sid = selectedStudentID {
                selectedEnrollmentID = s.enrollments.first(where: { $0.studentID == sid })?.id
                    ?? s.enrollments.first?.id
            } else {
                selectedEnrollmentID = s.enrollments.first?.id
            }
        }

        if let sid0 = selectedSessionID, removedSessionIDs.contains(sid0) {
            if let sid = selectedStudentID {
                selectedSessionID = s.sessions.first(where: { $0.studentID == sid })?.id
                    ?? s.sessions.first?.id
            } else {
                selectedSessionID = s.sessions.first?.id
            }
        }

        if s.students.isEmpty {
            selectedStudentID = nil
            selectedEnrollmentID = nil
            selectedSessionID = nil
        }
    }

    // MARK: - CRUD: Enrollment

    private func parseTimeOption(_ option: String) -> (start: String, end: String)? {
        let text = option.trimmingCharacters(in: .whitespacesAndNewlines)
        let seps: [Character] = ["–", "-", "—", "~", "～"]
        for sep in seps {
            let parts = text.split(separator: sep).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty {
                return (TD.normalizeHHmmString(parts[0]), TD.normalizeHHmmString(parts[1]))
            }
        }
        return nil
    }

    func addEnrollment(for studentID: UUID, from template: TermTemplate? = nil) -> Enrollment {
        var s = state
        var e = Enrollment(studentID: studentID, teacherID: student(by: studentID)?.teacherID ?? selectedTeacherID)

        if let template {
            e.title = template.title
            e.pricePerLesson = template.suggestedPricePerLesson
            e.plannedLessons = template.suggestedLessons
            e.durationMinutes = template.suggestedDurationMinutes
            e.windows = template.windows
            e.skipHolidays = s.settings.skipHolidaysByDefault
            e.selectedWindowID = nil

            if let first = template.timeOptions.first, let r = parseTimeOption(first) {
                e.timeHHmm = r.start
                e.durationMinutes = TD.durationMinutes(startHHmm: r.start, endHHmm: r.end, min: 30, max: 300, step: 10)
            } else if let first = template.timeOptions.first {
                let start = first.split(separator: "–").first.map(String.init) ?? "18:30"
                e.timeHHmm = TD.normalizeHHmmString(start)
            } else {
                e.timeHHmm = "18:30"
            }
        }

        s.enrollments.append(e)
        state = s

        // ✅ 更一致：创建报名后，学生/报名都跟着切过去
        selectedStudentID = studentID
        selectedEnrollmentID = e.id
        sidebar = .booking
        return e
    }

    func upsertEnrollment(_ e: Enrollment) {
        var s = state
        if let idx = s.enrollments.firstIndex(where: { $0.id == e.id }) {
            s.enrollments[idx] = e
        } else {
            s.enrollments.append(e)
        }
        state = s
    }

    /// ✅ 关键修复：删除报名必须“稳定选中下一行”，同时清理关联 sessions，且不让 UI/selection 乱跳
    func deleteEnrollment(_ id: UUID) {
        var s = state

        // 先用 UI 同样的排序拿到“删除前顺序”，这样才能“就近选中”
        let oldOrdered = orderedEnrollments(s.enrollments)
        let oldIndex = oldOrdered.firstIndex(where: { $0.id == id })

        let removedSessionIDs = Set(s.sessions.filter { $0.enrollmentID == id }.map { $0.id })

        // 真删除
        s.enrollments.removeAll { $0.id == id }
        s.sessions.removeAll { $0.enrollmentID == id }
        state = s

        // 处理 enrollment selection（就近、稳定）
        if selectedEnrollmentID == id {
            let newOrdered = orderedEnrollments(s.enrollments)
            if newOrdered.isEmpty {
                selectedEnrollmentID = nil
            } else if let oldIndex {
                let idx = min(oldIndex, newOrdered.count - 1) // 删除当前行后，选中“原位置的下一行/就近行”
                selectedEnrollmentID = newOrdered[idx].id
            } else {
                selectedEnrollmentID = newOrdered.first?.id
            }
        }

        // 同步 student selection（避免“我在看 A 的报名，但 selectedStudent 还是 B”）
        if let eid = selectedEnrollmentID, let e = enrollment(by: eid) {
            selectedStudentID = e.studentID
        }

        // 处理 session selection（如果选中的 session 属于被删报名，就切到新报名的第一节课或置空）
        if let sid = selectedSessionID, removedSessionIDs.contains(sid) {
            if let eid = selectedEnrollmentID {
                selectedSessionID = state.sessions.first(where: { $0.enrollmentID == eid })?.id
                    ?? state.sessions.first?.id
            } else {
                selectedSessionID = state.sessions.first?.id
            }
        }

        if state.sessions.isEmpty {
            selectedSessionID = nil
        }
    }

    // MARK: - CRUD: Session

    func addSession(studentID: UUID, enrollmentID: UUID?, day: Date, hhmm: String, duration: Int) -> Session {
        var s = state
        let start = TD.composeDateTime(day: day, hhmm: hhmm)
        let teacherID = enrollmentID.flatMap { enrollment(by: $0)?.teacherID }
            ?? student(by: studentID)?.teacherID
            ?? selectedTeacherID

        let session = Session(
            studentID: studentID,
            teacherID: teacherID,
            enrollmentID: enrollmentID,
            startAt: start,
            durationMinutes: duration,
            status: .planned,
            meetingLink: enrollmentID.flatMap { enrollment(by: $0)?.meetingLink } ?? ""
        )
        s.sessions.append(session)
        state = s
        selectedSessionID = session.id
        return session
    }

    func upsertSession(_ ss: Session) {
        var s = state
        if let idx = s.sessions.firstIndex(where: { $0.id == ss.id }) {
            s.sessions[idx] = ss
        } else {
            s.sessions.append(ss)
        }
        state = s
    }

    func deleteSession(_ id: UUID) {
        var s = state
        s.sessions.removeAll { $0.id == id }
        state = s
        if selectedSessionID == id { selectedSessionID = s.sessions.first?.id }
        if s.sessions.isEmpty { selectedSessionID = nil }
    }

    func toggleAttendance(_ id: UUID) {
        guard var ss = state.sessions.first(where: { $0.id == id }) else { return }
        ss.status = (ss.status == .attended) ? .planned : .attended
        upsertSession(ss)
    }

    // MARK: - Scheduling: Holiday

    func isHolidayBlocked(_ day: Date) -> Bool {
        let d = TD.startOfDay(day)
        for r in state.settings.holidayRanges {
            let a = TD.startOfDay(r.start)
            let b = TD.startOfDay(r.end)
            if d >= a && d <= b { return true }
        }
        return false
    }

    // MARK: - Scheduling: Generator

    func generateSessions(for enrollmentID: UUID) -> (added: Int, exhausted: Bool) {
        guard let e = enrollment(by: enrollmentID) else { return (0, true) }

        let already = sessions(forEnrollmentID: enrollmentID).count
        if already >= e.plannedLessons { return (0, false) }

        let need = e.plannedLessons - already
        let duration = e.durationMinutes
        let hhmm = e.timeHHmm

        var ranges: [(Date, Date)] = []
        if !e.windows.isEmpty {
            if let wid = e.selectedWindowID,
               let w = e.windows.first(where: { $0.id == wid }) {
                ranges = [(TD.startOfDay(w.start), TD.startOfDay(w.end))]
            } else {
                ranges = e.windows.map { (TD.startOfDay($0.start), TD.startOfDay($0.end)) }
            }
        } else if let s = e.startDate, let t = e.endDate {
            ranges = [(TD.startOfDay(s), TD.startOfDay(t))]
        } else {
            return (0, true)
        }

        var added: [Session] = []
        var remaining = need

        for (start, end) in ranges {
            var day = start
            while day <= end && remaining > 0 {
                let weekday = TD.calendar.component(.weekday, from: day) // 1..7
                let matchesWeekday = e.weekdays.isEmpty ? true : e.weekdays.contains(weekday)

                if matchesWeekday {
                    let blocked = e.skipHolidays ? isHolidayBlocked(day) : false
                    if !blocked {
                        let stID = e.studentID
                        let tID = e.teacherID ?? student(by: stID)?.teacherID ?? selectedTeacherID
                        let startAt = TD.composeDateTime(day: day, hhmm: hhmm)

                        let ss = Session(
                            studentID: stID,
                            teacherID: tID,
                            enrollmentID: e.id,
                            startAt: startAt,
                            durationMinutes: duration,
                            status: .planned,
                            meetingLink: e.meetingLink
                        )
                        added.append(ss)
                        remaining -= 1
                    }
                }

                day = TD.addDays(day, 1)
            }
            if remaining == 0 { break }
        }

        var s = state
        s.sessions.append(contentsOf: added)
        state = s

        return (added.count, remaining > 0)
    }

    // MARK: - Quick actions

    func quickAddStudent() {
        _ = addStudent(name: "New Student")
    }

    func quickAddSessionForSelection() {
        guard let sid = selectedStudentID else {
            sidebar = .students
            return
        }
        let today = Date()
        _ = addSession(studentID: sid, enrollmentID: selectedEnrollmentID, day: today, hhmm: "18:30", duration: 120)
        sidebar = .booking
    }
}

// =====================================================
// MARK: - Persistence (Application Support JSON)
// =====================================================

final class Persistence {
    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("TutorDesk", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("data.json")
    }

    func load<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

// =====================================================
// MARK: - SeedData (Default templates + holidays)
// =====================================================

enum SeedData {
    static func makeDefault() -> AppState {
        var st = AppState()

        let teacher = Teacher(
            displayName: "Shuxin Cao",
            headline: "TutorDesk · Lead Instructor",
            bio: """
Hello! This is your teacher profile.

• 5+ years teaching experience
• Math + Programming (OI / NOIP / GESP)
• Online sessions + personalized plans

Edit this section like a personal blog.
""",
            contact: ""
        )
        st.teachers = [teacher]
        st.settings.skipHolidaysByDefault = true
        st.settings.currencyCode = "CNY"

        st.settings.holidayRanges = [
            HolidayRange(name: "元旦", start: TD.makeDate(y: 2026, m: 1, d: 1), end: TD.makeDate(y: 2026, m: 1, d: 3)),
            HolidayRange(name: "春节", start: TD.makeDate(y: 2026, m: 2, d: 15), end: TD.makeDate(y: 2026, m: 2, d: 23)),
            HolidayRange(name: "清明节", start: TD.makeDate(y: 2026, m: 4, d: 4), end: TD.makeDate(y: 2026, m: 4, d: 6)),
            HolidayRange(name: "劳动节", start: TD.makeDate(y: 2026, m: 5, d: 1), end: TD.makeDate(y: 2026, m: 5, d: 5)),
            HolidayRange(name: "端午节", start: TD.makeDate(y: 2026, m: 6, d: 19), end: TD.makeDate(y: 2026, m: 6, d: 21)),
            HolidayRange(name: "中秋节", start: TD.makeDate(y: 2026, m: 9, d: 25), end: TD.makeDate(y: 2026, m: 9, d: 27)),
            HolidayRange(name: "国庆节", start: TD.makeDate(y: 2026, m: 10, d: 1), end: TD.makeDate(y: 2026, m: 10, d: 7))
        ]

        let winterWindows: [DateWindow] = [
            DateWindow(name: "一期", start: TD.makeDate(y: 2026, m: 1, d: 23), end: TD.makeDate(y: 2026, m: 1, d: 29)),
            DateWindow(name: "二期", start: TD.makeDate(y: 2026, m: 1, d: 31), end: TD.makeDate(y: 2026, m: 2, d: 6)),
            DateWindow(name: "三期", start: TD.makeDate(y: 2026, m: 2, d: 8), end: TD.makeDate(y: 2026, m: 2, d: 14)),
            DateWindow(name: "四期", start: TD.makeDate(y: 2026, m: 2, d: 22), end: TD.makeDate(y: 2026, m: 2, d: 28))
        ]

        let winter = TermTemplate(
            title: "Winter Break 2026",
            subtitle: "4 windows · choose your time slot",
            windows: winterWindows,
            timeOptions: [
                "08:30–10:30",
                "10:40–12:40",
                "13:30–15:30",
                "15:50–17:50",
                "18:30–20:30"
            ],
            weekdayAvailability: [],
            suggestedLessons: 7,
            suggestedPricePerLesson: 220,
            suggestedDurationMinutes: 120
        )

        let spring = TermTemplate(
            title: "Spring 2026",
            subtitle: "weekly availability (start date TBD)",
            windows: [],
            timeOptions: [],
            weekdayAvailability: [
                WeekdayAvailability(weekday: 2, timeRanges: ["18:30–20:30"], note: "可灵活调整", status: "暂时空闲"),
                WeekdayAvailability(weekday: 3, timeRanges: ["18:30–20:30"], note: "可灵活调整", status: "暂时空闲"),
                WeekdayAvailability(weekday: 4, timeRanges: ["18:30–20:30"], note: "可灵活调整", status: "暂时空闲"),
                WeekdayAvailability(weekday: 1, timeRanges: ["08:30–10:30", "18:30–20:30"], note: "可灵活调整", status: "暂时空闲")
            ],
            suggestedLessons: 17,
            suggestedPricePerLesson: 220,
            suggestedDurationMinutes: 120
        )

        st.templates = [winter, spring]

        let sampleStudent = Student(
            name: "Demo Student",
            grade: "G8",
            notes: "You can delete this.",
            teacherID: teacher.id
        )
        st.students = [sampleStudent]

        st.enrollments = [
            Enrollment(
                studentID: sampleStudent.id,
                teacherID: teacher.id,
                title: "Winter Break 2026",
                pricePerLesson: 220,
                plannedLessons: 7,
                totalPaid: 0,
                durationMinutes: 120,
                windows: winterWindows,
                startDate: nil,
                endDate: nil,
                selectedWindowID: nil,
                weekdays: [],
                timeHHmm: "18:30",
                meetingLink: "",
                skipHolidays: true
            )
        ]

        return st
    }
}
