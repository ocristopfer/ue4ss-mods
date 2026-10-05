"""Builds the release zips of every mod in dist/.

For each <game>/<Mod>, three zips with the same files:

  <game>-<Mod>-<version>.zip          <Mod>/...                                   goes into Mods/
  <game>-<Mod>-<version>-windows.zip  Binaries/Win64/ue4ss/Mods/<Mod>/...         drop-in
  <game>-<Mod>-<version>-linux.zip    Binaries/Linux/ue4ss/Mods/<Mod>/...         drop-in

The drop-in zips mirror the game's folder: extract them into the folder that contains
`Binaries/` and the mod lands in place, replacing an older version. Nothing outside the mod's own
folder is written (no mods.txt: `enabled.txt` turns the mod on).

Stdlib only. Folders starting with a dot (the `.testbed` checkers) are left out, and the zips are
deterministic (fixed order and date): packaging the same commit twice gives the same files.
"""
from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
FIXED_DATE = (2000, 1, 1, 0, 0, 0)
# The version lives in main.lua (`local VERSION = "x.y.z"`): a single place, shown by the mod itself.
VERSION_RE = re.compile(r'^local VERSION = "(\d+\.\d+\.\d+)"', re.MULTILINE)
# Where UE4SS looks for mods, relative to the game folder that holds Binaries/: the official
# Windows release and the Linux build of ocristopfer/RE-UE4SS both use ue4ss/Mods.
LAYOUTS = {
    "": "",
    "-windows": "Binaries/Win64/ue4ss/Mods/",
    "-linux": "Binaries/Linux/ue4ss/Mods/",
}


def version_of(mod: Path) -> str:
    found = VERSION_RE.search((mod / "scripts" / "main.lua").read_text(encoding="utf-8"))
    if not found:
        raise SystemExit(f"{mod.name}: no `local VERSION = \"x.y.z\"` in scripts/main.lua")
    return found.group(1)


def mods() -> list[Path]:
    # <game>/<Mod>/scripts/main.lua -> <game>/<Mod>; a game or mod starting with a dot is not a mod.
    found = (p.parent.parent for p in ROOT.glob("*/*/scripts/main.lua"))
    return sorted(m for m in found if not m.name.startswith(".") and not m.parent.name.startswith("."))


def files_of(mod: Path) -> list[Path]:
    return [
        path
        for path in sorted(mod.rglob("*"))
        if path.is_file() and not any(part.startswith(".") for part in path.relative_to(mod).parts)
    ]


def package(mod: Path) -> list[Path]:
    DIST.mkdir(exist_ok=True)
    base = f"{mod.parent.name}-{mod.name}-{version_of(mod)}"
    files = files_of(mod)
    targets = []
    for suffix, prefix in LAYOUTS.items():
        target = DIST / f"{base}{suffix}.zip"
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
            for path in files:
                info = zipfile.ZipInfo(f"{prefix}{mod.name}/{path.relative_to(mod).as_posix()}", FIXED_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                zf.writestr(info, path.read_bytes())
        targets.append(target)
    return targets


def main() -> int:
    found = mods()
    for mod in found:
        for target in package(mod):
            print(target.relative_to(ROOT))
    return 0 if found else 1


if __name__ == "__main__":
    sys.exit(main())
