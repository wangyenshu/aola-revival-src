#!/bin/sh
# Compile one rebuilt module against the original 2013 libraries.
#   build/as3c.sh <src-dir> <main.as> <out.swf>
# Env: ROYALE (royale-asjs dir), PLAYERGLOBAL (swc), LIBSWC (dir of 2013 lib SWCs),
#      EXTRA_SWC (more SWCs, e.g. the rebuilt control), SHARED (extra source dir)
set -e
SRC="$1"; MAIN="$2"; OUT="$3"
EXT=""
for s in "$LIBSWC"/*.swc $EXTRA_SWC; do EXT="$EXT -external-library-path+=$s"; done
CFG="$(dirname "$0")/empty-config.xml"
java -Droyalelib="$ROYALE/frameworks" -jar "$ROYALE/lib/mxmlc.jar" -load-config="$CFG" \
  -external-library-path+="$PLAYERGLOBAL" $EXT \
  -source-path+="$SRC" ${SHARED:+-source-path+="$SHARED"} ${GEN:+-source-path+="$GEN"} -target-player=10.1 -swf-version=10 \
  -static-link-runtime-shared-libraries=true -debug=false -optimize=true -omit-trace-statements=false \
  -default-size 960 560 -default-frame-rate 25 \
  -output="$OUT" "$SRC/$MAIN" 2>&1 | grep -v "JAVA_TOOL_OPTIONS"
