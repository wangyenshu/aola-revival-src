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
# Era files fixed where they cannot work as they are (tools/patch_scripts.py): a panel that
# removes itself from FloatPanelManager went round without end (library/common), the
# 2010 亚比特训's cards had nowhere for the 亚比's icon (pet/pettraining), and 动物捕捉's
# 天空乐园 clouds drew black (game/catchanimal).
python3 "$TOOLS/patch_scripts.py" --ffdec "${FFDEC:?ffdec.jar}" --game "$GAME" --out-root "$DEST"
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
# catalogservice's 购买 dialogs are those of its copy under the 2013 URL (ConfirmBuy, ConfirmBuyClothes;
# its later code left out, BuyFlow showing them).
build catalog mmo/catalog/DocCatalog.as catalog-code.swf ""
CD=mmo.catalog.dialogs
python3 "$TOOLS/swf_transplant.py" --art "$(art catalog/catalogservice.swf)" --code "$OUT/catalog-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.catalog.DocCatalog --bind 163=$CD.ConfirmBuy --bind 161=$CD.ConfirmBuyClothes \
  --bind 156=$CD.InfoPanel \
  --note "REBUILT catalog/catalogservice (aola-revival) on the art of its copy under the 2013 URL" \
  --out "$W/catalog/catalogservice.swf%3F130117"
export EXTRA_SWC="$OUT/swc/play.swc"

# Player card with the wardrobe: rebuilt usercard/usercardservice.
build usercard mmo/usercard/DocUserCard.as usercard.swf "usercard/usercardservice.swf%3F130117"
# A player's avatar in a holder (UserAvatarService): rebuilt useravatar/useravatarservice.
build useravatar mmo/useravatar/DocUserAvatar.as useravatar.swf "useravatar/useravatarservice.swf%3F1210"

# 亚比仓库: rebuilt pet/petwarehouse (the 2012 and 2013 modules are lost: its 2012 look is the
# January 2012 tutorial house/houseteachmovie/houseteachpetstore's picture, taken at run time).
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
# 猎空's panel (守护者之战 猎空, August 2013): its decompiled code on the 2013 libraries, on its art.
build shikarsky mmo/revival/shikarsky/DocShikarSky.as shikarsky-code.swf ""
mkdir -p "$W/dailyactivity/bosspanel"
python3 "$TOOLS/swf_transplant.py" --art "$(art dailyactivity/bosspanel/shikarskybosspanel.swf)" --code "$OUT/shikarsky-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.shikarsky.DocShikarSky --bind 127=mmo.bosspanel.shikarsky.ShikarSkyBossPanel --bind 68=mmo.bosspanel.shikarsky.BossInfoPanel \
  --note "LATER dailyactivity/bosspanel/shikarskybosspanel on the 2013 libraries (aola-revival): the 背包, 治疗 and 远程仓库 on the 2013 services" \
  --out "$W/dailyactivity/bosspanel/shikarskybosspanel.swf%3F1210"
# What panels ask about a 亚比 or skill (names, evolution, egg pictures): rebuilt
# pet/petskillmesservice on the revival's tables (rebuild/gen/petmes, tools/gen_petmes.py).
export GEN="$HERE/../gen/petmes"
build petskillmes mmo/pet/petskillmessage/DocPetSkillMes.as petmes.swf "pet/petskillmesservice.swf%3F130124"
unset GEN
# The 亚比 tables of the 2013 PMCustomData (names, stats, skills, attributes, experience):
# rebuilt pet/pmservice (rebuild/gen/pmservice, tools/gen_pmservice.py).
export GEN="$HERE/../gen/pmservice"
build pmservice mmo/pm/service/DocPMService.as pmservice.swf "pet/pmservice.swf%3F130124"
unset GEN
# The following 亚比: rebuilt pet/petfollow (PetClient2 54_8 / 54_9, user variable "p").
# (the later 亚比's scene clothes in rebuild/gen/petfollow from tools/gen_petclothes.py)
export GEN="$HERE/../gen/petfollow"
build petfollow mmo/petfollow/DocPetFollow.as petfollow.swf "pet/petfollow.swf%3F121213"
unset GEN
build petpackage mmo/pet/petpackage/DocPetPackage.as petpackage-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/petpackage.swf)" --code "$OUT/petpackage-code.swf" --drop-art-abc \
  --bind 0=mmo.pet.petpackage.PetPackage --bind 243=mmo.pet.petpackage.PetPackagePanel \
  --bind 106=mmo.pet.petpackage.MessagePanel --bind 54=mmo.pet.petpackage.PPMovie --bind 27=mmo.pet.petpackage.HPMovie \
  --note "REBUILT pet/petpackage: rebuilt code (aola-revival) on the original 亚比背包 art" \
  --out "$W/pet/petpackage.swf%3F1210"
# The bag's 道具 page: rebuilt pet/petitem (service PetItem; 14_12, server petitems.ts) on the
# art of its later copy (the page, symbol 668, its squares, 706, and 我要使用, 517).
build petitem mmo/pet/petitem/DocPetItem.as petitem-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/petitem.swf)" --code "$OUT/petitem-code.swf" --drop-art-abc \
  --bind 0=mmo.pet.petitem.DocPetItem --bind 668=mmo.pet.petitem.PetItemPanel --bind 706=mmo.pet.petitem.ItemView \
  --bind 517=mmo.pet.petitem.QuantitySelectePanel \
  --note "REBUILT pet/petitem (aola-revival) on the art of its later copy" \
  --out "$W/pet/petitem.swf%3F130124"
# The views of the tips (TipsManager): rebuilt library_res/common_res_tips on the art of its later
# copy, whose own code calls what the 2013 libraries lack (every big tip failed with it).
build tipsres mmo/revival/tipsres/DocTipsRes.as tipsres-code.swf ""
TP=mmo.common.utils.tips
python3 "$TOOLS/swf_transplant.py" --art "$(art library_res/common_res_tips.swf)" --code "$OUT/tipsres-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.tipsres.DocTipsRes --bind 12=$TP.TipsView --bind 8=$TP.TipsViewBig --bind 30=$TP.HtmlTipsViewBig --bind 27=$TP.SkillTipsViewBig \
  --note "REBUILT library_res/common_res_tips (aola-revival) on the art of its later copy" \
  --out "$W/library_res/common_res_tips.swf%3F121115"
