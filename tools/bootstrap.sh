#!/bin/sh
# From a checkout without 百田's game files: download them, then build the site.
#   sh tools/bootstrap.sh [options of tools/fetch_game.py, e.g. --keep-changed]
# Needs Python 3, Node 22.18+, Java 11+, curl and unzip (docs/DEVELOPMENT.md);
# FFmpeg makes the theatre's films playable in the page (optional).
set -e
cd "$(dirname "$0")/.."
python3 tools/fetch_game.py "$@" || {
  echo "Some game files could not be downloaded (see work/fetch-game-report.json)." >&2
  echo "The build continues; the game may miss what they held." >&2
}
npm ci
npm run build:swf
npm run build
echo "Done. Start the site with: npm run serve"
