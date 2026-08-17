#!/usr/bin/env bash

# Lightweight static and synthetic validation for the active production workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
active=(
    project_config.sh BIDSto3col.sh gen3colfiles.sh
    run_gen3colfiles.sh run_logged.sh
    L1stats.sh run_L1stats.sh L2stats.sh run_L2stats.sh
    L3stats.sh run_L3stats.sh validate_workflow.sh
)

for script in "${active[@]}"; do
    bash -n "${SCRIPT_DIR}/${script}"
done
echo "PASS: bash syntax"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x "${active[@]/#/${SCRIPT_DIR}/}"
    echo "PASS: ShellCheck"
else
    echo "SKIP: ShellCheck is not installed"
fi

PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/socdoors-pycache" python3 -m py_compile "${SCRIPT_DIR}/build_L1_manifest.py"
echo "PASS: Python syntax"

production=(project_config.sh gen3colfiles.sh run_gen3colfiles.sh L1stats.sh run_L1stats.sh L2stats.sh run_L2stats.sh L3stats.sh run_L3stats.sh)
if grep -En 'rf1-sra-data|rf1-sra/stimuli|istart-socdoors' "${production[@]/#/${SCRIPT_DIR}/}"; then
    echo "ERROR: obsolete production path or clone instruction found." >&2
    exit 1
fi
echo "PASS: no obsolete production paths"

bash "${PROJECT_ROOT}/tests/test_workflow.sh"
