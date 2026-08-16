import SwiftUI
import LaTeXSwiftUI

struct MainAreaView: View {
    @ObservedObject var vm: ExplorerViewModel
    @State private var selectedTab: String = ""
    @State private var zoomedChart: String? = nil
    
    var body: some View {
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
                outputDashboardView
            }
            
        case .failed(let msg):
            errorView(message: msg)
            //outputDashboardView
            
        default:
            if vm.uiState.selectedOutputs.isEmpty {
                emptySelectionView
            } else {
                outputDashboardView
            }
        }
    }
    
    // State views
    
    private var idleView: some View {
        ContentUnavailableView(
            "No results yet",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Wait for the initial model to evaluate.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(ContainerRelativeShape())
        .padding(10)
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
        .clipShape(ContainerRelativeShape())
        .padding(10)
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Computation Failed",
            systemImage: "flame.fill",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(ContainerRelativeShape())
        .padding(10)
    }
    
    private var emptySelectionView: some View {
        ContentUnavailableView(
            "No observable selected",
            systemImage: "checklist",
            description: Text("Check at least one observable in the sidebar.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(ContainerRelativeShape())
        .padding(10)
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
                    .tabItem { Text(tab.title) }
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
    
    private var outputDashboardView: some View {
        let allObs = ObservableOutput.allCases
        
        let pkObs = allObs.filter { $0.category == "pk" && $0 != .gb }
        let otherObs = allObs.filter { $0.category != "pk" || $0 == .gb }
        let combinePk = vm.uiState.combinePk && !pkObs.isEmpty
        
        var charts: [DashboardChart] = []
        if combinePk {
            let combinedView = AnyView(CombinedPkView(vm: vm, pkObs: pkObs))
            charts.append(DashboardChart(
                tag: "combined_pk",
                title: "Power Spectra",
                obs: pkObs.first!, // placeholder, used only for type info
                liveOutput: pkObs.first.flatMap { vm.computedOutputs[$0.pythonSubtype] },
                fullView: combinedView
            ))
            for obs in otherObs {
                let fullView = AnyView(SingleObservableView(vm: vm, obs: obs))
                charts.append(DashboardChart(
                    tag: obs.id,
                    title: obs.rawValue,
                    obs: obs,
                    liveOutput: vm.computedOutputs[obs.pythonSubtype],
                    fullView: fullView
                ))
            }
            if let zoomed = zoomedChart, !charts.contains(where: { $0.tag == zoomed }) {
                DispatchQueue.main.async {
                    zoomedChart = "combined_pk"
                }
            }
        } else {
            for obs in allObs {
                let fullView = AnyView(SingleObservableView(vm: vm, obs: obs))
                charts.append(DashboardChart(
                    tag: obs.id,
                    title: obs.rawValue,
                    obs: obs,
                    liveOutput: vm.computedOutputs[obs.pythonSubtype],
                    fullView: fullView
                ))
            }
            if zoomedChart == "combined_pk" {
                if let firstPk = pkObs.first {
                    DispatchQueue.main.async {
                        zoomedChart = firstPk.id
                    }
                } else {
                    // fallback: just clear zoom
                    DispatchQueue.main.async {
                        zoomedChart = nil
                    }
                }
            }
        }
        
        return DashboardGridView(charts: charts, zoomedChart: $zoomedChart, uiState: vm.uiState)
    }
    
    struct DashboardGridView: View {
        let charts: [DashboardChart]
        
        @Binding var zoomedChart: String?
        @Namespace private var namespace
        
        @ObservedObject var uiState: AppUIState
        @GestureState private var pinchScale: CGFloat = 1.0
        
        var body: some View {
            ZStack {
                if zoomedChart == nil {
                    ScrollView {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: uiState.numberOfColumns)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(charts, id: \.tag) { chart in
                                VStack {
                                    LaTeX(chart.title)
                                        .font(.headline)
                                        .padding(.top, 20)
                                    if let live = chart.liveOutput {
                                        SmallChartView(obs: chart.obs, liveOutput: live)
                                            .padding(.top, 10)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        Text("No data").foregroundColor(.secondary)
                                            .padding(.vertical, 10)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                                .aspectRatio(4 / 3, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.2), lineWidth: 1)))
                                .matchedGeometryEffect(id: chart.tag, in: namespace, isSource: zoomedChart == nil)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        zoomedChart = chart.tag
                                    }
                                }
                                .gesture(
                                    MagnificationGesture()
                                        .updating($pinchScale) { value, state, _ in
                                            state = value
                                        }
                                        .onEnded { value in
                                            withAnimation {
                                                if value < 0.8 && uiState.numberOfColumns < 5 {
                                                    uiState.numberOfColumns += 1
                                                } else if value > 1.2 && uiState.numberOfColumns > 1 {
                                                    uiState.numberOfColumns -= 1
                                                }
                                            }
                                        }
                                )
                                .opacity(zoomedChart == nil || zoomedChart == chart.tag ? 1 : 0)
                            }
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: uiState.numberOfColumns)
                        .padding(10)
                    }
                }
                
                if let tag = zoomedChart, let chart = charts.first(where: { $0.tag == tag }) {
                    VStack {
                        LaTeX(chart.title)
                            .font(.largeTitle)
                            .padding()
                        chart.fullView
                    }
                    .background(ContainerRelativeShape().fill(.thinMaterial).overlay(ContainerRelativeShape().stroke(Color.primary.opacity(0.2), lineWidth: 1)))
                    .matchedGeometryEffect(id: chart.tag, in: namespace, isSource: zoomedChart != nil)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                    .padding(10)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            zoomedChart = nil
                        }
                    }
                }
            }
            //.clipShape(ContainerRelativeShape())
            //.padding()
            //.frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(id: "Back", placement: .navigation) {
                    if zoomedChart != nil {
                        Button("Back", systemImage: "chevron.left", action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                zoomedChart = nil
                            }
                        })
                    }
                }
                #if os(iOS)
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible)
                }
                #endif
                
                ToolbarItem(id: "Zoom", placement: .automatic) {
                    if zoomedChart == nil {
                        ZoomToolbar(numberOfColumns: $uiState.numberOfColumns)
                    }
                }
                #if os(iOS)
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible)
                }
                #endif
            }
        }
    }
}


