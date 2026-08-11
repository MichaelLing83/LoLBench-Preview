#!/usr/bin/env bash
# Coverage runner for Ruff PR-9599 via cargo-llvm-cov.
#
# cargo-llvm-cov 0.5.36 forbids --no-clean + --no-report together, so we
# use `show-env` to set the coverage env vars (LLVM_PROFILE_FILE etc.)
# and then drive cargo test normally.  The .profraw files accumulate in
# target/llvm-cov-target/.  After tests, `report --lcov` aggregates.
#
# Under --network=none, cargo-llvm-cov's auto-install via rustup fails.
# We export LLVM_COV / LLVM_PROFDATA up-front so it skips the install.
set -uo pipefail
PRIV=/opt/lolbench/private
WS=/workspace
RUFF=$WS/ruff
SUITE=${LOLBENCH_SUITE:-orig}

log() { echo "[coverage] $*" >&2; }

HOST_TRIPLE=$(rustc -vV | grep 'host:' | awk '{print $2}')
SYSROOT=$(rustc --print sysroot)
LLVM_BIN_DIR="$SYSROOT/lib/rustlib/$HOST_TRIPLE/bin"
export LLVM_COV="$LLVM_BIN_DIR/llvm-cov"
export LLVM_PROFDATA="$LLVM_BIN_DIR/llvm-profdata"
log "LLVM_COV=$LLVM_COV"

cd "$RUFF"
git config --global --add safe.directory "$RUFF"
git reset --hard >/dev/null 2>&1
log "applying solution.patch"; git apply "$PRIV/solution.patch"
log "applying eval_tests.patch"; git apply "$PRIV/eval_tests.patch"
case "$SUITE" in
  orig|aug|union) ;;
  *) log "unknown LOLBENCH_SUITE=$SUITE"; exit 2 ;;
esac
if [ "$SUITE" != "orig" ]; then
    log "applying eval_tests_aug.patch"; git apply "$PRIV/eval_tests_aug.patch"
fi

read_selectors() {
    local kind=$1
    case "$SUITE:$kind" in
      orig:f2p)  grep -v '^\s*$' "$PRIV/f2p.txt" ;;
      orig:p2p)  grep -v '^\s*$' "$PRIV/p2p.txt" ;;
      aug:f2p)   grep -v '^\s*$' "$PRIV/f2p_aug.txt" ;;
      aug:p2p)   grep -v '^\s*$' "$PRIV/p2p_aug.txt" ;;
      union:f2p) cat "$PRIV/f2p.txt" "$PRIV/f2p_aug.txt" | grep -v '^\s*$' ;;
      union:p2p) cat "$PRIV/p2p.txt" "$PRIV/p2p_aug.txt" | grep -v '^\s*$' ;;
    esac
}

mapfile -t FAIL_TO_PASS < <(read_selectors f2p)
mapfile -t PASS_TO_PASS < <(read_selectors p2p)

run_set() {
    local label=$1; shift
    local sels=("$@")
    local out="$WS/lcov_${label}.info"
    rm -f "$out"
    # show-env: cargo-llvm-cov prints the coverage env vars; we eval them
    # so subsequent `cargo test` runs produce .profraw under
    # target/llvm-cov-target/.
    cargo llvm-cov clean --workspace --quiet 2>>"$WS/.cov_build.log" || true
    # `show-env --export-prefix` outputs lines like:
    #   export CARGO_LLVM_COV_TARGET_DIR=/workspace/ruff/target/llvm-cov-target
    #   export RUSTFLAGS="-C instrument-coverage ..."
    #   export LLVM_PROFILE_FILE=/.../cov-%p-%m.profraw
    eval "$(cargo llvm-cov show-env --export-prefix 2>>"$WS/.cov_build.log")"
    log "$label: coverage env set; LLVM_PROFILE_FILE=${LLVM_PROFILE_FILE:-unset}"
    log "$label: running ${#sels[@]} selectors"
    for sel in "${sels[@]}"; do
        local file=${sel%%::*}
        local name=${sel##*::}
        log "  $label: $file::$name"
        cargo test -p ruff --test "$file" --color=never \
            -- --exact --nocapture "$name" \
            >>"$WS/.cov_${label}.log" 2>&1 || true
    done
    log "$label: emitting LCOV → $out"
    cargo llvm-cov report --lcov --output-path "$out" --color=never \
        >>"$WS/.cov_${label}.log" 2>&1 || true
    if [ -s "$out" ]; then
        log "$label: LCOV size $(wc -l < "$out") lines"
    else
        log "$label: LCOV empty — last 50 lines of .cov_${label}.log:"
        tail -50 "$WS/.cov_${label}.log" >&2 || true
    fi
}

run_set f2p "${FAIL_TO_PASS[@]}"
run_set p2p "${PASS_TO_PASS[@]}"

mkdir -p /out
set +e
python3 "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --ruff-root "$RUFF" \
    --f2p-lcov "$WS/lcov_f2p.info" \
    --p2p-lcov "$WS/lcov_p2p.info" \
    --out /out/coverage_report.json
analyse_rc=$?
set -e
cp /out/coverage_report.json "$PRIV/coverage_report.json" 2>/dev/null || true

echo
echo "=== coverage_report summary ==="
python3 - <<'PY'
import json
r = json.load(open("/out/coverage_report.json"))
s = r["summary"]
print("  coverage_complete                  :", r.get("coverage_complete", False))
print("  lines added by solution.patch      :", s["lines_in_patch_total"])
print("  executable subset (denominator)    :", s["executable_lines_in_patch"])
print("  F2P covered                        : {:5d}  ({}%)".format(s["f2p_covered"],   s["f2p_pct"]))
print("  P2P covered                        : {:5d}  ({}%)".format(s["p2p_covered"],   s["p2p_pct"]))
print("  F2P union P2P covered              : {:5d}  ({}%)".format(s["union_covered"], s["union_pct"]))
PY
exit $analyse_rc
