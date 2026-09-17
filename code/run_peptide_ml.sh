#!/usr/bin/env bash
# run_peptide_ml.sh - run the peptide ML task with the USER's conda env.
#
# The recipe's local step calls this (not peptide_ml.py directly) because the
# watcher runs under cron with a minimal PATH: even `conda` may be invisible.
# So this wrapper re-discovers a working ML interpreter at runtime, in order:
#   1. the envs round 39's probe reported (results/status/machine_probe.json),
#      first one whose python imports numpy+pandas+sklearn wins;
#   2. a fresh scan of $HOME/miniconda3 (and siblings) + PATH, same test;
#   3. nothing found -> exit 1 with a message (honest fail, no fake pass).
#
# No conda activation is needed: the env's python binary is exec'd directly.
# No install is attempted: the user asked to reuse their existing envs.
# Usage: bash code/run_peptide_ml.sh   (repo root as cwd)
set -u -o pipefail
cd "$(dirname "$0")/.."
REPO="$(pwd)"

CANDS_FILE="$(mktemp)"
trap 'rm -f "$CANDS_FILE"' EXIT

# --- 1. envs the probe reported (absolute python paths, probe order) ---
if [ -f results/status/machine_probe.json ]; then
    python3 - results/status/machine_probe.json "$CANDS_FILE" <<'PY' 2>/dev/null || true
import json, os, sys
try:
    d = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    sys.exit(0)
seen = set()
with open(sys.argv[2], 'a', encoding='utf-8') as fh:
    for e in d.get('envs') or []:
        p = e.get('python_exe') or ''
        if p and p not in seen and os.path.isfile(p):
            seen.add(p)
            fh.write(p + '\n')
PY
fi

# --- 2. fresh scan (probe file missing/stale, or envs renamed since) ---
for root in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" \
            "$HOME/mambaforge" /opt/conda /opt/miniconda3; do
    [ -d "$root" ] || continue
    for py in "$root/bin/python" "$root/envs/"*/bin/python; do
        [ -f "$py" ] || continue
        grep -qxF "$py" "$CANDS_FILE" 2>/dev/null || echo "$py" >> "$CANDS_FILE"
    done
done
# --- 2b. windows layout (git-bash): <root>/python.exe, <root>/envs/*/python.exe ---
for root in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" \
            "$HOME/mambaforge" /c/miniconda3 /c/anaconda3 /c/tools/miniconda3; do
    [ -d "$root" ] || continue
    for py in "$root/python.exe" "$root/envs/"*/python.exe; do
        [ -f "$py" ] || continue
        grep -qxF "$py" "$CANDS_FILE" 2>/dev/null || echo "$py" >> "$CANDS_FILE"
    done
done
for cmd in python3 python; do
    hit="$(command -v "$cmd" 2>/dev/null || true)"
    [ -n "$hit" ] || continue
    grep -qxF "$hit" "$CANDS_FILE" 2>/dev/null || echo "$hit" >> "$CANDS_FILE"
done

# --- pick the first interpreter that imports the ML stack ---
TEST='import numpy, pandas, sklearn; print("ml-ok")'
CHOSEN=""
while IFS= read -r py; do
    [ -n "$py" ] || continue
    if [ "$(timeout 60 "$py" -c "$TEST" 2>/dev/null)" = "ml-ok" ]; then
        CHOSEN="$py"
        break
    fi
    echo "   .. $py has no numpy/pandas/sklearn - skipped"
done < "$CANDS_FILE"

if [ -z "$CHOSEN" ]; then
    echo "[FAIL] no python on this machine imports numpy+pandas+sklearn."
    echo "       tried:"; sed 's/^/         /' "$CANDS_FILE"
    echo "       fix: install the stack into a conda env, then re-request the round."
    exit 1
fi

echo "== peptide ML interpreter: $CHOSEN"
"$CHOSEN" --version
exec "$CHOSEN" code/peptide_ml.py
