"""
fix_const.py - removes the `const` keywords that break after FC became dynamic.

Run it from your flutter_app folder (the one with pubspec.yaml):

    python fix_const.py

It runs `flutter analyze`, finds every "not a constant" error, removes the
`const` that encloses the error, and repeats until the errors are gone.
Only the word `const` is removed (or `const x = [...]` becomes `final x = [...]`).
Nothing else in your code is touched. A backup of lib/ is made first.
"""
import os
import re
import shutil
import subprocess
import sys

CODES = {
    "invalid_constant",
    "const_with_non_constant_argument",
    "non_constant_list_element",
    "non_constant_map_element",
    "non_constant_map_key",
    "non_constant_map_value",
    "non_constant_set_element",
    "const_initialized_with_non_constant_value",
}
LOC = re.compile(r"(lib[\\/][^\s:]+\.dart):(\d+):(\d+)\s+-\s+(\w+)")
CONST = re.compile(r"\bconst\b")
OPEN = {"(": ")", "[": "]", "{": "}"}
CLOSE = set(OPEN.values())


def match_close(text, open_pos):
    depth = 0
    for i in range(open_pos, len(text)):
        c = text[i]
        if c in OPEN:
            depth += 1
        elif c in CLOSE:
            depth -= 1
            if depth == 0:
                return i
    return len(text)


def enclosing_const(text, off):
    """Nearest `const` whose expression contains offset `off`."""
    cands = [m for m in CONST.finditer(text, 0, off)]
    for m in reversed(cands):
        rest = text[m.end():]
        b = re.search(r"[(\[{;]", rest)
        if not b or b.group() == ";":
            continue
        open_pos = m.end() + b.start()
        if match_close(text, open_pos) >= off:
            return m, text[m.end():open_pos]
    return None, ""


def fix_file(path, locs):
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
    starts = [0]
    for m in re.finditer("\n", text):
        starts.append(m.end())
    offsets = sorted({starts[l - 1] + c - 1 for l, c in locs if l - 1 < len(starts)}, reverse=True)
    done = set()
    changed = 0
    for off in offsets:
        m, between = enclosing_const(text, off)
        if m is None or m.start() in done:
            continue
        done.add(m.start())
        if "=" in between:  # declaration: const x = [...]  ->  final x = [...]
            text = text[:m.start()] + "final" + text[m.end():]
        else:  # expression: const Foo(...)  ->  Foo(...)
            end = m.end()
            while end < len(text) and text[end] in " \t":
                end += 1
            text = text[:m.start()] + text[end:]
        changed += 1
    if changed:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(text)
    return changed


def analyze():
    r = subprocess.run("flutter analyze --no-pub", shell=True, capture_output=True,
                       text=True, encoding="utf-8", errors="replace")
    return r.stdout + "\n" + r.stderr


def main():
    if not os.path.isdir("lib"):
        sys.exit("Run this from the folder that contains lib/ and pubspec.yaml")
    if not os.path.exists("lib_backup_before_const_fix"):
        shutil.copytree("lib", "lib_backup_before_const_fix")
        print("Backup saved in lib_backup_before_const_fix/")
    for n in range(1, 41):
        out = analyze()
        by_file = {}
        for f, l, c, code in LOC.findall(out):
            if code in CODES:
                by_file.setdefault(f.replace("\\", os.sep), []).append((int(l), int(c)))
        if not by_file:
            print("No more constant errors.")
            break
        total = sum(fix_file(f, locs) for f, locs in by_file.items())
        print(f"Pass {n}: fixed {total} places in {len(by_file)} files")
        if total == 0:
            print("Could not fix the rest automatically; run `flutter analyze` and send me what is left.")
            break
    print("Done. Run `flutter analyze` to see what is left.")


if __name__ == "__main__":
    main()