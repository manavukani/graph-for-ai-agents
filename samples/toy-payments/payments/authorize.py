"""Risk / auth step. Owned by @risk-owners in CODEOWNERS."""


def authorize_payment(payment_id: str, amount_cents: int) -> str:
    if amount_cents <= 0:
        raise ValueError("amount_cents must be positive")
    return f"auth:{payment_id}:{amount_cents}"
