# Spike: CodeGraph via MCP

Evaluate **[CodeGraph](https://github.com/colbymchenry/codegraph)** (`@colbymchenry/codegraph`, MIT) against a local repo. Do not write a graph engine.

CodeGraph parses with tree-sitter, stores symbols and edges in **SQLite + FTS5** under `.codegraph/`, and speaks **MCP over stdio** (`codegraph serve --mcp`). That matches the repo-local / worktree case: no daemon, no Neo4j, no Kùzu.

Upstream docs: [install](https://colbymchenry.github.io/codegraph/getting-started/installation/), [CLI](https://colbymchenry.github.io/codegraph/reference/cli/).

## What you are scoring

Use a real checkout if you have one (Ripple / RLUSD services). Otherwise use [`samples/toy-payments`](../samples/toy-payments) — a tiny settlement flow with CALLS, structure, and `CODEOWNERS`.

| Question | How to probe | Pass if |
| --- | --- | --- |
| CALLS | `codegraph callers -p <repo> post_ledger_entry` / `codegraph callees -p <repo> settle_payment` | Callers and callees match source |
| Impact | `codegraph impact -p <repo> post_ledger_entry` | Blast radius includes `settle_payment` (and notify if linked) |
| Structure | `codegraph files` / `codegraph query settle` | Modules and symbols are listed |
| Ownership | Open `CODEOWNERS` next to the graph | Agent can combine path owners with impact (CodeGraph does not replace CODEOWNERS) |
| MCP | Agent lists `codegraph_explore` after restart | Stdio server starts; no extra process to babysit |
| Worktree | `codegraph init` in a second clone | Index is per-checkout (`.codegraph/`), not a shared service |

If Cypher is required after this, stop and go to CodeGraphContext ([next steps](next-steps.md)). Do not extend CodeGraph into a custom DB.

## Install CodeGraph

Pick one. Open a **new shell** after the installer so `codegraph` is on `PATH`.

```bash
npm i -g @colbymchenry/codegraph
# or (no global npm):
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

Optional: `codegraph telemetry off` (anonymous usage is on by default upstream).

## Index a repo

```bash
# This repo's fixture (from the repo root)
./scripts/eval-codegraph.sh samples/toy-payments

# Any other checkout
cd /path/to/your/repo
codegraph init
codegraph status
```

`init` creates `.codegraph/` and builds the graph. While `codegraph serve --mcp` is running, a file watcher keeps the index fresh. For scripts / CI without the watcher, use `codegraph index` (full) or `codegraph sync` (incremental).

Do not commit `.codegraph/` (already in this repo’s `.gitignore`).

## Wire MCP (Claude Code / Cursor)

**Preferred:** let CodeGraph write agent config:

```bash
codegraph install --target=claude,cursor --yes
# project-local instead of global:
codegraph install --target=claude,cursor --location=local --yes
```

**Manual:** copy [`config/mcp.codegraph.example.json`](../config/mcp.codegraph.example.json).

| Client | Typical drop-in |
| --- | --- |
| Claude Code (user) | `mcpServers` in `~/.claude.json` |
| Claude Code (project) | `.mcp.json` in the repo root |
| Cursor (user) | `~/.cursor/mcp.json` |
| Cursor (project) | `.cursor/mcp.json` |

Stdio command is always:

```text
codegraph serve --mcp
```

Optional flags: `--path <repo>` (otherwise the client’s workspace root) and `--no-watch` on slow filesystems. Restart the agent after changing MCP config. You do not run `serve` yourself; the client spawns it. The CLI `codegraph explore` command returns the same payload as the `codegraph_explore` MCP tool, so you can score CALLS / impact without an IDE.

Default MCP surface is one tool: **`codegraph_explore`** (source + call paths + blast radius). Narrower tools (`codegraph_callers`, `codegraph_impact`, …) exist but are unlisted unless you set e.g. `CODEGRAPH_MCP_TOOLS=explore,node,search,callers,callees,impact,files,status`. CLI equivalents work without MCP:

```bash
# From inside the indexed repo, or pass --path / -p
codegraph query settle_payment --json
codegraph callers post_ledger_entry --json
codegraph callees settle_payment --json
codegraph impact post_ledger_entry --depth 3 --json
codegraph explore "how does settle_payment reach notify_settlement"
```

Query commands default to cwd’s `.codegraph/`. The eval script always passes `--path` so you can run it from this repo root.

## Eval script

[`scripts/eval-codegraph.sh`](../scripts/eval-codegraph.sh) resolves `codegraph` (PATH, then `npx @colbymchenry/codegraph`), indexes the target directory, and runs the queries above. It never starts a database server.

```bash
./scripts/eval-codegraph.sh                  # defaults to samples/toy-payments
./scripts/eval-codegraph.sh /path/to/repo
```

## Prompts to try in Claude Code / Cursor

After MCP is connected and the target repo is indexed:

- “Using CodeGraph, who calls `post_ledger_entry` and what is the impact of changing it?”
- “Using `codegraph_explore`, how does `settle_payment` reach `notify_settlement`?”
- “What is the structure of `samples/toy-payments`, and who owns `payments/ledger.py`?”

Expect the agent to call MCP (or you run the CLI) instead of grepping the tree.

## If CodeGraph is not enough

Do **not** add a schema or a new extractor in this repo. Follow [next-steps.md](next-steps.md): CodeGraphContext (Cypher, embedded backend) → only then Ladybug / GitNexus as an extension.
