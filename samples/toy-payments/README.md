# toy-payments

Tiny fixture for the CodeGraph spike. Not a product.

Settlement is a straight CALLS chain so `callers` / `callees` / `impact` have something to resolve:

`settle_payment` → `authorize_payment` → `post_ledger_entry` → `notify_settlement`

Path owners live in [`CODEOWNERS`](CODEOWNERS). Index from the repo root:

```bash
./scripts/eval-codegraph.sh samples/toy-payments
```
