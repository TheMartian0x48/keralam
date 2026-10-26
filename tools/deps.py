#!/usr/bin/env python3
"""Download kashmir into vendor/kashmir at a pinned commit, and repair the checkout.

    python3 tools/deps.py            (or: make deps)

Repair is a fresh clone: vendor/kashmir is a cache, never a place to edit. It is
re-created when it is missing, is not a git repository, sits on another commit, or has
local edits.
"""
import shutil
import subprocess
import sys
from pathlib import Path

KASHMIR_URL = "https://github.com/TheMartian0x48/kashmir"
KASHMIR_COMMIT = "50dd489fc567014cc7aa2f870d9f16bebacdd58a"
KASHMIR_PATH = Path(__file__).resolve().parent.parent / "vendor" / "kashmir"


def git(cwd, *args):
    """Run git and return its trimmed stdout, or None on failure (stderr is printed)."""
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=str(cwd) if cwd else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
    except OSError as error:
        print("deps: cannot run git: {}".format(error), file=sys.stderr)
        return None
    if result.returncode != 0:
        print("deps: git {} failed:\n{}".format(" ".join(args), result.stderr), file=sys.stderr)
        return None
    return result.stdout.strip()


def checkout_is_healthy():
    """A git repository on the pinned commit with a clean tree."""
    if not (KASHMIR_PATH / ".git").exists():
        return False
    if git(KASHMIR_PATH, "rev-parse", "HEAD") != KASHMIR_COMMIT:
        return False
    return git(KASHMIR_PATH, "status", "--porcelain") == ""


def clone_checkout():
    if KASHMIR_PATH.exists():
        shutil.rmtree(str(KASHMIR_PATH))
    KASHMIR_PATH.parent.mkdir(parents=True, exist_ok=True)
    if git(None, "clone", "--quiet", KASHMIR_URL, str(KASHMIR_PATH)) is None:
        return False
    if git(KASHMIR_PATH, "checkout", "--quiet", KASHMIR_COMMIT) is None:
        return False
    return checkout_is_healthy()


def main():
    short = KASHMIR_COMMIT[:12]
    if checkout_is_healthy():
        print("deps: kashmir {} ok ({})".format(short, KASHMIR_PATH))
        return 0
    print("deps: fetching kashmir {} into {}".format(short, KASHMIR_PATH))
    if not clone_checkout():
        print("deps: could not set up kashmir", file=sys.stderr)
        return 1
    print("deps: kashmir {} ready".format(short))
    return 0


if __name__ == "__main__":
    sys.exit(main())
