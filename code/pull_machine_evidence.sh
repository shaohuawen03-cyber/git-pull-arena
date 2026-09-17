#!/usr/bin/env bash
# pull_machine_evidence.sh - take the machine's own report before committing.
#
# Why this exists (round 30, on the real user machine): the watcher pushes
# results/ (receipt, quality report, page sources, finished pptx). The agent's
# worktree still holds ITS OWN copies from a sandbox run, so the next
# `agent-sync.sh` (or `agent-check.sh --accept`) commits those stale files over
# the machine's report - the repo then shows environment=sandbox for a round the
# machine actually passed. `accept` is fixed (it restores results/ first); this
# script is the same guard for the sync path, and can be run any time:
#
#   bash code/pull_machine_evidence.sh        # before agent-sync / after a verdict
#
# It only touches paths the machine owns (results/**); anything the agent creates
# inside results/ that the remote does not have is left alone.
#
# Exit 0 = done (worktree now carries the remote's copy of the machine's files),
# 1 = could not fetch (no remote / offline).
set -u -o pipefail
cd "$(dirname "$0")/.."

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
REMOTE="origin"
if [ -f skills/git-sync/sync.config.json ]; then
    R=$(sed -n 's/.*"remote"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        skills/git-sync/sync.config.json | head -1)
    [ -n "$R" ] && REMOTE="$R"
fi
if [ -z "$BRANCH" ]; then
    echo "[FAIL] not on a branch"
    exit 1
fi
if ! git fetch "$REMOTE" --quiet; then
    echo "[WARN] git fetch failed - keeping the worktree as it is"
    exit 1
fi
ORIGIN="$REMOTE/$BRANCH"
if ! git rev-parse --verify --quiet "$ORIGIN" >/dev/null; then
    echo "[WARN] $ORIGIN does not exist yet - nothing to restore"
    exit 0
fi

# only the paths the MACHINE writes: its round logs, the two receipts, the
# checker evidence, the page sources and the finished decks. Everything else
# under results/ is the agent's (above all results/status/success_criteria.json,
# which the agent edits and the machine only reads) and is left alone.
# Round 39: the probe report + all *_receipt.* + the peptide task dir joined the
# list (accept had buried the machine's LAPTOP probe under a stale sandbox copy).
# Rule: every NEW evidence path a recipe's local plane writes must be added here
# AND in skills/git-sync/scripts/agent-check.sh (--accept), or accept/sync will
# clobber it with the worktree's stale copy.
restored=0
for pat in 'results/status/check_r*.txt' 'results/status/pptmaster_local*' \
           'results/status/svg/*' 'results/*/pptmaster_local*' 'results/*/svg/*' \
           'results/*/DECK_*.pptx' 'results/status/machine_probe.*' \
           'results/status/*_receipt.*' 'results/peptide_ml/*'; do
    for f in $pat; do
        [ -f "$f" ] || continue
        if git cat-file -e "$ORIGIN:$f" 2>/dev/null; then
            if [ "$(git hash-object "$f" 2>/dev/null)" != "$(git rev-parse "$ORIGIN:$f" 2>/dev/null)" ]; then
                git checkout "$ORIGIN" -- "$f" 2>/dev/null && {
                    echo "   restored $f (machine's copy)"
                    restored=$((restored + 1))
                }
            fi
        fi
    done
done

echo "== machine evidence in place ($restored file(s) restored from $ORIGIN)"
