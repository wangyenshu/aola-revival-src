#!/bin/sh
# Fetch era resources that are not part of the client but that rebuilt modules
# use as artwork, into the mirror root.
#   tools/fetch_refs.sh <mirror-root>
# map/mapguide2012.swf: the world map of 30 Nov 2012 (XMP ModifyDate
# 2012-11-30T20:12:23+08:00) from 百田's guide page
# aola.100bt.com/xinshouybdt/52097.html; used by the rebuilt map/map.
set -e
M="${1:?mirror root}/www.9aola.com"
mkdir -p "$M/map"
curl -sSf -o "$M/map/mapguide2012.swf" http://img2.a0bi.com/upload/old/web/1354946686227_.swf
sha1sum "$M/map/mapguide2012.swf"
