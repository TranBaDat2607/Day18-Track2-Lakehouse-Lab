"""Tiny helper module for the lightweight (delta-rs + DuckDB) path.

Used by all notebooks/*.py — keeps imports + paths consistent.

The Delta tables on disk are the *same format* Spark/Databricks would write,
so a student can later point Spark at `_lakehouse/silver/llm_calls` and get
the same data. This is the value of an open table format.
"""
from __future__ import annotations

import os
from pathlib import Path


def _default_root() -> Path:
    """Resolve where Delta tables live.

    Order of precedence:
      1. ``LAKEHOUSE_ROOT`` env var (set this to ``s3://…`` or any dir you like).
      2. Repo-local ``_lakehouse/`` — easy to inspect, easy to wipe.

    Windows caveat: delta-rs (object_store) percent-encodes spaces in local
    paths (``COLOR FULL`` → ``COLOR%20FULL``), which breaks table creation when
    the repo lives under a path containing a space — e.g. a Windows username
    like ``COLOR FULL``. Short paths and junctions don't help (delta-rs
    canonicalizes them back to the spaced path first). So when the in-repo
    default would contain a space on Windows, divert to a space-free directory
    on the same drive. Override anytime with ``LAKEHOUSE_ROOT``.
    """
    env = os.environ.get("LAKEHOUSE_ROOT")
    if env:
        return Path(env)
    in_repo = Path(__file__).resolve().parents[1] / "_lakehouse"
    if os.name == "nt" and " " in str(in_repo):
        drive = Path(in_repo.anchor or "C:\\")
        return drive / "vinai_lakehouse"
    return in_repo


ROOT = _default_root()


def path(layer: str, table: str) -> str:
    """Return absolute path to a table inside a medallion layer.

    layer ∈ {"bronze", "silver", "gold", "scratch"}.
    """
    p = ROOT / layer / table
    p.parent.mkdir(parents=True, exist_ok=True)
    return str(p)


def reset(*paths: str) -> None:
    """Delete tables (idempotent rerun support). No-op if missing."""
    import shutil
    for p in paths:
        shutil.rmtree(p, ignore_errors=True)


# ── Convenience: swap to S3 / MinIO with one env var ──
# To target s3://bucket/key instead of local disk, set:
#   LAKEHOUSE_ROOT=s3://my-bucket/lakehouse
#   AWS_* env vars per usual
# delta-rs handles the s3:// scheme natively (no Hadoop, no JVM).
