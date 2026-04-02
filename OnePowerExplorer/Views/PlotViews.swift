import SwiftUI
import Charts
import LaTeXSwiftUI

// SingleObservableView

struct SingleObservableView: View {
    @ObservedObject var vm: ExplorerViewModel
    let obs: ObservableOutput

    private var subtype: String { obs.pythonSubtype }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let out = vm.computedOutputs[subtype] {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        projectionWarning
                        
                        LogLogChartView(
                            obs: obs,
                            liveOutput: out,
                            referenceModel: vm.referenceModel,
                            showComponents: vm.uiState.showComponents,
                            showReference: vm.uiState.compareReference
                        ).frame(maxWidth: .infinity)
                        
                        if vm.uiState.compareReference, let ref = vm.referenceModel,
                           let refOut = ref.outputs[subtype]
                        {
                            RatioPanelView(
                                obs: obs,
                                liveOutput: out,
                                referenceOutput: refOut
                            ).frame(maxWidth: .infinity)
                        }
                    }
                }
            } else {
                ContentUnavailableView("No data for \(obs.rawValue)",
                                       systemImage: "questionmark.circle")
            }
            if vm.computedOutputs[subtype] != nil {
                CSVExportButton(vm: vm, subtype: subtype)
                    .frame(alignment: .trailing)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var projectionWarning: some View {
        let angularSubtypes = ["wtheta", "gamma", "xip", "xim"]
        if angularSubtypes.contains(subtype) {
            if vm.params.z_vec == 0 {
                WarningBanner("This statistic is not well-defined at z=0. Select a higher redshift.")
            } else {
                WarningBanner("Evaluated at a single redshift with simplified projection — illustrative only.")
            }
        }
    }
}

// CombinedPkView

struct CombinedPkView: View {
    @ObservedObject var vm: ExplorerViewModel
    let pkObs: [ObservableOutput]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("All Power Spectra")
                    .font(.headline)
                
