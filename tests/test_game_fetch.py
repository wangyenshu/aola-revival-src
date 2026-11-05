"""Tests of tools/game_sources.py and tools/fetch_game.py against a local server."""
from __future__ import annotations

import base64
import hashlib
import json
import os
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TOOLS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools")
sys.path.insert(0, TOOLS)

import fetch_game  # noqa: E402
import game_sources  # noqa: E402

FILES = {"/play/a.swf": b"era file", "/play/b.swf": b"replaced later", "/old/c.png": b"captured"}


class Server(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        body = FILES.get(self.path)
        if body is None:
            self.send_response(404)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


def sha(b: bytes) -> str:
    return hashlib.sha1(b).hexdigest()


class GameFetchTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.httpd = ThreadingHTTPServer(("127.0.0.1", 0), Server)
        cls.base = f"http://127.0.0.1:{cls.httpd.server_address[1]}"
        threading.Thread(target=cls.httpd.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()

    def test_sources_then_fetch(self):
        with tempfile.TemporaryDirectory() as d:
            files = os.path.join(d, "FILES.jsonl")
            rows = [
                {"path": "www.9aola.com/a.swf%3F1210", "size": 8, "sha1": sha(b"era file"), "origin": "era", "src": "a.swf"},
                {"path": "www.9aola.com/b.swf%3F1210", "size": 8, "sha1": sha(b"original"), "origin": "later", "src": "b.swf"},
                {"path": "www.9aola.com/c.png", "size": 8, "sha1": sha(b"captured"), "origin": "capture"},
                {"path": "www.9aola.com/gone.swf", "size": 3, "sha1": sha(b"???"), "origin": "capture"},
            ]
            with open(files, "w", encoding="utf-8") as f:
                f.write("".join(json.dumps(r) + "\n" for r in rows))
            cdx = os.path.join(d, "cdx.jsonl")
            with open(cdx, "w", encoding="utf-8") as f:
                digest = base64.b32encode(bytes.fromhex(sha(b"captured"))).decode()
                f.write(json.dumps({"original": "http://x/c.png", "ts": "20130101000000", "digest": digest, "status": "200"}) + "\n")
            out = os.path.join(d, "sources.jsonl")
            code = game_sources.main(["build", "--files", files, "--previous", "", "--cdx", cdx, "--out", out, "--allow-missing"])
            self.assertEqual(code, 0)
            src = {json.loads(line)["path"]: json.loads(line) for line in open(out, encoding="utf-8")}
            self.assertEqual(src["www.9aola.com/a.swf%3F1210"]["urls"], ["http://aola.100bt.com/play/a.swf"])
            self.assertEqual(src["www.9aola.com/c.png"]["urls"], ["https://web.archive.org/web/20130101000000id_/http://x/c.png"])
            self.assertNotIn("urls", src["www.9aola.com/gone.swf"])
            self.assertEqual(game_sources.main(["check", "--files", files, "--sources", out]), 1)  # gone.swf has no source

            # Point the URLs at the local server and fetch.
            for r in src.values():
                r["urls"] = [u.replace("http://aola.100bt.com", self.base).replace("https://web.archive.org/web/20130101000000id_/http://x", self.base + "/old")
                             for u in r.get("urls", [])]
            with open(out, "w", encoding="utf-8") as f:
                f.write("".join(json.dumps(r) + "\n" for r in src.values()))
            game = os.path.join(d, "game")
            report = os.path.join(d, "report.json")
            args = ["--sources", out, "--out", game, "--report", report, "--retries", "1", "--mismatch-retries", "0"]
            self.assertEqual(fetch_game.main(args), 1)
            got = {p["path"]: p["status"] for p in json.load(open(report, encoding="utf-8"))["problems"]}
            self.assertEqual(got["www.9aola.com/b.swf%3F1210"], "changed-skipped")
            self.assertEqual(got["www.9aola.com/gone.swf"], "failed")
            self.assertEqual(open(os.path.join(game, "www.9aola.com", "a.swf%3F1210"), "rb").read(), b"era file")
            self.assertTrue(os.path.exists(os.path.join(game, "www.9aola.com", "c.png")))
            self.assertFalse(os.path.exists(os.path.join(game, "www.9aola.com", "b.swf%3F1210")))
            self.assertTrue(os.path.exists(os.path.join(game, "FILES.jsonl")))
            # --keep-changed keeps the newer copy; a second run finds the rest present.
            fetch_game.main(args + ["--keep-changed"])
            self.assertEqual(open(os.path.join(game, "www.9aola.com", "b.swf%3F1210"), "rb").read(), b"replaced later")
            fetch_game.main(args + ["--verify-only"])
            got = {p["path"]: p["status"] for p in json.load(open(report, encoding="utf-8"))["problems"]}
            self.assertNotIn("www.9aola.com/a.swf%3F1210", got)


if __name__ == "__main__":
    unittest.main()
