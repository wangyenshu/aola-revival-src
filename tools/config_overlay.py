#!/usr/bin/env python3
"""Write the rebuilt overlay of the January 2013 config.xml.

The client reads <play> (modules loaded on entering the game) and <service>
(services initialised after that) from config.xml. The original lists name 96
modules; some survive as era originals, some exist only as rebuilt modules or
generated stand-ins, a few not at all. This copies the original file and
rewrites those two lists, keeping the original order, to the modules that can
be served, and the services those modules define. Everything else in the file
is untouched.

  tools/config_overlay.py --config mirror/www.9aola.com/config.xml%3F201301241 \\
      --service-config src/interfaces/scripts/mmo/interfaces/ServiceConfig.as \\
      --status module-status.json --rebuilt rebuilt --out rebuilt/www.9aola.com/config.xml%3F201301241
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_stubs import parse_service_config  # noqa: E402
from mirrorpath import url_to_relpath  # noqa: E402


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--config", required=True, help="original config.xml")
    p.add_argument("--service-config", required=True, help="decompiled 2013 ServiceConfig.as")
    p.add_argument("--status", required=True, help="tools/module_status.py output")
    p.add_argument("--rebuilt", required=True, help="rebuilt root (modules found here count as available)")
    p.add_argument("--base", default="http://www.9aola.com/")
    p.add_argument("--allow-late", action="append", default=[],
                   help="module served even though only a later copy exists (pure assets/data whose structure matches)")
    p.add_argument("--out", required=True)
    a = p.parse_args(argv)

    text = Path(a.config).read_text(encoding="utf-8")
    status = json.loads(Path(a.status).read_text())
    services = parse_service_config(Path(a.service_config))
    module_of = {s.id: s.module for s in services}
    rebuilt = Path(a.rebuilt)

    def available(module: str) -> str | None:
        v = status.get(module, {}).get("version", "1210")
        if (rebuilt / url_to_relpath(f"{a.base}{module}.swf?{v}")).is_file():
            return "rebuilt"
        if status.get(module, {}).get("status") == "original":
            return "original"
        if module in a.allow_late and status.get(module, {}).get("status") == "late":
            return "late-asset"
        return None

    m_play = re.search(r"<play>(.*?)</play>", text, re.S)
    m_svc = re.search(r"<service>(.*?)</service>", text, re.S)
    play = [x.strip() for x in m_play.group(1).split(",") if x.strip()]
    svc = [x.strip() for x in m_svc.group(1).split(",") if x.strip()]
    keep_play = [m for m in play if available(m)]
    dropped = [m for m in play if not available(m)]
    ok_modules = set(keep_play) | {m for m in status if available(m)}
    keep_svc = [s for s in svc if module_of.get(s) in ok_modules]
    dropped_svc = [s for s in svc if s not in keep_svc]

    note = (
        f"<!-- REBUILT OVERLAY of config.xml?201301241 (aola-revival). <play> and <service> keep the "
        f"original order, limited to modules that can be served: {sum(available(m) == 'original' for m in keep_play)} "
        f"era originals, {sum(available(m) == 'rebuilt' for m in keep_play)} rebuilt modules or stand-ins and "
        f"{sum(available(m) == 'late-asset' for m in keep_play)} later asset files ({', '.join(m for m in keep_play if available(m) == 'late-asset') or 'none'}). "
        f"Left out (only later rebuilds exist, no stand-in yet): {', '.join(dropped) or 'none'}. Everything else is the original file. -->"
    )
    out = text[: m_play.start()] + "<play>" + ",".join(keep_play) + "</play>" + text[m_play.end(): m_svc.start()]
    out += "<service>" + ",".join(keep_svc) + "</service>" + text[m_svc.end():]
    out = re.sub(r"(<\?xml[^>]*\?>\s*<\w+[^>]*>)", lambda m: m.group(1) + "\n    " + note, out, count=1)
    if note not in out:
        out = note + "\n" + out
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_text(out, encoding="utf-8")
    print(f"play: {len(keep_play)}/{len(play)} modules; service: {len(keep_svc)}/{len(svc)}")
    if dropped:
        print("  play left out:", ", ".join(dropped))
    if dropped_svc:
        print("  services left out:", ", ".join(dropped_svc))


if __name__ == "__main__":
    main()
