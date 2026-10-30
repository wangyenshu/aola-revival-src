"""Offline tests for the capture tools, against a fake Wayback Machine.

  python -m unittest discover -s tests -v
"""

from __future__ import annotations

import base64
import zlib
import hashlib
import io
import json
import sys
import tempfile
import threading
import unittest
from contextlib import redirect_stdout
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import manifest  # noqa: E402
import swfinfo  # noqa: E402
import fill_summary  # noqa: E402
import mirrorpath  # noqa: E402
import swf_recon  # noqa: E402
import wayback  # noqa: E402

FILES = {
    # original URL -> {timestamp: body}
    "http://aola.100bt.com/play/start~1.xml": {
        "20120301000000": b"<s><v>120301</v></s>",
        "20120820000000": b"<s><v>120820</v></s>",
        "20130105000000": b"<s><v>130105</v></s>",
    },
    "http://aola.100bt.com:80/play/Main.swf": {"20120810120000": b"FWS-main"},
    "http://aola.100bt.com/play/fightassets/pet12.swf": {"20111201000000": b"CWS-pet12"},
    "http://aola.100bt.com/play/map/1001.swf?v=3": {"20120901000000": b"CWS-map"},
}


def b32(data: bytes) -> str:
    return base64.b32encode(hashlib.sha1(data).digest()).decode()