                Chart {
                    ForEach(Array(pkObs.enumerated()), id: \.offset) { idx, obs in
                        let subtype = obs.pythonSubtype
                        if let out = vm.computedOutputs[subtype] {
                            let pts = chartPoints(out, subtype: subtype)
                            ForEach(pts) { pt in
                                LineMark(
                                    x: .value("k", pt.logX),
                                    y: .value("P(k)", pt.logY)
                                )
                                .foregroundStyle(by: .value("Spectrum", obs.rawValue))
                            }
                        }
                    }
                }
                .frame(height: 550)
                .chartXAxisLabel(position: .bottom, alignment: .center)  { LaTeX("$k \\, [h \\, \\text{Mpc}^{-1}]$").font(.body).foregroundColor(.primary).fixedSize() }
                .chartYAxisLabel(position: .leading, alignment: .center) { LaTeX("$P(k) \\; [(Mpc/h)^3]$").font(.body).foregroundColor(.primary).fixedSize().rotationEffect(.degrees(-180)) }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                        if let d = val.as(Double.self) {
                            AxisValueLabel { LaTeX("$10^{\(Int(d))}$").font(.caption).foregroundColor(.primary).fixedSize() }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                        if let d = val.as(Double.self) {
                            AxisValueLabel { LaTeX("$10^{\(Int(d))}$").font(.caption).foregroundColor(.primary).fixedSize() }
                        }
                    }
                }
                .chartLegend(position: .topTrailing)
                
                if vm.uiState.compareReference, let ref = vm.referenceModel {
                    Divider()
                    Text("Relative differences vs. reference")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ForEach(pkObs) { obs in
                        let subtype = obs.pythonSubtype
                        if let live = vm.computedOutputs[subtype],
                           let refOut = ref.outputs[subtype]
                        {
                            RatioPanelView(obs: obs, liveOutput: live, referenceOutput: refOut)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func chartPoints(_ out: ComputedOutput, subtype: String) -> [ChartPoint] {
        zip(out.x, out.yTot).compactMap { (x, y) -> ChartPoint? in
            guard x > 0, y > 0 else { return nil }
            let yVal = subtype == "mi" ? abs(y) : y
            guard yVal > 0 else { return nil }
            return ChartPoint(logX: log10(x), logY: log10(yVal))
        }
    }
}

// LogLogChartView

/// Renders a log-log chart by pre-computing log10 values and labelling axes
/// accordingly. Swift Charts doesn't support true log axes natively (as of
/// macOS 14), so we display log10-transformed data with annotated tick labels.
struct LogLogChartView: View {
    let obs: ObservableOutput
    let liveOutput: ComputedOutput
    let referenceModel: SavedModel?
    let showComponents: Bool
    let showReference: Bool

    private var subtype: String { obs.pythonSubtype }
    private var useLogX: Bool { obs.logX }
    private var useLogY: Bool { obs.logY }

    var body: some View {
        Chart {
            // --- Reference model ---
            if showReference, let ref = referenceModel, let out = ref.outputs[subtype] {
                let pts = makePoints(out.x, out.yTot)
                ForEach(pts) { pt in
                    LineMark(x: .value("x", pt.logX), y: .value("y", pt.logY))
                        .foregroundStyle(by: .value("Series", "Reference"))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                }
            }

            // --- Components (1h / 2h or cen / sat) ---
            if showComponents {
                ForEach(componentKeys, id: \.self) { key in
                    if let yArr = liveOutput.y[key] {
                        let pts = makePoints(liveOutput.x, yArr)
                        ForEach(pts) { pt in
                            LineMark(x: .value("x", pt.logX), y: .value("y", pt.logY))
                                .foregroundStyle(by: .value("Series", key))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                        }
                    }
                }
            }

            // --- Live model (on top) ---
            let livePts = makePoints(liveOutput.x, liveOutput.yTot)
            ForEach(livePts) { pt in
                LineMark(x: .value("x", pt.logX), y: .value("y", pt.logY))
                    .foregroundStyle(by: .value("Series", "Live Model"))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
        }
        .frame(height: 550)
        .chartXAxisLabel(position: .bottom, alignment: .center) { LaTeX(obs.xLabel).font(.body).foregroundColor(.primary).fixedSize() }
        .chartYAxisLabel(position: .leading, alignment: .center) { LaTeX(obs.yLabel).font(.body).foregroundColor(.primary).fixedSize().rotationEffect(.degrees(-180)) }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                if let d = val.as(Double.self) {
                    AxisValueLabel { LaTeX("$10^{\(Int(d))}$").font(.caption).foregroundColor(.primary).fixedSize() }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                if let d = val.as(Double.self) {
                    AxisValueLabel { useLogY ? LaTeX("$10^{\(Int(d))}$").font(.caption).foregroundColor(.primary).fixedSize() : LaTeX("$\(d)$").font(.caption).foregroundColor(.primary).fixedSize() }
                }
            }
        }
        .chartLegend(position: .topTrailing)
    }

    private var componentKeys: [String] {
        liveOutput.y.keys.filter { $0 != "tot" }.sorted()
    }

    private func makePoints(_ xs: [Double], _ ys: [Double]) -> [ChartPoint] {
        zip(xs, ys).compactMap { (x, y) -> ChartPoint? in
            let xv = useLogX ? (x > 0 ? log10(x) : nil) : x
            let yv: Double?
            if subtype == "mi" {
                yv = useLogY ? (abs(y) > 0 ? log10(abs(y)) : nil) : abs(y)
            } else {
                yv = useLogY ? (y > 0 ? log10(y) : nil) : y
            }
            guard let xv, let yv, xv.isFinite, yv.isFinite else { return nil }
            return ChartPoint(logX: xv, logY: yv)
        }
    }
}

// RatioPanelView

struct RatioPanelView: View {
    let obs: ObservableOutput
    let liveOutput: ComputedOutput
    let referenceOutput: ComputedOutput
    private var useLogX: Bool { obs.logX }
    private var useLogY: Bool { obs.logY }

    private var ratioPoints: [ChartPoint] {
        let xRef = referenceOutput.x
        let yRef = referenceOutput.yTot

        return liveOutput.x.enumerated().compactMap { (i, x) -> ChartPoint? in
            guard let refY = interpolate(x: x, xs: xRef, ys: yRef),
                  refY != 0 else { return nil }
            let liveY = liveOutput.yTot[i]
            let ratio = (liveY - refY) / refY * 100.0
            let xv = obs.logX ? (x > 0 ? log10(x) : nil) : x
            guard let xv, xv.isFinite, ratio.isFinite else { return nil }
            return ChartPoint(logX: xv, logY: ratio)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Relative difference vs. reference [%]")
                .font(.caption).foregroundStyle(.secondary)

            Chart {
                RuleMark(y: .value("zero", 0))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                let pts = ratioPoints
                ForEach(pts) { pt in
                    LineMark(x: .value("x", pt.logX), y: .value("Δ%", pt.logY))
                        .foregroundStyle(.blue)
                }
            }
            .frame(height: 150)
            .chartYAxisLabel(position: .leading, alignment: .center) { LaTeX("$(\\text{Live} − \\text{Ref}) / \\text{Ref}  [%]$").font(.body).foregroundColor(.primary).fixedSize().rotationEffect(.degrees(-180)) }
            .chartXAxisLabel(position: .bottom, alignment: .center) { LaTeX(obs.xLabel).font(.body).foregroundColor(.primary).fixedSize() }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                    if let d = val.as(Double.self) {
                        AxisValueLabel { LaTeX("$10^{\(Int(d))}$").font(.caption).foregroundColor(.primary).fixedSize() }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [-100, 0, 100]) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.25)).foregroundStyle(Color.primary)
                    if let d = val.as(Double.self) {
                        AxisValueLabel { LaTeX("$\(d)$").font(.caption).foregroundColor(.primary).fixedSize() }
                    }
                }
            }
        }
    }

    private func interpolate(x: Double, xs: [Double], ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count > 1 else { return nil }
        if let exact = xs.firstIndex(of: x) { return ys[exact] }
        guard let idx = xs.firstIndex(where: { $0 >= x }), idx > 0 else { return nil }
        let x0 = xs[idx - 1], x1 = xs[idx]
        let y0 = ys[idx - 1], y1 = ys[idx]
        let t = (x - x0) / (x1 - x0)
        return y0 + t * (y1 - y0)
    }
}

// CSV Export Button

struct CSVExportButton: View {
    @ObservedObject var vm: ExplorerViewModel
    let subtype: String
    @State private var showPanel = false

    var body: some View {
        Button {
            exportCSV()
        } label: {
            Label("Export CSV", systemImage: "square.and.arrow.down")
        }
    }

    private func exportCSV() {
        guard let data = vm.csvData(for: subtype) else {
            // Show error alert
            return
        }
        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(subtype).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
            } catch {
                // Show error alert
            }
        }
        #endif
    }
}

// WarningBanner

struct WarningBanner: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// ChartPoint

struct ChartPoint: Identifiable {
    let id = UUID()
    let logX: Double
    let logY: Double
}
