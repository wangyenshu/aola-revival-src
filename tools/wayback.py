#!/usr/bin/env python3
"""Capture 2012-era 奥拉星 files from the Wayback Machine into a frozen mirror.

Run on your own machine (archive.org must be reachable). Standard library only.

  1. scan       list every capture of the target hosts via the CDX index
  2. histogram  count SWF captures per month and suggest an anchor month
  3. plan       pick, for each URL, the capture closest to the anchor date
  4. fetch      download original bytes (Wayback "id_" mode) into mirror/
  5. coverage   compare a wanted-URL list (from manifest.py) with the mirror
  6. fill-live  optional: fetch still-missing files from the live CDN,
                tagged as non-2012 provenance
  7. fill-manifest  fetch every file of a client manifest from the live CDN and
                keep it in mirror/ only when its Flash XMP modify date equals
                the manifest's version stamp; everything else goes to
                mirror-unverified/ for review

Typical run (work/ holds indexes, mirror/ holds files):

  python tools/wayback.py scan --out work/cdx.jsonl
  python tools/wayback.py histogram --cdx work/cdx.jsonl --year 2012
  python tools/wayback.py plan --cdx work/cdx.jsonl --anchor 2012-08-15 --out work/plan.jsonl
  python tools/wayback.py fetch --plan work/plan.jsonl --mirror mirror --index work/index.jsonl
  python tools/wayback.py coverage --wanted work/wanted.txt --index work/index.jsonl --cdx work/cdx.jsonl

Be polite: the defaults keep to about one request per second. The Wayback
Machine throttles or blocks clients that hammer it.
"""

from __future__ import annotations

import argparse
import base64
import collections
import datetime as dt
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mirrorpath import normalize_url, url_to_relpath  # noqa: E402
from swfinfo import inspect, stamp_yymmdd  # noqa: E402

WAYBACK = "https://web.archive.org"
USER_AGENT = "aola-revival/0.1 (personal game preservation; polite crawler)"
# Until mid-2013 the game ran on 9aola.com (play page, client SWFs, login and
# service hosts); aola.100bt.com was the news/guide site. Both are scanned.
DEFAULT_PATTERNS = [
    "www.9aola.com/*",
    "web.9aola.com/*",
    "login.9aola.com/*",
    "service.9aola.com/*",
    "aola.100bt.com/*",
    "www.100bt.com/aola*",
    "service-aola.100bt.com/*",
]
CDX_FIELDS = "timestamp,original,mimetype,statuscode,digest,length"
SWF_MIMES = ("application/x-shockwave-flash", "application/futuresplash")


# ───────────────────────────── HTTP helpers ─────────────────────────────

class Http:
    def __init__(self, delay: float, retries: int = 4, timeout: float = 60.0, backoff: float = 5.0):
        self.delay = delay
        self.retries = retries
        self.timeout = timeout
        self.backoff = backoff
        self._last = 0.0

    def get(self, url: str) -> tuple[bytes, str, dict]:
        """GET with throttling and retries. Returns (body, final_url, headers)."""
        attempt = 0
        while True:
            wait = self.delay - (time.monotonic() - self._last)
            if wait > 0:
                time.sleep(wait)
            self._last = time.monotonic()
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    return resp.read(), resp.geturl(), dict(resp.headers)
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    raise
                retryable = e.code == 429 or e.code >= 500
                if not retryable or attempt >= self.retries:
                    raise
                backoff = 60 if e.code == 429 else self.backoff * (2 ** attempt)
            except (urllib.error.URLError, TimeoutError, ConnectionError, OSError):
                if attempt >= self.retries:
                    raise
                backoff = self.backoff * (2 ** attempt)
            attempt += 1
            print(f"  retry {attempt}/{self.retries} in {backoff}s: {url}", file=sys.stderr)
            time.sleep(backoff)


def read_jsonl(path: Path):
    if not path.exists():
        return
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)


