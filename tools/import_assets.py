#!/usr/bin/env python3
"""Copy the glTF / UI / audio files we use from D:\\ASSETS\\KayKit into res://assets/.

The source folder is never modified. Re-run any time; the copy is idempotent.

    python tools/import_assets.py [--source D:/ASSETS/KayKit]
    godot --headless --path . --import
    godot --headless --path . -s res://tools/list_clips.gd
    python tools/import_assets.py --docs-only     # regenerates assets/ASSETS.md

Whitelists below are the single place that decides which files enter the project.
"""
import argparse
import fnmatch
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
CLIPS_JSON = ASSETS / "clips.json"

CC0 = "CC0 1.0 (per the pack's bundled License.txt)"

# Each pack: source folder, destination (under assets/), and a list of rules.
# A rule is (source subfolder, glob patterns, recursive, excluded folder names).
PACKS = [
    {
        "id": "adventurers", "family": "KayKit", "dest": "kaykit/adventurers",
        "name": "KayKit Adventurers 2.0 FREE", "src": "KayKit_Adventurers_2.0_FREE",
        "rules": [
            ("Characters/gltf", ["Knight.glb", "Barbarian.glb", "Ranger.glb", "Mage.glb", "Rogue.glb", "Rogue_Hooded.glb"], False, []),
            ("Assets/gltf", ["sword*.gltf", "bow*.gltf", "arrow_bow*.gltf", "quiver*.gltf", "crossbow*.gltf",
                             "arrow_crossbow*.gltf", "staff*.gltf", "wand*.gltf", "shield*.gltf", "spellbook*.gltf"], False, []),
        ],
    },
    {
        "id": "skeletons", "family": "KayKit", "dest": "kaykit/skeletons",
        "name": "KayKit Skeletons 1.1 FREE", "src": "KayKit_Skeletons_1.1_FREE",
        "rules": [
            ("characters/gltf", ["*.glb"], False, []),
            ("assets/gltf", ["*.gltf"], False, []),
        ],
    },
    {
        "id": "animations", "family": "KayKit", "dest": "kaykit/animations",
        "name": "KayKit Character Animations 1.1", "src": "KayKit_Character_Animations_1.1",
        "rules": [
            ("Animations/gltf/Rig_Medium", ["*.glb"], False, []),
            ("Animations/gltf/Rig_Large", ["*.glb"], False, []),
            ("Mannequin Character/characters", ["*.glb"], False, []),
        ],
    },
    {
        "id": "hexagon", "family": "KayKit", "dest": "kaykit/hexagon",
        "name": "KayKit Medieval Hexagon 1.0 FREE", "src": "KayKit_Medieval_Hexagon_Pack_1.0_FREE",
        "rules": [
            ("Assets/gltf/buildings/blue", ["*.gltf"], False, []),
            ("Assets/gltf/buildings/red", ["*.gltf"], False, []),
            ("Assets/gltf/buildings/neutral", ["*.gltf"], False, []),
            ("Assets/gltf/decoration", ["*.gltf"], True, []),
            ("Assets/gltf/tiles/base", ["*.gltf"], False, []),
            ("Assets/gltf/tiles/coast", ["*.gltf"], False, ["waterless"]),
            ("Assets/gltf/tiles/rivers", ["*.gltf"], False, ["waterless"]),
        ],
    },
    {
        "id": "forest", "family": "KayKit", "dest": "kaykit/forest",
        "name": "KayKit Forest Nature 1.0 FREE", "src": "KayKit_Forest_Nature_Pack_1.0_FREE",
        "rules": [("Assets/gltf", ["*.gltf"], False, [])],
    },
    {
        "id": "dungeon", "family": "KayKit", "dest": "kaykit/dungeon",
        "name": "KayKit Dungeon 1.1 FREE", "src": "KayKit_Dungeon_Pack_1.1_FREE",
        "rules": [("Assets/gltf", ["barrier*.gltf", "banner_*.gltf", "coin_stack_*.gltf", "chest*.gltf", "barrel*.gltf",
                                   "crate*.gltf", "torch*.gltf", "wall_cracked*.gltf", "wall_broken*.gltf"], False, [])],
    },
    {
        "id": "ui", "family": "Kenney", "dest": "kenney/ui",
        "name": "Kenney UI Pack 2.0", "src": "kenney_ui-pack(1)",
        "rules": [("Vector", ["*.svg"], True, []), ("Font", ["*.ttf"], False, [])],
    },
    {
        "id": "audio", "family": "Kenney", "dest": "kenney/audio",
        "name": "Kenney Interface Sounds 1.0", "src": "kenney_interface-sounds(1)",
        "rules": [("Audio", ["*.ogg"], False, [])],
    },
]


