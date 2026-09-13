"""Orchestrates authorize → ledger → notify. Primary CALLS / impact root."""

from payments.authorize import authorize_payment
from payments.ledger import post_ledger_entry
from payments.notify import notify_settlement


def settle_payment(payment_id: str, amount_cents: int) -> str:
    auth = authorize_payment(payment_id, amount_cents)
    entry = post_ledger_entry(payment_id, amount_cents, auth)
    return notify_settlement(payment_id, entry)