struct DashboardChart {
    let tag: String
    let title: String
    let obs: ObservableOutput
    let liveOutput: ComputedOutput?
    let fullView: AnyView
}

// Zoom Toolbar

struct ZoomToolbar: View {
    @Binding var numberOfColumns: Int

    var body: some View {
        ControlGroup {
            Button("Zoom Out", systemImage: "minus") {
                withAnimation {
                    numberOfColumns += 1
                }
            }
            .disabled(numberOfColumns >= 6)
            .help("Zoom Out")
            Button("Zoom In", systemImage: "plus") {
                withAnimation {
                    numberOfColumns -= 1
                }
            }
            .disabled(numberOfColumns <= 1)
            .help("Zoom In")
        } label: {
            Label("Zoom", systemImage: "magnifyingglass")
        }.controlGroupStyle(.navigation)
    }
}

// Model Management Toolbar

struct ModelManagementToolbar: View {
    @ObservedObject var vm: ExplorerViewModel
    //@State private var exportSubtype: String?
    //@State private var showExportPanel = false
    var onReferenceSet: (() -> Void)?
    var onReferenceCleared: (() -> Void)?

    var body: some View {
        ControlGroup {
            Button("Set", systemImage: "bookmark.fill") {
                vm.setReferenceModel()
                onReferenceSet?()
            }
            .disabled(vm.computedOutputs.isEmpty)
            .help("Set the current computed outputs as the reference model for comparison")
            Button("Clear", systemImage: "trash") {
                vm.clearReferenceModel()
                onReferenceCleared?()
            }
            .disabled(vm.referenceModel == nil)
            .help("Clear the reference model")
        } label: {
            Label("Reference", systemImage: "bookmark")
        }.controlGroupStyle(.navigation)
    }
}

struct StatusToolbar: View {
    @ObservedObject var vm: ExplorerViewModel
    //@State private var exportSubtype: String?
    //@State private var showExportPanel = false
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
