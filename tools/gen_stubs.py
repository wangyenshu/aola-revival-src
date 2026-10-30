#!/usr/bin/env python3
"""Generate AS3 stand-ins for the 2013 services whose modules did not survive.

The January 2013 client finds every service through mmo.interfaces.ServiceConfig:
an id, the interface it implements, the implementing class name, the module SWF
that defines that class, and a locator. Code all over the game calls
ServiceContainer.getService(ISomething) and expects the class to exist, so a
lost module breaks every scene that touches it.

For each service whose module is lost (see --available), this writes a class
with the original fully qualified name that implements the original interface:
every method is present and returns an empty value, and the first call of each
one is logged (mmo.revival.RLog.stub), which shows what to rebuild next.
Classes are grouped by their original module path, one source tree each, plus
a document class per module so mxmlc links them all:

  <out>/<module path>/src/<package>/<Class>.as
  <out>/<module path>/src/mmo/revival/stubdoc/<Doc>.as
  <out>/modules.json        module path -> doc class, services, version

Usage:
  tools/gen_stubs.py --src ../aola-work/src --available available.json --out rebuild/gen/stubs
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

DEFAULTS = {
    "void": None, "int": "0", "uint": "0", "Number": "0", "Boolean": "false",
    "String": '""', "Array": "[]", "Object": "{}", "*": "null",
}
FLASH_EVENT_IFACES = {"flash.events.IEventDispatcher", "IEventDispatcher"}


@dataclass
class ServiceEntry:
    id: str
    interface: str  # fully qualified
    class_name: str
    module: str
    locator: str | None


@dataclass
class Member:
    kind: str  # "method" | "get" | "set"
    name: str
    params: str
    ret: str


@dataclass
class Iface:
    fqn: str
    file: Path
    imports: list[str]
    extends: list[str]  # fully qualified
    members: list[Member] = field(default_factory=list)


# ───────────────────────── parsing ─────────────────────────

def split_args(s: str, start: int) -> tuple[list[str], int]:
    """Split the argument list that begins after '(' at s[start]; returns args, end index."""
    depth, i, cur, args, quote = 0, start, [], [], None
    while i < len(s):
        c = s[i]
        if quote:
            cur.append(c)
            if c == "\\":
                cur.append(s[i + 1])
                i += 1
            elif c == quote:
                quote = None
        elif c in "\"'":
            quote = c
            cur.append(c)
        elif c in "([{":
            depth += 1
            cur.append(c)
        elif c in ")]}":
            if depth == 0:
                args.append("".join(cur).strip())
                return args, i
            depth -= 1
            cur.append(c)
        elif c == "," and depth == 0:
            args.append("".join(cur).strip())
            cur = []
        else:
            cur.append(c)
        i += 1
    raise ValueError("unterminated argument list")


def imports_of(text: str) -> dict[str, str]:
    return {m.split(".")[-1]: m for m in re.findall(r"^\s*import\s+([\w.]+);", text, re.M) if not m.endswith("*")}


def unquote(a: str) -> str | None:
    a = a.strip()
    if a == "null":
        return None
    if a[:1] in "\"'":
        return a[1:-1]
    return a


def parse_service_config(path: Path) -> list[ServiceEntry]:
    text = path.read_text(encoding="utf-8")
    imps = imports_of(text)
    out = []
    for m in re.finditer(r"new ServiceInfo\(", text):
        args, _ = split_args(text, m.end())
        sid, iface, cls, module = (unquote(a) for a in args[:4])
        loc = unquote(args[4]) if len(args) > 4 else None
        if iface and "." not in iface:
            iface = imps.get(iface, "mmo.interfaces." + iface)  # unimported: ServiceConfig's own package
        out.append(ServiceEntry(sid, iface, cls, module, loc))
    return out


def index_sources(src_root: Path) -> dict[str, Path]:
    """FQN -> decompiled file, across the 2013 library decompiles."""
    idx: dict[str, Path] = {}
    for f in sorted(src_root.glob("*/scripts/**/*.as")):
        parts = f.relative_to(src_root).with_suffix("").parts  # lib, "scripts", package..., Class
        idx.setdefault(".".join(parts[2:]), f)
    return idx


MEMBER_RE = re.compile(r"^\s*function\s+(?:(get|set)\s+)?(\w+)\s*\((.*?)\)\s*:\s*([\w.*]+)\s*;", re.M)


def parse_iface(fqn: str, idx: dict[str, Path], cache: dict[str, Iface]) -> Iface | None:
    if fqn in cache:
        return cache[fqn]
    f = idx.get(fqn)
    if f is None:
        return None
    text = f.read_text(encoding="utf-8")
    pkg = fqn.rsplit(".", 1)[0] if "." in fqn else ""
    imps = imports_of(text)
    m = re.search(r"interface\s+\w+(?:\s+extends\s+([\w.,\s]+?))?\s*\{", text)
    if not m:
        return None
    ext = []
    for e in (m.group(1) or "").split(","):
        e = e.strip()
        if not e:
            continue
        ext.append(e if "." in e else imps.get(e, f"{pkg}.{e}" if pkg else e))
    it = Iface(fqn, f, [i for i in re.findall(r"^\s*import\s+([\w.*]+);", text, re.M)], ext)
    for kind, name, params, ret in MEMBER_RE.findall(text):
        it.members.append(Member(kind or "method", name, params, ret))
    cache[fqn] = it
    for e in ext:
        parse_iface(e, idx, cache)
    return it


def hierarchy(fqn: str, cache: dict[str, Iface], seen=None) -> list[Iface]:
    seen = seen if seen is not None else set()
    if fqn in seen or fqn not in cache:
        return []
    seen.add(fqn)
    out = [cache[fqn]]
    for e in cache[fqn].extends:
        out += hierarchy(e, cache, seen)
    return out


# ───────────────────────── generation ─────────────────────────

def default_for(ret: str) -> str | None:
    if ret in DEFAULTS:
        return DEFAULTS[ret]
    return "null"


def gen_class(svc: ServiceEntry, ifaces: list[Iface], idx: dict[str, Path], extra_impl: list[str]) -> str:
    pkg, cls = (svc.class_name.rsplit(".", 1) + [""])[:2] if "." in svc.class_name else ("", svc.class_name)
    imports = {"flash.events.EventDispatcher", "mmo.revival.RLog", svc.interface}
    for it in ifaces:
        ipkg = it.fqn.rsplit(".", 1)[0]
        imports.add(ipkg + ".*")
        imports.update(i for i in it.imports)
    imports.update(extra_impl)
    impl = [svc.interface.split(".")[-1]] + [e.split(".")[-1] for e in extra_impl]
    lines = [
        f"package {pkg}",
        "{",
        *[f"   import {i};" for i in sorted(imports)],
        "",
        "   /**",
        f"    * REBUILT STUB for {svc.id}. Module {svc.module}.swf of January 2013 is lost;",
        f"    * this keeps the original class name and interface ({svc.interface}) so",
        "    * code that looks the service up keeps running. Every method returns an",
        "    * empty value and logs its first call.",
        "    */",
        f"   public class {cls} extends EventDispatcher implements {', '.join(dict.fromkeys(impl))}",
        "   {",
        f"      public function {cls}()",
        "      {",
        "         super();",
        "      }",
        "",
    ]
    done: set[tuple[str, str]] = set()
    props: dict[str, str] = {}
    for it in ifaces:
        for mb in it.members:
            key = (mb.kind, mb.name)
            if key in done:
                continue
            done.add(key)
            tag = f'"{cls}.{mb.name}"'
            if mb.kind == "get":
                props.setdefault(mb.name, mb.ret)
                lines += [f"      public function get {mb.name}() : {mb.ret}",
                          "      {",
                          f"         RLog.stub({tag});",
                          f"         return this._{mb.name} as {mb.ret};" if mb.ret not in ("*", "int", "uint", "Number", "Boolean", "String")
                          else f"         return this._{mb.name};",
                          "      }", ""]
            elif mb.kind == "set":
                props.setdefault(mb.name, "*")
                p = mb.params.split(":")[0].strip() or "param1"
                lines += [f"      public function set {mb.name}({mb.params}) : {mb.ret}",
                          "      {",
                          f"         this._{mb.name} = {p};",
                          "      }", ""]
            else:
                d = default_for(mb.ret)
                body = [f"         RLog.stub({tag});"]
                if mb.name == "init" and mb.ret == "void":
                    body.append('         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));')
                if d is not None:
                    body.append(f"         return {d};")
                lines += [f"      public function {mb.name}({mb.params}) : {mb.ret}", "      {", *body, "      }", ""]
    for name, typ in props.items():
        has_get = ("get", name) in done
        init = ""
        if has_get and typ in ("int", "uint", "Number"):
            init = " = 0"
        elif has_get and typ == "Boolean":
            init = " = false"
        lines.insert(lines.index("      public function " + cls + "()"), f"      private var _{name}:{typ if typ in ('int','uint','Number','Boolean','String') else '*'}{init};")
    if "mmo.interfaces.IServiceLocator" in extra_impl:
        lines.insert(lines.index("      public function " + cls + "()"), f"      private static var __instance:{cls};\n")
        lines += [
            "      public function getInstance() : IService",
            "      {",
            f"         if (__instance == null) __instance = new {cls}();",
            "         return __instance;",
            "      }",
            "",
        ]
    lines += ["   }", "}", ""]
    if "mmo.interfaces.InitServiceEvent" not in imports and any(l.find("InitServiceEvent") >= 0 for l in lines):
        lines.insert(2, "   import mmo.interfaces.InitServiceEvent;")
    return "\n".join(lines)


def gen_locator(loc: str, svc: ServiceEntry) -> str:
    pkg, cls = loc.rsplit(".", 1)
    return "\n".join([
        f"package {pkg}", "{",
        "   import mmo.interfaces.IService;",
        "   import mmo.interfaces.IServiceLocator;",
        f"   import {svc.class_name};", "",
        f"   /** REBUILT STUB locator for {svc.id} (module {svc.module} is lost). */",
        f"   public class {cls} implements IServiceLocator", "   {",
        f"      private static var instance:{svc.class_name.split('.')[-1]};", "",
        f"      public function {cls}()", "      {", "      }", "",
        "      public function getInstance() : IService", "      {",
        f"         if (instance == null) instance = new {svc.class_name.split('.')[-1]}();",
        "         return instance;", "      }", "   }", "}", ""])


def safe(module: str) -> str:
    return re.sub(r"\W", "_", module)


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", required=True, help="dir of 2013 library decompiles (<lib>/scripts/...)")
    p.add_argument("--available", required=True,
                   help="JSON {module path: 'original'|'rebuilt'} for modules that need no stub")
    p.add_argument("--versions", help="JSON {module path: version} for the install name")
    p.add_argument("--out", required=True)
    p.add_argument("--only", help="regex on module paths")
    a = p.parse_args(argv)

    src = Path(a.src)
    cfg = next(src.glob("interfaces/scripts/mmo/interfaces/ServiceConfig.as"))
    services = parse_service_config(cfg)
    avail = json.loads(Path(a.available).read_text())
    versions = json.loads(Path(a.versions).read_text()) if a.versions else {}
    idx = index_sources(src)
    cache: dict[str, Iface] = {}
    out = Path(a.out)
    modules: dict[str, dict] = {}
    skipped = []
    for svc in services:
        if svc.module in avail or (a.only and not re.search(a.only, svc.module)):
            continue
        if svc.class_name in idx:
            skipped.append((svc.id, "class exists in a surviving 2013 library"))
            continue
        it = parse_iface(svc.interface, idx, cache)
        if it is None:
            skipped.append((svc.id, f"interface {svc.interface} not found"))
            continue
        ifaces = hierarchy(svc.interface, cache)
        mod = modules.setdefault(svc.module, {"classes": [], "services": [], "version": versions.get(svc.module)})
        if svc.class_name in mod["classes"]:
            mod["services"].append(svc.id)
            continue
        extra = []
        if svc.locator and svc.locator == svc.class_name:
            extra.append("mmo.interfaces.IServiceLocator")
            extra.append("mmo.interfaces.IService")
        base = out / svc.module / "src"
        f = base / (svc.class_name.replace(".", "/") + ".as")
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(gen_class(svc, ifaces, idx, extra), encoding="utf-8")
        mod["classes"].append(svc.class_name)
        mod["services"].append(svc.id)
        if svc.locator and svc.locator not in (svc.class_name,) and not svc.locator.startswith("mmo.interfaces."):
            lf = base / (svc.locator.replace(".", "/") + ".as")
            lf.parent.mkdir(parents=True, exist_ok=True)
            lf.write_text(gen_locator(svc.locator, svc), encoding="utf-8")
            mod["classes"].append(svc.locator)
    for module, mod in modules.items():
        doc = f"Doc_{safe(module)}"
        d = out / module / "src" / "mmo" / "revival" / "stubdoc" / f"{doc}.as"
        d.parent.mkdir(parents=True, exist_ok=True)
        d.write_text("\n".join([
            "package mmo.revival.stubdoc", "{", "   import flash.display.Sprite;",
            *[f"   import {c};" for c in mod["classes"]], "",
            f"   /** REBUILT: document class of the stand-in for {module}.swf. */",
            f"   public class {doc} extends Sprite", "   {",
            f"      public function {doc}()", "      {", "         super();",
            *[f"         {c.split('.')[-1]};" for c in mod["classes"]],
            "      }", "   }", "}", ""]), encoding="utf-8")
        mod["doc"] = f"mmo/revival/stubdoc/{doc}.as"
    (out / "modules.json").write_text(json.dumps(modules, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"{len(services)} services; stubs for {sum(len(m['services']) for m in modules.values())} "
          f"in {len(modules)} modules; skipped {len(skipped)}")
    for s in skipped:
        print("  skip", *s, file=sys.stderr)


if __name__ == "__main__":
    main()
