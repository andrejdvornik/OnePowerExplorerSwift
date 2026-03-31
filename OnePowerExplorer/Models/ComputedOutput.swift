import Foundation

// ComputedOutput

/// Holds the x-axis and named y-series for one observable.
struct ComputedOutput: Identifiable {
    let id = UUID()
    let subtype: String
    var x: [Double]
    /// Keys: "tot", optionally "1h"/"2h" or "cen"/"sat"
    var y: [String: [Double]]

    var yTot: [Double] { y["tot"] ?? [] }
}

// SavedModel

/// A snapshot of computed outputs that can be compared against the live model.
struct SavedModel: Identifiable {
    let id = UUID()
    let label: String
    var outputs: [String: ComputedOutput]   // keyed by subtype
}

// ComputeError

enum ComputeError: LocalizedError {
    case pythonUnavailable
    case computeFailed(String)
    case numericalInstability

    var errorDescription: String? {
        switch self {
        case .pythonUnavailable:
            return "Python / PythonKit is not available. Make sure the embedded Python is installed."
        case .computeFailed(let msg):
            return "Computation failed: \(msg)"
        case .numericalInstability:
            return "Numerical instability detected — adjust parameters and try again."
        }
    }
}
