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
# The start screen without the January 2013 campaign (no earlier picture survives):
# tools/clean_start.py takes the title and captions out of user/yunyingres and the
# links to 百田's other games out of sight in user/yunyingstart.
mkdir -p "$W/user"
python3 "$TOOLS/clean_start.py" --ffdec "${FFDEC:?ffdec.jar}" --res "$(art user/yunyingres.swf)" --start "$(art user/yunyingstart.swf)" \
  --out-res "$W/user/yunyingres.swf%3F130124" --out-start "$W/user/yunyingstart.swf%3F121203"
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
# The story quests' tables come from rebuild/gen/taskdata (tools/gen_tasks.py).
export GEN="$HERE/../gen/taskdata"
build taskdefines mmo/taskdefines/DocClass.as taskdefines.swf "task/taskdefines.swf%3F130124"
unset GEN
build taskservice mmo/taskservice/DocClass.as taskservice.swf "task/taskservice.swf%3F130103"
build taskextmanager mmo/taskextmanager/DocClass.as taskextmanager.swf "task/taskextmanager.swf%3F1210"
build taskpanelnew mmo/taskpanelnew/DocClass.as taskpanelnew.swf "task/taskpanelnew.swf%3F130103"
build tasktransport mmo/tasktransport/DocClass.as tasktransport.swf "task/tasktransportpanel.swf%3F1210"
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

# 亚比仓库: rebuilt pet/petwarehouse (drawn panel; the 2013 module is lost).
build petwarehouse mmo/petwarehouse/DocPetWareHouse.as petwarehouse.swf "pet/petwarehouse.swf%3F121227"

# 亚比: rebuilt pet/petdataservice and pet/petdictionarydata (species table in
# rebuild/gen/petdict from tools/gen_pets.py), and the 亚比背包: rebuilt code
# on the original 2012 art of pet/petpackage.swf.
build pet mmo/pet/dataservice/DocPetData.as petdata.swf "pet/petdataservice.swf%3F130124"
export GEN="$HERE/../gen/petdict"
build pet mmo/pet/petdictionarydata/DocPetDict.as petdict.swf "pet/petdictionarydata.swf%3F130124"
unset GEN
# The notice strip: an empty Sprite (later homes hide and show it as a DisplayObject).
build notifyview mmo/notifyview/DocNotifyView.as notifyview.swf "baseservice/notifyview.swf%3F130124"
# The 兜兜回收器 of 道具店, 服装店, 家具店: rebuilt buyback/stuffbuyback (service StuffBuyBack).
build buyback mmo/buyback/stuff/DocStuffBuyBack.as stuffbuyback.swf "buyback/stuffbuyback.swf%3F1210"
# The 守护者 (the areas' bosses of BossTimeHelper): rebuilt dailyactivity/dailyactivityservice.
build dailyactivity mmo/dailyactivity/DocDailyActivity.as dailyactivity.swf "dailyactivity/dailyactivityservice.swf%3F130117"
# What panels ask about a 亚比 or skill (names, evolution, egg pictures): rebuilt
# pet/petskillmesservice on the revival's tables (rebuild/gen/petmes, tools/gen_petmes.py).
export GEN="$HERE/../gen/petmes"
build petskillmes mmo/pet/petskillmessage/DocPetSkillMes.as petmes.swf "pet/petskillmesservice.swf%3F130124"
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

# The HELLO in scenes: rebuilt init/robotmanager.
build robotmanager mmo/robot/robotmanager/DocClass.as robotmanager.swf "init/robotmanager.swf%3F130103"

# Scene music: rebuilt init/sceneinit (the later copy calls later services).
build sceneinit mmo/sceneinit/DocClass.as sceneinit.swf "init/sceneinit.swf%3F121220"

# No play-time limit (防沉迷) in a private revival: rebuilt antiaddiction/antiaddiction.
build antiaddiction mmo/antiaddiction/DocClass.as antiaddiction.swf "antiaddiction/antiaddiction.swf%3F130117"

