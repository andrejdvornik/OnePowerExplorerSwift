import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ExplorerViewModel()
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(params: vm.params, uiState: vm.uiState, vm: vm)
                .navigationSplitViewColumnWidth(min: 280, ideal: 350, max: 450)
        } detail: {
            MainAreaView(vm: vm)
        }
        .frame(minWidth: 1200, minHeight: 600)
        .onAppear {
            PythonBridge.shared.setup { [weak vm] in
                vm?.runInitialModelIfNeeded()
            }
        }.toolbar(content: {
            // Use platform-appropriate toolbar placement: `topBarLeading` is iOS-only
            #if os(iOS)
            ToolbarItemGroup(placement: .topBarLeading) {
                ModelManagementToolbar(vm: vm)
            }
            ToolbarItemGroup(placement: .principal) {
                StatusToolbar(vm: vm)
            }
            #else
            ToolbarItemGroup(placement: .navigation) {
                ModelManagementToolbar(vm: vm)
            }
            ToolbarItemGroup(placement: .principal) {
                StatusToolbar(vm: vm)
            }
            #endif
        })
    }
}

// A SwiftUI preview.
//#Preview {
//    ContentView()
//}
