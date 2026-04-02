import Foundation
import Combine

// ComputeState

enum ComputeState: Equatable {
    case idle
    case computing(message: String)
    case done
    case unstable(String)
    case failed(String)
}

// ExplorerViewModel

@MainActor
final class ExplorerViewModel: ObservableObject {

    @Published var params = AppParameters()
    @Published var uiState = AppUIState()

    @Published var computeState: ComputeState = .idle
    @Published var computedOutputs: [String: ComputedOutput] = [:]

    @Published var referenceModel: SavedModel? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: AnyCancellable?
    
    private var currentTask: Task<Void, Never>?
    private var hasRunInitialModel = false
    private var requestID = UUID()

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
    @MainActor
    func runInitialModelIfNeeded() {
        guard !hasRunInitialModel else { return }
        hasRunInitialModel = true
        runModel()
    }
    
    func runModel() {
        currentTask?.cancel()

        let msg = Self.loadingMessages.randomElement()!
        computeState = .computing(message: msg)

        let snapParams = params.copy()

        currentTask = Task { @MainActor [weak self] in
            guard let self = self else { return }

            await self.computeWithPython(params: snapParams)
        }
    }

    private func computeWithPython(params: AppParameters) async {
        do {
            let snapParams = params.copy()
            let outputs = try await PythonBridge.shared.compute(
                params: snapParams,
                components: true
            )

            self.computedOutputs = outputs
            self.computeState = .done

        } catch is CancellationError {
        } catch ComputeError.numericalInstability {
            // Handle numerical instability as a warning/unstable state
            self.computeState = .unstable("Numerical instability detected. Try adjusting parameters.")
        } catch {
            self.computeState = .failed(error.localizedDescription)
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
