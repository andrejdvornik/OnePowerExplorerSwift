import SwiftUI
import LaTeXSwiftUI

struct SidebarView: View {
    @ObservedObject var params: AppParameters
    @ObservedObject var uiState: AppUIState
    @ObservedObject var vm: ExplorerViewModel

    var body: some View {
        List {
            Section {
                Toggle("Compare to reference model", isOn: $uiState.compareReference).toggleStyle(.switch)
                Toggle("Show halo model components", isOn: $uiState.showComponents).toggleStyle(.switch)
                Toggle("Combine power spectra on one plot", isOn: $uiState.combinePk).toggleStyle(.switch)
            } header: { Text("Display") }

            // Observable selection
            //ObservableSelectionView(uiState: uiState)

            // General settings
            GeneralSettingsView(params: params)

            // Cosmological parameters
            CosmoParamsView(params: params)

            // Halo model parameters
            HaloModelParamsView(params: params)

            // HOD parameters
            HODParamsView(params: params)

            // Links
            Link("OnePower on PyPI",
                destination: URL(string: "https://pypi.org/project/onepower/")!)
                .font(.caption)
            Link("OnePower on GitHub",
                destination: URL(string: "https://github.com/KiDS-WL/onepower")!)
                .font(.caption)

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
}

// Observable Selection

struct ObservableSelectionView: View {
    @ObservedObject var uiState: AppUIState
    @State private var topExpanded: Bool = true

    var body: some View {
        Section(isExpanded: $topExpanded, content: {
            ForEach(ObservableOutput.allCases) { obs in
                Toggle(isOn: Binding(
                    get: { uiState.selectedOutputs.contains(obs) },
                    set: { checked in
                        var newSet = uiState.selectedOutputs
                        if checked {
                            newSet.insert(obs)
                        } else {
                            newSet.remove(obs)
                        }
                        uiState.selectedOutputs = newSet
                    }
                )) { LaTeX(obs.rawValue).foregroundColor(.primary) }
                    .toggleStyle(.switch)
            }
        }, header: { Text("Observables") })
    }
}

// General Settings

struct GeneralSettingsView: View {
    @ObservedObject var params: AppParameters
    @State private var topExpanded: Bool = true

    var body: some View {
        Section(isExpanded: $topExpanded, content: {
            LabeledIntField(label: "$N_k$ points", value: $params.nk, range: 10...1000)
            LabeledNumberField("$k_{\\mathrm{min} } \\; [h \\; \\mathrm{Mpc}^{-1 }]$", value: $params.kmin, format: "%.4e")
            LabeledNumberField("$k_{\\mathrm{max} } \\; [h \\; \\mathrm{Mpc}^{-1 }]$", value: $params.kmax)
            LabeledNumberField("$M_{\\mathrm{min} } \\; [\\log_{10 }(h^{-1 } \\;  M_{\\odot })]$", value: $params.mmin)
            LabeledNumberField("$M_{\\mathrm{max} } \\; [\\log_{10 }(h^{-1 } \\;  M_{\\odot })]$", value: $params.mmax)
            LabeledNumberField("$r_{p,\\mathrm{min} } \\; [h^{-1 } \\; \\mathrm{Mpc}]$", value: $params.rpmin)
            LabeledNumberField("$r_{p,\\mathrm{max} } \\; [h^{-1 } \\; \\mathrm{Mpc}]$", value: $params.rpmax)
            LabeledNumberField("$\\theta_{\\mathrm{min} } \\; [\\mathrm{arcmin}]$", value: $params.thetamin)
            LabeledNumberField("$\\theta_{\\mathrm{max} } \\; [\\mathrm{arcmin}]$", value: $params.thetamax)
        }, header: { Text("General Settings") })
    }
}

// Cosmological Parameters

struct CosmoParamsView: View {
    @ObservedObject var params: AppParameters
    @State private var topExpanded: Bool = true

    var body: some View {
        Section(isExpanded: $topExpanded, content: {
            LabeledSliderField("$\\Omega_{\\mathrm{c} }$", value: $params.omega_c, step: 0.01, range: 0.001...1.0)
            LabeledSliderField("$\\Omega_{\\mathrm{b} }$", value: $params.omega_b, step: 0.00, range: 0.001...1.0)
            LabeledSliderField("$h$", value: $params.h, step: 0.01, range: 0.1...1.0)
            LabeledSliderField("$n_s$", value: $params.ns, step: 0.005, range: 0.0...2.0)
            LabeledSliderField("$\\sigma_8$", value: $params.sigma_8, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("Redshift $z$", value: $params.z_vec, step: 0.1, range: 0.0...2.0)
            LabeledSliderField("$\\Sigma m_{\\nu} [\\mathrm{eV}]$", value: $params.m_nu, step: 0.01, range: 0.0...0.1)
            LabeledSliderField("$w_0$", value: $params.w0, step: 0.05, range: -1.5...(-0.5))
            LabeledSliderField("$w_a$", value: $params.wa, step: 0.05, range: -1.0...0.5)
            LabeledSliderField("$T_{\\mathrm{CMB} } [\\mathrm{K}]$", value: $params.tcmb, step: 0.01, range: 2.0...5.0)
        }, header: { Text("Cosmological Parameters") })
    }
}

// Halo Model Parameters

struct HaloModelParamsView: View {
    @ObservedObject var params: AppParameters
    @State private var topExpanded: Bool = false

    var body: some View {
        Section(isExpanded: $topExpanded, content: {
            Toggle("Dewiggle", isOn: $params.dewiggle).toggleStyle(.switch)
            Toggle("Point Mass", isOn: $params.pointmass).toggleStyle(.switch)

            EnumPicker(label: "Mass definition", selection: $params.mdefModel)
            EnumPicker(label: "HMF model", selection: $params.hmfModel)
            EnumPicker(label: "Bias model", selection: $params.biasModel)
            EnumPicker(label: "Halo profile (matter)", selection: $params.haloProfileDM)
            EnumPicker(label: "Halo profile (galaxies)", selection: $params.haloProfileSat)
            EnumPicker(label: "Concentration (matter)", selection: $params.haloConcentrationDM)
            EnumPicker(label: "Concentration (galaxies)", selection: $params.haloConcentrationSat)

            LabeledSliderField("Overdensity", value: $params.overdensity, step: 1, range: 50...1000)
            LabeledSliderField("$\\delta_{\\mathrm{c} }$", value: $params.delta_c, step: 0.001, range: 0.5...3.0, format: "%.3f")
            LabeledSliderField("Norm $c(M)$ matter", value: $params.norm_cen, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("Norm $c(M)$ gal", value: $params.norm_sat, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("$\\eta$ matter", value: $params.eta_cen, step: 0.01, range: -2.0...2.0)
            LabeledSliderField("$\\eta$ galaxies", value: $params.eta_sat, step: 0.01, range: -2.0...2.0)

            EnumPicker(label: "HMCode ingredients", selection: $params.hmcodeIngredients)

            if params.hmcodeIngredients == .mead2020_feedback {
                LabeledSliderField("$\\log_{10 } T_{\\mathrm{AGN} }$", value: $params.log10T_AGN, step: 0.01, range: 6.0...10.0)
            }
            if params.hmcodeIngredients == .fit {
                LabeledSliderField("$M_{\\mathrm{b} }$", value: $params.mb, step: 0.01, range: 9.0...15.0)
            }

            EnumPicker(label: "Nonlinear mode", selection: $params.nonlinearMode)
            if params.nonlinearMode == .fortuna {
                LabeledSliderField("$t_{\\mathrm{eff} }$", value: $params.t_eff, step: 0.01, range: 0.0...1.0)
            }
        }, header: { Text("Halo Model Parameters") })
    }
}

// HOD Parameters

struct HODParamsView: View {
    @ObservedObject var params: AppParameters
    @State private var topExpanded: Bool = false

    var body: some View {
        Section(isExpanded: $topExpanded, content: {
            EnumPicker(label: "HOD model", selection: $params.hodModel)
            LabeledNumberField("$M^{* }_{\\mathrm{min} }$", value: $params.obs_min, step: 0.1)
            LabeledNumberField("$M^{* }_{\\mathrm{max} }$", value: $params.obs_max, step: 0.1)

            switch params.hodModel {
            case .Cacciato:
                CacciatoParamsView(p: $params.hodParams)
            case .Zheng:
                ZhengParamsView(p: $params.hodParams)
            case .Simple, .Zehavi:
                SimpleParamsView(p: $params.hodParams)
            case .Zhai:
                ZhaiParamsView(p: $params.hodParams)
            }

            // Assembly bias (all models)
            LabeledSliderField("$A_{\\mathrm{cen} }$", value: $params.hodParams.A_cen, step: 0.01, range: -1.0...1.0)
            LabeledSliderField("$A_{\\mathrm{sat} }$", value: $params.hodParams.A_sat, step: 0.01, range: -1.0...1.0)
        }, header: { Text("HOD Parameters") })
    }
}

struct CacciatoParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("$\\log_{10 } O_{\\mathrm{norm,c} }$", value: $p.log10_obs_norm_c, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{ch} }$", value: $p.log10_m_ch, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\gamma_1$", value: $p.g1, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$\\gamma_2$", value: $p.g2, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$\\sigma_{\\mathrm{c} }$", value: $p.sigma_log10_O_c, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("$\\mathrm{norm}_{\\mathrm{s} }$", value: $p.norm_s, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("$M_{\\mathrm{pivot} }$", value: $p.pivot, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\alpha_{\\mathrm{s} }$", value: $p.alpha_s, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$\\beta_{\\mathrm{s} }$", value: $p.beta_s, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$b_0$", value: $p.b0, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$b_1$", value: $p.b1, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("$b_2$", value: $p.b2, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct ZhengParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{min} }$", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_0$", value: $p.log10_M0, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_1$", value: $p.log10_M1, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\sigma$", value: $p.sigma, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("$\\alpha$", value: $p.alpha, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct SimpleParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{min} }$", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{sat} }$", value: $p.log10_Msat, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\alpha$", value: $p.alpha, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct ZhaiParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{min} }$", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{sat} }$", value: $p.log10_Msat, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\log_{10 } M_{\\mathrm{cut} }$", value: $p.log10_Mcut, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("$\\sigma$", value: $p.sigma, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("$\\alpha$", value: $p.alpha, step: 0.01, range: -5.0...5.0)
        }
    }
}

// Helpers

struct LabeledNumberField: View {
    let label: String
    @Binding var value: Double
    var step: Double = 0.1
    var format: String = "%.4g"

    init(_ label: String, value: Binding<Double>, step: Double = 0.1, format: String = "%.4g") {
        self.label = label
        self._value = value
        self.step = step
        self.format = format
    }

    var body: some View {
        HStack {
            LaTeX(label)
                //.frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            TextField("", value: $value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 60)
        }
    }

    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        f.usesGroupingSeparator = false
        return f
    }
}

struct LabeledSliderField: View {
    let label: String
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let format: String

    // Internal normalized slider value
    @State private var normalizedValue: Double = 0.0

    init(
        _ label: String,
        value: Binding<Double>,
        step: Double = 0.1,
        range: ClosedRange<Double> = 0...1,
        format: String = "%.4g"
    ) {
        self.label = label
        self._value = value
        self.step = step
        self.range = range
        self.format = format

        // Initialize normalizedValue based on the current value
        self._normalizedValue = State(initialValue: Self.normalize(value.wrappedValue, range: range))
    }

    var body: some View {
        HStack {
            LaTeX(label)
                //.frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Slider(value: $normalizedValue)
                .controlSize(.small)
                .frame(width: 120, alignment: .trailing)
                .onChange(of: normalizedValue) {_, newValue in
                    // Update the external value when the slider changes
                    value = Self.denormalize(newValue, range: range)
                }
            TextField("", value: $value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 60, alignment: .trailing)
                .onChange(of: value) {_, newValue in
                    // Update the normalized value when the text field changes
                    normalizedValue = Self.normalize(newValue, range: range)
                }
        }
    }

    // Normalize the external value to a 0...1 range for the slider
    private static func normalize(_ value: Double, range: ClosedRange<Double>) -> Double {
        let rangeSize = range.upperBound - range.lowerBound
        guard rangeSize > 0 else { return 0.0 }
        return (value - range.lowerBound) / rangeSize
    }

    // Denormalize the slider value back to the external value
    private static func denormalize(_ normalizedValue: Double, range: ClosedRange<Double>) -> Double {
        let rangeSize = range.upperBound - range.lowerBound
        return range.lowerBound + normalizedValue * rangeSize
    }

    // Calculate the normalized step size
    private static func normalizedStep(step: Double, range: ClosedRange<Double>) -> Double {
        let rangeSize = range.upperBound - range.lowerBound
        guard rangeSize > 0 else { return 0.01 }
        return step / rangeSize
    }

    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 3
        f.minimumFractionDigits = 0
        f.usesGroupingSeparator = false
        return f
    }
}

struct LabeledIntField: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10000

    var body: some View {
        HStack {
            LaTeX(label)
                //.frame(width: 120, alignment: .leading)
            Spacer()
            TextField("", value: $value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 60)
            //Stepper("\(value)", value: $value, in: range)
            //    .font(.system(size: 12, design: .monospaced))
            //    .frame(width: 60, alignment: .trailing)
        }
    }
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 3
        f.minimumFractionDigits = 0
        f.usesGroupingSeparator = false
        return f
    }
}

struct EnumPicker<T: RawRepresentable & CaseIterable & Hashable>: View
    where T.RawValue == String
{
    let label: String
    @Binding var selection: T

    var body: some View {
        HStack {
            LaTeX(label)
                //.frame(minWidth: 120, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { val in
                    Text(val.rawValue)
                        .tag(val)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(width: 100, alignment: .trailing)
            .truncationMode(.tail)
            .pickerStyle(.menu)
            .fixedSize()
        }
    }
}
