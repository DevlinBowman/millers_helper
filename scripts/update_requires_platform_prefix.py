#!/usr/bin/env python3
"""
scripts/update_requires_platform_prefix.py

Repo-wide Lua require() updater to prefix selected top-level modules with "platform.".

Targets:
  classify
  format
  io
  order_context
  parsers

Rules:
  - Only rewrites require("...") or require('...') string literals.
  - Only rewrites when the require path starts with one of the targets.
  - Does NOT rewrite if it already starts with "platform.".
  - Leaves non-literal requires (require(var)) untouched.

Usage:
  python3 scripts/update_requires_platform_prefix.py --root /path/to/repo --apply
  python3 scripts/update_requires_platform_prefix.py --root . --check
"""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Tuple


TARGET_PREFIXES = ("classify", "format", "io", "order_context", "parsers")

# Matches: require("path") or require('path'), capturing quote + path.
RE_REQUIRE_LITERAL = re.compile(
    r"""require\s*\(\s*(?P<q>["'])(?P<path>[^"']+)(?P=q)\s*\)"""
)


@dataclass(frozen=True)
class Change:
    file_path: str
    original: str
    updated: str
    count: int


def should_prefix(require_path: str) -> bool:
    if require_path.startswith("platform."):
        return False
    for prefix in TARGET_PREFIXES:
        if require_path == prefix or require_path.startswith(prefix + "."):
            return True
    return False


def rewrite_lua_text(text: str) -> Tuple[str, int]:
    changed_count = 0

    def _replace(match: re.Match) -> str:
        nonlocal changed_count
        q = match.group("q")
        path = match.group("path")

        if not should_prefix(path):
            return match.group(0)

        changed_count += 1
        new_path = "platform." + path
        return f'require({q}{new_path}{q})'

    updated = RE_REQUIRE_LITERAL.sub(_replace, text)
    return updated, changed_count


def iter_lua_files(repo_root: str) -> Iterable[str]:
    for dirpath, dirnames, filenames in os.walk(repo_root):
        # Skip common vendored/build dirs if present.
        dirnames[:] = [
            d for d in dirnames
            if d not in (".git", "node_modules", "dist", "build", ".cache", ".venv", "venv")
        ]
        for name in filenames:
            if name.endswith(".lua"):
                yield os.path.join(dirpath, name)


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write_text(path: str, content: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def rewrite_repo(repo_root: str, apply: bool) -> List[Change]:
    changes: List[Change] = []

    for file_path in iter_lua_files(repo_root):
        original = read_text(file_path)
        updated, count = rewrite_lua_text(original)
        if count == 0:
            continue

        changes.append(Change(file_path=file_path, original=original, updated=updated, count=count))
        if apply:
            write_text(file_path, updated)

    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Repo root (default: .)")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="Report changes without writing files")
    mode.add_argument("--apply", action="store_true", help="Apply changes in-place")
    args = parser.parse_args()

    repo_root = os.path.abspath(args.root)
    changes = rewrite_repo(repo_root=repo_root, apply=args.apply)

    total_files = len(changes)
    total_rewrites = sum(c.count for c in changes)

    if args.check:
        print(f"[CHECK] files_with_changes={total_files} require_rewrites={total_rewrites}")
        for c in changes:
            print(f"  - {os.path.relpath(c.file_path, repo_root)} ({c.count})")
        return 1 if total_rewrites > 0 else 0

    print(f"[APPLY] files_changed={total_files} require_rewrites={total_rewrites}")
    for c in changes:
        print(f"  - {os.path.relpath(c.file_path, repo_root)} ({c.count})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
