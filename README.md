# graph-for-ai-agents

Repo-local **code-graph knowledge base** for coding agents (Claude Code, Cursor, and similar) via [MCP](https://modelcontextprotocol.io/).

The goal is better **CALLS / impact**, **structure**, and **ownership** context while working a large event-driven microservices codebase — not a custom graph-database product.

This repo is a **thin spike**: reuse an existing local indexer + stdio MCP server. It does not invent a graph engine.

## Purpose

Give an agent a queryable map of a checkout / worktree so it can answer:

- What calls this symbol, and what does it call?
- What is the blast radius of a change?
- How is this service / package structured?
- Who owns this path? (still file-based: `CODEOWNERS` + the graph; not a new ownership DB)

The broader platform (edge → orchestration → integration / processing / security → events → data / monitoring / reconciliation) stays as-is. This KB is for agents working that code.

## Non-goals

- Building or forking a graph database
- Replacing platform services with a graph product
- A team-wide shared ownership / event map (that is a later, different problem)
- Vendoring Neo4j or archived [Kùzu](https://github.com/kuzudb/kuzu) (Kùzu Inc. was acquired by Apple; Kùzu OSS is archived)
- Inventing schemas, query languages, or extractors when an existing tool already does the job

## Decision (do not reopen)

Room consensus for the **repo-local / worktree** case:

| Choice | Status |
| --- | --- |
| Embedded / zero-daemon (SQLite + stdio MCP) | **Win** — spike this first |
| Custom Kùzu MVP | **Dead** — do not build |
| Invent a graph engine | **No** |
| Shared Neo4j service | **Out of scope** for this MVP (only if a later team-wide map is wanted) |

**Spike order** (stop at the first tool that is good enough):

1. **[CodeGraph](https://github.com/colbymchenry/codegraph)** (`@colbymchenry/codegraph`, MIT) — tree-sitter → local SQLite (FTS5) → `codegraph serve --mcp`. First spike.
2. **[CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext)** (MIT, Cypher backends) — only if you need Cypher. Prefer embedded **FalkorDB Lite** or **LadybugDB**. Do not stand up Neo4j. Do not take a dependency on archived Kùzu OSS.
3. **Ladybug / [GitNexus](https://github.com/abhigyanpatwari/GitNexus)** — only if *extending* an existing Ladybug-backed tool, not inventing one.

See [docs/next-steps.md](docs/next-steps.md) for the evaluation checklist.

## Quick start (CodeGraph → Claude Code / Cursor)

You need a machine with CodeGraph on `PATH` (or `npx`). This repo does not vendor CodeGraph.

```bash
# 1. Install the CLI (pick one)
npm i -g @colbymchenry/codegraph
# or: curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

# 2. Wire MCP into your agent(s) once
codegraph install --target=claude,cursor --yes
# or copy config/mcp.codegraph.example.json into Claude Code / Cursor (see docs)

# 3. Index a repo (sample fixture, or any local checkout)
./scripts/eval-codegraph.sh samples/toy-payments
# equivalent: cd /path/to/repo && codegraph init

# 4. Restart Claude Code / Cursor so it launches: codegraph serve --mcp
```

Agents query the graph over **stdio MCP**. They do not talk to a graph daemon. The index lives in the target repo’s `.codegraph/` directory (gitignored).

Full commands, MCP snippets, and what to score: [docs/spike-codegraph.md](docs/spike-codegraph.md).

## Layout

```
config/mcp.codegraph.example.json   # stdio MCP snippet (Claude Code + Cursor)
docs/spike-codegraph.md             # how to run / evaluate CodeGraph
docs/next-steps.md                  # CodeGraph → CGC → Ladybug/GitNexus
samples/toy-payments/               # tiny CALLS / impact / CODEOWNERS fixture
scripts/eval-codegraph.sh           # index + CLI queries (no custom engine)
```

## License

This spike is [MIT](LICENSE).

Upstream tools stay under their own licenses (CodeGraph and CodeGraphContext are MIT). We reuse them; we do not re-license or vendor them here.
