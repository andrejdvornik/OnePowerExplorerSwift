import SwiftUI
import LaTeXSwiftUI

struct MainAreaView: View {
    @ObservedObject var vm: ExplorerViewModel
    @State private var selectedTab: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // State-dependent content
            switch vm.computeState {
            case .idle:
                //idleView
                if vm.uiState.selectedOutputs.isEmpty {
                    emptySelectionView
                } else {
                    idleView
                }
                
            case .computing:
                //computingView(message: msg)
                if vm.uiState.selectedOutputs.isEmpty {
                    emptySelectionView
                } else {
                    outputTabsView
                }
                
            case .failed(let msg):
                errorView(message: msg)
                
            default:
                if vm.uiState.selectedOutputs.isEmpty {
                    emptySelectionView
                } else {
                    outputTabsView
                }
            }
        }
    }

    // State views

    private var idleView: some View {
        ContentUnavailableView(
            "No results yet",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Wait for the initial model to evaluate.")
        ).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func computingView(message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .controlSize(.large)
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Computation Failed",
            systemImage: "flame.fill",
            description: Text(message)
        ).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptySelectionView: some View {
        ContentUnavailableView(
            "No observable selected",
            systemImage: "checklist",
            description: Text("Check at least one observable in the sidebar.")
        ).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var outputTabsView: some View {
        let selected = vm.uiState.selectedOutputs
        let allObs = ObservableOutput.allCases.filter { selected.contains($0) }

        let pkObs = allObs.filter { $0.category == "pk" && $0 != .gb }
        let otherObs = allObs.filter { $0.category != "pk" || $0 == .gb }
        let combinePk = vm.uiState.combinePk && !pkObs.isEmpty

        let tabs: [(tag: String, view: AnyView, title: String)] = {
            if combinePk {
                return [
                    ("combined_pk",
                     AnyView(CombinedPkView(vm: vm, pkObs: pkObs)),
                     "Power Spectra")
                ] + otherObs.map {
                    ($0.id,
                     AnyView(SingleObservableView(vm: vm, obs: $0)),
                     $0.rawValue)
                }
            } else {
                return allObs.map {
                    ($0.id,
                     AnyView(SingleObservableView(vm: vm, obs: $0)),
                     $0.rawValue)
                }
            }
        }()

        return TabView(selection: $selectedTab) {
            ForEach(tabs, id: \.tag) { tab in
                tab.view
                .tabItem { LaTeX(tab.title).imageRenderingMode(.template).foregroundColor(.secondary).fixedSize() }
                .tag(tab.tag)
            }
        }
        .onChange(of: tabs.map(\.tag)) { _, newTabs in
            if !newTabs.contains(selectedTab) {
                selectedTab = newTabs.first ?? ""
            }
        }
        .clipShape(ContainerRelativeShape())
        .padding(10)
    }
}

// Model Management Toolbar

struct ModelManagementToolbar: View {
    @ObservedObject var vm: ExplorerViewModel
    @State private var exportSubtype: String?
    @State private var showExportPanel = false
    var onReferenceSet: (() -> Void)?
    var onReferenceCleared: (() -> Void)?

    var body: some View {
        HStack {
            Button("Set as reference") {
                vm.setReferenceModel()
                onReferenceSet?()
            }
            .disabled(vm.computedOutputs.isEmpty)
            
            Divider().padding(.vertical, 8)
            Button("Clear reference") {
                vm.clearReferenceModel()
                onReferenceCleared?()
            }
            .disabled(vm.referenceModel == nil)
        }
        //.padding(.horizontal, 12)
        .frame(alignment: .leading)
    }
}

struct StatusToolbar: View {
    @ObservedObject var vm: ExplorerViewModel
    @State private var exportSubtype: String?
    @State private var showExportPanel = false
    @Binding var showReferenceSet: Bool
    @Binding var showReferenceCleared: Bool

    var body: some View {
        HStack(spacing: 4) {
            if case .computing(let msg) = vm.computeState {
                ProgressView()
                    .controlSize(.small)
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if case .failed(let msg) = vm.computeState {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if case .unstable(let msg) = vm.computeState {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if showReferenceSet {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Reference set")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if showReferenceCleared {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                Text("Reference cleared")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if case .done = vm.computeState {
                Text("Ready")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 300, alignment: .center)
    }
}