# Shooting (射击) and the beams sent at things (gathering): the 2013
# shoot/shoot and shoot/shooteffectservice are lost; the later ones (the live
# client's, decompiled) are compiled against the 2013 interfaces, the few
# later-only calls replaced (marked in the sources), and put back on the
# later modules' own art (their symbols keep their class names).
build shoot mmo/shoot/DocClass.as shoot-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art shoot/shoot.swf)" --code "$OUT/shoot-code.swf" --drop-art-abc \
  --note "LATER shoot/shoot: the live client's code compiled against the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/shoot/shoot.swf%3F130124"
build shooteffect mmo/shoot/effect/DocClass.as shooteffect-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art shoot/shooteffectservice.swf)" --code "$OUT/shooteffect-code.swf" --drop-art-abc \
  --note "LATER shoot/shooteffectservice: the live client's code compiled against the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/shoot/shooteffectservice.swf%3F130124"

# Mini games: rebuilt game/gamemanager (the later one on the 2013 interfaces;
# the games themselves are the era/later game/*.swf, run by SceneManager.loadGame).
build gamemanager mmo/game/DocGameManager.as gamemanager.swf "game/gamemanager.swf%3F121220"

# 商城: rebuilt rmbshoppingmallservice (the era 收费 catalog books in a drawn chooser).
build rmbmall mmo/rmbshoppingmallservice/DocRmbMall.as rmbmall.swf "rmbshoppingmallservice/rmbshoppingmallservice.swf%3F130124"

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
# The 家园 (house 247, where 回家 leads first; its 我的家 is the 小屋): rebuilt
# furniture/b000247 (the January 2013 one is lost; the captured file is a later
# rework). Its picture is the January 2012 tutorial house/houseteachmovie/
# houseteachgarden, its trees the June 2012 plant/y<id>, both loaded at run time.
java -jar "$FFDEC" -swf2swc "$OUT/swc/housecommon.swc" "$OUT/housecommon.swf" > /dev/null
export EXTRA_SWC="$OUT/swc/play.swc $OUT/swc/housecommon.swc"
build garden mmo/house/b000247/b000247_Doc.as garden.swf "furniture/b000247.swf%3F130117"
# The 动物园 (house 20000, through the garden's tube): rebuilt furniture/b020000
# (the January 2013 one is lost) on the art of the later copy (January 2021).
build zoo mmo/house/b020000/DocZooRevived.as zoo-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art furniture/b020000.swf)" \
  --code "$OUT/zoo-code.swf" --bind 0=mmo.house.b020000.DocZooRevived --bind 110=mmo.house.b020000.ZooRevived \
  --note "REBUILT furniture/b020000: rebuilt code (aola-revival) on the art of the later b020000.swf" \
  --out "$W/furniture/b020000.swf%3F1210"
export EXTRA_SWC="$OUT/swc/play.swc"

# 奥拉广场: rebuilt code on the July 2012 artwork (bigscene/starlandcopy).
build scenes/starland mmo/scene/starland/Docstarland.as starland-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art bigscene/starlandcopy.swf)" \
  --code "$OUT/starland-code.swf" --bind 0=mmo.scene.starland.Docstarland --bind 225=mmo.scene.starland.Starland \
  --note "REBUILT scene/starland: rebuilt code (aola-revival) on the July 2012 art of bigscene/starlandcopy.swf" \
  --out "$W/scene/starland.swf%3F130124"
# 流星购物街 (starshopping): the January 2013 scene is lost (the live one is of
# 2026); the config gives the July 2012 art (starlandcopy) that name.
cp "$W/scene/starland.swf%3F130124" "$W/scene/starshopping.swf%3F130124"

