# Next-step checklist

Work top to bottom. **Stop at the first tool that is good enough.** Do not invent a graph engine. Do not add Neo4j or archived Kùzu as a dependency.

## 1. Evaluate CodeGraph (current spike)

- [ ] Install `@colbymchenry/codegraph` (MIT) and run [`scripts/eval-codegraph.sh`](../scripts/eval-codegraph.sh) on `samples/toy-payments`
- [ ] Repeat on a real service checkout (worktree-friendly: index stays in that clone’s `.codegraph/`)
- [ ] Register stdio MCP (`codegraph install` or [`config/mcp.codegraph.example.json`](../config/mcp.codegraph.example.json))
- [ ] In Claude Code / Cursor, confirm `codegraph_explore` answers CALLS + impact without a file crawl
- [ ] Note gaps: languages, cross-repo edges, ownership (CODEOWNERS is still the source of truth)

**Ship CodeGraph as the local KB** if CALLS / impact / structure are accurate enough for agent work.

## 2. Only if you need Cypher: CodeGraphContext

Use [CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext) (MIT, `pip install codegraphcontext`) when the agent must run Cypher (`execute_cypher_query`) and CodeGraph’s tools are not enough.

- [ ] `pip install codegraphcontext` and `cgc doctor`
- [ ] Embedded backend only: **FalkorDB Lite** (Unix default) or **LadybugDB** (`cgc config db` / Ladybug extra)
- [ ] **Do not** run `codegraphcontext neo4j setup` or set `NEO4J_*` for this MVP
- [ ] **Do not** adopt archived Kùzu OSS as the long-term engine (CGC may still list Kuzu as a fallback — treat Ladybug / FalkorDB Lite as the allowed embedded options)
- [ ] `cgc index` a sample or local repo, then `cgc mcp setup` / `cgc mcp start`
- [ ] Re-run the same CALLS / impact / structure questions in Cypher + MCP

**Stay on CodeGraph** if Cypher was a nice-to-have, not a requirement.

## 3. Only if extending, not inventing: Ladybug / GitNexus

- [ ] Revisit only if you need Ladybug-native features CodeGraph and CGC lack
- [ ] Prefer **[GitNexus](https://github.com/abhigyanpatwari/GitNexus)** (Ladybug-backed, MCP) over writing your own Ladybug schema
- [ ] Extend GitNexus / Ladybug; do not start a new graph product

## Still out of scope

- Shared Neo4j as a team-wide service / event ownership map — different problem, later
- Custom extractors, query planners, or a homegrown SQLite graph schema
- Replacing edge / orchestration / events / reconciliation services with this KB
