// Models.swift
import Foundation

// MARK: - App Language

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Hashable {
    case system
    case zhHans
    case en

    var id: String { rawValue }

    func resolved() -> AppLanguage {
        if self != .system { return self }
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        if code.hasPrefix("zh") { return .zhHans }
        return .en
    }
}

// MARK: - Core Models

enum SidebarItem: String, Codable, CaseIterable, Identifiable {
    case schedule, booking, students, teacher, settings
    var id: String { rawValue }

    var titleKey: LKey {
        switch self {
        case .schedule: return .schedule
        case .booking: return .booking
        case .students: return .students
        case .teacher: return .teacher
        case .settings: return .settings
        }
    }

    var icon: String {
        switch self {
        case .schedule: return "calendar"
        case .booking: return "slider.horizontal.3"
        case .students: return "person.2"
        case .teacher: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}

enum SessionStatus: String, Codable, CaseIterable, Identifiable {
    case planned, attended, missed, canceled
    var id: String { rawValue }

    var titleKey: LKey {
        switch self {
        case .planned: return .statusPlanned
        case .attended: return .statusAttended
        case .missed: return .statusMissed
        case .canceled: return .statusCanceled
        }
    }
}

struct Teacher: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var displayName: String = "Primary Teacher"
    var headline: String = "Math & Programming Coach"
    var bio: String = "Edit your story here.\n\n- 5+ years teaching\n- OI / NOIP / GESP\n- Online classes"
    var contact: String = ""
}

struct Student: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var grade: String = ""
    var notes: String = ""
    var teacherID: UUID? = nil
    var isArchived: Bool = false
}

struct Enrollment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var studentID: UUID
    var teacherID: UUID?

    var title: String = "Phase"
    var pricePerLesson: Int = 220
    var plannedLessons: Int = 12
    var totalPaid: Int = 0

    var durationMinutes: Int = 120

    var windows: [DateWindow] = []
    var startDate: Date? = nil
    var endDate: Date? = nil

    var selectedWindowID: UUID? = nil

    var weekdays: Set<Int> = []               // 1=Sun ... 7=Sat

    var timeHHmm: String = "18:30"            // start
    var endHHmm: String = ""                 // end（空=按 duration 自动算）

    var meetingLink: String = ""
    var skipHolidays: Bool = true
}

struct Session: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var studentID: UUID
    var teacherID: UUID?
    var enrollmentID: UUID?

    var startAt: Date
    var durationMinutes: Int = 120
    var status: SessionStatus = .planned

    var meetingLink: String = ""
    var notes: String = ""
}

struct DateWindow: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var start: Date
    var end: Date
}

struct TermTemplate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String

    var windows: [DateWindow] = []
    var timeOptions: [String] = []
    var weekdayAvailability: [WeekdayAvailability] = []

    var suggestedLessons: Int = 12
    var suggestedPricePerLesson: Int = 220
    var suggestedDurationMinutes: Int = 120
}

struct WeekdayAvailability: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var weekday: Int // 1..7
    var timeRanges: [String]
    var note: String = "Flexible"
    var status: String = "Available"
}

struct HolidayRange: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var start: Date
    var end: Date
}

struct AppSettings: Codable, Hashable {
    var currencyCode: String = "CNY"
    var accentHex: String = "#2A7BFF"
    var skipHolidaysByDefault: Bool = true

    var appLanguage: AppLanguage = .zhHans

    var exportEnabled: Bool = false
    var importEnabled: Bool = false

    var holidayRanges: [HolidayRange] = []
}

struct AppState: Codable, Hashable {
    var teachers: [Teacher] = []
    var students: [Student] = []
    var enrollments: [Enrollment] = []
    var sessions: [Session] = []

    var templates: [TermTemplate] = []
    var settings: AppSettings = AppSettings()
}
