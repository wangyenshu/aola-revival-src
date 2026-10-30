#!/bin/sh
# Fetch the tools that compile the rebuilt SWF modules (no game files) into
# .toolchain/ and write .toolchain/env.sh. Needs Node (npm), curl, unzip, Java 11+.
#   rebuild/build/setup-toolchain.sh [dir]
#
#   Apache Royale 0.9.12 (mxmlc for SWF)    npm @apache-royale/royale-js-swf
#   playerglobal.swc 10.1 (Flash Player 10.1 API)   github.com/nexussays/playerglobal
#   JPEXS FFDec 26.4.0 (SWF -> SWC, sprite export)  github.com/jindrapetrik/jpexs-decompiler
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
T="${1:-$HERE/../../.toolchain}"
mkdir -p "$T"
T="$(cd "$T" && pwd)"

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d" " -f1; else shasum -a 256 "$1" | cut -d" " -f1; fi; }
fetch() { # <url> <sha256> <dest>
  if [ -f "$3" ] && [ "$(sha256 "$3")" = "$2" ]; then return; fi
  echo "downloading $1"
  curl -fsSL --retry 3 -o "$3.part" "$1"
  got="$(sha256 "$3.part")"
  if [ "$got" != "$2" ]; then echo "checksum mismatch for $1: $got" >&2; rm -f "$3.part"; exit 1; fi
  mv "$3.part" "$3"
}

ROYALE="$T/royale/node_modules/@apache-royale/royale-js-swf/royale-asjs"
if [ ! -f "$ROYALE/lib/mxmlc.jar" ]; then
  echo "installing Apache Royale 0.9.12 (npm)"
  mkdir -p "$T/royale"
  npm install --prefix "$T/royale" --no-audit --no-fund --loglevel=error @apache-royale/royale-js-swf@0.9.12
fi

mkdir -p "$T/playerglobal/10.1"
fetch https://raw.githubusercontent.com/nexussays/playerglobal/master/10.1/playerglobal.swc \
  a75587fa56dc0ce38a13a5b9ccca95c64f1373917a2ede87844278cac585e0a9 "$T/playerglobal/10.1/playerglobal.swc"

if [ ! -f "$T/ffdec/ffdec.jar" ]; then
  fetch https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version26.4.0/ffdec_26.4.0.zip \
    56ce960aeafc7caf034e2052ba49f878a883f7c7ca690da6eeffca9587b5e4b9 "$T/ffdec_26.4.0.zip"
  rm -rf "$T/ffdec"; mkdir -p "$T/ffdec"
  unzip -q "$T/ffdec_26.4.0.zip" -d "$T/ffdec"
  rm -f "$T/ffdec_26.4.0.zip"
fi

cat > "$T/env.sh" <<ENV
export ROYALE="$ROYALE"
export PLAYERGLOBAL="$T/playerglobal/10.1/playerglobal.swc"
export FFDEC="$T/ffdec/ffdec.jar"
ENV
java -version 2>&1 | head -1
echo "toolchain ready: . $T/env.sh"
