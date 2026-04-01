import SwiftUI

struct SidebarView: View {
    @ObservedObject var params: AppParameters
    @ObservedObject var uiState: AppUIState
    @ObservedObject var vm: ExplorerViewModel
    @State private var topExpanded: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                // Header logo / title
                /*
                VStack(alignment: .leading, spacing: 2) {
                    Text("OnePower Explorer")
                        .font(.title2).bold()
                    Text("Halo Model & Predictions")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                */
                //Divider()

                // Run button
                /*
                Button(action: { vm.runModel() }) {
                    Label("Run Model", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(params.selectedOutputs.isEmpty)
                */
                // UI toggles
                GroupBox("Display") {
                    VStack(alignment: .leading) {
                        Toggle("Compare to reference model", isOn: $uiState.compareReference)
                        Toggle("Show halo model components", isOn: $uiState.showComponents)
                        Toggle("Combine power spectra on one plot", isOn: $uiState.combinePk)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Observable selection
                ObservableSelectionView(uiState: uiState)

                // General settings
                DisclosureGroup("General Settings", isExpanded: $topExpanded) {
                    GeneralSettingsView(params: params)
                }

                // Cosmological parameters
                DisclosureGroup("Cosmological Parameters") {
                    CosmoParamsView(params: params)
                }

                // Halo model parameters
                DisclosureGroup("Halo Model Parameters") {
                    HaloModelParamsView(params: params)
                }

                // HOD parameters
                DisclosureGroup("HOD Parameters") {
                    HODParamsView(params: params)
                }

                Divider()

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
        }
        .frame(maxWidth: .infinity)
    }
}

// Observable Selection

struct ObservableSelectionView: View {
    @ObservedObject var uiState: AppUIState