# 道具店: the later scene's own code (2016 copy, decompiled), compiled against
# the 2013 interfaces without its one later-only call, on that copy's art.
build scenes/toolshop mmo/scene/toolshop/DocToolshop.as toolshop-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/toolshop.swf)" \
  --code "$OUT/toolshop-code.swf" --bind 0=mmo.scene.toolshop.DocToolshop --bind 203=mmo.scene.toolshop.Toolshop \
  --note "LATER scene/toolshop: its code compiled against the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/scene/toolshop.swf%3F121203"

# 生态园: the 2020 scene's code on the 2013 interfaces, its game spots opening
# (its classes are renamed: the art keeps the 2020 classes of the same names,
# and the player uses the first definition of a name)
# the 生态园 games of the January 2013 config (gamePvZ, gameCatchAnimal, gameSeaDefend).
build scenes/ecologicalpark mmo/scene/starland/DocEcologicalParkRevived.as ecologicalpark-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/ecologicalpark.swf)" \
  --code "$OUT/ecologicalpark-code.swf" --bind 0=mmo.scene.starland.DocEcologicalParkRevived --bind 176=mmo.scene.starland.EcologicalParkRevived \
  --note "LATER scene/ecologicalpark: its code rewritten for the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/scene/ecologicalpark.swf%3F121220"

# 十字大道: the 2020 scene's code on the 2013 engine (its 升降机 rides), with
# the 2013 doors (爱心协会 down the lift; not the later 卡牌达人馆), on its own art.
build scenes/crossroad mmo/scene/starland/DocCrossroadRevived.as crossroad-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/crossroad.swf)" \
  --code "$OUT/crossroad-code.swf" --bind 0=mmo.scene.starland.DocCrossroadRevived --bind 197=mmo.scene.starland.CrossroadRevived \
  --note "LATER scene/crossroad: its code on the 2013 engine with the 2013 doors (aola-revival), on its own art" \
  --out "$W/scene/crossroad.swf%3F130124"

# 图书馆: the 2019 copy's art, its buttons answered on the 2013 engine, with
# the shelf of 奥拉周刊 back issues (rebuild/gen/weekly from tools/gen_bconfig.py).
export GEN="$HERE/../gen/weekly"
build scenes/library mmo/scene/library/DocLibraryRevived.as library-code.swf ""
unset GEN
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/library.swf)" \
  --code "$OUT/library-code.swf" --bind 0=mmo.scene.library.DocLibraryRevived --bind 87=mmo.scene.library.LibraryRevived \
  --note "LATER scene/library: its art with the 2013 engine's answers and the 往期周刊 shelf (aola-revival)" \
  --out "$W/scene/library.swf%3F1210"

# 崩坏的上古神殿: the 2019 scene's code on the 2013 engine, its 黑洞 film played
# once (the later code's looping clip started it again in every scene after).
build scenes/temple1 mmo/scene/temple/DocTemple1Revived.as temple1-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/temple1.swf)" \
  --code "$OUT/temple1-code.swf" --bind 0=mmo.scene.temple.DocTemple1Revived --bind 116=mmo.scene.temple.Temple1Revived \
  --note "LATER scene/temple1: its code on the 2013 engine, the film played once (aola-revival), on its own art" \
  --out "$W/scene/temple1.swf%3F1210"

# 欢乐岛: the 2020 scene cut down to the 2013 engine (its own code needs later
# services and could not be built), on its own art.
# 火山口 (where 烈焰鸟 sleeps): the later scene/feier4's code cut down, on its own art.
build scenes/feier4 mmo/scene/feier/DocFeier4Revived.as feier4-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/feier4.swf)" \
  --code "$OUT/feier4-code.swf" --bind 0=mmo.scene.feier.DocFeier4Revived --bind 67=mmo.scene.feier.Feier4Revived \
  --note "LATER scene/feier4: its code cut down for the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/scene/feier4.swf%3F1210"
