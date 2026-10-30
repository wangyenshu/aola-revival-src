#!/bin/sh
# Build every rebuilt SWF module from rebuild/src (and the stand-ins in
# rebuild/gen/stubs) into one folder, served above game/ by the static site.
#   rebuild/build/build-swf.sh [out-dir]        (default build/rebuilt)
# The tools come from .toolchain/ (rebuild/build/setup-toolchain.sh, run here
# when missing) unless ROYALE, PLAYERGLOBAL and FFDEC are set. Java 11+,
# Python 3 and Node are needed. JOBS sets parallel stub builds (default 4).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="${1:-$ROOT/build/rebuilt}"
GAME="$ROOT/game"
if [ -z "$ROYALE" ] || [ -z "$PLAYERGLOBAL" ] || [ -z "$FFDEC" ]; then
  [ -f "$ROOT/.toolchain/env.sh" ] || sh "$HERE/setup-toolchain.sh" "$ROOT/.toolchain"
  . "$ROOT/.toolchain/env.sh"
fi
export ROYALE PLAYERGLOBAL FFDEC

# The 2013 libraries as SWCs.
export LIBSWC="$ROOT/rebuild/out/libswc"
mkdir -p "$LIBSWC"
grep -v '^#' "$HERE/libs.txt" | while read -r name file; do
  [ -n "$name" ] || continue
  [ -f "$LIBSWC/$name.swc" ] && [ "$LIBSWC/$name.swc" -nt "$GAME/$file" ] && continue
  java -jar "$FFDEC" -swf2swc "$LIBSWC/$name.swc" "$GAME/$file" > /dev/null 2>&1
  [ -f "$LIBSWC/$name.swc" ] || { echo "could not make $name.swc from game/$file" >&2; exit 1; }
done

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
rm -rf "$OUT/www.9aola.com"
sh "$HERE/all.sh" "$OUT" "$GAME"
sh "$HERE/stubs.sh" "$ROOT/rebuild/gen/stubs" "$OUT" "${JOBS:-4}" | tee "$ROOT/rebuild/out/stubs.log" | grep -v '^ok' || true
# Data the rebuilt modules and the emulator read (config overlay, 亚比 and item tables).
cp -R "$ROOT/rebuild/static/." "$OUT/"
fails="$(grep -c '^FAIL' "$ROOT/rebuild/out/stubs.log" || true)"
n="$(find "$OUT" -type f | wc -l | tr -d ' ')"
echo "built $n files into $OUT"
if [ "$fails" != "0" ]; then echo "$fails stand-ins failed to build (rebuild/out/stubs.log)" >&2; exit 1; fi
