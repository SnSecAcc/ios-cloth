import SwiftUI

@main
struct IntelegentApp: App {
    @State private var state = AppState()
    @AppStorage("theme") private var theme: ThemeChoice = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                .preferredColorScheme(theme.colorScheme)
                .task { await state.bootstrap() }
        }
    }
}
