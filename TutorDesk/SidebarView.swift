import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let lang = store.state.settings.appLanguage

        List(selection: $store.sidebar) {
            ForEach(SidebarItem.allCases) { item in
                Label {
                    Text(L.t(item.titleKey, lang: lang))
                } icon: {
                    Image(systemName: item.icon)
                }
                .tag(item)
            }
        }
        .listStyle(.sidebar)
    }
}
