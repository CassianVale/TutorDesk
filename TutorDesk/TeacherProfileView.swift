import SwiftUI

struct TeacherProfileView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List(selection: $store.selectedTeacherID) {
            ForEach(store.state.teachers) { t in
                VStack(alignment: .leading, spacing: 4) {
                    Text(t.displayName).font(.system(size: 13, weight: .semibold))
                    Text(t.headline).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .tag(Optional(t.id))
            }
        }
        .listStyle(.inset)
    }
}

struct TeacherDetailView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft: Teacher? = nil

    var body: some View {
        let lang = store.state.settings.appLanguage

        if let id = store.selectedTeacherID, let t = store.teacher(by: id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L.t(.teacherProfileTitle, lang: lang))
                        .font(.system(size: 16, weight: .semibold))

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField(L.t(.displayName, lang: lang), text: Binding(
                                get: { draft?.displayName ?? t.displayName },
                                set: { v in var x = draft ?? t; x.displayName = v; draft = x; store.upsertTeacher(x) }
                            ))

                            TextField(L.t(.headline, lang: lang), text: Binding(
                                get: { draft?.headline ?? t.headline },
                                set: { v in var x = draft ?? t; x.headline = v; draft = x; store.upsertTeacher(x) }
                            ))

                            Text(L.t(.bioTitle, lang: lang))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            TextEditor(text: Binding(
                                get: { draft?.bio ?? t.bio },
                                set: { v in var x = draft ?? t; x.bio = v; draft = x; store.upsertTeacher(x) }
                            ))
                            .frame(minHeight: 240)

                            TextField(L.t(.contact, lang: lang), text: Binding(
                                get: { draft?.contact ?? t.contact },
                                set: { v in var x = draft ?? t; x.contact = v; draft = x; store.upsertTeacher(x) }
                            ))
                        }
                        .padding(10)
                    }

                    Spacer(minLength: 20)
                }
                .padding(16)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.t(.noTeacherSelected, lang: lang))
                    .font(.system(size: 16, weight: .semibold))
                Text(L.t(.createOrSelectTeacherTip, lang: lang))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(16)
        }
    }
}
