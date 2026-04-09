import SwiftUI
import Charts
import LaTeXSwiftUI

struct SmallChartView: View {
    let obs: ObservableOutput
    let liveOutput: ComputedOutput

    private var subtype: String { obs.pythonSubtype }
    private var useLogX: Bool { obs.logX }
    private var useLogY: Bool { obs.logY }

    var body: some View {
        let points = makePoints(liveOutput.x, liveOutput.yTot)

        let xs = points.map { $0.logX }
        let ys = points.map { $0.logY }

        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1

        Chart {
            ForEach(points) { pt in
                AreaMark(
                    x: .value("x", pt.logX),
                    yStart: .value("y", minY),
                    yEnd: .value("y", pt.logY)
                )
            }
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.5),
                        Color.blue.opacity(0.01)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            ForEach(points) { pt in
                LineMark(
                    x: .value("x", pt.logX),
                    y: .value("y", pt.logY)
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(.blue)
            }
        }
        .chartXScale(domain: minX...maxX)
        .chartYScale(domain: minY...maxY)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(.clear)
                .clipped()
        }
        .frame(height: 100)
        .clipped()
    }
    
    private func transformX(_ x: Double) -> Double? {
        guard !useLogX || x > 0 else { return nil }
        return useLogX ? log10(x) : x
    }

    private func transformY(_ y: Double) -> Double? {
        let value = subtype == "mi" ? abs(y) : y
        guard !useLogY || value > 0 else { return nil }
        return useLogY ? log10(value) : value
    }
    
    private func makePoints(_ xs: [Double], _ ys: [Double]) -> [ChartPoint] {
        zip(xs, ys).compactMap { (x, y) in
            guard let xv = transformX(x),
                  let yv = transformY(y),
                  xv.isFinite,
                  yv.isFinite else { return nil }

            return ChartPoint(logX: xv, logY: yv)
        }
    }
}

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
                ContentUnavailableView("No data for selected observable",
                                       systemImage: "questionmark.circle",)
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

                let series: [(name: String, pts: [ChartPoint])] = pkObs.compactMap { obs in
                    let subtype = obs.pythonSubtype
                    guard let out = vm.computedOutputs[subtype] else { return nil }
                    return (obs.rawValue, chartPoints(out, subtype: subtype))
                }

                let allPts = series.flatMap { $0.pts }

                let xs = allPts.map { $0.logX }
                let ys = allPts.map { $0.logY }

                let xDomain = safeRange(xs)
                let yDomain = safeRange(ys)

                Chart {
                    ForEach(series, id: \.name) { entry in
                        ForEach(entry.pts) { pt in
                            LineMark(
                                x: .value("k", pt.logX),
                                y: .value("P(k)", pt.logY)
                            )
                            .foregroundStyle(by: .value("Spectrum", entry.name))
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                    }
                }
                .chartXScale(domain: xDomain)
                .chartYScale(domain: yDomain)
                .clipped()
                .frame(height: 550)

                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    LaTeX("$k \\; [h \\; \\mathrm{Mpc}^{-1 }]$").font(.body)
                }
                .chartYAxisLabel(position: .leading, alignment: .center) {
                    LaTeX("$P(k) \\; [(\\mathrm{Mpc}/h)^3]$")
                        .font(.body)
                        .rotationEffect(.degrees(-180))
                }

                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                            .foregroundStyle(Color.primary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                            .foregroundStyle(Color.primary)

                        if let d = val.as(Double.self) {
                            AxisValueLabel {
                                LaTeX("$10^{ \(Int(d)) }$").font(.caption)
                            }
                        }
                    }
                }
                
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                            .foregroundStyle(Color.primary)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                            .foregroundStyle(Color.primary)

                        if let d = val.as(Double.self) {
                            AxisValueLabel {
                                LaTeX("$10^{ \(Int(d)) }$").font(.caption)
                            }
                        }
                    }
                }

                .chartLegend(position: .topTrailing)

                if vm.uiState.compareReference, let ref = vm.referenceModel {
                    Divider()

                    Text("Relative differences vs. reference")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(pkObs) { obs in
                        let subtype = obs.pythonSubtype
                        if let live = vm.computedOutputs[subtype],
                           let refOut = ref.outputs[subtype] {
                            RatioPanelView(
                                obs: obs,
                                liveOutput: live,
                                referenceOutput: refOut
                            )
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func chartPoints(_ out: ComputedOutput, subtype: String) -> [ChartPoint] {
        zip(out.x, out.yTot).compactMap { (x, y) -> ChartPoint? in
            guard x > 0 else { return nil }

            let yVal = subtype == "mi" ? abs(y) : y
            guard yVal > 0 else { return nil }

            let xv = log10(x)
            let yv = log10(yVal)

            guard xv.isFinite, yv.isFinite else { return nil }

            return ChartPoint(logX: xv, logY: yv)
        }
    }

    private func safeRange(_ values: [Double]) -> ClosedRange<Double> {
        guard let min = values.min(), let max = values.max() else {
            return 0...1
        }

        if min == max {
            return (min - 1)...(max + 1)
        }

        return min...max
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
        let livePts = makePoints(liveOutput.x, liveOutput.yTot)

        let componentPts: [(key: String, pts: [ChartPoint])] = showComponents
            ? componentKeys.compactMap { key in
                guard let yArr = liveOutput.y[key] else { return nil }
                return (key, makePoints(liveOutput.x, yArr))
            }
            : []

        let refPts: [ChartPoint] = {
            if showReference,
               let ref = referenceModel,
               let out = ref.outputs[subtype] {
                return makePoints(out.x, out.yTot)
            }
            return []
        }()

        // --- Combine ALL points for domain ---
        let allPts = livePts + componentPts.flatMap { $0.pts } + refPts

        let xs = allPts.map { $0.logX }
        let ys = allPts.map { $0.logY }

        let xDomain = safeRange(xs)
        let yDomain = safeRange(ys)

        Chart {
            // --- Reference model ---
            if showReference {
                ForEach(refPts) { pt in
                    LineMark(
                        x: .value("x", pt.logX),
                        y: .value("y", pt.logY)
                    )
                    .foregroundStyle(by: .value("Series", "Reference"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }

            // --- Components ---
            ForEach(componentPts, id: \.key) { entry in
                ForEach(entry.pts) { pt in
                    LineMark(
                        x: .value("x", pt.logX),
                        y: .value("y", pt.logY)
                    )
                    .foregroundStyle(by: .value("Series", entry.key))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
                }
            }

            // --- Live model (on top) ---
            ForEach(livePts) { pt in
                LineMark(
                    x: .value("x", pt.logX),
                    y: .value("y", pt.logY)
                )
                .foregroundStyle(by: .value("Series", "Live Model"))
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .clipped()
        .frame(height: 550)

        .chartXAxisLabel(position: .bottom, alignment: .center) {
            LaTeX(obs.xLabel).font(.body)
        }
        .chartYAxisLabel(position: .leading, alignment: .center) {
            LaTeX(obs.yLabel)
                .font(.body)
                .rotationEffect(.degrees(-180))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                    .foregroundStyle(Color.primary)
                AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                    .foregroundStyle(Color.primary)

                if let d = val.as(Double.self) {
                    AxisValueLabel {
                        useLogX
                        ? LaTeX("$10^{ \(Int(d)) }$").font(.caption)
                        : LaTeX("$\(d)$").font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { val in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                    .foregroundStyle(Color.primary)
                AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                    .foregroundStyle(Color.primary)

                if let d = val.as(Double.self) {
                    AxisValueLabel {
                        useLogY
                        ? LaTeX("$10^{ \(Int(d)) }$").font(.caption)
                        : LaTeX("$\(d)$").font(.caption)
                    }
                }
            }
        }

        .chartLegend(position: .topTrailing)
    }

    private var componentKeys: [String] {
        liveOutput.y.keys.filter { $0 != "tot" }.sorted()
    }

    private func safeRange(_ values: [Double]) -> ClosedRange<Double> {
        guard let min = values.min(), let max = values.max() else {
            return 0...1
        }

        if min == max {
            return (min - 1)...(max + 1)
        }

        return min...max
    }

    private func makePoints(_ xs: [Double], _ ys: [Double]) -> [ChartPoint] {
        zip(xs, ys).compactMap { (x, y) in
            guard let xv = transformX(x),
                  let yv = transformY(y),
                  xv.isFinite,
                  yv.isFinite else { return nil }

            return ChartPoint(logX: xv, logY: yv)
        }
    }

    private func transformX(_ x: Double) -> Double? {
        guard !useLogX || x > 0 else { return nil }
        return useLogX ? log10(x) : x
    }

    private func transformY(_ y: Double) -> Double? {
        let value = subtype == "mi" ? abs(y) : y
        guard !useLogY || value > 0 else { return nil }
        return useLogY ? log10(value) : value
    }
}

// RatioPanelView

struct RatioPanelView: View {
    let obs: ObservableOutput
    let liveOutput: ComputedOutput
    let referenceOutput: ComputedOutput

    private var useLogX: Bool { obs.logX }

    var body: some View {
        let pts = makeRatioPoints()

        let xs = pts.map { $0.logX }
        let ys = pts.map { $0.logY }

        let xDomain = safeRange(xs)
        let yDomain = symmetricYRange(ys, maxLimit: 100) // ✅ symmetric ±100%

        VStack(alignment: .leading, spacing: 4) {
            Text("Relative difference vs. reference [%]")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                RuleMark(y: .value("zero", 0))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                ForEach(pts) { pt in
                    LineMark(
                        x: .value("x", pt.logX),
                        y: .value("Δ%", pt.logY)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yDomain)   // ✅ symmetric applied here
            .clipped()
            .frame(height: 150)

            .chartYAxisLabel(position: .leading, alignment: .center) {
                LaTeX("$(\\mathrm{Live} − \\mathrm{Ref}) / \\mathrm{Ref}  [%]$")
                    .font(.body)
                    .rotationEffect(.degrees(-180))
            }
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                LaTeX(obs.xLabel).font(.body)
            }

            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                        .foregroundStyle(Color.primary)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                        .foregroundStyle(Color.primary)

                    if let d = val.as(Double.self) {
                        AxisValueLabel {
                            useLogX
                            ? LaTeX("$10^{ \(Int(d)) }$").font(.caption)
                            : LaTeX("$\(d)$").font(.caption)
                        }
                    }
                }
            }

            .chartYAxis {
                AxisMarks(values: symmetricTicks(for: yDomain)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.25))
                        .foregroundStyle(Color.primary)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.25))
                        .foregroundStyle(Color.primary)

                    if let d = val.as(Double.self) {
                        AxisValueLabel {
                            LaTeX("$\(Int(d))$").font(.caption)
                        }
                    }
                }
            }
        }
    }

    private func makeRatioPoints() -> [ChartPoint] {
        let xRef = referenceOutput.x
        let yRef = referenceOutput.yTot

        return liveOutput.x.enumerated().compactMap { (i, x) in
            guard let refY = interpolate(x: x, xs: xRef, ys: yRef),
                  refY != 0 else { return nil }

            let liveY = liveOutput.yTot[i]
            let ratio = (liveY - refY) / refY * 100.0

            guard let xv = transformX(x),
                  xv.isFinite,
                  ratio.isFinite else { return nil }

            return ChartPoint(logX: xv, logY: ratio)
        }
    }

    private func transformX(_ x: Double) -> Double? {
        guard !useLogX || x > 0 else { return nil }
        return useLogX ? log10(x) : x
    }

    private func symmetricYRange(_ values: [Double], maxLimit: Double) -> ClosedRange<Double> {
        guard !values.isEmpty else { return -1...1 }

        let maxAbs = min(max(values.map { abs($0) }.max() ?? 1, 1), maxLimit)

        // avoid flat line
        if maxAbs == 0 {
            return -1...1
        }

        return -maxAbs...maxAbs
    }

    private func symmetricTicks(for range: ClosedRange<Double>) -> [Double] {
        let maxVal = max(abs(range.lowerBound), abs(range.upperBound))

        return [
            -maxVal,
            -maxVal / 2,
            0,
            maxVal / 2,
            maxVal
        ]
    }

    private func safeRange(_ values: [Double]) -> ClosedRange<Double> {
        guard let min = values.min(), let max = values.max() else {
            return 0...1
        }

        if min == max {
            return (min - 1)...(max + 1)
        }

        return min...max
    }

    private func interpolate(x: Double, xs: [Double], ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count > 1 else { return nil }

        if let exact = xs.firstIndex(of: x) {
            return ys[exact]
        }

        guard let idx = xs.firstIndex(where: { $0 >= x }), idx > 0 else {
            return nil
        }

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