    var body: some View {
        GroupBox("Observables") {
            VStack(alignment: .leading) {
                ForEach(ObservableOutput.allCases) { obs in
                    Toggle(obs.rawValue, isOn: Binding(
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
                    ))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// General Settings

struct GeneralSettingsView: View {
    @ObservedObject var params: AppParameters

    var body: some View {
        VStack(alignment: .leading) {
            LabeledIntField(label: "N_k points", value: $params.nk, range: 10...1000)
            LabeledNumberField("k_min [h Mpc⁻¹]", value: $params.kmin, format: "%.4e")
            LabeledNumberField("k_max [h Mpc⁻¹]", value: $params.kmax)
            LabeledNumberField("M_min [log₁₀]", value: $params.mmin)
            LabeledNumberField("M_max [log₁₀]", value: $params.mmax)
            LabeledNumberField("r_p,min [h⁻¹ Mpc]", value: $params.rpmin)
            LabeledNumberField("r_p,max [h⁻¹ Mpc]", value: $params.rpmax)
            LabeledNumberField("θ_min [arcmin]", value: $params.thetamin)
            LabeledNumberField("θ_max [arcmin]", value: $params.thetamax)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Cosmological Parameters

struct CosmoParamsView: View {
    @ObservedObject var params: AppParameters

    var body: some View {
        VStack(alignment: .leading) {
            LabeledSliderField("Ω_c", value: $params.omega_c, step: 0.01, range: 0.001...1.0)
            LabeledSliderField("Ω_b", value: $params.omega_b, step: 0.00, range: 0.001...1.0)
            LabeledSliderField("h", value: $params.h, step: 0.01, range: 0.1...1.0)
            LabeledSliderField("n_s", value: $params.ns, step: 0.005, range: 0.0...2.0)
            LabeledSliderField("σ₈", value: $params.sigma_8, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("Redshift z", value: $params.z_vec, step: 0.1, range: 0.0...2.0)
            LabeledSliderField("Σ m_ν [eV]", value: $params.m_nu, step: 0.01, range: 0.0...0.1)
            LabeledSliderField("w₀", value: $params.w0, step: 0.05, range: -1.5...(-0.5))
            LabeledSliderField("w_a", value: $params.wa, step: 0.05, range: -1.0...0.5)
            LabeledSliderField("T_CMB [K]", value: $params.tcmb, step: 0.01, range: 2.0...5.0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Halo Model Parameters

struct HaloModelParamsView: View {
    @ObservedObject var params: AppParameters

    var body: some View {
        VStack(alignment: .leading) {
            //Toggle("Dewiggle", isOn: $params.dewiggle).toggleStyle(.checkbox)
            //Toggle("Point Mass", isOn: $params.pointmass).toggleStyle(.checkbox)
            
            GroupBox() {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Dewiggle", isOn: $params.dewiggle)
                    Toggle("Point Mass", isOn: $params.pointmass)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            EnumPicker(label: "Mass definition", selection: $params.mdefModel)
            EnumPicker(label: "HMF model", selection: $params.hmfModel)
            EnumPicker(label: "Bias model", selection: $params.biasModel)
            EnumPicker(label: "Halo profile (matter)", selection: $params.haloProfileDM)
            EnumPicker(label: "Halo profile (galaxies)", selection: $params.haloProfileSat)
            EnumPicker(label: "Concentration (matter)", selection: $params.haloConcentrationDM)
            EnumPicker(label: "Concentration (galaxies)", selection: $params.haloConcentrationSat)

            LabeledSliderField("Overdensity", value: $params.overdensity, step: 1, range: 50...1000)
            LabeledSliderField("δ_c", value: $params.delta_c, step: 0.001, range: 0.5...3.0, format: "%.3f")
            LabeledSliderField("Norm c(M) matter", value: $params.norm_cen, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("Norm c(M) gal", value: $params.norm_sat, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("η matter", value: $params.eta_cen, step: 0.01, range: -2.0...2.0)
            LabeledSliderField("η galaxies", value: $params.eta_sat, step: 0.01, range: -2.0...2.0)

            EnumPicker(label: "HMCode ingredients", selection: $params.hmcodeIngredients)

            if params.hmcodeIngredients == .mead2020_feedback {
                LabeledSliderField("log₁₀ T_AGN", value: $params.log10T_AGN, step: 0.01, range: 6.0...10.0)
            }
            if params.hmcodeIngredients == .fit {
                LabeledSliderField("M_b", value: $params.mb, step: 0.01, range: 9.0...15.0)
            }

            EnumPicker(label: "Nonlinear mode", selection: $params.nonlinearMode)
            if params.nonlinearMode == .fortuna {
                LabeledSliderField("t_eff", value: $params.t_eff, step: 0.01, range: 0.0...1.0)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// HOD Parameters

struct HODParamsView: View {
    @ObservedObject var params: AppParameters

    var body: some View {
        VStack(alignment: .leading) {
            EnumPicker(label: "HOD model", selection: $params.hodModel)
            LabeledNumberField("obs_min [log₁₀]", value: $params.obs_min, step: 0.1)
            LabeledNumberField("obs_max [log₁₀]", value: $params.obs_max, step: 0.1)

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
            LabeledSliderField("A_cen", value: $params.hodParams.A_cen, step: 0.01, range: -1.0...1.0)
            LabeledSliderField("A_sat", value: $params.hodParams.A_sat, step: 0.01, range: -1.0...1.0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CacciatoParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("log₁₀ O_norm,c", value: $p.log10_obs_norm_c, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M_ch", value: $p.log10_m_ch, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("γ₁", value: $p.g1, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("γ₂", value: $p.g2, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("σ_c", value: $p.sigma_log10_O_c, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("norm_s", value: $p.norm_s, step: 0.01, range: 0.0...2.0)
            LabeledSliderField("M_pivot", value: $p.pivot, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("α_s", value: $p.alpha_s, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("β_s", value: $p.beta_s, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("b₀", value: $p.b0, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("b₁", value: $p.b1, step: 0.01, range: -5.0...5.0)
            LabeledSliderField("b₂", value: $p.b2, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct ZhengParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("log₁₀ M_min", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M₀", value: $p.log10_M0, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M₁", value: $p.log10_M1, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("σ", value: $p.sigma, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("α", value: $p.alpha, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct SimpleParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("log₁₀ M_min", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M_sat", value: $p.log10_Msat, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("α", value: $p.alpha, step: 0.01, range: -5.0...5.0)
        }
    }
}

struct ZhaiParamsView: View {
    @Binding var p: HODParams
    var body: some View {
        Group {
            LabeledSliderField("log₁₀ M_min", value: $p.log10_Mmin, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M_sat", value: $p.log10_Msat, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("log₁₀ M_cut", value: $p.log10_Mcut, step: 0.01, range: 1.0...15.0)
            LabeledSliderField("σ", value: $p.sigma, step: 0.01, range: 0.01...3.0)
            LabeledSliderField("α", value: $p.alpha, step: 0.01, range: -5.0...5.0)
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
            Text(label)
                .frame(width: 120, alignment: .leading)
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
            Text(label)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Slider(value: $normalizedValue)
                .controlSize(.small)
                .onChange(of: normalizedValue) {_, newValue in
                    // Update the external value when the slider changes
                    value = Self.denormalize(newValue, range: range)
                }
            Spacer()
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
            Text(label)
                .frame(width: 120, alignment: .leading)
            Spacer()
            Stepper("\(value)", value: $value, in: range)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 120, alignment: .trailing)
        }
    }
}

struct EnumPicker<T: RawRepresentable & CaseIterable & Hashable>: View
    where T.RawValue == String
{
    let label: String
    @Binding var selection: T

    var body: some View {
        HStack {
            Text(label)
                .frame(minWidth: 120, alignment: .leading)
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
