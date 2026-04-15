import Foundation

// Enums

enum HMFModel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case Tinker10, ST, PS, SMT, Jenkins, Warren, Reed03, Reed07, Peacock,
         Angulo, AnguloBound, Watson, Watson_FoF, Crocce, Courtin,
         Bhattacharya, Tinker08, Behroozi, Pillepich, Manera, Ishiyama,
         Bocquet200mDMOnly, Bocquet200mHydro, Bocquet200cDMOnly,
         Bocquet200cHydro, Bocquet500cDMOnly, Bocquet500cHydro
}

enum BiasModel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case Tinker10, Tinker10PBSplit, ST99, Mo96, Jing98, SMT01,
         Seljak04, Seljak04Cosmo, Tinker05, Mandelbaum05,
         Pillepich10, Manera10, TinkerSD05
}

enum HaloProfile: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case NFW, NFWInf, GeneralizedNFW, GeneralizedNFWInf, Einasto,
         Hernquist, HernquistInf, Moore, MooreInf, Constant,
         CoreNFW, PowerLawWithExpCut
}

enum ConcentrationModel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case Duffy08, Bullock01, Bullock01Power, Maccio07,
         Zehavi11, Ludlow16, Ludlow16Empirical
}

enum MassDefModel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case SOMean, SOVirial, SOCritical, FOF
}

enum HMCodeIngredients: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case none = "None"
    case mead2020
    case mead2020_feedback
    case fit
    var pythonValue: String? {
        self == .none ? nil : rawValue
    }
}

enum NonlinearMode: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case none = "None"
    case bnl, hmcode, fortuna
    var pythonValue: String? {
        self == .none ? nil : rawValue
    }
}

enum HODModel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case Cacciato, Zheng, Simple, Zehavi, Zhai
}

// Observable

enum ObservableOutput: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case pmm = "Matter Power Spectrum $P_{\\mathrm{mm}}(k)$"
    case pgm = "Galaxy-matter Power Spectrum $P_{\\mathrm{gm}}(k)$"
    case pgg = "Galaxy-galaxy Power Spectrum $P_{\\mathrm{gg}}(k)$"
    case pii = "Intrinsic-intrinsic Power Spectrum $P_{\\mathrm{II}}(k)$"
    case pgi = "Galaxy-Intrinsic Power Spectrum $P_{\\mathrm{gI}}(k)$"
    case pmi = "Matter-Intrinsic Power Spectrum $P_{\\mathrm{mI}}(k)$"
    case gb  = "Galaxy Bias $b_{\\mathrm{g}}(k)$"
    case hmf = "Halo Mass Function"
    case biasFn = "Halo Bias Function"
    case concMatter = "Concentration (matter)"
    case concGal    = "Concentration (galaxies)"
    case smf = "Stellar Mass Function"
    case hod = "HOD"
    case ds      = "$\\Delta \\Sigma(r_p)$"
    case wp      = "$w_p(r_p)$"
    case wtheta  = "$w(\\theta)$"
    case gamma   = "$\\gamma_t(\\theta)$"
    case xip     = "$\\xi_{+}(\\theta)$"
    case xim     = "$\\xi_{-}(\\theta)$"

    var pythonSubtype: String {
        switch self {
        case .pmm:      return "mm"
        case .pgm:      return "gm"
        case .pgg:      return "gg"
        case .pii:      return "ii"
        case .pgi:      return "gi"
        case .pmi:      return "mi"
        case .gb:       return "gb"
        case .hmf:      return "hmf"
        case .biasFn:   return "bias"
        case .concMatter: return "conc_cen"
        case .concGal:  return "conc_sat"
        case .smf:      return "smf"
        case .hod:      return "hod"
        case .ds:       return "ds"
        case .wp:       return "wp"
        case .wtheta:   return "wtheta"
        case .gamma:    return "gamma"
        case .xip:      return "xip"
        case .xim:      return "xim"
        }
    }

    var category: String {
        switch self {
        case .pmm, .pgm, .pgg, .pii, .pgi, .pmi, .gb: return "pk"
        case .hmf, .biasFn, .concMatter, .concGal, .smf, .hod: return "mass"
        case .ds, .wp, .wtheta, .gamma, .xip, .xim: return "proj"
        }
    }

    var xLabel: String {
        switch self {
        case .pmm, .pgm, .pgg, .pii, .pgi, .pmi, .gb:
            return "$k \\; [h \\; \\mathrm{Mpc}^{-1 }]$"
        case .hmf, .biasFn, .concMatter, .concGal:
            return "$M_h \\; [h^{-1 } \\; M_{\\odot }]$"
        case .hod, .smf:
            return "$M^{* } \\; [h^{-2 } \\; M_{\\odot }]$"
        case .ds, .wp:
            return "$r_p \\; [h^{-1 } \\; \\mathrm{Mpc}]$"
        case .wtheta, .gamma, .xip, .xim:
            return "$\\theta \\; [\\mathrm{arcmin}]$"
        }
    }

    var yLabel: String {
        switch self {
        case .pmm, .pgm, .pgg, .pii, .pgi:
            return "$P(k) \\; [(\\mathrm{Mpc}/h)^3]$"
        case .pmi:
            return "$|P(k)| \\; [(\\mathrm{Mpc}/h)^3]$"
        case .gb:
            return "$b_g(k)$"
        case .hmf:
            return "$\\frac{dn}{dM}$"
        case .biasFn:
            return "$b_h(M)$"
        case .concMatter, .concGal:
            return "$c(M)$"
        case .smf:
            return "$\\Phi \\; [h^3 \\; \\mathrm{dex}^{-1 } \\mathrm{Mpc}^{-3 }]$"
        case .hod:
            return "$<N|M>$"
        case .ds:
            return "$\\Delta \\Sigma \\; [h \\; M_{\\odot }/\\mathrm{pc}^{2 }]$"
        case .wp:
            return "$w_p(r_p) \\; [h^{-1 } \\; \\mathrm{Mpc}]$"
        case .wtheta:
            return "$w(\\theta)$"
        case .gamma:
            return "$\\gamma_t(\\theta)$"
        case .xip:
            return "$\\xi_{+}(\\theta)$"
        case .xim:
            return "$\\xi_{-}(\\theta)$"
        }
    }

    var logX: Bool { true }
    var logY: Bool { self != .gb }
}

