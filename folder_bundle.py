#!/usr/bin/env python3
"""Pack a folder into a single plain-text bundle and unpack it again.

Usage:
    folder_bundle.py pack <folder> [-o bundle.txt] [--exclude GLOB ...]
    folder_bundle.py unpack <bundle.txt> [-o outdir] [--force]

Bundle format (byte-length prefixed, so content can never clash with markers):
    #BUNDLE v1
    #FILE <byte_length> <relative/posix/path>
    <exactly byte_length bytes of content>
    #END
"""
import argparse
import fnmatch
import os
import sys
from pathlib import Path

MAGIC = b"#BUNDLE v1\n"
DEFAULT_EXCLUDES = [".git", "__pycache__"]


def is_excluded(rel, patterns):
    parts = rel.split("/")
    return any(
        fnmatch.fnmatch(p, pat) or fnmatch.fnmatch(rel, pat)
        for pat in patterns
        for p in parts
    )


def pack(folder, output, excludes):
    root = Path(folder).resolve()
    if not root.is_dir():
        sys.exit(f"error: {folder} is not a directory")
    out = Path(output).resolve() if output else Path(f"{root.name}.bundle.txt").resolve()
    patterns = DEFAULT_EXCLUDES + list(excludes)

    count = skipped = 0
    with open(out, "wb") as f:
        f.write(MAGIC)
        for dirpath, dirnames, filenames in os.walk(root):
            rel_dir = Path(dirpath).relative_to(root).as_posix()
            dirnames[:] = sorted(
                d for d in dirnames
                if not is_excluded(f"{rel_dir}/{d}" if rel_dir != "." else d, patterns)
            )
            for name in sorted(filenames):
                path = Path(dirpath) / name
                rel = path.relative_to(root).as_posix()
                if path == out or is_excluded(rel, patterns) or path.is_symlink():
                    continue
                data = path.read_bytes()
                try:
                    if b"\0" in data:
                        raise UnicodeDecodeError("utf-8", b"", 0, 1, "NUL byte")
                    data.decode("utf-8")
                except UnicodeDecodeError:
                    print(f"skipped (not text): {rel}", file=sys.stderr)
                    skipped += 1
                    continue
                f.write(f"#FILE {len(data)} {rel}\n".encode())
                f.write(data)
                f.write(b"\n#END\n")
                count += 1
    print(f"packed {count} file(s), skipped {skipped} -> {out}")


def unpack(bundle, outdir, force):
    src = Path(bundle)
    data = src.read_bytes()
    if not data.startswith(MAGIC):
        sys.exit("error: not a valid bundle (missing header)")
    out = Path(outdir) if outdir else Path(src.name.split(".")[0] or "unpacked")
    out_root = out.resolve()

    pos = len(MAGIC)
    count = 0
    while pos < len(data):
        eol = data.index(b"\n", pos)
        header = data[pos:eol].decode("utf-8")
        if not header.startswith("#FILE "):
            sys.exit(f"error: corrupt bundle near byte {pos}")
        try:
            length_s, rel = header[len("#FILE "):].split(" ", 1)
            length = int(length_s)
        except ValueError:
            sys.exit(f"error: bad header: {header!r}")
        start = eol + 1
        end = start + length
        if data[end:end + 6] != b"\n#END\n":
            sys.exit(f"error: corrupt entry for {rel!r}")

        if rel.startswith("/") or ".." in rel.split("/") or "\\" in rel:
            sys.exit(f"error: unsafe path in bundle: {rel!r}")
        target = (out_root / rel).resolve()
        if out_root not in target.parents:
            sys.exit(f"error: unsafe path in bundle: {rel!r}")
        if target.exists() and not force:
            sys.exit(f"error: {target} exists (use --force to overwrite)")

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data[start:end])
        count += 1
        pos = end + 6
    print(f"unpacked {count} file(s) -> {out_root}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd")
    sub.required = True

    p = sub.add_parser("pack", help="folder -> single file")
    p.add_argument("folder")
    p.add_argument("-o", "--output")
    p.add_argument("--exclude", nargs="*", default=[], metavar="GLOB")

    u = sub.add_parser("unpack", help="single file -> folder")
    u.add_argument("bundle")
    u.add_argument("-o", "--output")
    u.add_argument("--force", action="store_true")

    a = ap.parse_args()
    if a.cmd == "pack":
        pack(a.folder, a.output, a.exclude)
    else:
        unpack(a.bundle, a.output, a.force)


if __name__ == "__main__":
    main()

