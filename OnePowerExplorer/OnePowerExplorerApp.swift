import SwiftUI

@main
struct OnePowerExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 600)
                .onAppear {
                    #if os(macOS)
                    NSWindow.allowsAutomaticWindowTabbing = false
                    #endif
                }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
        .commands {
            Menus()
        }
    }
}