# The 超进化机 of the 亚比研究中心 (config of 7 February 2013: pet/superevolution v130131, lost): rebuilt
# on the art of its 2015 copy, the 2013 超进化 only (贝鲁特 opens it; server superevo.ts).
build superevolution mmo/superevolution/DocSuperEvolution.as superevolution-code.swf ""
SE=mmo.superevolution
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/superevolution.swf)" --code "$OUT/superevolution-code.swf" --drop-art-abc --only-binds \
  --bind 0=$SE.DocSuperEvolution --bind 858=$SE.SuperEvolutionPanel --bind 1679=$SE.EvoPanel --bind 1776=$SE.ChoosePetPanel \
  --bind 1763=$SE.PetContainer --bind 1644=$SE.ItemView --bind 1754=$SE.EvolutionMovie --bind 1643=$SE.StopClip \
  --note "REBUILT pet/superevolution (aola-revival) on the art of its 2015 copy" \
  --out "$W/pet/superevolution.swf%3F1210"
# The 植树盆's tree panel: rebuilt yz/treemanager (on the art of its 2016 build) and the
# panels it opens, yz/panel_res (盆栽道具, 守护亚比; on their April 2012 art).
build treemanager mmo/treemanager/DocTreeManager.as treemanager-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art yz/treemanager.swf)" --code "$OUT/treemanager-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.treemanager.DocTreeManager --bind 290=mmo.treemanager.treepanel.TreePanel --bind 15=mmo.treemanager.treepanel.VisitorPanel \
  --bind 236=mmo.treemanager.treepanel.Pickfruit --bind 206=mmo.treemanager.treepanel.UseTool --bind 221=mmo.treemanager.treepanel.UseTool7 \
  --bind 119=mmo.treemanager.treepanel.LevelUp --bind 156=mmo.treemanager.treepanel.LevelUpDown --bind 50=mmo.treemanager.treepanel.Nutrtion \
  --bind 33=mmo.treemanager.treepanel.AddHealthMovie \
  --note "REBUILT yz/treemanager (aola-revival) on the art of its later copy" \
  --out "$W/yz/treemanager.swf%3F1210"
build treepanelres mmo/treemanager/DocTreePanelRes.as treepanelres-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art yz/panel_res.swf)" --code "$OUT/treepanelres-code.swf" --drop-art-abc \
  --bind 0=mmo.treemanager.DocTreePanelRes --bind 91=mmo.treemanager.treepanel.SelectPlantToolPanel --bind 57=mmo.treemanager.treepanel.GuardYabiPanel \
  --bind 94=mmo.treemanager.treepanel.PlantItemView --bind 22=mmo.treemanager.treepanel.PetBriefCard \
  --note "REBUILT yz/panel_res (aola-revival) on its April 2012 art" \
  --out "$W/yz/panel_res.swf%3F1210"
# The 盆栽道具's pictures, plantitem/view1 … view7 (the era files are lost): six
# pictures of the 种植手册's 种植道具 page (catalog/zhongzhi2) and the shovel of the
# tree manager's 铲除 film, each made a SWF of its own bound to mmo.plantitem.view<id>.
build plantitemview mmo/plantitem/DocPlantItemViews.as plantitemview-code.swf ""
rm -rf "$OUT/plantitem"
java -jar "$FFDEC" -selectid 54,56,69,79,81,84 -format sprite:swf -export sprite "$OUT/plantitem" "$(art catalog/zhongzhi2.swf)" > /dev/null
java -jar "$FFDEC" -selectid 208 -format sprite:swf -export sprite "$OUT/plantitem" "$(art yz/treemanager.swf)" > /dev/null
n=1
for s in 54 56 69 79 81 84 208; do
  python3 "$TOOLS/swf_transplant.py" --art "$OUT/plantitem/DefineSprite_$s/1.swf" --wrap-root $s --code "$OUT/plantitemview-code.swf" \
    --drop-art-abc --only-binds --bind $s=mmo.plantitem.view$n \
    --note "REBUILT plantitem/view$n (aola-revival): character $s of the era catalog/zhongzhi2 or the later yz/treemanager" \
    --out "$W/plantitem/view$n.swf%3F1210"
  n=$((n + 1))
done
# 动物捕捉's panel: rebuilt game/catchanimalpanel (what one has, 进入 and its map of the four
# 乐园, 操作说明, the tips; the lost 动物乐园购买册 drawn as CatchShop) on its later copy's art.
build catchanimalpanel mmo/game/catchanimalpanel/DocCatchAnimalPanel.as catchanimalpanel-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art game/catchanimalpanel.swf)" --code "$OUT/catchanimalpanel-code.swf" --drop-art-abc \
  --bind 0=mmo.game.catchanimalpanel.DocCatchAnimalPanel --bind 137=mmo.game.catchanimalpanel.StartPanel \
  --bind 410=mmo.game.catchanimalpanel.CatchMap --bind 89=mmo.game.catchanimalpanel.HelpPanel --bind 26=mmo.game.catchanimalpanel.TipsPanel \
  --note "REBUILT game/catchanimalpanel (aola-revival) on the art of its later copy" \
  --out "$W/game/catchanimalpanel.swf%3F1210"

