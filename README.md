# OnePower Explorer — Native macOS App

A native macOS SwiftUI port of the OnePower Streamlit Explorer,
using **PythonKit** to call the `onepower` and `pk_to_real` Python packages
directly from Swift.

---

## Requirements

| Tool | Version |
|---|---|
| macOS | 14 Sonoma or later |
| Xcode | 15 or later |
| Python | 3.10 – 3.12 (system or Homebrew) |
| onepower | latest (`pip install onepower`) |

---

## Setup

### 1. Install the Python dependencies

```bash
pip install onepower numpy
# pk_to_real is part of the onepower package — verify:
python -c "from pk_to_real import PkTransformer; print('OK')"
```

### 2. Tell PythonKit which Python to use

PythonKit reads the environment variable `PYTHON_LIBRARY` to find the
shared Python library (`.dylib`).  Set it before launching the app.

**Homebrew Python 3.12 example:**
```bash
export PYTHON_LIBRARY=$(python3-config --prefix)/lib/libpython3.12.dylib
```

Or hard-code it in the Xcode scheme's **Run → Environment Variables**:
```
PYTHON_LIBRARY = /opt/homebrew/opt/python@3.12/Frameworks/Python.framework/Versions/3.12/lib/libpython3.12.dylib
```

### 3. Open in Xcode

```bash
open OnePowerExplorer.xcodeproj
```

Xcode will automatically resolve the **PythonKit** Swift Package.

### 4. Build & Run

Select the **OnePowerExplorer** scheme → `⌘R`.

---

## Project Structure

```
OnePowerExplorer/
├── OnePowerExplorerApp.swift        # @main entry point
├── Models/
│   ├── AppParameters.swift          # All user-controllable parameters + enums
│   └── ComputedOutput.swift         # Result types + error types
├── Python/
│   └── PythonBridge.swift           # PythonKit wrapper (runs on background queue)
├── ViewModels/
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

* **Log axes** — Swift Charts (macOS 14) does not support true logarithmic
  axes.  The app pre-transforms data with `log10()` and labels the ticks as
  `10^N`.  This is visually identical but the grid lines are evenly spaced in
  log space.

* **Python sandbox** — The app disables the macOS sandbox in the entitlements
  file so that PythonKit can load arbitrary `.dylib` files and packages.
  Do not re-enable the sandbox without also embedding Python.framework.

* **Slow first run** — The Python interpreter is initialised lazily on a
  background thread the first time you press **Run Model**.  Subsequent runs
  reuse the same interpreter and are much faster.

* **Thread safety** — All Python calls are confined to the `PythonBridge`
  serial queue; results are delivered to `@MainActor` via `Task { @MainActor }`.

---

## Customising Python path at runtime

If you want to let users pick their Python installation, you can add a
`PreferencesView` that writes `PYTHON_LIBRARY` to `UserDefaults` and then
calls `Py_SetProgramName` before `PythonBridge.setup()`.

---

## License

Same as the OnePower package — see https://github.com/KiDS-WL/onepower.
