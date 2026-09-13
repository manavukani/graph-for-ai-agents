"""Ledger write. Owned by @ledger-owners. Changing this should show impact on settle."""


def post_ledger_entry(payment_id: str, amount_cents: int, auth_token: str) -> str:
    if not auth_token.startswith("auth:"):
        raise ValueError("missing authorization")
    return f"ledger:{payment_id}:{amount_cents}"