# 亚比 battles: rebuilt pet/wildpetservice (wild 亚比 walking in scenes; their
# points in rebuild/gen/wildpet from tools/gen_wildpets.py) and
# pet/loginpetfightnew (the battle screen, after the official screenshots of
# 2011–12; backgrounds in rebuild/gen/petfight).
export GEN="$HERE/../gen/wildpet"
build wildpet mmo/wildpet/DocWildPet.as wildpet.swf ""
# On the 2013 file's art: its FightIcon (the cursor 时空隧道 asks it for).
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/wildpetservice.swf)" --code "$OUT/wildpet.swf" --drop-art-abc \
  --bind 0=mmo.wildpet.DocWildPet --bind 4=mmo.wildpet.WildPetArtStub \
  --note "REBUILT pet/wildpetservice (aola-revival) with the 2013 file's FightIcon" \
  --out "$W/pet/wildpetservice.swf%3F130124"
export GEN="$HERE/../gen/petfight"
build petfight mmo/petfightnew/DocLoginPetFight.as petfight.swf ""
unset GEN
# The 属性等级 shown over a 亚比 (AttributeLevelPanel): the art of that panel in the later
# battle module (character 2837 of pet/petfightnew, the 2026 copy), taken out alone.
# And the button over the skills for 究极 and 超奥义 (BigSkillButton): character 898 of the same
# file (BigSkillMC, its mcView's frames 聚能中 / 究极变身 / 剩余回合 / 超奥义 / BOSS克星).
rm -rf "$OUT/attrlevel" "$OUT/bigskill"
java -jar "$FFDEC" -selectid 2837 -format sprite:swf -export sprite "$OUT/attrlevel" "$(art pet/petfightnew.swf)" > /dev/null
java -jar "$FFDEC" -selectid 898 -format sprite:swf -export sprite "$OUT/bigskill" "$(art pet/petfightnew.swf)" > /dev/null
python3 "$TOOLS/swf_transplant.py" --art "$(ls "$OUT"/attrlevel/DefineSprite_2837*/1.swf)" --wrap-root 2837 \
  --add-art "$(ls "$OUT"/bigskill/DefineSprite_898*/1.swf)=898" --image-shapes --drop-art-abc \
  --code "$OUT/petfight.swf" --bind 0=mmo.petfightnew.DocLoginPetFight --bind 2837=mmo.petfightnew.AttributeLevelPanel \
  --bind 898=mmo.petfightnew.BigSkillButton \
  --note "REBUILT pet/loginpetfightnew (aola-revival); its 属性等级 panel and big-skill button are characters 2837 and 898 of the later pet/petfightnew" \
  --out "$W/pet/loginpetfightnew.swf%3F1210"

# The HELLO in scenes: rebuilt init/robotmanager (its menu, the wheel of December 2012, drawn,
# with the skills' icons of 2012 from robot/revival/helloskillicons: HelloWheel).
build robotmanager mmo/robot/robotmanager/DocClass.as robotmanager.swf "init/robotmanager.swf%3F130103"
# The HELLO's own panels: rebuilt robot/robotmes (基本资料) and robot/robotitem (HELLO物品)
# on the art of their copies of 2015 and 2016.
mkdir -p "$W/robot"
build robotmes mmo/robot/robotmes/DocRobotMes.as robotmes-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art robot/robotmes.swf)" --code "$OUT/robotmes-code.swf" --drop-art-abc \
  --bind 0=mmo.robot.robotmes.DocRobotMes --bind 132=mmo.robot.robotmes.RobotMesPanel --bind 76=mmo.robot.Robotskillicon \
  --note "REBUILT robot/robotmes (aola-revival) on the art of its 2015 copy" \
  --out "$W/robot/robotmes.swf%3F1210"
build robotitem mmo/robot/robotitem/DocRobotItem.as robotitem-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art robot/robotitem.swf)" --code "$OUT/robotitem-code.swf" --drop-art-abc \
  --bind 0=mmo.robot.robotitem.DocRobotItem --bind 36=mmo.robot.robotitem.RobotItemPanel \
  --bind 6=mmo.robot.robotitem.robotmaterial.RobotItemView --bind 3=mmo.robot.robotitem.robotmaterial.FeedMaterial \
  --note "REBUILT robot/robotitem (aola-revival) on the art of its 2016 copy" \
  --out "$W/robot/robotitem.swf%3F1210"

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
# The 收费亚比蛋商品册's first page (catalog/egg1; the January 2013 page is lost): the 2013 eggs
# that have a price, on the art of its 2016 copy.
build catalogpages mmo/itemcatalog/DocEggPage.as eggpage-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art catalog/egg1.swf)" --code "$OUT/eggpage-code.swf" --drop-art-abc \
  --bind 165=mmo.itemcatalog.Egg1_1 --bind 25=mmo.itemcatalog.PetEggPanel --bind 6=mmo.itemcatalog.BuyBtn --bind 107=mmo.itemcatalog.EggPageBar \
  --note "REBUILT catalog/egg1 (aola-revival) on the art of its 2016 copy" \
  --out "$W/catalog/egg1.swf%3F130117"

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
# Pages 7 and 10 of the January 2013 周刊 (weekly/weekly128) are asked for at ?1301251, the other
# pages at the loader's ?1210 under which game/ keeps them all: those two at that name too.
mkdir -p "$W/weekly/weekly128"
for p in 7 10; do cat "$(art weekly/weekly128/aolaweekly128_$p.swf)" > "$W/weekly/weekly128/aolaweekly128_$p.swf%3F1301251"; done

