#!/usr/bin/env bash
# Index a repo with CodeGraph and run CALLS / impact / structure queries.
# Reuses @colbymchenry/codegraph — does not start a DB server or invent a graph.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: eval-codegraph.sh [repo-path]

  repo-path   Directory to index (default: samples/toy-payments relative to repo root)

Requires CodeGraph on PATH, or npm/npx to run @colbymchenry/codegraph.
Does not register MCP (see config/mcp.codegraph.example.json or: codegraph install).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
target="${1:-${repo_root}/samples/toy-payments}"

if [[ ! -d "${target}" ]]; then
  echo "error: not a directory: ${target}" >&2
  exit 1
fi
target="$(cd "${target}" && pwd)"

resolve_codegraph() {
  if command -v codegraph >/dev/null 2>&1; then
    echo "codegraph"
    return 0
  fi
  if command -v npx >/dev/null 2>&1; then
    echo "npx --yes @colbymchenry/codegraph"
    return 0
  fi
  echo "error: codegraph not on PATH and npx not available." >&2
  echo "Install: npm i -g @colbymchenry/codegraph" >&2
  echo "     or: curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh" >&2
  exit 1
}

CG="$(resolve_codegraph)"
run_cg() {
  # shellcheck disable=SC2086
  ${CG} "$@"
}

echo "==> CodeGraph: $(run_cg version 2>/dev/null || run_cg --version 2>/dev/null || echo unknown)"
echo "==> Target:    ${target}"
echo

if [[ ! -d "${target}/.codegraph" ]]; then
  echo "==> init (create .codegraph/ + index)"
  run_cg init "${target}"
else
  echo "==> index (refresh existing .codegraph/)"
  run_cg index "${target}"
fi

echo
echo "==> status"
run_cg status "${target}" || true

echo
echo "==> structure: files"
run_cg files "${target}/payments" --max-depth 2 || run_cg files "${target}" || true

echo
echo "==> structure: query settle_payment"
run_cg query settle_payment --limit 10 --json || true

echo
echo "==> CALLS: callers of post_ledger_entry"
run_cg callers post_ledger_entry --json || true

echo
echo "==> CALLS: callees of settle_payment"
run_cg callees settle_payment --json || true

echo
echo "==> impact: post_ledger_entry"
run_cg impact post_ledger_entry --depth 3 --json || true

echo
echo "==> explore (same shape as MCP tool codegraph_explore)"
run_cg explore "how does settle_payment reach notify_settlement" || true

echo
echo "==> ownership (file-based; not a graph node type)"
if [[ -f "${target}/CODEOWNERS" ]]; then
  cat "${target}/CODEOWNERS"
else
  echo "(no CODEOWNERS in ${target} — use the target repo's CODEOWNERS / OWNERS)"
fi

echo
echo "Next: wire stdio MCP (do not run a graph daemon):"
echo "  codegraph install --target=claude,cursor --yes"
echo "  # or copy ${repo_root}/config/mcp.codegraph.example.json"
echo "  # Claude Code: ~/.claude.json or project .mcp.json"
echo "  # Cursor:      ~/.cursor/mcp.json or .cursor/mcp.json"
echo "Restart the agent so it spawns: codegraph serve --mcp"
echo
echo "Score results with docs/spike-codegraph.md. If Cypher is required, see docs/next-steps.md."