def append_jsonl(path: Path, rows) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    n = 0
    with path.open("a", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
            n += 1
    return n


def ts_to_date(ts: str) -> dt.datetime:
    ts = (ts + "00000000000000")[:14]
    return dt.datetime.strptime(ts, "%Y%m%d%H%M%S")


def is_swf(row: dict) -> bool:
    mime = (row.get("mime") or "").lower()
    path = urllib.parse.urlsplit(row["url"]).path.lower()
    return mime in SWF_MIMES or path.endswith(".swf")


def sha1_base32(data: bytes) -> str:
    return base64.b32encode(hashlib.sha1(data).digest()).decode("ascii")


# ───────────────────────────── scan ─────────────────────────────

def cmd_scan(a) -> None:
    http = Http(a.delay)
    out = Path(a.out)
    state_path = out.with_suffix(".state.json")
    state = json.loads(state_path.read_text("utf-8")) if state_path.exists() else {}
    seen = {(r["url"], r["ts"]) for r in read_jsonl(out)}
    patterns = a.pattern or DEFAULT_PATTERNS
    for pattern in patterns:
        st = state.get(pattern, {})
        if st.get("done"):
            print(f"[scan] {pattern}: already complete, skipping")
            continue
        resume = st.get("resume")
        page = 0
        total_new = 0
        while True:
            params = {
                "url": pattern,
                "from": a.from_year,
                "to": a.to_year,
                "output": "json",
                "fl": CDX_FIELDS,
                "showResumeKey": "true",
                "limit": str(a.page_size),
            }
            if not a.all_status:
                params["filter"] = "statuscode:200"
            if resume:
                params["resumeKey"] = resume
            url = f"{a.wayback}/cdx/search/cdx?" + urllib.parse.urlencode(params)
            body, _, _ = http.get(url)
            text = body.decode("utf-8", "replace").strip()
            rows = json.loads(text) if text else []
            resume = None
            if rows and rows[-1] and len(rows) >= 2 and rows[-2] == []:
                resume = rows[-1][0]
                rows = rows[:-2]
            header, data = (rows[0], rows[1:]) if rows else ([], [])
            new = []
            for r in data:
                rec = dict(zip(header, r))
                row = {
                    "url": normalize_url(rec["original"]),
                    "original": rec["original"],
                    "ts": rec["timestamp"],
                    "mime": rec.get("mimetype", ""),
                    "status": rec.get("statuscode", ""),
                    "digest": rec.get("digest", ""),
                    "length": rec.get("length", ""),
                }
                key = (row["url"], row["ts"])
                if key in seen:
                    continue
                seen.add(key)
                new.append(row)
            total_new += append_jsonl(out, new)
            page += 1
            state[pattern] = {"resume": resume, "done": resume is None}
            state_path.write_text(json.dumps(state, indent=2), "utf-8")
            print(f"[scan] {pattern}: page {page}, +{len(new)} (total new {total_new})")
            if resume is None:
                break
    print(f"[scan] index: {out} ({len(seen)} captures)")


# ───────────────────────────── histogram ─────────────────────────────

def cmd_histogram(a) -> None:
    caps = collections.Counter()
    urls = collections.defaultdict(set)
    for row in read_jsonl(Path(a.cdx)):
        if not a.all_types and not is_swf(row):
            continue
        month = row["ts"][:4] + "-" + row["ts"][4:6]
        caps[month] += 1
        urls[month].add(row["url"])
    if not caps:
        print("No matching captures.")
        return
    width = max(len(u) for u in urls.values())
    print(f"{'month':8} {'captures':>9} {'unique':>7}")
    for month in sorted(caps):
        bar = "#" * max(1, round(40 * len(urls[month]) / width))
        print(f"{month:8} {caps[month]:9d} {len(urls[month]):7d} {bar}")
    in_year = [m for m in urls if m.startswith(str(a.year))]
    if in_year:
        best = max(in_year, key=lambda m: len(urls[m]))
        print(f"\nSuggested anchor: {best}-15  ({len(urls[best])} unique "
              f"{'files' if a.all_types else 'SWFs'} captured that month)")


# ───────────────────────────── plan ─────────────────────────────

def cmd_plan(a) -> None:
    anchor = dt.datetime.strptime(a.anchor, "%Y-%m-%d")
    lo = dt.datetime.strptime(a.not_before, "%Y-%m-%d") if a.not_before else None
    hi = dt.datetime.strptime(a.not_after, "%Y-%m-%d") if a.not_after else None
    include = re.compile(a.include) if a.include else None
    exclude = re.compile(a.exclude) if a.exclude else None
    best: dict[str, tuple[float, dict]] = {}
    for row in read_jsonl(Path(a.cdx)):
        if row.get("status") not in ("200", 200, ""):
            continue
        if include and not include.search(row["url"]):
            continue
        if exclude and exclude.search(row["url"]):
            continue
        when = ts_to_date(row["ts"])
        if (lo and when < lo) or (hi and when > hi):
            continue
        days = (when - anchor).total_seconds() / 86400
        score = -days if days <= 0 else days * a.after_penalty
        cur = best.get(row["url"])
        if cur is None or score < cur[0]:
            best[row["url"]] = (score, {**row, "delta_days": round(days, 1)})
    rows = [v for _, v in sorted(best.values(), key=lambda t: t[1]["url"])]
    out = Path(a.out)
    if out.exists():
        out.unlink()
    append_jsonl(out, rows)
    deltas = sorted(abs(r["delta_days"]) for r in rows)
    median = deltas[len(deltas) // 2] if deltas else 0
    within = sum(1 for d in deltas if d <= 90)
    print(f"[plan] {len(rows)} URLs -> {out}")
    print(f"[plan] median distance from anchor: {median:.0f} days; "
          f"{within} URLs within 90 days of {a.anchor}")


# ───────────────────────────── fetch ─────────────────────────────

ID_RE = re.compile(r"/web/(\d{14})id_/")


def save_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".part")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def cmd_fetch(a) -> None:
    http = Http(a.delay)
    mirror = Path(a.mirror)
    index = Path(a.index)
    errors = index.with_name(index.stem + ".errors.jsonl")
    done = {r["url"] for r in read_jsonl(index) if (mirror / r["relpath"]).exists()}
    plan = [r for r in read_jsonl(Path(a.plan)) if r["url"] not in done]
    if a.max:
        plan = plan[: a.max]
    print(f"[fetch] {len(done)} already mirrored, {len(plan)} to fetch")
    ok = bad = 0
    for i, row in enumerate(plan, 1):
        src = f"{a.wayback}/web/{row['ts']}id_/{row['original']}"
        try:
            body, final, headers = http.get(src)
        except Exception as e:  # noqa: BLE001 - log and continue
            bad += 1
            append_jsonl(errors, [{"url": row["url"], "src": src, "error": repr(e)}])
            print(f"  [{i}/{len(plan)}] FAIL {row['url']}: {e}")
            continue
        m = ID_RE.search(final)
        got_ts = m.group(1) if m else row["ts"]
        rel = url_to_relpath(row["url"])
        save_atomic(mirror / rel, body)
        digest = sha1_base32(body)
        rec = {
            "url": row["url"],
            "original": row["original"],
            "ts": got_ts,
            "relpath": rel,
            "size": len(body),
            "sha1_b32": digest,
            "digest_ok": (digest == row.get("digest")) if row.get("digest") else None,
            "mime": headers.get("Content-Type", row.get("mime", "")),
            "provenance": "wayback",
        }
        append_jsonl(index, [rec])
        ok += 1
        flag = "" if rec["digest_ok"] in (True, None) else "  (digest mismatch)"
        print(f"  [{i}/{len(plan)}] {got_ts} {row['url']} {len(body)}B{flag}")
    print(f"[fetch] done: {ok} saved, {bad} failed (see {errors})")


# ───────────────────────────── coverage ─────────────────────────────

def category(url: str, depth: int) -> str:
    parts = urllib.parse.urlsplit(url)
    segs = [s for s in parts.path.split("/") if s][:-1][:depth]
    return parts.netloc + ("/" + "/".join(segs) if segs else "")


def strip_query(url: str) -> str:
    return url.split("?", 1)[0]


def cmd_coverage(a) -> None:
    wanted = []
    for line in Path(a.wanted).read_text("utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            wanted.append(normalize_url(line))
    key = strip_query if a.ignore_query else (lambda u: u)
    prov = {}
    for r in read_jsonl(Path(a.index)):
        prov.setdefault(key(r["url"]), r.get("provenance", "wayback"))
    in_cdx = {key(r["url"]) for r in read_jsonl(Path(a.cdx))} if a.cdx else set()
    stats = collections.defaultdict(collections.Counter)
    missing = []
    for url in wanted:
        k = key(url)
        if k in prov:
            state = "wayback" if prov[k] == "wayback" else "other"
        elif k in in_cdx:
            state = "captured-not-fetched"
        else:
            state = "missing"
            missing.append(url)
        stats[category(url, a.depth)][state] += 1
    cols = ["wayback", "other", "captured-not-fetched", "missing"]
    lines = ["| category | wanted | " + " | ".join(cols) + " | 2012 share |",
             "| --- | ---: | " + " | ".join("---:" for _ in cols) + " | ---: |"]
    tot = collections.Counter()
    for cat in sorted(stats, key=lambda c: -sum(stats[c].values())):
        c = stats[cat]
        n = sum(c.values())
        tot.update(c)
        lines.append(f"| {cat} | {n} | " + " | ".join(str(c[x]) for x in cols)
                     + f" | {100 * c['wayback'] / n:.0f}% |")
    n = sum(tot.values()) or 1
    lines.append(f"| **all** | {sum(tot.values())} | " + " | ".join(str(tot[x]) for x in cols)
                 + f" | **{100 * tot['wayback'] / n:.0f}%** |")
    report = "\n".join(lines)
    print(report)
    if a.report:
        Path(a.report).write_text("# Coverage\n\n" + report + "\n", "utf-8")
    if a.missing_out:
        Path(a.missing_out).write_text("\n".join(missing) + ("\n" if missing else ""), "utf-8")
        print(f"\n{len(missing)} missing URLs -> {a.missing_out}")
    print(f"\nFidelity score (share served from Wayback captures): {100 * tot['wayback'] / n:.1f}%")


# ───────────────────────────── fill-live ─────────────────────────────

def cmd_fill_live(a) -> None:
    http = Http(a.delay)
    mirror = Path(a.mirror)
    index = Path(a.index)
    have = {r["url"] for r in read_jsonl(index)}
    todo = [normalize_url(u) for u in Path(a.missing).read_text("utf-8").split() if u.strip()]
    todo = [u for u in todo if u not in have]
    stamp = dt.date.today().isoformat()
    print(f"[fill-live] {len(todo)} URLs; files will be tagged provenance=live-{stamp}")
    for i, url in enumerate(todo, 1):
        src = url.replace("http://", "https://", 1) if a.https else url
        try:
            body, _, headers = http.get(src)
        except Exception as e:  # noqa: BLE001
            print(f"  [{i}/{len(todo)}] FAIL {url}: {e}")
            continue
        rel = url_to_relpath(url)
        save_atomic(mirror / rel, body)
        append_jsonl(index, [{
            "url": url, "original": src, "ts": dt.datetime.now().strftime("%Y%m%d%H%M%S"),
            "relpath": rel, "size": len(body), "sha1_b32": sha1_base32(body),
            "digest_ok": None, "mime": headers.get("Content-Type", ""),
            "provenance": f"live-{stamp}",
        }])
        print(f"  [{i}/{len(todo)}] {url} {len(body)}B")


# ───────────────────────────── fill-manifest ─────────────────────────────

ENTRY_RE = re.compile(r'<f\s+n="([^"]+)"\s+v="([^"]+)"')


def load_entries(paths: list[str]) -> dict[str, str]:
    """Merge manifests in order; later files (e.g. a start.xml patch list) win."""
    entries: dict[str, str] = {}
    for p in paths:
        text = Path(p).read_bytes().decode("utf-8", "ignore")
        for n, v in ENTRY_RE.findall(text):
            entries[n] = v
    return entries


def summarize_fill(log: Path) -> None:
    latest = {}
    for r in read_jsonl(log):
        latest[r["url"]] = r
    by = collections.defaultdict(collections.Counter)
    for r in latest.values():
        by[r["name"].split("/")[0]][r["outcome"]] += 1
    cols = ["verified", "verified-older", "newer", "undated", "http-404", "other"]
    print("| folder | files | " + " | ".join(cols) + " |")
    print("| --- | ---: | " + " | ".join("---:" for _ in cols) + " |")
    tot = collections.Counter()
    for top in sorted(by, key=lambda k: -sum(by[k].values())):
        c = by[top]
        other = sum(n for k, n in c.items() if k not in cols[:-1])
        row = [c[k] for k in cols[:-1]] + [other]
        tot.update(dict(zip(cols, row)))
        print(f"| {top} | {sum(c.values())} | " + " | ".join(map(str, row)) + " |")
    print(f"| **all** | {sum(tot.values())} | " + " | ".join(str(tot[k]) for k in cols) + " |")


def classify(name: str, version: str, body: bytes) -> tuple[str, object]:
    """verified: XMP modify date equals the stamp; verified-older: modified before
    the stamp and (since the CDN serves the latest version) never changed after;
    newer: changed after the client shipped; undated: no XMP to judge by."""
    info = inspect(body) if name.lower().endswith(".swf") else None
    stamp, mod = stamp_yymmdd(version), (info.modify_yymmdd if info else None)
    if info and not info.ok:
        return "not-swf", info
    if mod and stamp:
        return ("verified" if mod == stamp else "newer" if mod > stamp else "verified-older"), info
    return "undated", info


VERIFIED = ("verified", "verified-older")


def cmd_fill_manifest(a) -> None:
    import threading
    from concurrent.futures import ThreadPoolExecutor

    entries = load_entries(a.manifest + (a.patch or []))
    mirror, quarantine = Path(a.mirror), Path(a.quarantine)
    index, log = Path(a.index), Path(a.log)
    have = {r["url"] for r in read_jsonl(index)}
    retry = ("error", "http-5", "not-swf", "older")
    done = {r["url"] for r in read_jsonl(log) if not r["outcome"].startswith(retry)}
    only = re.compile(a.only) if a.only else None
    todo = []
    for n, v in sorted(entries.items()):
        if only and not only.search(n):
            continue
        name = n if re.search(r"\.\w{2,4}$", n) else n + ".swf"
        client_url = normalize_url(urllib.parse.urljoin(a.client_base, name) + "?" + v)
        if client_url in have or client_url in done:
            continue
        todo.append((n, v, name, client_url))
    if a.max:
        todo = todo[: a.max]
    print(f"[fill] {len(entries)} manifest entries; {len(todo)} left to fetch from {a.live_base} "
          f"with {a.workers} workers")
    deadline = time.monotonic() + a.time_limit if a.time_limit else None
    counts = collections.Counter()
    lock = threading.Lock()
    local = threading.local()
    progress = iter(range(1, len(todo) + 1))

    def work(item) -> None:
        n, v, name, client_url = item
        if deadline and time.monotonic() > deadline:
            return
        if not hasattr(local, "http"):
            # The live CDN sometimes stalls a connection: fail fast and retry.
            local.http = Http(a.delay, retries=4, timeout=8, backoff=1)
        src = urllib.parse.urljoin(a.live_base, name)
        rec = {"url": client_url, "name": n, "v": v, "src": src, "t": dt.datetime.now().isoformat(timespec="seconds")}
        try:
            body, _, headers = local.http.get(src)
        except urllib.error.HTTPError as e:
            rec["outcome"] = f"http-{e.code}"
        except Exception as e:  # noqa: BLE001
            rec.update(outcome="error", error=repr(e))
        else:
            outcome, info = classify(name, v, body)
            rel = url_to_relpath(client_url)
            root = mirror if outcome in VERIFIED else quarantine
            save_atomic(root / rel, body)
            rec.update(outcome=outcome, size=len(body), sha1_b32=sha1_base32(body),
                       xmp_modify=getattr(info, "modify_yymmdd", None),
                       swf=f"{info.compression} v{info.swf_version}" if info is not None and info.ok else None,
                       saved=f"{root.name}/{rel}")
            if outcome in VERIFIED:
                with lock:
                    append_jsonl(index, [{
                        "url": client_url, "original": src, "ts": dt.datetime.now().strftime("%Y%m%d%H%M%S"),
                        "relpath": rel, "size": len(body), "sha1_b32": rec["sha1_b32"], "digest_ok": None,
                        "mime": headers.get("Content-Type", ""), "provenance": f"live-{outcome}",
                    }])
        with lock:
            append_jsonl(log, [rec])
            counts[rec["outcome"]] += 1
            print(f"  [{next(progress)}/{len(todo)}] {rec['outcome']:14} v{v} xmp={rec.get('xmp_modify')} {n}", flush=True)

    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        list(pool.map(work, todo))
    if deadline and time.monotonic() > deadline and sum(counts.values()) < len(todo):
        print("[fill] time limit reached; run again to continue")
    print(f"[fill] this run: {dict(counts)}")
    summarize_fill(log)


# ───────────────────────────── CLI ─────────────────────────────

def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--wayback", default=WAYBACK, help="Wayback base URL (override for tests)")
    p.add_argument("--delay", type=float, default=1.0, help="seconds between requests")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("scan", help="list captures via the CDX index")
    s.add_argument("--pattern", action="append", help="CDX url pattern (repeatable); default: 100bt hosts")
    s.add_argument("--from", dest="from_year", default="2010")
    s.add_argument("--to", dest="to_year", default="2014")
    s.add_argument("--page-size", type=int, default=5000)
    s.add_argument("--all-status", action="store_true", help="keep non-200 captures too")
    s.add_argument("--out", default="work/cdx.jsonl")
    s.set_defaults(fn=cmd_scan)

    s = sub.add_parser("histogram", help="SWF captures per month")
    s.add_argument("--cdx", default="work/cdx.jsonl")
    s.add_argument("--year", type=int, default=2012)
    s.add_argument("--all-types", action="store_true", help="count every file type, not only SWF")
    s.set_defaults(fn=cmd_histogram)

    s = sub.add_parser("plan", help="choose the capture nearest the anchor for each URL")
    s.add_argument("--cdx", default="work/cdx.jsonl")
    s.add_argument("--anchor", required=True, help="YYYY-MM-DD")
    s.add_argument("--not-before", help="YYYY-MM-DD; ignore older captures")
    s.add_argument("--not-after", help="YYYY-MM-DD; ignore newer captures")
    s.add_argument("--after-penalty", type=float, default=1.5,
                   help="weight on captures after the anchor (>1 prefers older files)")
    s.add_argument("--include", help="regex a URL must match")
    s.add_argument("--exclude", help="regex that drops a URL")
    s.add_argument("--out", default="work/plan.jsonl")
    s.set_defaults(fn=cmd_plan)

    s = sub.add_parser("fetch", help="download original bytes into the mirror")
    s.add_argument("--plan", default="work/plan.jsonl")
    s.add_argument("--mirror", default="mirror")
    s.add_argument("--index", default="work/index.jsonl")
    s.add_argument("--max", type=int, help="stop after N files")
    s.set_defaults(fn=cmd_fetch)

    s = sub.add_parser("coverage", help="wanted URLs vs mirror")
    s.add_argument("--wanted", required=True, help="text file, one URL per line")
    s.add_argument("--index", default="work/index.jsonl")
    s.add_argument("--cdx", help="cdx.jsonl, to flag captured-but-not-fetched")
    s.add_argument("--ignore-query", action="store_true")
    s.add_argument("--depth", type=int, default=2, help="path segments per category")
    s.add_argument("--report", help="write the table as markdown")
    s.add_argument("--missing-out", help="write missing URLs here")
    s.set_defaults(fn=cmd_coverage)

    s = sub.add_parser("fill-live", help="fetch missing files from the live CDN (non-2012)")
    s.add_argument("--missing", required=True, help="file of URLs (coverage --missing-out)")
    s.add_argument("--mirror", default="mirror")
    s.add_argument("--index", default="work/index.jsonl")
    s.add_argument("--https", action="store_true", help="request over https")
    s.set_defaults(fn=cmd_fill_live)

    s = sub.add_parser("fill-manifest", help="fetch a manifest's files from the live CDN, verified by XMP date")
    s.add_argument("--manifest", action="append", required=True, help="versiondata XML (repeatable)")
    s.add_argument("--patch", action="append", help="start.xml hot-patch lists applied after the manifest")
    s.add_argument("--client-base", default="http://www.9aola.com/", help="where the client loads files from")
    s.add_argument("--live-base", default="http://aola.100bt.com/play/", help="live CDN root holding the same paths")
    s.add_argument("--mirror", default="mirror")
    s.add_argument("--quarantine", default="mirror-unverified")
    s.add_argument("--index", default="work/index.jsonl")
    s.add_argument("--log", default="work/fill-live.jsonl")
    s.add_argument("--only", help="regex on manifest paths (e.g. ^scene/)")
    s.add_argument("--max", type=int)
    s.add_argument("--time-limit", type=float, help="stop starting new downloads after N seconds")
    s.add_argument("--workers", type=int, default=4, help="parallel downloads (each keeps --delay between its requests)")
    s.set_defaults(fn=cmd_fill_manifest)

    a = p.parse_args(argv)
    a.wayback = a.wayback.rstrip("/")
    a.fn(a)


if __name__ == "__main__":
    main()