build scenes/summerhotspring mmo/scene/hotspringscene/DocSummerHotSpringRevived.as summerhotspring-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/summerhotspring.swf)" \
  --code "$OUT/summerhotspring-code.swf" --bind 0=mmo.scene.hotspringscene.DocSummerHotSpringRevived --bind 45=mmo.scene.hotspringscene.SummerHotSpringRevived \
  --note "LATER scene/summerhotspring: its code cut down for the 2013 interfaces (aola-revival), on its own art" \
  --out "$W/scene/summerhotspring.swf%3F130124"

# The eggs being hatched (pet/peteggservice, lost): panels read them through it.
build peteggservice mmo/pet/peteggservice/DocPetEggService.as peteggservice.swf "pet/peteggservice.swf%3F1210"

# 时空隧道 (spacetime/spacetimeservice, lost): the later service's code on the 2013 interfaces.
build spacetime mmo/spacetime/DocClass.as spacetime.swf "spacetime/spacetimeservice.swf%3F121213"

# 财富小管家 (fortunemanager/fortunemanager, lost): the 晶币 bank of 奥拉广场, rebuilt.
build fortunemanager mmo/fortunemanager/DocFortuneManager.as fortunemanager.swf "fortunemanager/fortunemanager.swf%3F130117"

# The scene arrows (baseservice/scenearrow, lost): the stand-in with the later
# interface's removeArrowsByGroup, which 星光游乐场's game buttons call first.
build scenearrow mmo/scenearrow/DocSceneArrow.as scenearrow.swf "baseservice/scenearrow.swf%3F130124"

# Later copies of mini games that call SocketClient.startGame, which the 2013
# library lacks (the call threw and no board was drawn): the call renamed to
# hasEventListener, harmless (tools/abc_rename.py). Only games without a
# startGame of their own; 星光游乐场's 亚比连连看, 鲁比跳跳 and 黄金矿工 among them.
mkdir -p "$W/game"
for g in carsurf flycat flygame flystone gamellk goldpitman lubigame makecake matchthree mycat penguin recyclegame shootgame slamdunk; do
  f="$(art game/$g.swf)"
  python3 "$TOOLS/abc_rename.py" --rename startGame=hasEventListener \
    --note "LATER game/$g: SocketClient.startGame (later only) renamed hasEventListener (aola-revival, tools/abc_rename.py)" \
    "$f" "$W/game/$(basename "$f")"
done

# The 家园's 亚比批量孵化器 (era pet/pethatchegg): its decompiled code with the
# eggs' names under them and their pictures while they hatch, on its own art.
build pethatchegg mmo/pet/pethatchegg/PetHatchEgg.as pethatchegg-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/pethatchegg.swf)" --code "$OUT/pethatchegg-code.swf" --drop-art-abc \
  --note "ERA pet/pethatchegg: its decompiled code with the eggs' names and pictures (aola-revival), on its own art" \
  --out "$W/pet/pethatchegg.swf%3F1210"

# The small pictures (_S) the peticon files of the 亚比 one could not get in
# 2012 and 2013 lack (missing or an empty sprite): each file's own large picture,
# scaled; the missing classes from a compiled template (tools/peticon_fill.py).
build peticonfill mmo/pet/peticon777777_S.as peticonfill-template.swf ""
python3 "$TOOLS/peticon_fill.py" --game "$GAME" --template "$OUT/peticonfill-template.swf" --out "$W"

# 奇草树林 (云端王国's first room): the later scene's code on the 2013
# interfaces and that copy's art, with the room's map button back (it opens
# the era 云端王国 map, scene/cloudstarmap).
build scenes/cloudstar1 mmo/scene/cloudstar1/DocCloudStar1.as cloudstar1-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/cloudstar1.swf)" \
  --code "$OUT/cloudstar1-code.swf" --bind 0=mmo.scene.cloudstar1.DocCloudStar1 --bind 24=mmo.scene.cloudstar1.CloudStar1 \
  --note "LATER scene/cloudstar1: its code compiled against the 2013 interfaces (aola-revival), its map button redrawn, on its own art" \
  --out "$W/scene/cloudstar1.swf%3F1210"