// HOD Params

struct HODParams {
    // Cacciato
    var log10_obs_norm_c: Double = 9.95
    var log10_m_ch: Double = 11.24
    var g1: Double = 3.18
    var g2: Double = 0.245
    var sigma_log10_O_c: Double = 0.157
    var norm_s: Double = 0.562
    var pivot: Double = 12.0
    var alpha_s: Double = -1.18
    var beta_s: Double = 2.0
    var b0: Double = -1.17
    var b1: Double = 1.53
    var b2: Double = -0.217
    // Zheng / Simple / Zehavi
    var log10_Mmin: Double = 12.0
    var log10_M0: Double = 12.0
    var log10_M1: Double = 13.0
    var log10_Msat: Double = 13.0
    // Zhai extras
    var log10_Mcut: Double = 12.32
    var sigma: Double = 0.15
    var alpha: Double = 1.0
    // Shared assembly bias
    var A_cen: Double = 0.0
    var A_sat: Double = 0.0
}

// AppParameters

final class AppParameters: ObservableObject, @unchecked Sendable {

    // General
    @Published var kmin: Double = 1e-3
    @Published var kmax: Double = 10.0
    @Published var nk: Int = 300
    @Published var mmin: Double = 9.0
    @Published var mmax: Double = 15.0
    @Published var rpmin: Double = 0.1
    @Published var rpmax: Double = 20.0
    @Published var thetamin: Double = 0.5
    @Published var thetamax: Double = 200.0

    // Cosmology
    @Published var omega_c: Double = 0.25
    @Published var omega_b: Double = 0.05
    @Published var h: Double = 0.7
    @Published var ns: Double = 0.9
    @Published var sigma_8: Double = 0.8
    @Published var z_vec: Double = 0.2
    @Published var m_nu: Double = 0.06
    @Published var w0: Double = -1.0
    @Published var wa: Double = 0.0
    @Published var tcmb: Double = 2.7255

    // Halo model
    @Published var dewiggle: Bool = false
    @Published var pointmass: Bool = false
    @Published var mdefModel: MassDefModel = .SOMean
    @Published var hmfModel: HMFModel = .Tinker10
    @Published var biasModel: BiasModel = .Tinker10
    @Published var haloProfileDM: HaloProfile = .NFW
    @Published var haloProfileSat: HaloProfile = .NFW
    @Published var haloConcentrationDM: ConcentrationModel = .Duffy08
    @Published var haloConcentrationSat: ConcentrationModel = .Duffy08
    @Published var overdensity: Double = 200.0
    @Published var delta_c: Double = 1.696
    @Published var norm_cen: Double = 1.0
    @Published var norm_sat: Double = 1.0
    @Published var eta_cen: Double = 0.0
    @Published var eta_sat: Double = 0.0
    @Published var hmcodeIngredients: HMCodeIngredients = .none
    @Published var log10T_AGN: Double = 7.8
    @Published var mb: Double = 13.87
    @Published var nonlinearMode: NonlinearMode = .none
    @Published var t_eff: Double = 0.0

