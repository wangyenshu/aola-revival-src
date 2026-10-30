#!/bin/sh
# Compile the generated service stand-ins (rebuild/gen/stubs, made by
# tools/gen_stubs.py) and install each under <out-root> at its original module
# URL. Needs rebuild/out/swc/play.swc from all.sh.
#   build/stubs.sh <gen/stubs dir> <out-root> [parallel jobs]
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
STUBS="$(cd "${1:?gen/stubs dir}" && pwd)"
DEST="$(mkdir -p "${2:?rebuilt root}" && cd "$2" && pwd)"
JOBS="${3:-4}"
EXTRA_SWC="${EXTRA_SWC:-$HERE/../out/swc/play.swc}"
unset GEN  # as3c.sh would add it as a source path
export HERE STUBS DEST EXTRA_SWC
python3 - "$STUBS/modules.json" <<'PY' | xargs -P "$JOBS" -n 3 sh -c '
  mod="$0"; doc="$1"; ver="$2"
  log="$HERE/../out/stubs/$mod"; mkdir -p "$log"; out="$log/out.swf"
  if SHARED="$HERE/../src/shared" sh "$HERE/as3c.sh" "$STUBS/$mod/src" "$doc" "$out" > "$log/build.log" 2>&1 && [ -f "$out" ]; then
    dest="$DEST/www.9aola.com/$mod.swf%3F$ver"; mkdir -p "$(dirname "$dest")"; cp "$out" "$dest"; echo "ok   $mod"
  else
    echo "FAIL $mod (see rebuild/out/stubs/$mod/build.log)"
  fi'
import json, os, sys
skip = set()
ns = os.path.join(os.environ["HERE"], "no-stub.txt")
if os.path.exists(ns):
    skip = {l.strip() for l in open(ns, encoding="utf-8") if l.strip() and not l.startswith("#")}
for mod, m in json.load(open(sys.argv[1])).items():
    if mod not in skip:
        print(mod, m["doc"], m.get("version") or "1210")
PY