def referenced_files(gltf: Path):
    """Sidecar files (.bin, textures) a .gltf points at, as URIs relative to the .gltf."""
    data = json.loads(gltf.read_text(encoding="utf-8"))
    uris = [b["uri"] for b in data.get("buffers", []) if "uri" in b and not b["uri"].startswith("data:")]
    uris += [i["uri"] for i in data.get("images", []) if "uri" in i and not i["uri"].startswith("data:")]
    return uris


def copy_file(src: Path, dst: Path, copied: set):
    if dst in copied:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    copied.add(dst)


def import_pack(pack, source: Path):
    src_root = source / pack["src"]
    if not src_root.is_dir():
        sys.exit(f"missing source pack: {src_root}")
    dest_root = ASSETS / pack["dest"]
    copied: set = set()
    for sub, patterns, recursive, excluded in pack["rules"]:
        base = src_root / sub
        if not base.is_dir():
            sys.exit(f"missing folder: {base}")
        it = base.rglob("*") if recursive else base.glob("*")
        for f in sorted(it):
            if not f.is_file() or any(part in excluded for part in f.relative_to(base).parts):
                continue
            if not any(fnmatch.fnmatch(f.name, p) for p in patterns):
                continue
            # Hexagon keeps its buildings/<team> and decoration/<kind> structure.
            if pack["id"] == "hexagon":
                rel = f.parent.relative_to(src_root / "Assets/gltf")
            else:
                rel = Path(".")
            dst = dest_root / rel / f.name
            copy_file(f, dst, copied)
            if f.suffix == ".gltf":
                for uri in referenced_files(f):
                    side_src = (f.parent / uri).resolve()
                    side_dst = (dst.parent / uri).resolve()
                    if not side_src.is_file():
                        sys.exit(f"{f.name}: referenced file not found: {side_src}")
                    try:
                        side_dst.relative_to(ASSETS.resolve())
                    except ValueError:
                        sys.exit(f"{f.name}: sidecar {uri} would land outside assets/")
                    copy_file(side_src, side_dst, copied)
    return sorted(copied)


def write_docs(packs_files, license_texts):
    clips = json.loads(CLIPS_JSON.read_text()) if CLIPS_JSON.exists() else {}
    out = ["# Asset inventory", "",
           "Generated by `tools/import_assets.py`. Sources stay untouched in `D:\\ASSETS\\KayKit`; "
           "re-import by running the tool. KayKit and Kenney packs are listed separately.", ""]
    for family in ("KayKit", "Kenney"):
        out += [f"## {family}", ""]
        for pack in [p for p in PACKS if p["family"] == family]:
            files = packs_files[pack["id"]]
            out += [f"### {pack['name']}", "",
                    f"- Source: `{pack['src']}`",
                    f"- License: {CC0}",
                    f"- Imported to: `{pack['dest']}/` ({len(files)} files)", ""]
            out += ["| File | Pack |", "| --- | --- |"]
            for f in files:
                out.append(f"| `{f.relative_to(ASSETS).as_posix()}` | {pack['name']} |")
            out.append("")
    out += ["## Animation clips", "",
            "Clip names inside each animation pack (listed by `tools/list_clips.gd`).", ""]
    if not clips:
        out.append("_Not generated yet: run `tools/list_clips.gd`, then `--docs-only`._")
    for pack_file, names in sorted(clips.items()):
        out += [f"### {pack_file}", ""]
        out += [f"- `{n}`" for n in names]
        out.append("")
    (ASSETS / "ASSETS.md").write_text("\n".join(out) + "\n", encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="D:/ASSETS/KayKit")
    ap.add_argument("--docs-only", action="store_true")
    args = ap.parse_args()
    source = Path(args.source)
    packs_files = {}
    for pack in PACKS:
        if args.docs_only:
            root = ASSETS / pack["dest"]
            packs_files[pack["id"]] = sorted(p for p in root.rglob("*") if p.is_file() and p.suffix not in (".import", ".uid"))
        else:
            packs_files[pack["id"]] = import_pack(pack, source)
        print(f"{pack['id']}: {len(packs_files[pack['id']])} files")
    write_docs(packs_files, {})


if __name__ == "__main__":
    main()