# The home (小屋): rebuilt house/housecommon (HouseBase of every home SWF),
# houseloader, houseservice, furnituredecorator and yz/plantdecorator; the menu and the storage
# are rebuilt code on the art of the later house/housemenu and housestorage.
build housecommon mmo/housecommon/DocClass.as housecommon.swf "house/housecommon.swf%3F121206"
build house mmo/houseloader/DocClass.as houseloader.swf "house/houseloader.swf%3F1210"
build house mmo/houseservice/DocClass.as houseservice.swf "house/houseservice.swf%3F1210"
build house mmo/housedecorator/DocClass.as furnituredecorator.swf "house/furnituredecorator.swf%3F1210"
# The trees made furniture (收为家具) in the 小屋: rebuilt yz/plantdecorator, their pictures the June 2012 plant/y<id>.
build house mmo/plantdecorator/DocClass.as plantdecorator.swf "yz/plantdecorator.swf%3F1210"
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
# The 家园's 友谊留言板 (MessageBoardService): the later house/messageboard's code, decompiled and
# compiled against the 2013 interfaces, on its art (the 2013 module is lost).
build messageboard mmo/messageboard/DocMessageBoard.as messageboard-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art house/messageboard.swf)" --code "$OUT/messageboard-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.messageboard.DocMessageBoard --bind 67=mmo.messageboard.panel.MessageBoardPanel \
  --bind 214=mmo.messageboard.panel.LeaveWordPanel --bind 240=mmo.messageboard.panel.QuickTalkPanel \
  --bind 282=mmo.messageboard.panel.Scratchpad1 --bind 278=mmo.messageboard.panel.Scratchpad2 --bind 274=mmo.messageboard.panel.Scratchpad3 \
  --bind 264=mmo.messageboard.panel.Scratchpad4 --bind 260=mmo.messageboard.panel.Scratchpad5 --bind 255=mmo.messageboard.panel.Scratchpad6 \
  --bind 51=messageboard_fla.bianjizhuanbtai_92 --bind 73=messageboard_fla.sjswwas_69 --bind 54=messageboard_fla.skdjsss_91 \
  --note "LATER house/messageboard: its code compiled against the 2013 interfaces (aola-revival), on its art" \
  --out "$W/house/messageboard.swf%3F1210"
# The 家园 (house 247, where 回家 leads first; its 我的家 is the 小屋): rebuilt
# furniture/b000247 (the January 2013 one is lost; the captured file is a later
# rework). Its picture is the January 2012 tutorial house/houseteachmovie/
# houseteachgarden, its trees the June 2012 plant/y<id>, both loaded at run time.
java -jar "$FFDEC" -swf2swc "$OUT/swc/housecommon.swc" "$OUT/housecommon.swf" > /dev/null
export EXTRA_SWC="$OUT/swc/play.swc $OUT/swc/housecommon.swc"
build garden mmo/house/b000247/b000247_Doc.as garden.swf "furniture/b000247.swf%3F130117"
# The zoo's 2012 panels (the era code is a later one the 2013 files cannot run): rebuilt code
# on their art, each a module of its own: the 动物仓库 (zoo/zoores_1), 动物园信息 (zoo/zoores),
# the 饲料机 (zoo/zoores_5) and an animal's panel (zoo/petbreedingservice).
build zoopanels mmo/zoo/revival/DocZooStore.as zoostore-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art zoo/zoores_1.swf)" --code "$OUT/zoostore-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.zoo.revival.DocZooStore --bind 179=mmo.zoo.revival.ZooStorePanel --bind 43=mmo.zoo.revival.BabyCard \
  --bind 137=mmo.zoo.revival.MatureCard --bind 128=mmo.zoo.revival.ItemCard --bind 121=mmo.zoo.revival.SellPanel --bind 89=mmo.zoo.revival.EmptyTip \
  --note "REBUILT zoo 动物仓库 (aola-revival) on the art of zoo/zoores_1" --out "$W/zoo/revival/zoostore.swf%3F1210"
build zoopanels mmo/zoo/revival/DocZooInfo.as zooinfo-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art zoo/zoores.swf)" --code "$OUT/zooinfo-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.zoo.revival.DocZooInfo --bind 115=mmo.zoo.revival.InfoPanel \
  --note "REBUILT zoo 动物园信息 (aola-revival) on the art of zoo/zoores" --out "$W/zoo/revival/zooinfo.swf%3F1210"
build zoopanels mmo/zoo/revival/DocZooFeeder.as zoofeeder-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art zoo/zoores_5.swf)" --code "$OUT/zoofeeder-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.zoo.revival.DocZooFeeder --bind 208=mmo.zoo.revival.FeederPanel --bind 44=mmo.zoo.revival.FodderIcon \
  --bind 30=mmo.zoo.revival.FodderAdd --bind 216=mmo.zoo.revival.FodderQuick --bind 35=mmo.zoo.revival.FodderFull --bind 286=mmo.zoo.revival.FodderHow \
  --note "REBUILT zoo 饲料机 (aola-revival) on the art of zoo/zoores_5" --out "$W/zoo/revival/zoofeeder.swf%3F1210"
build zoopanels mmo/zoo/revival/DocZooAnimal.as zooanimal-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art zoo/petbreedingservice.swf)" --code "$OUT/zooanimal-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.zoo.revival.DocZooAnimal --bind 898=mmo.zoo.revival.AnimalPanel \
  --note "REBUILT zoo animal panel (aola-revival) on the art of zoo/petbreedingservice" --out "$W/zoo/revival/zooanimal.swf%3F1210"
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
# 流星购物街 (starshopping): the January 2013 scene is lost (the live one is a
# later one); the config gives the July 2012 art (starlandcopy) that name.
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

# 主题公园 and 亚比研究中心 (their January 2013 scenes lost, the live ones 2024–25 redrawings):
# rebuilt scenes on the oldest art that survives, the 2012 park (scene/memory/memory2) and
# the newbie quest's copy of the centre (scene/yabistudycopy, April 2014; its own timeline
# classes kept).
build scenes/themepark mmo/scene/themepark/DocThemeparkRevived.as themepark-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/memory/memory2.swf)" --code "$OUT/themepark-code.swf" --drop-art-abc \
  --bind 0=mmo.scene.themepark.DocThemeparkRevived --bind 9=mmo.scene.themepark.ThemeparkRevived \
  --note "REBUILT scene/themepark (aola-revival) on the 2012 主题公园 (scene/memory/memory2)" \
  --out "$W/scene/themepark.swf%3F130124"
build scenes/yabistudy mmo/scene/yabi/DocYabistudyRevived.as yabistudy-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/yabistudycopy.swf)" --code "$OUT/yabistudy-code.swf" \
  --bind 0=mmo.scene.yabi.DocYabistudyRevived --bind 187=mmo.scene.yabi.YabistudyRevived \
  --note "REBUILT scene/yabistudy (aola-revival) on scene/yabistudycopy (April 2014)" \
  --out "$W/scene/yabistudy.swf%3F130124"
