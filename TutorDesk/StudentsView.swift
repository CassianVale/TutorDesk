import SwiftUI

// =====================================================
// MARK: - StudentsView (List)
// =====================================================

struct StudentsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search: String = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        let lang = store.state.settings.appLanguage
        let resolved = lang.resolved()

        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField(L.t(.searchStudents, lang: lang), text: $search)
                    .textFieldStyle(.roundedBorder)

                Button(L.t(.newMenu, lang: lang)) {
                    store.quickAddStudent()
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text(resolved == .zhHans ? "删除" : "Delete")
                }
                .buttonStyle(.bordered)
                .disabled(store.selectedStudentID == nil)
            }
            .padding(12)

            Divider()

            List(selection: $store.selectedStudentID) {
                ForEach(filteredStudents) { st in
                    StudentRow(student: st)
                        .tag(st.id)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteStudent(st.id)
                            } label: {
                                Text(resolved == .zhHans ? "删除学员" : "Delete Student")
                            }
                        }
                }
                .onDelete(perform: deleteStudents)
            }
            .listStyle(.inset)

            #if os(macOS)
            .onDeleteCommand {
                if let id = store.selectedStudentID {
                    store.deleteStudent(id)
                }
            }
            #endif
        }
        .alert(resolved == .zhHans ? "确认删除学员？" : "Delete Student?", isPresented: $showDeleteConfirm) {
            Button(resolved == .zhHans ? "取消" : "Cancel", role: .cancel) {}
            Button(resolved == .zhHans ? "删除" : "Delete", role: .destructive) {
                if let id = store.selectedStudentID {
                    store.deleteStudent(id)
                }
            }
        } message: {
            Text(resolved == .zhHans ? "将同时删除该学员的报名与课次记录，且不可恢复。" : "This will also remove enrollments and sessions. This cannot be undone.")
        }
    }

    private func deleteStudents(at offsets: IndexSet) {
        // ✅ 不用 compactMap，避免 ElementOfResult 推断失败
        var ids: [UUID] = []
        for idx in offsets {
            if idx >= 0 && idx < filteredStudents.count {
                ids.append(filteredStudents[idx].id)
            }
        }
        for id in ids {
            store.deleteStudent(id)
        }
    }

    /// ✅ 不按 name 排序：避免改名时列表重排导致“像是删错人/跳动”
    private var filteredStudents: [Student] {
        let all = store.state.students
        let k = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if k.isEmpty { return all }
        return all.filter { st in
            st.name.lowercased().contains(k)
            || st.grade.lowercased().contains(k)
            || st.notes.lowercased().contains(k)
        }
    }
}

private struct StudentRow: View {
    @EnvironmentObject private var store: AppStore
    let student: Student

    var body: some View {
        let lang = store.state.settings.appLanguage

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.system(size: 13, weight: .semibold))

                if !student.grade.isEmpty {
                    Text(student.grade)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if student.isArchived {
                Text(L.t(.archived, lang: lang))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// =====================================================
// MARK: - StudentDetailView (Right panel)
// =====================================================

struct StudentDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        if let id = store.selectedStudentID, let st = store.student(by: id) {
            StudentEditor(student: st)
                .id(st.id) // ✅ 切换选中时重建编辑器，避免 draft 粘住旧人
                .padding(16)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.t(.selectStudent, lang: lang))
                    .font(.system(size: 16, weight: .semibold))
                Text(L.t(.createStudentsInLeftTip, lang: lang))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(16)
        }
    }
}

private struct StudentEditor: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: Student

    init(student: Student) {
        _draft = State(initialValue: student)
    }

    /// ✅ 防“删了又回来”：如果 student 已不存在，绝不再 upsert
    private func persistIfStillExists() {
        guard store.student(by: draft.id) != nil else { return }
        store.upsertStudent(draft)
    }

    var body: some View {
        let lang = store.state.settings.appLanguage

        let enrollments = store.state.enrollments
            .filter { $0.studentID == draft.id }
            .sorted { $0.title < $1.title }

        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L.t(.studentTitle, lang: lang))
                    .font(.system(size: 16, weight: .semibold))

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField(L.t(.name, lang: lang), text: $draft.name)
                            .onChange(of: draft.name) { _, _ in persistIfStillExists() }

                        TextField(L.t(.grade, lang: lang), text: $draft.grade)
                            .onChange(of: draft.grade) { _, _ in persistIfStillExists() }

                        Toggle(L.t(.archived, lang: lang), isOn: $draft.isArchived)
                            .onChange(of: draft.isArchived) { _, _ in persistIfStillExists() }

                        Divider()

                        Text(L.t(.notes, lang: lang))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 120)
                            .onChange(of: draft.notes) { _, _ in persistIfStillExists() }
                    }
                    .padding(10)
                }

                GroupBox(L.t(.teacherBinding, lang: lang)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker(L.t(.teacherLabel, lang: lang), selection: Binding<UUID?>(
                            get: { draft.teacherID ?? store.selectedTeacherID },
                            set: { v in
                                draft.teacherID = v
                                persistIfStillExists()
                            }
                        )) {
                            ForEach(store.state.teachers) { t in
                                Text(t.displayName).tag(t.id as UUID?)
                            }
                        }
                    }
                    .padding(10)
                }

                GroupBox(L.t(.enrollmentsSection, lang: lang)) {
                    VStack(alignment: .leading, spacing: 10) {
                        if enrollments.isEmpty {
                            Text(L.t(.noEnrollmentsYet, lang: lang))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(enrollments) { e in
                                Button {
                                    store.selectedEnrollmentID = e.id
                                    store.sidebar = .booking
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(e.title)
                                                .font(.system(size: 13, weight: .semibold))

                                            let summary = L.f(
                                                .enrollmentSummaryFmt,
                                                lang: lang,
                                                store.remainingLessons(e),
                                                TD.money(store.remainingAmount(e),
                                                         currencyCode: store.state.settings.currencyCode,
                                                         lang: lang)
                                            )

                                            Text(summary)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.03))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()

                        Menu(L.t(.addEnrollment, lang: lang)) {
                            ForEach(store.state.templates) { t in
                                Button(L.f(.fromTemplateFmt, lang: lang, t.title)) {
                                    _ = store.addEnrollment(for: draft.id, from: t)
                                }
                            }
                            Button(L.t(.blank, lang: lang)) {
                                _ = store.addEnrollment(for: draft.id, from: nil)
                            }
                        }
                        .menuStyle(.borderlessButton)
                    }
                    .padding(10)
                }

                Spacer(minLength: 20)
            }
        }
        // ✅ 切记：不要在 onDisappear 再 upsert（那会导致“删了又回来”）
    }
}
