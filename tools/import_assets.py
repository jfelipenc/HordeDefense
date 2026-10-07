#!/usr/bin/env python3
"""Copy the curated subset of the KayKit / Kenney packs into res://assets/.

    python tools/import_assets.py [--source D:/ASSETS/KayKit] [--manifest tools/asset_manifest.json]

The source folder is only read. For every .gltf copied, the .bin and texture files it
references are copied beside it. A pattern that matches nothing, or a missing referenced
file, is an error (so a changed source pack cannot silently shrink the project).
Re-running is safe: files are overwritten with identical content.
"""
import argparse
import glob
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = Path("D:/ASSETS/KayKit")
DEFAULT_MANIFEST = REPO / "tools" / "asset_manifest.json"
ASSETS = REPO / "assets"


class ImportError_(Exception):
    pass


def _referenced(gltf: Path) -> list[Path]:
    doc = json.loads(gltf.read_text(encoding="utf-8"))
    uris = [b["uri"] for b in doc.get("buffers", []) if "uri" in b]
    uris += [i["uri"] for i in doc.get("images", []) if "uri" in i]
    return [gltf.parent / u for u in uris if not u.startswith("data:")]


def _copy(src: Path, dest_dir: Path, dst_root: Path, copied: dict[str, Path]) -> None:
    target = dest_dir / src.name
    rel = target.relative_to(dst_root).as_posix()
    if rel in copied and copied[rel] != src and copied[rel].read_bytes() != src.read_bytes():
        raise ImportError_(f"name collision at {rel}: {copied[rel]} vs {src}")
    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, target)
    copied[rel] = src


def run(source: Path, dst_root: Path, manifest: list[dict]) -> list[str]:
    """Returns the sorted list of copied files relative to dst_root (posix paths)."""
    copied: dict[str, Path] = {}
    for entry in manifest:
        pack_dir = Path(source) / entry["pack"]
        dest_dir = Path(dst_root) / entry["dest"]
        for pattern in entry["include"]:
            matches = sorted(Path(p) for p in glob.glob(str(pack_dir / pattern)))
            if not matches:
                raise ImportError_(f"no match for {entry['pack']}/{pattern}")
            for src in matches:
                _copy(src, dest_dir, Path(dst_root), copied)
                if src.suffix == ".gltf":
                    for dep in _referenced(src):
                        if not dep.exists():
                            raise ImportError_(f"{src} references missing {dep}")
                        _copy(dep, dest_dir, Path(dst_root), copied)
        lic = entry.get("license")
        if lic:
            lic_src = pack_dir / lic
            if not lic_src.exists():
                raise ImportError_(f"missing license {lic_src}")
            dest_dir.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(lic_src, dest_dir / "LICENSE.txt")
            copied[(dest_dir / "LICENSE.txt").relative_to(dst_root).as_posix()] = lic_src
    return sorted(copied)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    ap.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = ap.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    try:
        files = run(args.source, ASSETS, manifest)
    except ImportError_ as e:
        print(f"import failed: {e}", file=sys.stderr)
        return 1
    print(f"copied {len(files)} files into {ASSETS}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