# 念之塔 (黑暗念之塔, 风暴星系): the later thinktower/thinktowerservice's code compiled against the
# 2013 interfaces on its art, and 幽冥大殿 (scene/youanmingzhou2, its later code on its art) whose
# tower opens the seals' panel (thinktower/enterpanel) as in 2011–12.
build thinktower mmo/thinktower/DocClass.as thinktower-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art thinktower/thinktowerservice.swf)" --code "$OUT/thinktower-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.thinktower.DocClass --bind 8=mmo.thinktower.btnExitHall \
  --note "LATER thinktower/thinktowerservice: its code compiled against the 2013 interfaces (aola-revival), on its art" \
  --out "$W/thinktower/thinktowerservice.swf%3F1210"
build scenes/youanmingzhou2 mmo/scene/youanmingzhou/DocYouanmingzhou2Revived.as youanmingzhou2-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/youanmingzhou2.swf)" --code "$OUT/youanmingzhou2-code.swf" \
  --bind 0=mmo.scene.youanmingzhou.DocYouanmingzhou2Revived --bind 108=mmo.scene.youanmingzhou.Youanmingzhou2Revived \
  --note "REBUILT scene/youanmingzhou2 (aola-revival): the later code on its art, its tower to the 念之塔's seals" \
  --out "$W/scene/youanmingzhou2.swf%3F1210"

# 奥拉之树 (its January 2013 scene lost, the live one a 2025 redrawing): rebuilt on the
# stylized tree of 2014–24, the copy in scene/aolatreefb (2021).
build scenes/aolatree mmo/scene/starland/DocAolatreeRevived.as aolatree-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/aolatreefb.swf)" --code "$OUT/aolatree-code.swf" --drop-art-abc \
  --bind 0=mmo.scene.starland.DocAolatreeRevived --bind 112=mmo.scene.starland.AolatreeRevived \
  --note "REBUILT scene/aolatree (aola-revival) on the stylized tree of scene/aolatreefb (2021)" \
  --out "$W/scene/aolatree.swf%3F130124"
# The 沙盒's room (aola-revival, docs/MODDING.md): code only; it shows the rooms of the
# mod that is running (control's ModRun).
build scenes/sandboxroom mmo/scene/sandbox/DocSandboxRoom.as sandboxroom.swf "scene/sandboxroom.swf%3F1210"

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
# The pet choice panels (pet/petUIservice, lost): 天赋启迪's 选择亚比.
build petui mmo/petUI/service/DocPetUIService.as petuiservice-code.swf ""
# Its 选择亚比 is the chooser of the 2012 modules: character 29 of the era activityres/breakegg.
rm -rf "$OUT/petselect"
java -jar "$FFDEC" -selectid 29 -format sprite:swf -export sprite "$OUT/petselect" "$(art activityres/breakegg.swf)" > /dev/null
python3 "$TOOLS/swf_transplant.py" --art "$(ls "$OUT"/petselect/DefineSprite_29*/1.swf)" --wrap-root 29 --drop-art-abc \
  --code "$OUT/petuiservice-code.swf" --bind 0=mmo.petUI.service.DocPetUIService --bind 29=mmo.petUI.petselect.PetSelectPanel \
  --note "REBUILT pet/petUIservice (aola-revival); its 选择亚比 is character 29 of the era activityres/breakegg" \
  --out "$W/pet/petUIservice.swf%3F130103"
# "PetPackage" (pet/newpetpackage, lost), asked for by scenes with bars of their own (时空隧道,
# 实战特训场, the 竞技场): the control bar's 亚比 panel.
build newpetpackage mmo/petpackage/service/DocNewPetPackage.as newpetpackage.swf "pet/newpetpackage.swf%3F121220"
# The 亚比 pictures panels ask for (pet/peticon, lost): IPetIcon hands out the interfaces' PetIconContainer.
build peticonservice mmo/peticon/DocPetIconService.as peticonservice.swf "pet/peticon.swf%3F1210"

# 时空隧道 (spacetime/spacetimeservice, lost): the later service's code on the 2013 interfaces.
build spacetime mmo/spacetime/DocClass.as spacetime.swf "spacetime/spacetimeservice.swf%3F121213"

# 坐骑: pet/petride (RideService, lost; the copy under its URL is of 2021) rebuilt.
build petride mmo/pet/petride/DocPetRide.as petride.swf "pet/petride.swf%3F121227"
# 亚比骑乘训练 (训练官卢卡斯, the PetRideTrannig service): pet/petridepanel's copy of 2021 (the 2013 one is
# lost), its code compiled against the 2013 libraries as it is, on its own art; it trains through
# the rebuilt RideService (54_11).
build petridepanel mmo/pet/petride/DocPetRidePanel.as petridepanel-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/petridepanel.swf)" --code "$OUT/petridepanel-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.pet.petride.DocPetRidePanel --bind 57=mmo.pet.petride.PetRidePanel --bind 20=mmo.pet.petride.PetRideTranningPetBriefCard \
  --note "LATER pet/petridepanel (2021) on the 2013 libraries (aola-revival)" \
  --out "$W/pet/petridepanel.swf%3F1210"

# The 四大副本 (奥拉战记): the later fbservice and fbteam modules (2025 copies; the
# 2013 ones are lost) on the 2013 interfaces, and the later choose panel (2016)
# with its 扫荡 hidden, on its own art.
build fbservice mmo/fbservice/DocClass.as fbservice.swf "fbservice/fbservice.swf%3F121220"
build fbteam mmo/fbteam/DocClass.as fbteam.swf "fbteam/fbteamservice.swf%3F121220"
build fbchoosepanel mmo/fbpanels/fbchoose/DocFbChoose.as fbchoosepanel-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art fbservice/fbchoosepanel.swf)" --code "$OUT/fbchoosepanel-code.swf" --drop-art-abc --bind 274=mmo.fbpanels.fbchoose.NoTimesLeft \
  --note "LATER fbservice/fbchoosepanel (2016) on the 2013 libraries (aola-revival): 扫荡 hidden, daily entries RECONSTRUCTED" \
  --out "$W/fbservice/fbchoosepanel.swf%3F1210"

