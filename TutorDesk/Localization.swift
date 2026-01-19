import Foundation

enum LKey: String {
    // Sidebar / Tabs
    case schedule, booking, students, teacher, settings

    // Common
    case general, dataLocalTip
    case language, followSystem, langChinese, langEnglish
    case rules, skipHolidaysByDefault

    case ok, cancel, add, delete, save, newMenu

    // Holidays
    case holidayRangesBlocked, noHolidayRanges, addRange
    case addHolidayRange, name, start, end

    // Import/Export
    case importExportReserved, exportSoon, importSoon, reservedTip

    // App Commands
    case cmdNewStudent, cmdNewSession

    // Schedule
    case calendarTab, templatesTab, today
    case quickSummary, noUpcomingSessionsTip
    case noSessionsOnThisDay
    case markAsPlanned, checkInAttended
    case windowsLabel, timeOptionsLabel, weeklyAvailabilityLabel
    case lessonsCountTag, minutesCountTag, pricePerLessonTag

    // Session Status
    case statusPlanned, statusAttended, statusMissed, statusCanceled

    // Booking list + search
    case searchStudentEnrollment
    case newStudent
    case enrollmentFromWinterTemplate, enrollmentFromSpringTemplate
    case enrollmentsSection
    case selectEnrollment
    case createStudentsEnrollmentsTip

    // Booking detail
    case bookingCheckin
    case enrollmentBox
    case titleField
    case pricePerLessonLabel
    case plannedLessonsLabel
    case durationLabel
    case minutesUnit
    case totalPaidLabel
    case timeHHmmLabel
    case skipHolidays
    case meetingLink
    case copy, open

    // Windows / weekdays
    case schedulingWindowsOptional
    case noWindowsSetTip
    case startDate, endDate
    case weekdaysTitle
    case weekdaysAnyDayTip
    case clear

    // Actions
    case addSession, generateSessions, deleteEnrollment
    case sessionsTitle, noSessionsYet
    case undo, checkIn

    // Summary cards
    case remainingLessons, remainingAmount, unpaidAmount, totalPackage
    case lessonsLeftTag

    // Add session sheet
    case addSessionTitle
    case dateLabel
    case timeLabel

    // Alerts
    case resultTitle
    case addedSessions
    case addedSessionsExhausted

    // Students
    case searchStudents
    case archived
    case selectStudent
    case createStudentsInLeftTip
    case studentTitle
    case grade
    case notes
    case teacherBinding
    case teacherLabel
    case noEnrollmentsYet
    case addEnrollment
    case fromTemplateFmt
    case blank
    case enrollmentSummaryFmt

    // Teacher
    case teacherProfileTitle
    case noTeacherSelected
    case createOrSelectTeacherTip
    case displayName
    case headline
    case bioTitle
    case bioHint
    case contact
}

struct L {
    static func t(_ key: LKey, lang: AppLanguage) -> String {
        let lang = lang.resolved()
        switch lang {
        case .zhHans:
            return zh[key] ?? en[key] ?? key.rawValue
        case .en, .system:
            return en[key] ?? key.rawValue
        }
    }

    static func f(_ key: LKey, lang: AppLanguage, _ args: CVarArg...) -> String {
        let fmt = t(key, lang: lang)
        return String(format: fmt, arguments: args)
    }

