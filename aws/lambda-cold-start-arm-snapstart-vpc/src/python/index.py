"""Minimal handler so Init Duration is mostly the runtime, not app code."""

def handler(event, context):
    return {"ok": True}