# 酷跑星世界 (game/parkour, a 2015 mini game; 星光游乐场's btnParkour): its code
# compiled against the 2013 libraries, with small revival copies of the later
# helpers it imports in its own source tree (BtEventDispatcher, ResourceObject,
# Parse, BitUtil, MaterialResultDialogHelper, ShowMovieOrCartoonHelper,
# MyXingBiHandler, TimeText_Helper) and the later loader calls (ResScheduler.getRes,
# SimpleCustomLoader.loadSingleRes) made 2013 ones, on its own art. Its panels,
# maps and avatars (parkourpanel*, field/*, avatar/*) hold art classes only and
# load as they are. The server side: server/src/game/sfs2013/parkour.ts.
build parkour mmo/game/parkour/DocParkourCompile.as parkour-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art game/parkour/parkour.swf)" --code "$OUT/parkour-code.swf" --drop-art-abc \
  --note "LATER game/parkour (2015) on the 2013 libraries (aola-revival): the later helpers it uses RECONSTRUCTED in its own code" \
  --out "$W/game/parkour/parkour.swf%3F1210"

# 财富小管家 and the 星币 machine (fortunemanager/starcoin, the later copy): its exchange panel
# (奥币铸造星币, 碎片铸造星币, the 财富小管家's 晶豆储蓄) compiled from its decompiled code against the
# 2013 libraries, on its own art; the real-money 购买星币 panel and the 二级密码 check are left out,
# and the 晶豆 come with the server's replies (the 2013 UserInfo has none). fortunemanager/
# fortunemanager (later) is served as it is: its FortuneManagerService opens this module's
# StarCoinPanelService. The server side: ScoreManager's accounts and MaterialExtension 14_19–14_21 (game.ts).
build starcoin mmo/revival/starcoin/DocStarCoin.as starcoin-code.swf ""
mkdir -p "$W/fortunemanager"
python3 "$TOOLS/swf_transplant.py" --art "$(art fortunemanager/starcoin.swf)" --code "$OUT/starcoin-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.starcoin.DocStarCoin --bind 492=mmo.starcoinexchange.panel.ExchangePanel --bind 361=mmo.starcoinexchange.panel.AoExchangePanel \
  --bind 333=mmo.starcoinexchange.panel.PieceExchangePanel --bind 1109=mmo.starcoinexchange.panel.PieceToCoinConfirmPanel \
  --bind 491=mmo.starcoinexchange.fortunemanager.FortunemanagerPanel --bind 429=mmo.starcoinexchange.fortunemanager.StoreMessagePanel \
  --bind 454=mmo.starcoinexchange.fortunemanager.StoreCoinPanel --bind 468=mmo.starcoinexchange.fortunemanager.SurePanel \
  --bind 476=mmo.starcoinexchange.fortunemanager.ReturnCoinPanel --bind 488=mmo.starcoinexchange.fortunemanager.AdvanceGetBackPanel \
  --bind 490=mmo.starcoinexchange.fortunemanager.OneDayGetBackPanel \
  --bind 17=starcoin_fla.Pic480 --bind 423=starcoin_fla.Szkljdksw71 --bind 1276=starcoin_fla.BubbleMovie \
  --note "LATER fortunemanager/starcoin on the 2013 libraries (aola-revival): the exchange panel only; no real-money panel, no 二级密码" \
  --out "$W/fortunemanager/starcoin.swf%3F130117"

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

# The same for later games that have a startGame of their own (冰之迷阵's game/brickgame, 霓虹泡泡珠's
# game/puzzlebobble and six more of the 2013 config): there the name goes to getBuddyByName, which the 2013 SocketClient has (one
# String in, a lookup in the friend list, nothing sent) and nothing of these games is called.
for g in brickgame chocolaterabbit eatbeans flyingunicorn onelinegame puzzlebobble yinijump zuma; do
  f="$(art game/$g.swf)"
  python3 "$TOOLS/abc_rename.py" --rename startGame=getBuddyByName \
    --note "LATER game/$g: SocketClient.startGame (later only) and the game's own startGame renamed getBuddyByName (aola-revival, tools/abc_rename.py)" \
    "$f" "$W/game/$(basename "$f")"
done

# Later games that load a panel with the later loader's SimpleCustomLoader.loadSingleRes (卖蛋糕小达人
# and 对决无双, for panels of later activities): the class they name is SimpleCLLoader, play.swf's,
# which does it with the 2013 loader (with SimpleCLParam, also in play.swf).
for g in makecake matchthree4activity; do
  f="$W/game/$(basename "$(art game/$g.swf)")"
  [ -f "$f" ] || f="$(art game/$g.swf)"
  python3 "$TOOLS/abc_rename.py" --rename SimpleCustomLoader=SimpleCLLoader \
    --note "LATER game/$g: SimpleCustomLoader (its loadSingleRes is later only) renamed SimpleCLLoader, play.swf's (aola-revival, tools/abc_rename.py)" \
    "$f" "$W/game/$g.tmp" && mv "$W/game/$g.tmp" "$W/game/$(basename "$(art game/$g.swf)")"
done

# 疯狂的水果 (game/flyingfruit, a later copy): its start panel waited for a 2016 activity's count and
# asked the later praise-and-feedback service (not in the 2013 service list) and material tips, and
# its end waited for that activity's count too: the screen stayed black. Its decompiled code compiled
# against the 2013 libraries without them, on its own art.
build games/flyingfruit mmo/game/flyingfruit/DocClass.as flyingfruit-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art game/flyingfruit.swf)" --code "$OUT/flyingfruit-code.swf" --drop-art-abc \
  --note "LATER game/flyingfruit: its decompiled code compiled against the 2013 libraries without the later praise-and-feedback stamp and material tips (aola-revival), on its own art" \
  --out "$W/game/$(basename "$(art game/flyingfruit.swf)")"

