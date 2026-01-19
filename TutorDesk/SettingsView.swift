import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        List {
            Section(L.t(.general, lang: lang)) {
                Text(L.t(.dataLocalTip, lang: lang))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.inset)
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAddHoliday = false

    var body: some View {
        let lang = store.state.settings.appLanguage

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L.t(.settings, lang: lang))
                    .font(.system(size: 16, weight: .semibold))

                GroupBox(L.t(.language, lang: lang)) {
                    Picker("", selection: Binding(
                        get: { store.state.settings.appLanguage },
                        set: { v in store.updateState { $0.settings.appLanguage = v } }
                    )) {
                        Text(L.t(.followSystem, lang: lang)).tag(AppLanguage.system)
                        Text(L.t(.langChinese, lang: lang)).tag(AppLanguage.zhHans)
                        Text(L.t(.langEnglish, lang: lang)).tag(AppLanguage.en)
                    }
                    .pickerStyle(.segmented)
                    .padding(10)
                }

                GroupBox(L.t(.rules, lang: lang)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(L.t(.skipHolidaysByDefault, lang: lang), isOn: Binding(
                            get: { store.state.settings.skipHolidaysByDefault },
                            set: { v in store.updateState { $0.settings.skipHolidaysByDefault = v } }
                        ))
                    }
                    .padding(10)
                }

                GroupBox(L.t(.holidayRangesBlocked, lang: lang)) {
                    VStack(alignment: .leading, spacing: 10) {
                        if store.state.settings.holidayRanges.isEmpty {
                            Text(L.t(.noHolidayRanges, lang: lang))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.state.settings.holidayRanges) { r in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(r.name).font(.system(size: 13, weight: .semibold))
                                        Text("\(TD.shortDate(r.start, lang: lang)) – \(TD.shortDate(r.end, lang: lang))")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        store.updateState { $0.settings.holidayRanges.removeAll { $0.id == r.id } }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(12)
                            }
                        }

                        Button(L.t(.addRange, lang: lang)) { showAddHoliday = true }
                            .buttonStyle(.bordered)
                    }
                    .padding(10)
                }

                GroupBox(L.t(.importExportReserved, lang: lang)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Button(L.t(.exportSoon, lang: lang)) {}.disabled(true)
                        Button(L.t(.importSoon, lang: lang)) {}.disabled(true)

                        Text(L.t(.reservedTip, lang: lang))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                }

                Spacer(minLength: 24)
            }
            .padding(16)
        }
        .sheet(isPresented: $showAddHoliday) { AddHolidaySheet() }
    }
}

private struct AddHolidaySheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "Holiday"
    @State private var start: Date = Date()
    @State private var end: Date = Date()

    var body: some View {
        let lang = store.state.settings.appLanguage

        VStack(alignment: .leading, spacing: 12) {
            Text(L.t(.addHolidayRange, lang: lang))
                .font(.system(size: 16, weight: .semibold))

            TextField(L.t(.name, lang: lang), text: $name)

            DatePicker(L.t(.start, lang: lang), selection: $start, displayedComponents: [.date])
            DatePicker(L.t(.end, lang: lang), selection: $end, displayedComponents: [.date])

            HStack {
                Button(L.t(.cancel, lang: lang)) { dismiss() }
                Spacer()
                Button(L.t(.add, lang: lang)) {
                    store.updateState { $0.settings.holidayRanges.append(HolidayRange(name: name, start: start, end: end)) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}