class FakeWayback(BaseHTTPRequestHandler):
    def log_message(self, *args):  # silence
        pass

    def do_GET(self):
        parts = urlsplit(self.path)
        if parts.path == "/cdx/search/cdx":
            q = parse_qs(parts.query)
            rows = []
            for url, caps in FILES.items():
                for ts, body in caps.items():
                    rows.append([ts, url, "application/x-shockwave-flash" if ".swf" in url else "text/xml",
                                 "200", b32(body), str(len(body))])
            rows.sort()
            start = int(q.get("resumeKey", ["0"])[0])
            limit = int(q["limit"][0])
            page = rows[start:start + limit]
            out = [q["fl"][0].split(",")] + page
            if start + limit < len(rows):
                out += [[], [str(start + limit)]]
            self._send(json.dumps(out).encode())
            return
        if parts.path.startswith("/web/"):
            ts, _, original = parts.path[5:].partition("id_/")
            original = original + ("?" + parts.query if parts.query else "")
            body = FILES.get(original, {}).get(ts)
            if body is None:
                self.send_error(404)
                return
            self._send(body)
            return
        self.send_error(404)

    def _send(self, body: bytes):
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class ToolsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv = ThreadingHTTPServer(("127.0.0.1", 0), FakeWayback)
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()
        cls.base = f"http://127.0.0.1:{cls.srv.server_address[1]}"

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()

    def run_tool(self, *args) -> str:
        buf = io.StringIO()
        with redirect_stdout(buf):
            wayback.main(["--wayback", self.base, "--delay", "0", *args])
        return buf.getvalue()

    def test_mirrorpath_rules(self):
        f = mirrorpath.url_to_relpath
        self.assertEqual(f("http://AOLA.100bt.com:80/play/Main.swf"), "aola.100bt.com/play/Main.swf")
        self.assertEqual(f("https://aola.100bt.com/play/"), "aola.100bt.com/play/index.html")
        self.assertEqual(f("aola.100bt.com/play/a/../b.swf"), "aola.100bt.com/play/b.swf")
        self.assertEqual(f("http://aola.100bt.com/../../etc/passwd"), "aola.100bt.com/etc/passwd")
        self.assertEqual(f("http://aola.100bt.com/play/map.swf?v=3&x=a b"),
                         "aola.100bt.com/play/map.swf%3Fv=3&x=a%20b")
        self.assertEqual(f("http://aola.100bt.com/play/%E4%BA%9A.swf"), "aola.100bt.com/play/%E4%BA%9A.swf")
        self.assertEqual(f("http://aola.100bt.com/play/亚.swf"), "aola.100bt.com/play/%E4%BA%9A.swf")
        self.assertEqual(f("http://host:8080/x"), "host_8080/x")
        # shared fixture with the TypeScript server
        fixtures = json.loads((ROOT / "tests" / "mirrorpath-fixtures.json").read_text("utf-8"))
        for url, rel in fixtures.items():
            self.assertEqual(f(url), rel, url)

    def test_pipeline(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = Path(tmp)
            cdx = t / "cdx.jsonl"
            self.run_tool("scan", "--pattern", "aola.100bt.com/*", "--page-size", "2", "--out", str(cdx))
            rows = list(wayback.read_jsonl(cdx))
            self.assertEqual(len(rows), 6)
            # resumable: a second scan adds nothing
            self.run_tool("scan", "--pattern", "aola.100bt.com/*", "--out", str(cdx))
            self.assertEqual(len(list(wayback.read_jsonl(cdx))), 6)

            out = self.run_tool("histogram", "--cdx", str(cdx), "--year", "2012")
            self.assertIn("Suggested anchor: 2012-", out)

            plan = t / "plan.jsonl"
            self.run_tool("plan", "--cdx", str(cdx), "--anchor", "2012-08-15", "--out", str(plan))
            chosen = {r["url"]: r["ts"] for r in wayback.read_jsonl(plan)}
            self.assertEqual(chosen["http://aola.100bt.com/play/start~1.xml"], "20120820000000")
            self.assertEqual(len(chosen), 4)

            mirror, index = t / "mirror", t / "index.jsonl"
            self.run_tool("fetch", "--plan", str(plan), "--mirror", str(mirror), "--index", str(index))
            self.assertEqual((mirror / "aola.100bt.com/play/start~1.xml").read_bytes(), b"<s><v>120820</v></s>")
            self.assertEqual((mirror / "aola.100bt.com/play/map/1001.swf%3Fv=3").read_bytes(), b"CWS-map")
            recs = list(wayback.read_jsonl(index))
            self.assertTrue(all(r["digest_ok"] for r in recs))
            # resumable fetch
            out = self.run_tool("fetch", "--plan", str(plan), "--mirror", str(mirror), "--index", str(index))
            self.assertIn("4 already mirrored, 0 to fetch", out)

            wanted = t / "wanted.txt"
            wanted.write_text("http://aola.100bt.com/play/Main.swf\n"
                              "http://aola.100bt.com/play/fightassets/pet99.swf\n", "utf-8")
            missing = t / "missing.txt"
            out = self.run_tool("coverage", "--wanted", str(wanted), "--index", str(index),
                                "--cdx", str(cdx), "--missing-out", str(missing))
            self.assertIn("Fidelity score (share served from Wayback captures): 50.0%", out)
            self.assertEqual(missing.read_text().strip(), "http://aola.100bt.com/play/fightassets/pet99.swf")

    def test_manifest_version_and_scan(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = Path(tmp)
            xml = t / "version.xml"
            xml.write_text('<root><f n="activityres/a/b_code" v="2025100927077881"/>'
                           '<f n="map/1001.swf" v="12"/></root>', "utf-8")
            buf = io.StringIO()
            with redirect_stdout(buf):
                manifest.main(["--base", "http://aola.100bt.com/play/", "version", str(xml), "--naming", "plain,tilde,query"])
            urls = buf.getvalue().split()
            self.assertIn("http://aola.100bt.com/play/activityres/a/b_code.swf", urls)
            self.assertIn("http://aola.100bt.com/play/activityres/a/b_code~2025100927077881.swf", urls)
            self.assertIn("http://aola.100bt.com/play/map/1001~12.swf", urls)
            self.assertIn("http://aola.100bt.com/play/map/1001.swf?12", urls)

            code = t / "Main.as"
            code.write_text('var u = "fightassets/pet" + id + ".swf"; load("ui/main.swf");'
                            ' x = "http://aola.100bt.com/play/start~1.xml";', "utf-8")
            buf = io.StringIO()
            with redirect_stdout(buf):
                manifest.main(["--base", "http://aola.100bt.com/play/", "scan", str(t)])
            urls = buf.getvalue().split()
            self.assertIn("http://aola.100bt.com/play/ui/main.swf", urls)
            self.assertIn("http://aola.100bt.com/play/start~1.xml", urls)

    def test_recon_scan(self):
        with tempfile.TemporaryDirectory() as tmp:
            s = Path(tmp) / "scripts" / "Main" / "scripts" / "mmo" / "net"
            s.mkdir(parents=True)
            (s / "GameSocket.as").write_text(
                "package mmo.net {\n import flash.net.Socket;\n public class GameSocket {\n"
                "  private var _s:Socket = new Socket();\n"
                "  public function send(cmd:int, body:ByteArray):void {\n"
                "   var b:ByteArray = new ByteArray(); b.writeUnsignedInt(body.length + 8);\n"
                "   b.writeInt(cmd); b.writeBytes(body); key = 0x5A; b[i] = b[i] ^ 0x5A;\n"
                "   _s.connect(\"118.123.4.5\", 8001);\n }}}\n", "utf-8")
            consts = "\n".join(f"  public static const C{i}:int = {1000 + i};" for i in range(20))
            (s / "Cmd.as").write_text("package mmo.net {\n public class Cmd {\n" + consts + "\n}}\n", "utf-8")
            res = swf_recon.scan(Path(tmp) / "scripts", 50)
            self.assertIn("Main/scripts/mmo/net/GameSocket.as", res["top_files"]["socket"])
            self.assertTrue(any(h["text"].startswith("b.writeInt(cmd)") for h in res["hits"]["framing"]))
            self.assertTrue(res["hits"]["crypto"])
            self.assertEqual(res["const_tables"][0]["file"], "Main/scripts/mmo/net/Cmd.as")
            self.assertEqual(res["ips"][0][0], "118.123.4.5")
            swf_recon.write_report(res, Path(tmp) / "out")
            self.assertIn("Command-table candidates", (Path(tmp) / "out" / "recon.md").read_text("utf-8"))


def make_swf(modify: str | None, sig: bytes = b"CWS", version: int = 10) -> bytes:
    """Minimal SWF: RECT, frame rate/count, FileAttributes, optional XMP Metadata, End."""
    import lzma
    import struct as st
    def tag(code, data):
        return st.pack("<H", (code << 6) | 0x3F) + st.pack("<I", len(data)) + data
    rect = bytes([0x08, 0x00])  # nbits=1, all zero
    body = rect + st.pack("<HH", 24 << 8, 1) + tag(69, st.pack("<I", 0x08))
    if modify:
        xmp = ('<x:xmpmeta><rdf:Description xmp:CreatorTool="Adobe Flash CS4 Professional" '
               f'xmp:CreateDate="2010-08-13T14:08:54+08:00" xmp:ModifyDate="{modify}T18:10:23+08:00"/></x:xmpmeta>')
        body += tag(77, xmp.encode())
    body += tag(82, b"\x01\x00\x00\x00\x00") + st.pack("<H", 0)
    if sig == b"FWS":
        return b"FWS" + bytes([version]) + st.pack("<I", len(body) + 8) + body
    if sig == b"CWS":
        return b"CWS" + bytes([version]) + st.pack("<I", len(body) + 8) + zlib.compress(body)
    alone = lzma.compress(body, format=lzma.FORMAT_ALONE)
    props, data = alone[:5], alone[13:]
    return b"ZWS" + bytes([version]) + st.pack("<I", len(body) + 8) + st.pack("<I", len(data)) + props + data


LIVE = {}


class FakeLive(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        body = LIVE.get(urlsplit(self.path).path)
        if body is None:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class FillSummaryTest(unittest.TestCase):
    def test_buckets(self):
        b = fill_summary.bucket
        self.assertEqual(b({"outcome": "verified-older", "v": "121206"}), "verified")
        self.assertEqual(b({"outcome": "newer", "v": "121227", "xmp_modify": "121228"}), "newer-near")
        self.assertEqual(b({"outcome": "newer", "v": "121101", "xmp_modify": "131101"}), "newer")
        self.assertEqual(b({"outcome": "undated", "v": "121227", "swf": "CWS v10"}), "undated-era")
        self.assertEqual(b({"outcome": "undated", "v": "121227", "swf": "ZWS v18"}), "undated-rebuilt")
        self.assertEqual(b({"outcome": "http-404", "v": "121001"}), "missing")


class FillManifestTest(unittest.TestCase):
    def test_swfinfo_reads_all_compressions(self):
        for sig in (b"FWS", b"CWS", b"ZWS"):
            i = swfinfo.inspect(make_swf("2012-12-06", sig))
            self.assertTrue(i.ok, i.error)
            self.assertEqual((i.compression, i.modify_yymmdd, i.as3), (sig.decode(), "121206", True))
        self.assertEqual(swfinfo.inspect(make_swf(None)).modify_yymmdd, None)
        self.assertFalse(swfinfo.inspect(b"<html>").ok)
        self.assertEqual(swfinfo.stamp_yymmdd("1301251"), "130125")
        self.assertEqual(swfinfo.stamp_yymmdd("1210"), "121031")
        self.assertIsNone(swfinfo.stamp_yymmdd("1299"))

    def test_fill_manifest_verifies_by_date(self):
        LIVE.clear()
        LIVE.update({
            "/play/fightassets/effect8201.swf": make_swf("2012-12-06"),      # matches stamp
            "/play/tasknpc/npc66.swf": make_swf("2013-01-10"),               # matches the patched stamp
            "/play/library/common.swf": make_swf("2015-03-02", b"ZWS", 18),  # rebuilt later
            "/play/scene/cubemansion.swf": make_swf(None),                   # no XMP
            "/play/scene/oldtown.swf": make_swf("2012-10-19"),               # unchanged since before the stamp
        })
        srv = ThreadingHTTPServer(("127.0.0.1", 0), FakeLive)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        live = f"http://127.0.0.1:{srv.server_address[1]}/play/"
        try:
            with tempfile.TemporaryDirectory() as tmp:
                t = Path(tmp)
                (t / "versiondata.xml").write_text(
                    '<version releaseDate="2013-01-25">\n'
                    '  <f n="fightassets/effect8201" v="121206" />\n  <f n="tasknpc/npc66" v="121130" />\n'
                    '  <f n="library/common" v="130124" />\n  <f n="scene/cubemansion" v="121213" />\n'
                    '  <f n="pet/gone" v="121001" />\n  <f n="scene/oldtown" v="121025" />\n</version>', "utf-8")
                (t / "start.xml").write_text('<r><t>open</t><v>201301241</v><u><f n="tasknpc/npc66" v="1301101" /></u></r>', "utf-8")
                args = ["fill-manifest", "--manifest", str(t / "versiondata.xml"), "--patch", str(t / "start.xml"),
                        "--live-base", live, "--mirror", str(t / "mirror"), "--quarantine", str(t / "mirror-unverified"),
                        "--index", str(t / "index.jsonl"), "--log", str(t / "fill.jsonl")]
                out = self.run_tool(*args)
                self.assertIn("6 left to fetch", out)
                log = {r["name"]: r["outcome"] for r in wayback.read_jsonl(t / "fill.jsonl")}
                self.assertEqual(log, {"fightassets/effect8201": "verified", "tasknpc/npc66": "verified",
                                       "library/common": "newer", "scene/cubemansion": "undated", "pet/gone": "http-404",
                                       "scene/oldtown": "verified-older"})
                self.assertTrue((t / "mirror/www.9aola.com/fightassets/effect8201.swf%3F121206").exists())
                self.assertTrue((t / "mirror/www.9aola.com/tasknpc/npc66.swf%3F1301101").exists())
                self.assertTrue((t / "mirror-unverified/www.9aola.com/library/common.swf%3F130124").exists())
                idx = list(wayback.read_jsonl(t / "index.jsonl"))
                self.assertEqual(sorted(r["provenance"] for r in idx),
                                 ["live-verified", "live-verified", "live-verified-older"])
                self.assertTrue((t / "mirror/www.9aola.com/scene/oldtown.swf%3F121025").exists())
                self.assertIn("0 left to fetch", self.run_tool(*args))
        finally:
            srv.shutdown()

    run_tool = ToolsTest.run_tool

    @classmethod
    def setUpClass(cls):
        cls.base = "http://127.0.0.1:9"  # unused by fill-manifest


class MakeGameRootTest(unittest.TestCase):
    """game/ from the working roots, then the same game/ again from its list."""

    def test_select_then_assemble(self):
        import make_game_root

        with tempfile.TemporaryDirectory() as t:
            t = Path(t)

            def put(rel, data):
                p = t / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(data)

            put("mirror/www.9aola.com/scene/a.swf%3F1210", b"era a")
            put("mirror/www.9aola.com/tasknpc/npc5.swf%3F1210", b"npc 5")
            put("supplement/www.9aola.com/scene/a.swf%3F1210", b"later a")  # answered by mirror
            put("supplement/www.9aola.com/library/b.swf%3F130124", b"listed b")
            put("supplement/www.9aola.com/tasknpc/npc3.swf%3F1210", b"npc 3")  # within the era numbers
            put("supplement/www.9aola.com/tasknpc/npc9.swf%3F1210", b"npc 9")  # after them
            put("supplement/www.9aola.com/fightres/x.swf", b"unused")
            (t / "manifest.xml").write_text('<version><f n="library/b" v="130124"/></version>')
            make_game_root.main(["select", "--era", str(t / "mirror"), "--later", str(t / "supplement"),
                                 "--manifest", str(t / "manifest.xml"), "--out", str(t / "game")])
            got = sorted(json.loads(l)["path"] for l in (t / "game/FILES.jsonl").read_text().splitlines())
            self.assertEqual(got, ["www.9aola.com/library/b.swf%3F130124", "www.9aola.com/scene/a.swf%3F1210",
                                   "www.9aola.com/tasknpc/npc3.swf%3F1210", "www.9aola.com/tasknpc/npc5.swf%3F1210"])
            self.assertEqual((t / "game/www.9aola.com/scene/a.swf%3F1210").read_bytes(), b"era a")
            # Elsewhere, from the list and the old roots only.
            with redirect_stdout(io.StringIO()):
                make_game_root.main(["assemble", "--files", str(t / "game/FILES.jsonl"),
                                     "--search", f"{t / 'mirror'},{t / 'supplement'}", "--out", str(t / "game2")])
            for rel in got:
                self.assertEqual((t / "game2" / rel).read_bytes(), (t / "game" / rel).read_bytes())


class GenNpcDataTest(unittest.TestCase):
    """Which NPCs stand where: era NPCs in the 2013 rooms, every NPC in the rooms added for the story quests."""

    def test_rooms_and_art(self):
        import gen_npc_data

        cfg = '<config><roomMap>%s</roomMap></config>'
        row = lambda n: f'<r nm="{n}" rm="{n}" swf="scene/{n}"/>'
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            later = t / "later" / "mmo/tasknpc/config"
            later.mkdir(parents=True)
            npc = lambda i, x: '{"npcId":%d,"viewId":1,"x":%d,"y":300,"type":NpcType.SCENE}' % (i, x)
            (later / "SceneNpcConfig.as").write_text(
                'config["library"] = [%s,%s,%s];\n' % (npc(10, 100), npc(43, 640), npc(99, 700))
                + 'config["giantcordillera1"] = [%s,%s];\n' % (npc(608, 300), npc(77, 500))
                + 'config["gone"] = [%s];\n' % npc(10, 1), encoding="utf-8")
            www = t / "game/www.9aola.com"
            www.mkdir(parents=True)
            (www / "config.xml%3F201301241").write_text(cfg % row("library"), encoding="utf-8")
            overlay = t / "overlay.xml"
            overlay.write_text(cfg % (row("library") + row("giantcordillera1")), encoding="utf-8")
            files = [("10", "era"), ("43", "later"), ("99", "later"), ("608", "era"), ("77", "later")]
            (t / "game/FILES.jsonl").write_text("".join(
                json.dumps({"path": f"www.9aola.com/tasknpc/npc{i}.swf%3F1210", "origin": o}) + "\n" for i, o in files), encoding="utf-8")
            talks = t / "TaskTalkData.as"
            talks.write_text('talk["43_1216_library"] = <config/>;', encoding="utf-8")
            with redirect_stdout(io.StringIO()):
                gen_npc_data.main(["--later", str(t / "later"), "--game", str(t / "game"), "--overlay", str(overlay),
                                   "--talks", str(talks), "--out", str(t / "out")])
            out = (t / "out/mmo/tasknpc/SceneNpcData.as").read_text(encoding="utf-8")
            # 2013 room: the era NPC as it is, the story NPC (later picture) only as a task NPC, the other later one not at all.
            self.assertIn('"library":[[10,1,100,300,0],[43,1,640,300,2]]', out)
            # Added room: every NPC whose picture game/ has.
            self.assertIn('"giantcordillera1":[[608,1,300,300,0],[77,1,500,300,0]]', out)
            self.assertNotIn('"gone"', out)


if __name__ == "__main__":
    unittest.main()