# The 家园's 亚比批量孵化器 (era pet/pethatchegg): its decompiled code with the
# eggs' names under them and their pictures while they hatch, on its own art.
build pethatchegg mmo/pet/pethatchegg/PetHatchEgg.as pethatchegg-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art pet/pethatchegg.swf)" --code "$OUT/pethatchegg-code.swf" --drop-art-abc \
  --note "ERA pet/pethatchegg: its decompiled code with the eggs' names and pictures (aola-revival), on its own art" \
  --out "$W/pet/pethatchegg.swf%3F1210"

# The small pictures (_S) the peticon files of the 亚比 one could not get in
# 2012 and 2013 lack (missing or an empty sprite): each file's own large picture,
# scaled; the missing classes from a compiled template (tools/peticon_fill.py). And the
# 亚比 of the tables with no peticon file at all (星石, 图腾 …): their three pictures made
# from their battle sprite (or 圣渊露龙's, as the later client showed those without art).
build peticonfill mmo/pet/peticon777777_S.as peticonfill-template.swf ""
build peticonfill mmo/pet/peticon777777_L.as peticonfill-template-l.swf ""
build peticonfill mmo/pet/peticon777777_F.as peticonfill-template-f.swf ""
python3 "$TOOLS/peticon_fill.py" --game "$GAME" --template "$OUT/peticonfill-template.swf" \
  --template-l "$OUT/peticonfill-template-l.swf" --template-f "$OUT/peticonfill-template-f.swf" \
  --pmdata "$HERE/../static/www.9aola.com/revival/pmdata.json" --out "$W"

# 奇草树林 (云端王国's first room): the later scene's code on the 2013
# interfaces and that copy's art, with the room's map button back (it opens
# the era 云端王国 map, scene/cloudstarmap).
build scenes/cloudstar1 mmo/scene/cloudstar1/DocCloudStar1.as cloudstar1-code.swf ""
python3 "$TOOLS/swf_transplant.py" --art "$(art scene/cloudstar1.swf)" \
  --code "$OUT/cloudstar1-code.swf" --bind 0=mmo.scene.cloudstar1.DocCloudStar1 --bind 24=mmo.scene.cloudstar1.CloudStar1 \
  --note "LATER scene/cloudstar1: its code compiled against the 2013 interfaces (aola-revival), its map button redrawn, on its own art" \
  --out "$W/scene/cloudstar1.swf%3F1210"

# 巨锁石灵的机关 (族长之帐 yakestar3's btn_head; otherpanel/yakestarrarepetpanel, the
# 2014 upload): its decompiled code compiled against the 2013 libraries, on its own
# art; the later ProgressFullSprite.lockScreen / unlockScreen it calls when 小石灵 is
# got are the 2013 show / close. The server side: server/src/game/sfs2013/planetacts.ts.
build yakestarpanel mmo/yakestarratepetpanel/DocYakestarCompile.as yakestarpanel-code.swf ""
mkdir -p "$W/otherpanel"
python3 "$TOOLS/swf_transplant.py" --art "$(art otherpanel/yakestarrarepetpanel.swf)" --code "$OUT/yakestarpanel-code.swf" --drop-art-abc \
  --note "LATER otherpanel/yakestarrarepetpanel (2014) on the 2013 libraries (aola-revival): ProgressFullSprite.lockScreen made show" \
  --out "$W/otherpanel/yakestarrarepetpanel.swf%3F1210"

# 波鲁跳火圈 (菲尔区 feier1's fire ring; the later scene and game, scene/feier1 and
# game/jumpfirering): their start panel game/jumpfireringstartpanel is lost. Rebuilt: it opens
# the game (whose start page has 开始, 规则 and 关闭), and its notice for a player in a team.
build jumpfireringstartpanel mmo/game/jumpfirering/start/DocStartPanel.as jumpfireringstartpanel.swf "game/jumpfireringstartpanel.swf%3F1210"

# 召唤奇灵王 (奇灵神树; activityres/activity130131/qiling/qilingdlg, the copy of February 2013): its
# decompiled code compiled against the 2013 libraries, on its own art; the later
# LocalStore.allowStore it asks is not in the 2013 library (storing is allowed). The server side:
# server/src/game/sfs2013/kingbosses.ts.
build qiling mmo/revival/qiling/DocQiling.as qiling-code.swf ""
mkdir -p "$W/activityres/activity130131/qiling"
python3 "$TOOLS/swf_transplant.py" --art "$(art activityres/activity130131/qiling/qilingdlg.swf)" --code "$OUT/qiling-code.swf" --drop-art-abc \
  --bind 0=mmo.revival.qiling.DocQiling --bind 252=mmo.activity130131.qiling.QilingDlg --bind 314=mmo.activity130131.qiling.PowerPanel \
  --bind 298=mmo.activity130131.qiling.StartPanel --bind 285=mmo.activity130131.qiling.RecipeDlg1 --bind 276=mmo.activity130131.qiling.RecipeDlg2 \
  --bind 141=mmo.activity130131.qiling.BeckonMovie \
  --note "LATER activityres/activity130131/qiling/qilingdlg (February 2013) on the 2013 libraries (aola-revival): LocalStore.allowStore taken out" \
  --out "$W/activityres/activity130131/qiling/qilingdlg.swf%3F1210"

