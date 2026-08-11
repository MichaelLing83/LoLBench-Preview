#!/usr/bin/env bash
# Coverage runner for FastAPI PR-4871.
# Measures coverage.py hits against the 4 modified fastapi/*.py files.
set -euo pipefail
PRIV=/opt/lolbench/private
FASTAPI=/workspace/fastapi
SUITE=${LOLBENCH_SUITE:-orig}
cd $FASTAPI
git config --global --add safe.directory $FASTAPI
git reset --hard >/dev/null 2>&1
case "$SUITE" in
    orig|aug|union) ;;
    *) echo "[coverage] unknown LOLBENCH_SUITE=$SUITE" >&2; exit 2 ;;
esac
git apply $PRIV/solution.patch $PRIV/eval_tests.patch
if [ "$SUITE" != "orig" ]; then
    git apply $PRIV/eval_tests_aug.patch
fi
pip install -e . >/tmp/install.log 2>&1 || true

COV_F2P=$PRIV/.coverage.f2p
COV_P2P=$PRIV/.coverage.p2p
COV_F2P_JSON=$PRIV/cov_f2p.json
COV_P2P_JSON=$PRIV/cov_p2p.json
rm -f "$COV_F2P" "$COV_P2P" "$COV_F2P_JSON" "$COV_P2P_JSON"

INCLUDE="fastapi/dependencies/utils.py,fastapi/param_functions.py,fastapi/params.py,fastapi/utils.py"

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

F2P_EFFECTIVE=$PRIV/.f2p_effective.txt
P2P_EFFECTIVE=$PRIV/.p2p_effective.txt
read_selectors f2p > "$F2P_EFFECTIVE"
read_selectors p2p > "$P2P_EFFECTIVE"

run_lane() {
    local data=$1 ids_file=$2 lane=$3
    mapfile -t IDS < <(grep -v '^\s*$' "$ids_file")
    COVERAGE_FILE="$data" python -m coverage run \
        --include="$INCLUDE" --branch \
        -m pytest "${IDS[@]}" -p no:cacheprovider \
        > /tmp/cov-$lane.log 2>&1 || true
}

run_lane "$COV_F2P" "$F2P_EFFECTIVE" f2p
run_lane "$COV_P2P" "$P2P_EFFECTIVE" p2p

emit_json() {
    local data=$1 out=$2
    # fastapi pyproject.toml enables coverage parallel-mode; data files are
    # written as .coverage.<host>.<pid>.<suffix>.  Combine into the single
    # base path first.
    if compgen -G "${data}.*" > /dev/null; then
        COVERAGE_FILE="$data" python -m coverage combine "${data}".* \
            > /tmp/cov-combine.log 2>&1 || true
    fi
    if [ ! -f "$data" ]; then
        echo '{"files":{}}' > "$out"
        return 0
    fi
    if COVERAGE_FILE="$data" python -m coverage json --pretty-print -o "$out" >/tmp/cov-emit.out 2>/tmp/cov-emit.err; then
        [ -s "$out" ] || echo '{"files":{}}' > "$out"
    elif grep -q "No data to report" /tmp/cov-emit.out /tmp/cov-emit.err 2>/dev/null; then
        echo '{"files":{}}' > "$out"
    else
        return 1
    fi
}
emit_json "$COV_F2P" "$COV_F2P_JSON" || echo "f2p json failed"
emit_json "$COV_P2P" "$COV_P2P_JSON" || echo "p2p json failed"

python "$PRIV/compute_coverage.py" \
    --solution-patch "$PRIV/solution.patch" \
    --f2p-json "$COV_F2P_JSON" \
    --p2p-json "$COV_P2P_JSON" \
    --out /out/coverage_report.json

cat /out/coverage_report.json | python -c "
import json, sys
r = json.load(sys.stdin)
s = r['summary']
print(f\"union_pct={s['union_pct']} f2p={s['f2p_pct']} p2p={s['p2p_pct']}\")"
