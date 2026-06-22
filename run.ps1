<#
  run.ps1 — Windows replacement for the Unix Makefile (lightweight path).

  `make` is not available on this machine and the Makefile uses Unix
  `.venv/bin/` paths, so this script drives the lab through the existing
  Anaconda env instead. Default env name: "vinai".

  Usage (PowerShell, from the repo root):
    .\run.ps1 setup       # install deps into the conda env + register Jupyter kernel
    .\run.ps1 smoke       # 5-second end-to-end smoke test
    .\run.ps1 data        # generate the 200K-row Bronze sample for NB4
    .\run.ps1 notebooks   # convert .py -> .ipynb and execute all 4 in-place
    .\run.ps1 lab         # open Jupyter Lab on http://localhost:8888
    .\run.ps1 clean       # wipe the lakehouse data dir
    .\run.ps1 help

  Override the env:  .\run.ps1 smoke -EnvName myenv
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet('help','setup','smoke','data','notebooks','lab','clean')]
  [string]$Target = 'help',
  [string]$EnvName = 'vinai'
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# Resolve the conda env's python.exe (fall back to whatever python is active).
function Get-EnvPython {
  try {
    $base = (& conda info --base).Trim()
    $candidate = Join-Path $base "envs\$EnvName\python.exe"
    if (Test-Path $candidate) { return $candidate }
  } catch { }
  Write-Warning "Could not find conda env '$EnvName'; falling back to 'python' on PATH."
  return 'python'
}
$PY = Get-EnvPython

switch ($Target) {
  'help' {
    Write-Host ""
    Write-Host "Day 18 Lakehouse Lab — Windows runner (env: $EnvName)" -ForegroundColor Cyan
    Write-Host "  .\run.ps1 setup       install deps + register Jupyter kernel"
    Write-Host "  .\run.ps1 smoke       5-second smoke test"
    Write-Host "  .\run.ps1 data        generate 200K-row Bronze sample"
    Write-Host "  .\run.ps1 notebooks   execute all 4 notebooks in-place"
    Write-Host "  .\run.ps1 lab         open Jupyter Lab (http://localhost:8888)"
    Write-Host "  .\run.ps1 clean       wipe the lakehouse data dir"
    Write-Host ""
    Write-Host "Python: $PY"
  }
  'setup' {
    & $PY -m pip install -r requirements.txt
    & $PY -m ipykernel install --user --name $EnvName --display-name "Python ($EnvName)"
    & $PY -m jupytext --to notebook notebooks\01_delta_basics.py notebooks\02_optimize_zorder.py notebooks\03_time_travel.py notebooks\04_medallion.py
    Write-Host "`n  Setup complete. Run '.\run.ps1 smoke' then '.\run.ps1 data'." -ForegroundColor Green
  }
  'smoke' {
    & $PY scripts\verify_lite.py
  }
  'data' {
    & $PY scripts\generate_data_lite.py
  }
  'notebooks' {
    & $PY -m jupytext --to notebook notebooks\01_delta_basics.py notebooks\02_optimize_zorder.py notebooks\03_time_travel.py notebooks\04_medallion.py
    foreach ($nb in '01_delta_basics','02_optimize_zorder','03_time_travel','04_medallion') {
      Write-Host "=== executing $nb ===" -ForegroundColor Cyan
      & $PY -m nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=$EnvName --ExecutePreprocessor.timeout=600 "notebooks\$nb.ipynb"
    }
    Write-Host "`n  All notebooks executed with outputs preserved." -ForegroundColor Green
  }
  'lab' {
    & $PY -m jupytext --to notebook --update notebooks\*.py 2>$null
    & $PY -m jupyterlab --notebook-dir=notebooks --ServerApp.token='' --no-browser
  }
  'clean' {
    # Mirror lakehouse.py: data lives in a space-free dir when the repo path has a space.
    $root = $env:LAKEHOUSE_ROOT
    if (-not $root) {
      if ($PSScriptRoot -match ' ') {
        $drive = (Split-Path -Qualifier $PSScriptRoot) + '\'
        $root = Join-Path $drive 'vinai_lakehouse'
      } else {
        $root = Join-Path $PSScriptRoot '_lakehouse'
      }
    }
    if (Test-Path $root) { Remove-Item -Recurse -Force $root; Write-Host "Wiped $root" }
    else { Write-Host "Nothing to clean ($root does not exist)" }
  }
}