# 魔龙之战 (深渊魔域; activityres/activity121220/abyssevilmainpanel, the copy of 2015): its decompiled
# code compiled against the 2013 libraries, on its own art; the later buff bar it put on the panel
# (IBuffCache, not in the 2013 interfaces) is left out. The server side: server/src/game/sfs2013/godbosses.ts.
build abyssevil mmo/revival/abyssevil/DocAbyssEvil.as abyssevil-code.swf ""
mkdir -p "$W/activityres/activity121220"
python3 "$TOOLS/swf_transplant.py" --art "$(art activityres/activity121220/abyssevilmainpanel.swf)" --code "$OUT/abyssevil-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.abyssevil.DocAbyssEvil --bind 216=mmo.activity121220.abyssevil.MainPanel --bind 69=mmo.activity121220.abyssevil.MoneyPanel \
  --bind 231=mmo.activity121220.abyssevil.BuyPanel --bind 234=mmo.activity121220.abyssevil.BuyLimitPanel --bind 25=mmo.activity121220.abyssevil.Need100LevelPanel \
  --note "LATER activityres/activity121220/abyssevilmainpanel (2015) on the 2013 libraries (aola-revival): the buff bar (IBuffCache) taken out" \
  --out "$W/activityres/activity121220/abyssevilmainpanel.swf%3F121227"

# 夜王复出！狼王再现！ (魂塔顶端; activityres/activity130221/wolfandnightking, February 2013, the module's
# copy of 2016): its decompiled code compiled against the 2013 libraries, on its own art, the later
# re-run's additions taken out. The two kings' panels (challenge0, challenge1, of 2016) bound to their
# art alone, without the later dialogs they carry. The server side: server/src/game/sfs2013/wnking.ts.
build wnking mmo/revival/wnking/DocWNKing.as wnking-code.swf ""
build wnking mmo/revival/wnking/DocWNKingRes.as wnkingres-code.swf ""
# The HELLO skills' icons of May 2012 (robot/robotanothermes, its skill bar of another player's
# HELLO) bound to classes of their own, for the rebuilt HELLO's menu (robotmanager HelloWheel).
build helloskillicons mmo/revival/helloskill/DocHelloSkill.as helloskill-code.swf ""
mkdir -p "$W/robot/revival"
HS=mmo.revival.helloskill.HelloSkill
python3 "$TOOLS/swf_transplant.py" --art "$(art robot/robotanothermes.swf)" --code "$OUT/helloskill-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.helloskill.DocHelloSkill --bind 5=${HS}Follow --bind 28=${HS}Heal --bind 9=${HS}Exp --bind 12=${HS}Hatch \
  --bind 44=${HS}Rare --bind 40=${HS}Sort --bind 78=${HS}Warehouse --bind 17=${HS}Replace --bind 33=${HS}Train \
  --note "the HELLO skill icons of robot/robotanothermes (May 2012) for the rebuilt HELLO menu (aola-revival)" \
  --out "$W/robot/revival/helloskillicons.swf%3F1210"

WNK=activityres/activity130221/wolfandnightking
mkdir -p "$W/$WNK"
python3 "$TOOLS/swf_transplant.py" --art "$(art $WNK/wolfandnightking.swf)" --code "$OUT/wnking-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.wnking.DocWNKing --bind 64=mmo.activity130221.wolfandnightking.WNKingChallengeMainPanel \
  --bind 110=mmo.activity130221.wolfandnightking.WNKingFinalChallengePanel --bind 175=mmo.activity130221.wolfandnightking.WNKingFinalTipsPanel \
  --note "LATER $WNK/wolfandnightking (2016) on the 2013 libraries (aola-revival): the main panel shown again, the later buttons taken out" \
  --out "$W/$WNK/wolfandnightking.swf%3F1210"
python3 "$TOOLS/swf_transplant.py" --art "$(art $WNK/wolfandnightkingchallenge0.swf)" --code "$OUT/wnkingres-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.wnking.DocWNKingRes --bind 122=mmo.activity130221.wolfandnightking.ChallengePanel0 \
  --note "LATER $WNK/wolfandnightkingchallenge0 (2016): the 狼王 panel alone (aola-revival)" \
  --out "$W/$WNK/wolfandnightkingchallenge0.swf%3F1210"
python3 "$TOOLS/swf_transplant.py" --art "$(art $WNK/wolfandnightkingchallenge1.swf)" --code "$OUT/wnkingres-code.swf" --drop-art-abc --only-binds \
  --bind 0=mmo.revival.wnking.DocWNKingRes --bind 198=mmo.activity130221.wolfandnightking.ChallengePanel1 \
  --note "LATER $WNK/wolfandnightkingchallenge1 (2016): the 夜王 panel alone (aola-revival)" \
  --out "$W/$WNK/wolfandnightkingchallenge1.swf%3F1210"

# 魔将挑战 (深渊之门 msevenstar4; the era activityres/activity121213/evilgeneralmainpanel): its win and
# 星币 films are lost, and the panel waits for their last frame to show 魔洛's 亚比蛋. Stand-ins of
# two empty frames (tools/blank_sprites.py), at both films' names.
build actfilms mmo/revival/actfilms/DocEvilGeneralFilms.as evilgeneralfilms-code.swf ""
python3 "$TOOLS/blank_sprites.py" --count 2 --frames 2 --out "$OUT/blank2.swf"
mkdir -p "$W/activityres/activity121213"
python3 "$TOOLS/swf_transplant.py" --art "$OUT/blank2.swf" --code "$OUT/evilgeneralfilms-code.swf" \
  --bind 0=mmo.revival.actfilms.DocEvilGeneralFilms --bind 1=mmo.activity121213.evilgeneral.WinMovie --bind 2=mmo.activity121213.evilgeneral.BuyMovie \
  --note "REBUILT activityres/activity121213/evilgeneralwinmovie and evilgeneralbuymovie (aola-revival): stand-ins for the lost films" \
  --out "$W/activityres/activity121213/evilgeneralwinmovie.swf%3F1210"
cat "$W/activityres/activity121213/evilgeneralwinmovie.swf%3F1210" > "$W/activityres/activity121213/evilgeneralbuymovie.swf%3F1210"

# 私聊 (talk/talk, the January 2013 module lost; the later copy needs later libraries):
# rebuilt TalkService and its window, at both names the client may ask for.
build talk mmo/talk/DocTalk.as talk.swf "talk/talk.swf%3F1301251"
cat "$OUT/talk.swf" > "$W/talk/talk.swf%3F1210"
