# Running this lab on Windows (Anaconda + PyCharm)

The upstream README assumes `make` and a Unix `.venv/bin/` layout. On Windows
with Anaconda we don't have `make`, so this repo ships **`run.ps1`** as a
drop-in replacement that drives the lab through the conda env `vinai`.

## One-time setup

1. Open a PowerShell terminal in the repo root (PyCharm: *Terminal* tab — it
   already activates the `vinai` interpreter you selected).
2. Install deps + register the Jupyter kernel:
   ```powershell
   .\run.ps1 setup
   ```
   (Equivalent to `make setup`. Uses Python 3.10–3.13 — `vinai` is 3.13.x. ✔)

## Run + test

```powershell
.\run.ps1 smoke       # 5-second end-to-end check → "All checks passed"
.\run.ps1 data        # generate the 200K-row Bronze sample (needed by NB4)
.\run.ps1 notebooks   # convert .py→.ipynb and execute all 4 with outputs
.\run.ps1 lab         # open Jupyter Lab at http://localhost:8888
```

In Jupyter Lab / PyCharm, pick the **"Python (vinai)"** kernel for the notebooks.

## Important: where the Delta tables are written

delta-rs (the engine behind the lightweight path) **percent-encodes spaces in
local paths**, so it cannot write under `C:\Users\COLOR FULL\...` (the space in
the username becomes `COLOR%20FULL` and fails with *Access is denied*).

`scripts/lakehouse.py` detects this and transparently diverts the data root to
a **space-free directory on the same drive**:

```
C:\vinai_lakehouse\{bronze,silver,gold,scratch}\...
```

The on-disk format is identical to what it would be in the repo's `_lakehouse/`.
To inspect: `tree C:\vinai_lakehouse` or open
`C:\vinai_lakehouse\bronze\llm_calls_raw\_delta_log\00000000000000000000.json`.

Override the location anytime:
```powershell
$env:LAKEHOUSE_ROOT = "D:\somewhere\lakehouse"   # any space-free path, or s3://...
```

## Submitting

`.gitignore` ignores `notebooks/*.ipynb`, but the deliverable **is** the executed
notebooks — force-add them:
```powershell
git add -f notebooks\*.ipynb submission\
```
