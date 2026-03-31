# OnePower Explorer — Native macOS App

A native macOS SwiftUI port of the OnePower Explorer streamlit app,
using **PythonKit** to call the `onepower` and `pk_to_real` Python packages
directly from Swift.

---

## Requirements

| Tool | Version |
|---|---|
| macOS | 15 Sequoia or later |

---

## Project Structure

```
OnePowerExplorer/
├── OnePowerExplorerApp.swift        # @main entry point
├── Models/
│   ├── AppParameters.swift          # All user-controllable parameters + enums
│   └── ComputedOutput.swift         # Result types + error types
├── ViewModels/
│   ├── PythonBridge.swift           # PythonKit wrapper (runs on background queue)
│   └── ExplorerViewModel.swift      # @MainActor state coordinator
└── Views/
    ├── ContentView.swift            # NavigationSplitView root
    ├── SidebarView.swift            # All parameter controls
    ├── MainAreaView.swift           # Toolbar + tabbed output area
    └── PlotViews.swift              # Swift Charts log-log plots + ratio panels
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  SidebarView  (parameter controls)                       │
│  ↓ binding to AppParameters                              │
│                                                          │
│  ExplorerViewModel  (@MainActor)                         │
│    - holds AppParameters                                 │
│    - holds computedOutputs: [String: ComputedOutput]     │
│    - calls PythonBridge.shared.compute(…)                │
│                                                          │
│  PythonBridge  (serial background DispatchQueue)         │
│    - imports onepower.Spectra via PythonKit              │
│    - imports pk_to_real.PkTransformer via PythonKit      │
│    - calls model.update(**params) then reads results     │
│    - converts numpy arrays → [Double] via .tolist()      │
│                                                          │
│  PlotViews  (Swift Charts)                               │
│    - log10-transforms data; labels axes as 10^N          │
│    - ratio panel shows (live − ref) / ref × 100 %        │
└─────────────────────────────────────────────────────────┘
```

---

## Feature parity with the Streamlit app

| Streamlit feature | macOS app |
|---|---|
| All 19 observables | ✅ |
| Cosmological parameters | ✅ |
| Halo model parameters (HMF, bias, profile, concentration, HMCode, …) | ✅ |
| All 5 HOD models with per-model parameter panels | ✅ |
| Show individual 1h/2h components | ✅ |
| Add models for comparison | ✅ |
| Set / clear reference model | ✅ |
| Relative-difference ratio panel | ✅ |
| Combine power spectra on one plot | ✅ |
| CSV export | ✅ (native NSSavePanel) |
| Loading messages from Middle-Universe | ✅ |
| Warning banners (redshift, projection, IA, SMF) | ✅ |
| MathJax axis labels | ⚠️  Unicode approximations (Swift Charts limitation) |
| Plotly interactive hover | ⚠️  Swift Charts provides basic hover tooltips |

---

## Known limitations & tips

* **Log axes** — Swift Charts (macOS 15) does not support true logarithmic
  axes.  The app pre-transforms data with `log10()` and labels the ticks as
  `10^N`.  This is visually identical but the grid lines are evenly spaced in
  log space.

* **Thread safety** — All Python calls are confined to the `PythonBridge`
  serial queue; results are delivered to `@MainActor` via `Task { @MainActor }`.

