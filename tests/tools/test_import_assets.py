import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import import_assets  # noqa: E402


def write_gltf(path: Path, bin_name: str, png_name: str | None) -> None:
    doc = {"asset": {"version": "2.0"}, "buffers": [{"uri": bin_name, "byteLength": 4}]}
    if png_name:
        doc["images"] = [{"uri": png_name}]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc))
    (path.parent / bin_name).write_bytes(b"\0\0\0\0")
    if png_name:
        (path.parent / png_name).write_bytes(b"png")


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.src = Path(self.tmp.name) / "src"
        self.dst = Path(self.tmp.name) / "dst"
        write_gltf(self.src / "PackA" / "gltf" / "sword.gltf", "sword.bin", "tex.png")
        write_gltf(self.src / "PackA" / "gltf" / "bow.gltf", "bow.bin", "tex.png")
        (self.src / "PackA" / "chars").mkdir(parents=True)
        (self.src / "PackA" / "chars" / "Knight.glb").write_bytes(b"glb")
        (self.src / "PackA" / "License.txt").write_text("CC0")

    def tearDown(self):
        self.tmp.cleanup()

    def manifest(self, include):
        return [{"pack": "PackA", "dest": "pack_a", "license": "License.txt", "include": include}]

    def test_gltf_brings_its_bin_and_texture_beside_it(self):
        copied = import_assets.run(self.src, self.dst, self.manifest(["gltf/sword.gltf"]))
        d = self.dst / "pack_a"
        self.assertTrue((d / "sword.gltf").exists())
        self.assertTrue((d / "sword.bin").exists())
        self.assertTrue((d / "tex.png").exists())
        self.assertFalse((d / "bow.gltf").exists(), "only requested files are copied")
        self.assertIn("pack_a/sword.bin", copied)

    def test_glb_and_license_are_copied(self):
        import_assets.run(self.src, self.dst, self.manifest(["chars/*.glb"]))
        self.assertTrue((self.dst / "pack_a" / "Knight.glb").exists())
        self.assertEqual((self.dst / "pack_a" / "LICENSE.txt").read_text(), "CC0")

    def test_pattern_with_no_match_is_an_error(self):
        with self.assertRaises(import_assets.ImportError_):
            import_assets.run(self.src, self.dst, self.manifest(["gltf/axe*.gltf"]))

    def test_missing_referenced_buffer_is_an_error(self):
        (self.src / "PackA" / "gltf" / "sword.bin").unlink()
        with self.assertRaises(import_assets.ImportError_):
            import_assets.run(self.src, self.dst, self.manifest(["gltf/sword.gltf"]))

    def test_rerun_is_idempotent_and_source_untouched(self):
        before = sorted(p.name for p in (self.src / "PackA" / "gltf").iterdir())
        first = import_assets.run(self.src, self.dst, self.manifest(["gltf/*.gltf"]))
        second = import_assets.run(self.src, self.dst, self.manifest(["gltf/*.gltf"]))
        self.assertEqual(sorted(first), sorted(second))
        self.assertEqual(before, sorted(p.name for p in (self.src / "PackA" / "gltf").iterdir()))


if __name__ == "__main__":
    unittest.main()