    private static let en: [LKey: String] = [
        .schedule: "Schedule",
        .booking: "Booking",
        .students: "Students",
        .teacher: "Teacher",
        .settings: "Settings",

        .general: "General",
        .dataLocalTip: "Data is stored locally (Application Support/TutorDesk/data.json).",

        .language: "Language",
        .followSystem: "Follow System",
        .langChinese: "Chinese",
        .langEnglish: "English",

        .rules: "Rules",
        .skipHolidaysByDefault: "Skip holidays by default (new enrollments)",

        .ok: "OK",
        .cancel: "Cancel",
        .add: "Add",
        .delete: "Delete",
        .save: "Save",
        .newMenu: "New",

        .holidayRangesBlocked: "Holiday Ranges (blocked)",
        .noHolidayRanges: "No holiday ranges.",
        .addRange: "Add Range",
        .addHolidayRange: "Add Holiday Range",
        .name: "Name",
        .start: "Start",
        .end: "End",

        .importExportReserved: "Import / Export (entry reserved)",
        .exportSoon: "Export Data… (Coming Soon)",
        .importSoon: "Import Data… (Coming Soon)",
        .reservedTip: "We keep these entries from day 1 so users can find them easily later.",

        .cmdNewStudent: "New Student",
        .cmdNewSession: "New Session",

        .calendarTab: "Calendar",
        .templatesTab: "Templates",
        .today: "Today",
        .quickSummary: "Quick Summary",
        .noUpcomingSessionsTip: "No upcoming sessions. Add sessions in Booking.",
        .noSessionsOnThisDay: "No sessions on this day.",
        .markAsPlanned: "Mark as Planned",
        .checkInAttended: "Check-in (Attended)",
        .windowsLabel: "Windows",
        .timeOptionsLabel: "Time Options",
        .weeklyAvailabilityLabel: "Weekly Availability",
        .lessonsCountTag: "%d lessons",
        .minutesCountTag: "%d min",
        .pricePerLessonTag: "¥%d/lesson",

        .statusPlanned: "PLANNED",
        .statusAttended: "ATTENDED",
        .statusMissed: "MISSED",
        .statusCanceled: "CANCELED",

        .searchStudentEnrollment: "Search student / enrollment",
        .newStudent: "Student",
        .enrollmentFromWinterTemplate: "Enrollment from Winter Template",
        .enrollmentFromSpringTemplate: "Enrollment from Spring Template",
        .enrollmentsSection: "Enrollments",
        .selectEnrollment: "Select an enrollment",
        .createStudentsEnrollmentsTip: "Create students and enrollments first, then generate sessions and check-in here.",

        .bookingCheckin: "Booking & Check-in",
        .enrollmentBox: "Enrollment",
        .titleField: "Title",
        .pricePerLessonLabel: "Price/lesson",
        .plannedLessonsLabel: "Planned lessons",
        .durationLabel: "Duration",
        .minutesUnit: "min",
        .totalPaidLabel: "Total paid",
        .timeHHmmLabel: "Time (HH:mm)",
        .skipHolidays: "Skip holidays",
        .meetingLink: "Meeting link",
        .copy: "Copy",
        .open: "Open",

        .schedulingWindowsOptional: "Scheduling Windows (optional)",
        .noWindowsSetTip: "No windows set. You can use start/end date instead, or copy from Winter template.",
        .startDate: "Start",
        .endDate: "End",

        .weekdaysTitle: "Weekdays",
        .weekdaysAnyDayTip: "(empty = any day within window)",
        .clear: "Clear",

        .addSession: "Add Session",
        .generateSessions: "Generate Sessions",
        .deleteEnrollment: "Delete Enrollment",
        .sessionsTitle: "Sessions",
        .noSessionsYet: "No sessions yet. Add or generate.",
        .undo: "Undo",
        .checkIn: "Check-in",

        .remainingLessons: "Remaining Lessons",
        .remainingAmount: "Remaining Value",
        .unpaidAmount: "Unpaid Amount",
        .totalPackage: "Total Package",
        .lessonsLeftTag: "%d left",

        .addSessionTitle: "Add Session",
        .dateLabel: "Date",
        .timeLabel: "Time (HH:mm)",

        .resultTitle: "Result",
        .addedSessions: "Added %d sessions.",
        .addedSessionsExhausted: "Added %d sessions. (Not enough valid days to reach planned lessons — please adjust range/weekdays.)",

        .searchStudents: "Search students",
        .archived: "Archived",
        .selectStudent: "Select a student",
        .createStudentsInLeftTip: "Create students in the left column.",
        .studentTitle: "Student",
        .grade: "Grade",
        .notes: "Notes",
        .teacherBinding: "Teacher Binding",
        .teacherLabel: "Teacher",
        .noEnrollmentsYet: "No enrollments yet.",
        .addEnrollment: "Add Enrollment",
        .fromTemplateFmt: "From %@",
        .blank: "Blank",
        .enrollmentSummaryFmt: "%d lessons left · %@ due",

        .teacherProfileTitle: "Teacher Profile",
        .noTeacherSelected: "No teacher selected",
        .createOrSelectTeacherTip: "Create or select a teacher in the left column.",
        .displayName: "Display Name",
        .headline: "Headline",
        .bioTitle: "Bio (like a personal blog)",
        .bioHint: "Edit this section like a personal blog.",
        .contact: "Contact"
    ]

