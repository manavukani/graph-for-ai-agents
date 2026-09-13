"""Downstream notification. Owned by @notifications."""


def notify_settlement(payment_id: str, ledger_ref: str) -> str:
    return f"notified:{payment_id}:{ledger_ref}"
