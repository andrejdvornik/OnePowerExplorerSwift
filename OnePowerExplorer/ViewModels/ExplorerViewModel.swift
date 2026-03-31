import Foundation
import Combine

// ComputeState

enum ComputeState: Equatable {
    case idle
    case computing(message: String)
    case done
    case failed(String)
}

// ExplorerViewModel

@MainActor
final class ExplorerViewModel: ObservableObject {

    @Published var params = AppParameters()
    @Published var uiState = AppUIState()

    @Published var computeState: ComputeState = .idle
    @Published var computedOutputs: [String: ComputedOutput] = [:]

    @Published var referenceModel: SavedModel?
    
    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: AnyCancellable?
    
    private var currentTask: Task<Void, Never>?
    private var hasRunInitialModel = false

    init() {
        uiState.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        // Debounce parameter changes and trigger recalculation
        params.objectWillChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.runModel()
        }
        .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.runInitialModelIfNeeded()
        }
    }
    
    
    @MainActor
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    static let loadingMessages: [String] = [
        "Consulting the Palantír of Power Spectra…",
        "Summoning haloes from the cosmic web…",
        "Forging 1-halo and 2-halo terms in Mount Doom…",
        "Traversing the large-scale structure of Middle-Universe…",
        "Counting galaxies… precious galaxies…",
        "Whispering to σ₈… it changes everything…",
        "The Fellowship is integrating over Mₕ…",
        "Adjusting Ω_c… carefully…",
        "Consulting the Eldar of Rivendell…",
        "Unraveling the cosmic web with Mithril threads…",
    ]

    // Run model
    func runInitialModelIfNeeded() {
        guard !hasRunInitialModel else { return }
        hasRunInitialModel = true
        runModel()
    }
    
    func runModel() {
        // Cancel the previous task if it's running
        currentTask?.cancel()

        // Skip if no outputs are selected
        //guard !params.selectedOutputs.isEmpty else { return }

        // Set loading state
        let msg = Self.loadingMessages.randomElement()!
        computeState = .computing(message: msg)

        // Start a new task
        currentTask = Task { @MainActor [weak self] in
            guard let self = self else { return }

            let snapParams = params.copy()
            await self.computeWithPython(params: snapParams)
        }
    }

    private func computeWithPython(params: AppParameters) async {
        // Use a continuation to bridge async/await with the completion handler
        await withCheckedContinuation { continuation in
            PythonBridge.shared.compute(
                params: params,
                components: true
            ) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch result {
                    case .success(let outputs):
                        self.computedOutputs = outputs
                        self.computeState = .done
                    case .failure(let error):
                        self.computeState = .failed(error.localizedDescription)
                    }
                    continuation.resume()
                }
            }
        }
    }

    // Model management
    func setReferenceModel() {
        guard !computedOutputs.isEmpty else { return }
        referenceModel = SavedModel(label: "Reference", outputs: computedOutputs)
    }

    func clearReferenceModel() {
        referenceModel = nil
    }

    // CSV export

    func csvData(for subtype: String) -> Data? {
        guard let out = computedOutputs[subtype] else { return nil }
        var lines: [String] = []
        let header = (["x"] + out.y.keys.sorted()).joined(separator: ",")
        lines.append(header)
        for (i, xVal) in out.x.enumerated() {
            var row = [String(xVal)]
            for key in out.y.keys.sorted() {
                row.append(String(out.y[key]?[i] ?? 0))
            }
            lines.append(row.joined(separator: ","))
        }
        return lines.joined(separator: "\n").data(using: .utf8)
    }
}
