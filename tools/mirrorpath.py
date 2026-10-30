"""Shared rules for turning an original URL into a path inside mirror/.

The same rules are implemented in server/src/http/mirrorPath.ts, so a file the
capture tools save is exactly the file the local HTTP server answers with.
Keep the two in sync (tests/test_mirrorpath.py and server tests check fixtures).

Rules
  host   lower-cased, default port (:80 / :443) dropped, "www." kept as-is
  path   percent-decoded, then re-encoded with SAFE_PATH; "." and ".." removed
  "/"    a path ending in "/" (or empty) maps to ".../index.html"
  query  kept: appended to the file name as "%3F" + quote(query, SAFE_QUERY)
"""

from __future__ import annotations

import posixpath
from urllib.parse import quote, unquote, urlsplit

SAFE_PATH = "/-_.~!$'()+,;=@"  # no "*" or ":" so paths stay valid on Windows
SAFE_QUERY = "-_.~=&"
QUERY_MARK = "%3F"


def normalize_url(url: str) -> str:
    """Canonical form used as the key in every index file."""
    if "://" not in url:
        url = "http://" + url
    parts = urlsplit(url)
    scheme = (parts.scheme or "http").lower()
    host = (parts.hostname or "").lower()
    port = parts.port
    if port and not ((scheme == "http" and port == 80) or (scheme == "https" and port == 443)):
        host = f"{host}:{port}"
    path = _clean_path(parts.path)
    out = f"http://{host}{path}"  # 2012 content was plain http; https captures fold in
    if parts.query:
        out += "?" + parts.query
    return out


def _clean_path(raw: str) -> str:
    path = unquote(raw or "/")
    trailing = path.endswith("/")
    path = posixpath.normpath("/" + path.lstrip("/"))
    if path == "/.":
        path = "/"
    path = path.replace("\\", "/")
    while path.startswith("/../"):
        path = path[3:]
    if path == "/..":
        path = "/"
    if trailing and not path.endswith("/"):
        path += "/"
    return quote(path, safe=SAFE_PATH)


def url_to_relpath(url: str) -> str:
    """Relative file path (POSIX separators) inside the mirror root."""
    parts = urlsplit(normalize_url(url))
    host = parts.netloc.replace(":", "_")
    path = parts.path
    if path.endswith("/"):
        path += "index.html"
    rel = host + path
    if parts.query:
        rel += QUERY_MARK + quote(parts.query, safe=SAFE_QUERY)
    return rel


def path_without_query(relpath: str) -> str:
    i = relpath.find(QUERY_MARK)
    return relpath if i < 0 else relpath[:i]
