"""Gera dist/<jogo>-<Mod>.zip de cada mod: a pasta do mod pronta para cair em Mods/.

So stdlib. Pastas que comecam com ponto (os verificadores de `.testbed`) ficam de fora, e o
zip e determinista (ordem e data fixas): dois empacotamentos do mesmo commit dao o mesmo
arquivo.
"""
from __future__ import annotations

import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
FIXED_DATE = (2000, 1, 1, 0, 0, 0)


def mods() -> list[Path]:
    # <jogo>/<Mod>/scripts/main.lua -> <jogo>/<Mod>; jogo ou mod com ponto (.testbed) nao e mod.
    found = (p.parent.parent for p in ROOT.glob("*/*/scripts/main.lua"))
    return sorted(m for m in found if not m.name.startswith(".") and not m.parent.name.startswith("."))


def package(mod: Path) -> Path:
    DIST.mkdir(exist_ok=True)
    target = DIST / f"{mod.parent.name}-{mod.name}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(mod.rglob("*")):
            if path.is_file() and not any(part.startswith(".") for part in path.relative_to(mod).parts):
                info = zipfile.ZipInfo(f"{mod.name}/{path.relative_to(mod).as_posix()}", FIXED_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                zf.writestr(info, path.read_bytes())
    return target


def main() -> int:
    found = mods()
    for mod in found:
        print(package(mod).relative_to(ROOT))
    return 0 if found else 1


if __name__ == "__main__":
    sys.exit(main())