    private static let zh: [LKey: String] = [
        .schedule: "课表",
        .booking: "排课",
        .students: "学员",
        .teacher: "主讲老师",
        .settings: "设置",

        .general: "通用",
        .dataLocalTip: "数据仅保存在本机（Application Support/TutorDesk/data.json）。",

        .language: "语言",
        .followSystem: "跟随系统",
        .langChinese: "中文",
        .langEnglish: "英文",

        .rules: "规则",
        .skipHolidaysByDefault: "默认避开法定节假日（新建报名）",

        .ok: "确定",
        .cancel: "取消",
        .add: "添加",
        .delete: "删除",
        .save: "保存",
        .newMenu: "新建",

        .holidayRangesBlocked: "禁排日期段（节假日）",
        .noHolidayRanges: "暂无禁排日期段。",
        .addRange: "新增日期段",
        .addHolidayRange: "新增禁排日期段",
        .name: "名称",
        .start: "开始",
        .end: "结束",

        .importExportReserved: "导入 / 导出（入口预留）",
        .exportSoon: "导出数据（即将支持）",
        .importSoon: "导入数据（即将支持）",
        .reservedTip: "我们从第一版就保留入口，后续上线功能用户更容易找到。",

        .cmdNewStudent: "新建学员",
        .cmdNewSession: "新建课次",

        .calendarTab: "日历",
        .templatesTab: "模板",
        .today: "今天",
        .quickSummary: "摘要",
        .noUpcomingSessionsTip: "近期无课次。请在「排课」中新增课次。",
        .noSessionsOnThisDay: "当天暂无课次。",
        .markAsPlanned: "标记为未签到",
        .checkInAttended: "签到（已上课）",
        .windowsLabel: "时间窗口",
        .timeOptionsLabel: "时间段可选",
        .weeklyAvailabilityLabel: "每周可选时间",
        .lessonsCountTag: "%d 节课",
        .minutesCountTag: "%d 分钟",
        .pricePerLessonTag: "¥%d/节",

        .statusPlanned: "计划",
        .statusAttended: "已上课",
        .statusMissed: "缺课",
        .statusCanceled: "取消",

        .searchStudentEnrollment: "搜索学员 / 报名阶段",
        .newStudent: "学员",
        .enrollmentFromWinterTemplate: "从寒假模板新建报名",
        .enrollmentFromSpringTemplate: "从春季模板新建报名",
        .enrollmentsSection: "报名阶段",
        .selectEnrollment: "请选择一个报名阶段",
        .createStudentsEnrollmentsTip: "先创建学员与报名阶段，然后在这里生成课次并进行签到。",

        .bookingCheckin: "排课与签到",
        .enrollmentBox: "报名信息",
        .titleField: "标题",
        .pricePerLessonLabel: "单价/节",
        .plannedLessonsLabel: "计划节数",
        .durationLabel: "时长",
        .minutesUnit: "分钟",
        .totalPaidLabel: "已收金额",
        .timeHHmmLabel: "上课时间（HH:mm）",
        .skipHolidays: "避开节假日",
        .meetingLink: "腾讯会议链接",
        .copy: "复制",
        .open: "打开",

        .schedulingWindowsOptional: "上课日期窗口（可选）",
        .noWindowsSetTip: "未设置窗口。你可以用开始/结束日期，或从寒假模板复制。",
        .startDate: "开始日期",
        .endDate: "结束日期",

        .weekdaysTitle: "每周上课日",
        .weekdaysAnyDayTip: "（为空表示窗口内任意日）",
        .clear: "清空",

        .addSession: "新增课次",
        .generateSessions: "生成课次",
        .deleteEnrollment: "删除报名",
        .sessionsTitle: "课次列表",
        .noSessionsYet: "暂无课次，可手动新增或生成。",
        .undo: "撤销",
        .checkIn: "签到",

        .remainingLessons: "剩余课时",
        .remainingAmount: "剩余金额",
        .unpaidAmount: "未收金额",
        .totalPackage: "套餐总额",
        .lessonsLeftTag: "剩余 %d 节",

        .addSessionTitle: "新增课次",
        .dateLabel: "日期",
        .timeLabel: "时间（HH:mm）",

        .resultTitle: "结果",
        .addedSessions: "已添加 %d 节课。",
        .addedSessionsExhausted: "已添加 %d 节课。（可排日期不足以达到计划节数，请调整日期范围/每周上课日。）",

        .searchStudents: "搜索学员",
        .archived: "已归档",
        .selectStudent: "请选择学员",
        .createStudentsInLeftTip: "请在左侧创建学员。",
        .studentTitle: "学员信息",
        .grade: "年级",
        .notes: "备注",
        .teacherBinding: "授课老师绑定",
        .teacherLabel: "授课老师",
        .noEnrollmentsYet: "暂无报名阶段。",
        .addEnrollment: "新增报名",
        .fromTemplateFmt: "来自 %@",
        .blank: "空白报名",
        .enrollmentSummaryFmt: "剩余 %d 节 · 待补 %@",

        .teacherProfileTitle: "老师主页",
        .noTeacherSelected: "未选择老师",
        .createOrSelectTeacherTip: "请在左侧创建或选择一位老师。",
        .displayName: "显示名称",
        .headline: "头衔",
        .bioTitle: "简介（类似个人博客）",
        .bioHint: "可像写博客一样编辑这一段。",
        .contact: "联系方式"
    ]
}
