#!/bin/sh
# Build every rebuilt module and install it under <out-root> at the URL the
# January 2013 manifest gives it. Usually run through build-swf.sh.
#   build/all.sh <out-root> <game-root>
#     e.g. build/all.sh ../../build/rebuilt ../../game
# Env: ROYALE, PLAYERGLOBAL, LIBSWC (see as3c.sh), FFDEC (ffdec.jar)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../src"
OUT="$HERE/../out"
TOOLS="$HERE/../../tools"
DEST="${1:?out root}"
GAME="${2:?game root (for artwork reused by rebuilt modules)}"
W="$DEST/www.9aola.com"
# The archived file for a game path (first version found).
art() { ls "$GAME/www.9aola.com/$1"* 2>/dev/null | head -1; }
mkdir -p "$OUT/swc"
export SHARED="$SRC/shared"
build() { # <module dir> <main> <out name> <installed relpath>
  sh "$HERE/as3c.sh" "$SRC/$1" "$2" "$OUT/$3" | grep -E "Error|error:|written" || true
  [ -f "$OUT/$3" ] || { echo "FAILED $1"; exit 1; }
  if [ -n "$4" ]; then mkdir -p "$(dirname "$W/$4")"; cp "$OUT/$3" "$W/$4"; echo "installed $4"; fi
}
rm -f "$OUT"/*.swf
build login mmo/user/login/Main.as login.swf "user/login.swf%3F1301301"
# play.swf carries the rebuilt scene engine (mmo.play.*, sources in src/control):
# it is in the main domain before any module loads. Everything else links
# against it as an external library.
export GEN="$SRC/control"
build play mmo/playmain/PlayMain.as play.swf "play.swf%3F130110"
unset GEN
java -jar "${FFDEC:?ffdec.jar}" -swf2swc "$OUT/swc/play.swc" "$OUT/play.swf" > /dev/null
export EXTRA_SWC="$OUT/swc/play.swc"
# The control bar: rebuilt control/control. Its 地图 planet is character 81
# of the era newBieHelpSystem/newBieHelpSystemService.swf, taken out with
# JPEXS and made a sprite of its own (swf_transplant.py --wrap-root).
build control mmo/control/DocControl.as control-code.swf ""
rm -rf "$OUT/planet"
java -jar "$FFDEC" -selectid 81 -format sprite:swf -export sprite "$OUT/planet" \
  "$(art newBieHelpSystem/newBieHelpSystemService.swf)" > /dev/null
python3 "$TOOLS/swf_transplant.py" --art "$OUT/planet/DefineSprite_81/1.swf" --wrap-root 81 \
  --code "$OUT/control-code.swf" --bind 0=mmo.control.DocControl --bind 81=mmo.control.BarPlanet \
  --note "REBUILT control/control: rebuilt code (aola-revival); the planet is character 81 of the era newBieHelpSystem/newBieHelpSystemService.swf" \
  --out "$W/control/control.swf%3F130117"

# World map: rebuilt map/map around the 30 Nov 2012 map 百田 published on its
# guide page (in game/ as map/mapguide2012.swf, from tools/fetch_refs.sh).
build map mmo/map/DocMap.as map.swf "map/map.swf%3F130124"

# NPCs: rebuilt task/tasknpc; its data (rebuild/gen/tasknpc) comes from
# tools/gen_npc_data.py, run once against the decompiled later module.
export GEN="$HERE/../gen/tasknpc"
build tasknpc mmo/tasknpc/DocTaskNpc.as tasknpc.swf "task/tasknpc.swf%3F130124"
unset GEN

# Tasks: rebuilt task/taskdefines (the 2012 newbie quest, RECONSTRUCTED),
# task/taskservice and task/taskextmanager, and the newbie quest's scripts
# taskext/task135, task140, task150.
build taskdefines mmo/taskdefines/DocClass.as taskdefines.swf "task/taskdefines.swf%3F130124"
build taskservice mmo/taskservice/DocClass.as taskservice.swf "task/taskservice.swf%3F130103"
build taskextmanager mmo/taskextmanager/DocClass.as taskextmanager.swf "task/taskextmanager.swf%3F1210"
build taskpanelnew mmo/taskpanelnew/DocClass.as taskpanelnew.swf "task/taskpanelnew.swf%3F130103"
build taskext/task135 mmo/task135/DocClass.as task135.swf "taskext/task135.swf%3F130110"
build taskext/task140 mmo/task140/DocClass.as task140.swf "taskext/task140.swf%3F130117"
build taskext/task150 mmo/task150/DocClass.as task150.swf "taskext/task150.swf%3F130110"

# Catalog books: rebuilt catalog/bconfigreaderservice with the era book list
# (rebuild/gen/bconfig from tools/gen_bconfig.py), and the book and buying
# modules catalog/bookclubservice and catalog/catalogservice on top of it.
export GEN="$HERE/../gen/bconfig"
build bconfig mmo/reader/DocBconfig.as bconfig.swf "catalog/bconfigreaderservice.swf%3F1210"
unset GEN
java -jar "$FFDEC" -swf2swc "$OUT/swc/bconfig.swc" "$OUT/bconfig.swf" > /dev/null
export EXTRA_SWC="$OUT/swc/play.swc $OUT/swc/bconfig.swc"
build catalog mmo/bookclub/DocBookClub.as bookclub.swf "catalog/bookclubservice.swf%3F121101"
build catalog mmo/catalog/DocCatalog.as catalog.swf "catalog/catalogservice.swf%3F130117"
export EXTRA_SWC="$OUT/swc/play.swc"

# Player card with the wardrobe: rebuilt usercard/usercardservice.
build usercard mmo/usercard/DocUserCard.as usercard.swf "usercard/usercardservice.swf%3F130117"

# 亚比: rebuilt pet/petdataservice and pet/petdictionarydata (species table in
# rebuild/gen/petdict from tools/gen_pets.py), and the 亚比背包: rebuilt code
# on the original 2012 art of pet/petpackage.swf.
build pet mmo/pet/dataservice/DocPetData.as petdata.swf "pet/petdataservice.swf%3F130124"
export GEN="$HERE/../gen/petdict"
build pet mmo/pet/petdictionarydata/DocPetDict.as petdict.swf "pet/petdictionarydata.swf%3F130124"
unset GEN
# The following 亚比: rebuilt pet/petfollow (PetClient2 54_8 / 54_9, user variable "p").
build petfollow mmo/petfollow/DocPetFollow.as petfollow.swf "pet/petfollow.swf%3F121213"
build petpackage mmo/pet/petpackage/DocPetPackage.as petpackage-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/petpackage.swf)" --code "$OUT/petpackage-code.swf" --drop-art-abc \
  --bind 0=mmo.pet.petpackage.PetPackage --bind 243=mmo.pet.petpackage.PetPackagePanel \
  --bind 106=mmo.pet.petpackage.MessagePanel --bind 54=mmo.pet.petpackage.PPMovie --bind 27=mmo.pet.petpackage.HPMovie \
  --note "REBUILT pet/petpackage: rebuilt code (aola-revival) on the original 亚比背包 art" \
  --out "$W/pet/petpackage.swf%3F1210"

# 亚比 battles: rebuilt pet/wildpetservice (wild 亚比 walking in scenes; their
# points in rebuild/gen/wildpet from tools/gen_wildpets.py) and
# pet/loginpetfightnew (the battle screen, after the official screenshots of
# 2011–12; backgrounds in rebuild/gen/petfight).
export GEN="$HERE/../gen/wildpet"
build wildpet mmo/wildpet/DocWildPet.as wildpet.swf "pet/wildpetservice.swf%3F130124"
export GEN="$HERE/../gen/petfight"
build petfight mmo/petfightnew/DocLoginPetFight.as petfight.swf "pet/loginpetfightnew.swf%3F1210"
unset GEN

# No play-time limit (防沉迷) in a private revival: rebuilt antiaddiction/antiaddiction.
build antiaddiction mmo/antiaddiction/DocClass.as antiaddiction.swf "antiaddiction/antiaddiction.swf%3F130117"

# Beams sent at things (gathering): rebuilt shoot/shooteffectservice.
build shooteffect mmo/shoot/effect/DocClass.as shooteffect.swf "shoot/shooteffectservice.swf%3F130124"

# Scene chat: rebuilt baseservice/scenetalk (the chat box is in the rebuilt control bar).
build scenetalk mmo/scenetalk/DocClass.as scenetalk.swf "baseservice/scenetalk.swf%3F1210"

# Faces (表情): rebuilt baseservice/face on the HELLO faces of the later
# face.swf (its own code left out).
build face mmo/faceservice/DocClass.as face-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art baseservice/face.swf)" \
  --code "$OUT/face-code.swf" --drop-art-abc \
  --note "REBUILT baseservice/face: rebuilt code (aola-revival) on the faces of the later face.swf" \
  --out "$W/baseservice/face.swf%3F1210"

# The HELLO on the bar: rebuilt hellohelper/helloiconservice (its art,
# hellohelper/helloiconres, is used as archived). Clicking it opens the
# 奥拉周刊: rebuilt baseservice/weekly (issues with era pages in
# rebuild/gen/weekly, from tools/gen_bconfig.py).
build helloicon mmo/hellohelper/helloicon/DocClass.as helloicon.swf "hellohelper/helloiconservice.swf%3F130110"
export GEN="$HERE/../gen/weekly"
build weekly mmo/weekly/DocClass.as weekly.swf "baseservice/weekly.swf%3F130117"
unset GEN

# The home (小屋): rebuilt house/housecommon (HouseBase of every home SWF),
# houseloader, houseservice and furnituredecorator; the menu and the storage
# are rebuilt code on the art of the later house/housemenu and housestorage.
build housecommon mmo/housecommon/DocClass.as housecommon.swf "house/housecommon.swf%3F121206"
build house mmo/houseloader/DocClass.as houseloader.swf "house/houseloader.swf%3F1210"
build house mmo/houseservice/DocClass.as houseservice.swf "house/houseservice.swf%3F1210"
build house mmo/housedecorator/DocClass.as furnituredecorator.swf "house/furnituredecorator.swf%3F1210"
build house mmo/housemenu/DocClass.as housemenu-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art house/housemenu.swf)" \
  --code "$OUT/housemenu-code.swf" --drop-art-abc \
  --bind 0=mmo.housemenu.DocClass --bind 199=mmo.housemenu.DocClass --bind 198=mmo.housemenu.HouseMenu \
  --bind 159=mmo.housemenu.BtnCatalog --bind 151=mmo.housemenu.StopClip --bind 145=mmo.housemenu.StopClip \
  --bind 124=mmo.housemenu.StopClip --bind 99=mmo.housemenu.StopClip --bind 16=mmo.housemenu.StopClip \
  --note "REBUILT house/housemenu: rebuilt code (aola-revival) on the art of the later housemenu.swf" \
  --out "$W/house/housemenu.swf%3F121203"
build house mmo/housestorage/DocClass.as housestorage-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art house/housestorage.swf)" \
  --code "$OUT/housestorage-code.swf" --drop-art-abc \
  --bind 0=mmo.housestorage.DocClass --bind 71=mmo.housestorage.DocClass --bind 70=mmo.housestorage.HouseStorage \
  --bind 53=mmo.housestorage.TableBar --bind 4=mmo.housestorage.ItemView \
  --bind 52=mmo.housestorage.TableButton --bind 45=mmo.housestorage.TableButton --bind 38=mmo.housestorage.TableButton \
  --bind 31=mmo.housestorage.TableButton --bind 22=mmo.housestorage.TableButton --bind 15=mmo.housestorage.TableButton \
  --note "REBUILT house/housestorage: rebuilt code (aola-revival) on the art of the later housestorage.swf" \
  --out "$W/house/housestorage.swf%3F121206"

# 奥拉广场: rebuilt code on the July 2012 artwork (bigscene/starlandcopy).
build scenes/starland mmo/scene/starland/Docstarland.as starland-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art bigscene/starlandcopy.swf)" \
  --code "$OUT/starland-code.swf" --bind 0=mmo.scene.starland.Docstarland --bind 225=mmo.scene.starland.Starland \
  --note "REBUILT scene/starland: rebuilt code (aola-revival) on the July 2012 art of bigscene/starlandcopy.swf" \
  --out "$W/scene/starland.swf%3F130124"
