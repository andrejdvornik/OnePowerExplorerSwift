import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ExplorerViewModel()
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var showReferenceSet = false
    @State private var showReferenceCleared = false

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(params: vm.params, uiState: vm.uiState, vm: vm)
                .navigationSplitViewColumnWidth(min: 280, ideal: 350, max: 450)
        } detail: {
            MainAreaView(vm: vm)
        }
        .frame(minWidth: 1200, minHeight: 600)
        .onAppear {
            Task {
                await PythonBridge.shared.setup()
                vm.runInitialModelIfNeeded()
            }
        }.toolbar(content: {
            // Use platform-appropriate toolbar placement: `topBarLeading` is iOS-only
            #if os(iOS)
            ToolbarItemGroup(placement: .topBarLeading) {
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
            }
            ToolbarItemGroup(placement: .principal) {
                StatusToolbar(vm: vm, showReferenceSet: $showReferenceSet, showReferenceCleared: $showReferenceCleared)
            }
            #else
            ToolbarItemGroup(placement: .navigation) {
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
            }
            ToolbarItemGroup(placement: .principal) {
                StatusToolbar(vm: vm, showReferenceSet: $showReferenceSet, showReferenceCleared: $showReferenceCleared)
            }
            #endif
        })
    }
}

// A SwiftUI preview.
//#Preview {
//    ContentView()
//}
