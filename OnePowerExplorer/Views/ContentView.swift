import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ExplorerViewModel()
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var showReferenceSet = false
    @State private var showReferenceCleared = false

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(params: vm.params, uiState: vm.uiState, vm: vm)
                .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 450)
        } detail: {
            MainAreaView(vm: vm)
        }
        .focusedObject(vm)
        .toolbar(id: "OnePower", content: {
            // Use platform-appropriate toolbar placement: `topBarLeading` is iOS-only
            #if os(iOS)
            ToolbarItem(id: "Model", placement: .topBarLeading) {
                ModelManagementToolbar(
                    vm: vm,
                    onReferenceSet: {
                        showReferenceSet = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showReferenceSet = false
                        }
                    },
                    onReferenceCleared: {
                        showReferenceCleared = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showReferenceCleared = false
                        }
                    })
            }.defaultCustomization(options: .alwaysAvailable)
            
            ToolbarItem(id: "Status", placement: .principal) {
                StatusToolbar(vm: vm, showReferenceSet: $showReferenceSet, showReferenceCleared: $showReferenceCleared)
            }.defaultCustomization(options: .alwaysAvailable)
            
            ToolbarItem(id: "Reset", placement: .topBarTrailing) {
                Button("Reset", systemImage: "arrow.uturn.backward") {
                    vm.params.resetParameters()
                }
                .help("Reset all parameters to their default values")
            }.defaultCustomization(options: .alwaysAvailable)
            #else
            ToolbarItem(id: "Model", placement: .automatic) {
                ModelManagementToolbar(
                    vm: vm,
                    onReferenceSet: {
                        showReferenceSet = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showReferenceSet = false
                        }
                    },
                    onReferenceCleared: {
                        showReferenceCleared = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showReferenceCleared = false
                        }
                    })
            }.defaultCustomization(options: .alwaysAvailable)
            
            ToolbarItem(id: "Status", placement: .principal) {
                StatusToolbar(vm: vm, showReferenceSet: $showReferenceSet, showReferenceCleared: $showReferenceCleared)
            }.defaultCustomization(options: .alwaysAvailable)
            
            ToolbarItem(id: "Reset", placement: .automatic) {
                Button("Reset", systemImage: "arrow.uturn.backward") {
                    vm.params.resetParameters()
                }
                .help("Reset all parameters to their default values")
            }.defaultCustomization(options: .alwaysAvailable)
            #endif
        })
        .toolbarRole(.editor)
        .frame(minWidth: 1200, minHeight: 600)
        .onAppear {
            Task {
                await PythonBridge.shared.setup()
                vm.runInitialModelIfNeeded()
            }
        }
    }
}

// A SwiftUI preview.
//#Preview {
//    ContentView()
//}
