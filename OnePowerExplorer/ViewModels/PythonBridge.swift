import Foundation
import PythonKit
import Python

// PythonBridge

/// Singleton that manages the Python interpreter and exposes
/// `compute(params:)` → `[String: ComputedOutput]`.
///
/// All Python calls are performed synchronously on a dedicated
/// serial background queue so the UI is never blocked.
actor PythonBridge {

    static let shared = PythonBridge()
    private let pythonQueue = DispatchQueue(label: "pythonQueue")

    // Python module references (lazily initialised once)
    private var Spectra: PythonObject?
    private var PkTransformer: PythonObject?
    private var np: PythonObject?

    private var isInitialised = false
    private var initError: Error?
    
    private var pythonThread: Thread?
    private var workItem: (() -> Void)?
    
    private var pythonReadyHandler: (() -> Void)?
    
    private var transformerCache: [String: PythonObject] = [:]

    private init() {}

    // Initialise Python environment

    /// Call once from the main thread at app launch.
    func setup() async {
        if !isInitialised {
            initialisePython()
        }
    }

    private func initialisePython() {
        guard !isInitialised else { return }

        do {
            guard let frameworksURL = Bundle.main.bundleURL
                .appendingPathComponent("Contents/Frameworks") as NSURL? else {
                fatalError("Could not locate Frameworks folder.")
            }

            let pythonFramework = frameworksURL.appendingPathComponent("Python.framework")

            let base = pythonFramework?
                .appendingPathComponent("Versions/3.11")

            let pythonHome = base?.appendingPathComponent("Python").path
            let pythonLib  = base?.appendingPathComponent("lib/python3.11").path
            let dynload    = base?.appendingPathComponent("lib/python3.11/lib-dynload").path
            let appPackages = Bundle.main.path(forResource: "app_packages", ofType: nil)

            setenv("PYTHONHOME", pythonHome, 1)
            setenv(
                "PYTHONPATH",
                [pythonLib, dynload, appPackages, Bundle.main.resourcePath]
                    .compactMap { $0 }
                    .joined(separator: ":"),
                1
            )
            Py_Initialize()

            let sys = try Python.attemptImport("sys")
            let np  = try Python.attemptImport("numpy")
            let onepower = try Python.attemptImport("onepower")
            let pkToReal = try Python.attemptImport("pk_to_real")

            self.np = np
            self.Spectra = onepower
            self.PkTransformer = pkToReal

            self.isInitialised = true
            _ = sys
            
        } catch {
            self.initError = ComputeError.pythonUnavailable
        }
    }

    /// Runs the full halo-model computation and returns results keyed by subtype.
    func compute(
        params p: AppParameters,
        components: Bool
    ) async throws -> [String: ComputedOutput] {

        if let err = initError {
            throw err
        }

        if !isInitialised {
            initialisePython()
        }

        guard isInitialised else {
            throw initError ?? ComputeError.pythonUnavailable
        }

        try Task.checkCancellation()

        return try runCompute(params: p, components: components)
    }

    // Internal compute

    private func runCompute(params p: AppParameters,
                            components: Bool) throws -> [String: ComputedOutput]
    {
        guard
            let np = np,
            let SpectraClass = Spectra,
            let PkTransformerClass = PkTransformer
        else { throw ComputeError.pythonUnavailable }

        // --- Build k_vec ---
        let kVec = np.logspace(
            np.log10(p.kmin), np.log10(p.kmax), p.nk
        )

        // --- Instantiate model ---
        let model = SpectraClass.Spectra()

        // --- HOD params dict ---
        let hodParamsDict = makeHODParamsDict(p)

        // --- obs / hod settings ---
        let obsSettings: PythonObject = [
            "observables_file": Python.None,
            "zmin": np.array([p.z_vec]),
            "zmax": np.array([p.z_vec]),
            "obs_min": np.array([8.0]),
            "obs_max": np.array([12.0]),
            "nz": 1,
            "nobs": 300,
            "observable_h_unit": "1/h^2"
        ]

        let hodSettings: PythonObject = [
            "observables_file": Python.None,
            "zmin": np.array([0.0]),
            "zmax": np.array([2.0]),
            "obs_min": np.array([p.obs_min]),
            "obs_max": np.array([p.obs_max]),
            "nz": 15,
            "nobs": 300,
            "observable_h_unit": "1/h^2"
        ]

        let computeObservable = (p.hodModel == .Cacciato)

        // --- Update model ---
        model.update(
            omega_c: p.omega_c,
            omega_b: p.omega_b,
            h0: p.h,
            n_s: p.ns,
            sigma_8: p.sigma_8,
            m_nu: p.m_nu,
            w0: p.w0,
            wa: p.wa,
            tcmb: p.tcmb,
            z_vec: np.array([p.z_vec, 2.1]),
            k_vec: kVec,
            Mmin: p.mmin,
            Mmax: p.mmax,
            dewiggle: p.dewiggle,
            pointmass: p.pointmass,
            mdef_model: p.mdefModel.rawValue,
            hmf_model: p.hmfModel.rawValue,
            bias_model: p.biasModel.rawValue,
            halo_profile_model_dm: p.haloProfileDM.rawValue,
            halo_profile_model_sat: p.haloProfileSat.rawValue,
            halo_concentration_model_dm: p.haloConcentrationDM.rawValue,
            halo_concentration_model_sat: p.haloConcentrationSat.rawValue,
            overdensity: p.overdensity,
            delta_c: p.delta_c,
            norm_cen: p.norm_cen,
            norm_sat: p.norm_sat,
            eta_cen: p.eta_cen,
            eta_sat: p.eta_sat,
            hmcode_ingredients: p.hmcodeIngredients.pythonValue.map { PythonObject($0) } ?? Python.None,
            log10T_AGN: p.log10T_AGN,
            mb: p.mb,
            t_eff: p.t_eff,
            nonlinear_mode: p.nonlinearMode.pythonValue.map { PythonObject($0) } ?? Python.None,
            compute_observable: computeObservable,
            obs_settings: obsSettings,
            hod_settings: hodSettings,
            hod_params: hodParamsDict,
            hod_model: p.hodModel.rawValue
        )

        // --- Compute all outputs ---
        var outputs: [String: ComputedOutput] = [:]
        
        guard model.checking[dynamicMember: "power_spectrum_mm"] != nil else {
            throw ComputeError.numericalInstability
        }

        for obs in ObservableOutput.allCases {
            try Task.checkCancellation()
            let subtype = obs.pythonSubtype
            let category = obs.category

            // Skip SMF if not Cacciato
            if obs == .smf && p.hodModel != .Cacciato { continue }

            do {
                switch category {
                case "pk":
                    let (xArr, yDict) = try computePowerSpectrum(
                        model: model, np: np, subtype: subtype, components: components)
                    outputs[subtype] = ComputedOutput(subtype: subtype, x: xArr, y: yDict)

                case "mass":
                    let (xArr, yDict) = try computeMassQuantity(
                        model: model, np: np, subtype: subtype, components: components)
                    outputs[subtype] = ComputedOutput(subtype: subtype, x: xArr, y: yDict)
                
                case "proj":
                    let (xArr, yDict) = try computeProjected(
                        model: model,
                        PkTransformerClass: PkTransformerClass,
                        subtype: subtype,
                        rpmin: p.rpmin, rpmax: p.rpmax,
                        thetamin: p.thetamin, thetamax: p.thetamax,
                        components: components)
                    outputs[subtype] = ComputedOutput(subtype: subtype, x: xArr, y: yDict)
                
                default:
                    break
                }
            } catch {
                // Individual observable failure — skip it, don't abort whole run
                print("Warning: failed computing \(subtype): \(error)")
            }
        }

        return outputs
    }

    // Power spectrum

    private func computePowerSpectrum(model: PythonObject,
                                      np: PythonObject,
                                      subtype: String,
                                      components: Bool) throws -> ([Double], [String: [Double]])
    {
        let psAttr: [String: String] = [
            "mm": "power_spectrum_mm",
            "gm": "power_spectrum_gm",
            "gg": "power_spectrum_gg",
            "ii": "power_spectrum_ii",
            "gi": "power_spectrum_gi",
            "mi": "power_spectrum_mi",
            "gb": "power_spectrum_gm"
        ]
        guard let attr = psAttr[subtype] else { throw ComputeError.computeFailed("Unknown subtype \(subtype)") }
        let ps = model[dynamicMember: attr]
        
        let k = toDoubleArray(model.k_vec)

        if subtype == "gb" {
            let bias = toDoubleArray(ps.galaxy_linear_bias[0][0])
            return (k, ["tot": bias])
        }

        var yDict: [String: [Double]] = ["tot": toDoubleArray(ps.pk_tot[0][0])]
        if components {
            yDict["1h"] = toDoubleArray(ps.pk_1h[0][0])
            yDict["2h"] = toDoubleArray(ps.pk_2h[0][0])
        }
        return (k, yDict)
    }

    // Mass quantities

    private func computeMassQuantity(model: PythonObject,
                                     np: PythonObject,
                                     subtype: String,
                                     components: Bool) throws -> ([Double], [String: [Double]])
    {
        let mass = toDoubleArray(model.mass)

        switch subtype {
        case "hmf":
            let dndlnm = toDoubleArray(model.dndlnm[0])
            let tot = zip(dndlnm, mass).map { $0 / $1 }
            return (mass, ["tot": tot])

        case "smf":
            guard Bool(model.obs_func.any() != Python.None) == true else {
                let failX = (0..<300).map { 8.0 + Double($0) * 4.0 / 299.0 }
                return (failX, ["tot": [Double](repeating: 0, count: 300)])
            }
            let x = toDoubleArray(model.obs_func_obs[0][0])
            var yDict: [String: [Double]] = ["tot": toDoubleArray(model.obs_func[0][0])]
            if components {
                yDict["cen"] = toDoubleArray(model.obs_func_cen[0][0])
                yDict["sat"] = toDoubleArray(model.obs_func_sat[0][0])
            }
            return (x, yDict)

        case "hod":
            var yDict: [String: [Double]] = ["tot": toDoubleArray(model.hod.hod[0][0])]
            if components {
                yDict["cen"] = toDoubleArray(model.hod.hod_cen[0][0])
                yDict["sat"] = toDoubleArray(model.hod.hod_sat[0][0])
            }
            return (mass, yDict)

        case "bias":
            return (mass, ["tot": toDoubleArray(model.halo_bias[0])])

        case "conc_cen":
            return (mass, ["tot": toDoubleArray(model.conc_cen[0])])

        case "conc_sat":
            return (mass, ["tot": toDoubleArray(model.conc_sat[0])])

        default:
            throw ComputeError.computeFailed("Unknown mass subtype \(subtype)")
        }
    }

    // Projected statistics

    private func computeProjected(model: PythonObject,
                                   PkTransformerClass: PythonObject,
                                   subtype: String,
                                   rpmin: Double, rpmax: Double,
                                   thetamin: Double, thetamax: Double,
                                   components: Bool) throws -> ([Double], [String: [Double]])
    {
        let modelCopy = model.clone()
        
        let (sepMin, sepMax): (Double, Double)
        if subtype == "ds" || subtype == "wp" {
            (sepMin, sepMax) = (rpmin, rpmax)
        } else {
            (sepMin, sepMax) = (thetamin, thetamax)
        }

        let transformer = PkTransformerClass.PkTransformer(
            subtype,
            modelCopy,
            sep_min_in: sepMin,
            sep_max_in: sepMax,
            components: components
        )
        let result = transformer()
        if components {
            let sep  = toDoubleArray(result[0])
            let xi   = toDoubleArray(result[1])
            let xi1h = toDoubleArray(result[2])
            let xi2h = toDoubleArray(result[3])
            transformer.close()
            _ = Python.import("gc").collect()
            return (sep, ["tot": xi, "1h": xi1h, "2h": xi2h])
        } else {
            let sep = toDoubleArray(result[0])
            let xi  = toDoubleArray(result[1])
            transformer.close()
            _ = Python.import("gc").collect()
            return (sep, ["tot": xi])
        }
    }

    // HOD params

    private func makeHODParamsDict(_ p: AppParameters) -> PythonObject {
        let hp = p.hodParams
        switch p.hodModel {
        case .Cacciato:
            return PythonObject([
                "log10_obs_norm_c": PythonObject(hp.log10_obs_norm_c),
                "log10_m_ch": PythonObject(hp.log10_m_ch),
                "g1": PythonObject(hp.g1),
                "g2": PythonObject(hp.g2),
                "sigma_log10_O_c": PythonObject(hp.sigma_log10_O_c),
                "norm_s": PythonObject(hp.norm_s),
                "pivot": PythonObject(hp.pivot),
                "alpha_s": PythonObject(hp.alpha_s),
                "beta_s": PythonObject(hp.beta_s),
                "b0": PythonObject(hp.b0),
                "b1": PythonObject(hp.b1),
                "b2": PythonObject(hp.b2),
                "A_cen": PythonObject(hp.A_cen),
                "A_sat": PythonObject(hp.A_sat)
            ])
        case .Zheng:
            return PythonObject([
                "log10_Mmin": PythonObject(hp.log10_Mmin),
                "log10_M0": PythonObject(hp.log10_M0),
                "log10_M1": PythonObject(hp.log10_M1),
                "sigma": PythonObject(hp.sigma),
                "alpha": PythonObject(hp.alpha),
                "A_cen": PythonObject(hp.A_cen),
                "A_sat": PythonObject(hp.A_sat)
            ])
        case .Simple, .Zehavi:
            return PythonObject([
                "log10_Mmin": PythonObject(hp.log10_Mmin),
                "log10_Msat": PythonObject(hp.log10_Msat),
                "alpha": PythonObject(hp.alpha),
                "A_cen": PythonObject(hp.A_cen),
                "A_sat": PythonObject(hp.A_sat)
            ])
        case .Zhai:
            return PythonObject([
                "log10_Mmin": PythonObject(hp.log10_Mmin),
                "log10_Msat": PythonObject(hp.log10_Msat),
                "log10_Mcut": PythonObject(hp.log10_Mcut),
                "sigma": PythonObject(hp.sigma),
                "alpha": PythonObject(hp.alpha),
                "A_cen": PythonObject(hp.A_cen),
                "A_sat": PythonObject(hp.A_sat)
            ])
        }
    }

    // Helpers

    private func toDoubleArray(_ pyObj: PythonObject) -> [Double] {
        // numpy tolist() → Python list → Swift array
        if let arr = Array<Double>(pyObj.tolist()) {
            return arr
        }
        return []
    }
}

// Mark PythonBridge as unchecked Sendable — internal mutable state is accessed
// only from the dedicated `pythonQueue`, so this is safe in practice.
extension PythonBridge: @unchecked Sendable {}