    // HOD
    @Published var hodModel: HODModel = .Cacciato
    @Published var obs_min: Double = 8.0
    @Published var obs_max: Double = 12.0
    @Published var hodParams = HODParams()
    
    @Published var allOutputs: Set<ObservableOutput> = [.pmm, .pgm, .pgg, .pii, .pgi, .pmi, .gb, .hmf, .biasFn, .concMatter, .concGal, .smf, .hod, .ds, .wp, .wtheta, .gamma, .xip, .xim]
}

extension AppParameters {
    func copy() -> AppParameters {
        let p = AppParameters()
        
        // General
        p.kmin = kmin
        p.kmax = kmax
        p.nk = nk
        p.mmin = mmin
        p.mmax = mmax
        p.rpmin = rpmin
        p.rpmax = rpmax
        p.thetamin = thetamin
        p.thetamax = thetamax
        
        // Cosmology
        p.omega_c = omega_c
        p.omega_b = omega_b
        p.h = h
        p.ns = ns
        p.sigma_8 = sigma_8
        p.z_vec = z_vec
        p.m_nu = m_nu
        p.w0 = w0
        p.wa = wa
        p.tcmb = tcmb
        
        // Halo model
        p.dewiggle = dewiggle
        p.pointmass = pointmass
        p.mdefModel = mdefModel
        p.hmfModel = hmfModel
        p.biasModel = biasModel
        p.haloProfileDM = haloProfileDM
        p.haloProfileSat = haloProfileSat
        p.haloConcentrationDM = haloConcentrationDM
        p.haloConcentrationSat = haloConcentrationSat
        p.overdensity = overdensity
        p.delta_c = delta_c
        p.norm_cen = norm_cen
        p.norm_sat = norm_sat
        p.eta_cen = eta_cen
        p.eta_sat = eta_sat
        p.hmcodeIngredients = hmcodeIngredients
        p.log10T_AGN = log10T_AGN
        p.mb = mb
        p.nonlinearMode = nonlinearMode
        p.t_eff = t_eff
        
        // HOD
        p.hodModel = hodModel
        p.obs_min = obs_min
        p.obs_max = obs_max
        p.hodParams = hodParams
        
        p.allOutputs = allOutputs
        
        return p
    }
}

extension AppParameters {
    func resetParameters() {
        // General
        kmin = 1e-3
        kmax = 10.0
        nk = 300
        mmin = 9.0
        mmax = 15.0
        rpmin = 0.1
        rpmax = 20.0
        thetamin = 0.5
        thetamax = 200.0

        // Cosmology
        omega_c = 0.25
        omega_b = 0.05
        h = 0.7
        ns = 0.9
        sigma_8 = 0.8
        z_vec = 0.2
        m_nu = 0.06
        w0 = -1.0
        wa = 0.0
        tcmb = 2.7255

        // Halo model
        dewiggle = false
        pointmass = false
        mdefModel = .SOMean
        hmfModel = .Tinker10
        biasModel = .Tinker10
        haloProfileDM = .NFW
        haloProfileSat = .NFW
        haloConcentrationDM = .Duffy08
        haloConcentrationSat = .Duffy08
        overdensity = 200.0
        delta_c = 1.696
        norm_cen = 1.0
        norm_sat = 1.0
        eta_cen = 0.0
        eta_sat = 0.0
        hmcodeIngredients = .none
        log10T_AGN = 7.8
        mb = 13.87
        nonlinearMode = .none
        t_eff = 0.0

        // HOD
        hodModel = .Cacciato
        obs_min = 8.0
        obs_max = 12.0
        hodParams = HODParams()

    }
}

@MainActor
final class AppUIState: ObservableObject {
    @Published var selectedOutputs: Set<ObservableOutput> = [.pmm]
    @Published var showComponents: Bool = false
    @Published var compareReference: Bool = false
    @Published var combinePk: Bool = false
    @Published var numberOfColumns: Int = 3
}
