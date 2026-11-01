package mmo.play.scene
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.system.ApplicationDomain;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.movie.MovieManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL. Small fixes to scenes whose files are later copies, made when
    * the scene is shown (SceneManager, after SCENE_INITED).
    *
    * The lift of the shops (btnLadder, "点我前往其他楼层", showing 种植园,
    * 家具店 and 服装店): in the later copies of 家具店 (2017), 服装店 and
    * 种植园 (2018) nothing listens to it any more. A click shows the three
    * floors to go to.
    *
    * 体育馆's 斑比向前冲 (a later game, its button in the later scene).
    * 日月之境 and 木石之境: their way back to 崩坏的上古神殿. 艺术馆: its door
    * to 博物馆大厅, moved off the room in the later copy. 古代遗迹, 龙族圣殿 and
    * 亚比训练室: doors their later copies lost (spot, ARRIVALS). 蓝宝石要塞, 六芒前殿,
    * 奇灵神树, 六芒内殿 and 龙族圣殿: the later copies' advertisements are hidden
    * (LATER_PROMOS).
    *
    * NPC menus (the 功能 the 30 Nov 2012 world map lists for places): the
    * revival's NPC service has no per-NPC menus, while the later scenes still
    * answer the choices of the later NpcMenu table (爱心天使协会 donate_union …,
    * task/tasknpc config/npc/NpcMenu): MENUS gives a room's NPCs those of
    * them whose 2012 function the scene still answers, while the room is shown.
    * Choices whose action starts with "revival_" are answered here (ACTIONS).
    *
    * 奥拉之树 (its scene is being redrawn): its functions hang on names, not
    * places. A button named threeHerosBtn or btnHistoryComic shows 奥拉星历史漫画
    * (the 三英雄与奥拉之辉 comic, taskres/threeHeros of March 2012, as the later
    * scene's threeHerosBtn did), one named btnBallWish or btnWish the 星愿气球
    * (BallWishService.showWishPanel); 历史学者萨鲁奇 (44) offers the comic too.
    */
   public class ScenePatches
   {
      private static const FLOORS:Array = [["种植园", "plantpark", "default"], ["家具店", "furnitureshop", "fromplantpark"], ["服装店", "clothesshop", "default"]];

      private static var menu:Sprite;

      private static const P121115:String = "revival_panel:activityres/activity121115/";
      private static const P121122:String = "revival_panel:activityres/activity121122/";

      /** room -> [npcId, choice text, action] (texts and actions of the later NpcMenu unless marked). */
      private static const MENUS:Object = {
         "loveassociation": [[42, "爱心天使协会", "donate_union"], [42, "我要贡献爱心", "donate_donate"], [42, "我需要帮助", "donate_take"]],
         // HELLO技能学习: the scene answers showSkillWakenInfo (RobotSkillService); the choice's words are the map's.
         "helloschool": [[14, "HELLO技能学习", "showSkillWakenInfo"], [14, "HELLO手册", "npc_hellocatalog"]],
         // 教官先锋队 (师徒): the scene answers fastclub_showMasterPanel with MasterSystemService's
         // showRelationshipPanel, which the stand-in lacks; the choice says it is being repaired.
         "fastclub": [[26, "我想了解一下奥拉师徒！", "fastclub_knowMaster"], [26, "我要成为奥拉师徒的一份子！", "revival_stub:MasterSystemService.showRelationshipPanel"]],
         "spacetimechallenge": [[99, "进入亚比对战空间", "YABI_ZHENG_BA"]],
         "amusementpark": [[239, "我要兑换奖品", "parkExchange"]],
         "employmenttown": [[465, "职业协会！", "465_occupationMes"], [465, "职业亚比大变身！", "465_evolution"]],
         "yabiunion": [[827, "亚比协会", "827_YabiUnion"]],
         "aolatree": [[44, "奥拉星历史漫画", "revival_historycomic"]],
         // 亚比融合 (PetMixService, pet/petmixnew): the rebuilt 亚比研究中心's art (the 2014 copy) has
         // no machine of its own for it; 贝鲁特 offers it (RECONSTRUCTED: where it is asked for).
         "yabistudy": [[11, "亚比融合", "revival_service:PetMixService"]],
         // The 道馆 (the later scenes of their 2015 return lost the masters' 2012 trials): each
         // master offers the map's three functions, opening the panels of November 2012
         // (activityres/activity121115, 121122) where the later scene does not.
         "huanlei": [[833, "幻雷的试炼", P121115 + "thunder/thunderspeedpanel|mmo.activity121115.thunder.thundertrain.panel.ThunderTrainPanel"],
            [833, "雷霆之塔", P121115 + "thunder/thundertower|mmo.activity121115.thunder.thundertower.TowerStartPanel"],
            [833, "踢馆！挑战幻雷！", P121115 + "thunder/thunderchallenge|mmo.activity121115.thunder.thunderchallenge.panel.ThunderChallengePanel"]],
         "huanyan": [[831, "最强力量PK战", P121115 + "activity_fire/powerfight|mmo.activity121115.activity_fire.powerfight.PowerFightMainPanel"],
            [831, "爆发力大冲击", P121115 + "activity_fire/breakout|mmo.activity121115.activity_fire.breakout.BreakOutMainPanel"],
            [831, "踢馆！挑战幻炎！", P121115 + "activity_fire/huanyanchallenge|mmo.activity121115.activity_fire.huanyanchallenge.HuanYanChallengePanel"]],
         "huanliu": [[832, "最强防御pk战", P121115 + "water/waterdefence|mmo.activity121115.water.waterdefence.WaterDefineDocClass"],
            [832, "幻流特训营", P121115 + "huanliu/trainmain|mmo.activity121115.trainroom.TrainRoomMainPanel"],
            [832, "踢馆！挑战幻流！", P121115 + "huanliu/huanliuchallenge|mmo.activity121115.trainroom.HLChallengeMainPanel"]],
         "huanming": [[836, "命运玩偶", P121122 + "fatedollpanel|mmo.activity121122.fate.fatedoll.FateDollMainPanel"],
            [836, "踢馆！挑战幻冥！", "836_HuanMingChallenge"]],
         "huanguang": [[835, "友情的试炼", "835_youqingshilian"], [835, "踢馆！挑战幻光", "835_HuanGuangChallenge"],
            [835, "我的伙伴我做主", P121122 + "myfriends|mmo.activity121122.myfriends.MFMainPanel"]],
         // 太空港's 战队 functions are 指挥官瑞斯's in the 战队要塞 behind it (the scene answers them;
         // SquadService itself is not rebuilt).
         // 蓝宝石要塞 (its 2026 scene answers none of its 2012 functions): 军需官亨特's weekly
         // 蓝宝石礼包 (the era VipGiftService's week panel) and 训练官卢卡斯's 亚比骑乘训练
         // (PetRideTrannig, pet/petridepanel, not rebuilt: its stand-in says so).
         "bluesquare": [[142, "我要领取蓝宝石礼包！", "revival_vipgift"], [148, "亚比骑乘训练", "revival_service:PetRideTrannig"]],
         // 上古使者 (312) of the 灵兽宫: the scene answers knowinfo (his conversation) and secret
         // (the 玄武 water panel, activityres/watercleanpanel of January 2012).
         "temple6": [[312, "我要如何获得灵兽的力量？", "knowinfo"], [312, "上古力量的秘密", "secret"]],
         "teambattlefort": [[340, "我要创建战队", "createSquad"], [340, "我要加入战队", "joinSquad"],
            [340, "我要招收队员", "inviteSquad"], [340, "战队最新公告", "noticeSquad"]]
      };

      /** [npcId, action] of the choices added for the room shown. */
      private static var added:Array = [];
      private static var listening:Boolean;
      private static var comic:MovieClip;

      public static function apply(info:SceneInfo):void
      {
         closeMenu();
         closeComic();
         dropMenus();
         if (info == null || info.scene == null) return;
         try
         {
            addMenus(String(info.sceneName));
         }
         catch (e0:Error) { RLog.error("scene patch menus " + info.sceneName, e0); }
         try
         {
            switch (String(info.sceneName))
            {
               case "furnitureshop":
               case "clothesshop":
               case "plantpark":
                  lift(info);
                  break;
               case "temple2":
               case "temple3":
                  // 日月之境 and 木石之境 (later copies) keep their first door (et1) hidden and
                  // without a target: in 2013 it led back to 崩坏的上古神殿.
                  door(info, "et1", "temple1", "from" + info.sceneName, "崩坏的上古神殿");
                  break;
               case "bluesquare":
                  // 骑士团长亚瑟 (btnArthur): the 2026 scene opens the 2025 vip/viparthur; he
                  // talks (his December 2012 picture, tasknpc/npc147) and gives the weekly gift.
                  takeOver(info, "btnArthur", showArthur);
                  hide(info, LATER_PROMOS.bluesquare);
                  break;
               case "hexagrampalace1":
               case "hexagrampalace3":
               case "hexagrampalace4":
                  hide(info, LATER_PROMOS[info.sceneName]);
                  break;
               case "gymnasium":
                  // 斑比向前冲: the later scene asks the later GameTable's GAME_NINJA_RUSH (66),
                  // which the 2013 one lacks; the revival's GameManager knows its room.
                  takeOver(info, "btnNinjaRush", function():void { showGame(66); });
                  break;
               case "maintown1":
                  // 异星传送枢纽: the later scene's door at the teleporter leads to 星际圈 (interstellar),
                  // a later room the 2013 config does not have; the hub sends one to the planets, as
                  // the world map (map/map) does (RECONSTRUCTED: the 2013 scene is lost).
                  opener(info, "et2", "异星传送枢纽", function():void { Panel_Helper.loadResAndShow("map/map", "mmo.map.AolaMapService"); });
                  break;
               case "summerhotspring":
                  // 亚比成长计划 (activityres/activity121108/yabilevelup, November 2012): the 2020
                  // scene has no way to it; a sign on the beach opens its main panel (RECONSTRUCTED).
                  growSign(info);
                  break;
               case "yishuzhidu2":
                  // 艺术馆: the later copy (2018) moved its door to 博物馆大厅 (et2) above the
                  // room, off the stage; it goes back to the top of the passage between the
                  // pillars at the back, where the room's walkable floor leads.
                  bringBack(info, "et2", 55);
                  break;
               case "msevenstar1":
                  // 古代遗迹 (a copy of August 2013) lost its way to 黑暗星穴, which still sends
                  // players back as from3to1 and takes them in as from1to3: the cave on the left.
                  spot(info, new Rectangle(40, 160, 170, 150), "msevenstar3", "from1to3", "黑暗星穴");
                  break;
               case "msevenstar2":
                  // 龙族圣殿 (a copy of 2020) has no way out: down the carpet on the left to 古代遗迹
                  // (above the corner the control bar's 小精灵 covers).
                  spot(info, new Rectangle(0, 395, 150, 75), "msevenstar1", "from2to1", "古代遗迹");
                  hide(info, LATER_PROMOS.msevenstar2);
                  break;
               case "yabitrain":
                  // 亚比训练室 (a later copy) has no way out: the stairs down to 亚比研究中心 and,
                  // on the right, 实战特训场 (whose 2011 scene leads back here as fromactualcombat).
                  spot(info, new Rectangle(395, 395, 170, 90), "yabistudy", "fromyabitrain", "亚比研究中心");
                  spot(info, new Rectangle(880, 235, 80, 100), "actualcombat", "default", "实战特训场");
                  break;
               case "aolatree":
                  for each (var hn:String in ["threeHerosBtn", "btnHistoryComic"]) takeOver(info, hn, showHistoryComic);
                  for each (var wn:String in ["btnBallWish", "btnWish"]) takeOver(info, wn, showBallWish);
                  break;
            }
         }
         catch (e:Error) { RLog.error("scene patch " + info.sceneName, e); }
      }

      private static function npcService():Object
      {
         try { return ServiceContainer.getService("TaskNpcService"); } catch (e:Error) {}
         return null;
      }

      private static function addMenus(room:String):void
      {
         var list:Array = MENUS[room] as Array;
         var npc:Object = list ? npcService() : null;
         if (npc == null) return;
         for each (var m:Array in list)
         {
            npc.addNpcInteraction(int(m[0]), String(m[1]), String(m[2]));
            added.push([int(m[0]), String(m[2]), String(m[1])]);
         }
         if (!listening)
         {
            listening = true;
            TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, onAction);
         }
      }

      private static function dropMenus():void
      {
         var npc:Object = added.length ? npcService() : null;
         for each (var a:Array in added)
         {
            try
            {
               npc.removeNpcInteraction(a[0], a[1]);
               npc.removeNpcInteraction(a[0], a[2]);
            }
            catch (e:Error) {}
         }
         added = [];
      }

      /** The choices answered here. */
      private static function onAction(e:TaskEvent):void
      {
         var action:String = e.params ? String(e.params.action) : "";
         try
         {
            if (action.indexOf("revival_panel:") == 0)
            {
               // "revival_panel:<file>|<class>": an era panel shown as the scenes show them.
               var pc:Array = action.substr(14).split("|");
               Panel_Helper.loadResAndShow(pc[0], pc[1]);
               return;
            }
            if (action.indexOf("revival_stub:") == 0)
            {
               RLog.stub(action.substr(13));
               return;
            }
            if (action.indexOf("revival_service:") == 0)
            {
               // "revival_service:<name>": a 2013 service's panel (IShowPanel).
               ServiceContainer.instance.tryGetService(action.substr(16), function(svc:*, o:Object = null):void
               {
                  try { if (svc != null) svc.showPanel(); } catch (e2:Error) { RLog.error("scene patch " + action, e2); }
               });
               return;
            }
            switch (action)
            {
               case "revival_historycomic": showHistoryComic(); break;
               case "revival_vipgift":
                  ServiceContainer.instance.tryGetService("VipGiftService", function(svc:*, o:Object = null):void
                  {
                     try { if (svc != null) svc.showPanel("mmo.vip.gift.WeekSelectPanel"); } catch (e3:Error) { RLog.error("scene patch vipgift", e3); }
                  });
                  break;
            }
         }
         catch (err:Error) { RLog.error("scene patch action " + action, err); }
      }

      /** 骑士团长亚瑟's talk (his words are lost: RECONSTRUCTED). */
      private static function showArthur():void
      {
         var npc:Object = npcService();
         if (npc == null) return;
         npc.showNpcPanelFreelyByXml(<config>
               <context npcId="147" str="我是蓝宝石骑士团的团长亚瑟。蓝宝石骑士们，每周都可以在这里领取一份蓝宝石礼包！">
                  <choice str="我要领取蓝宝石礼包！" action="revival_vipgift"/>
               </context>
            </config>, 147);
      }

      /** 奥拉星历史漫画: the comic of the three heroes and the 奥拉之辉 (taskres/threeHeros, mmo.task140.ThreeHerosMovie). */
      private static function showHistoryComic():void
      {
         if (comic != null) return;
         var cls:String = "mmo.task140.ThreeHerosMovie";
         // Asked in this scene: a scene changed while the comic loads does not get it.
         var asked:* = SceneManager.getInstance().loadedSceneInfo;
         var play:Function = function(o:* = null):void
         {
            ProgressFullSprite.close();
            if (SceneManager.getInstance().loadedSceneInfo != asked) return;
            if (comic != null || !ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var c:Class = ApplicationDomain.currentDomain.getDefinition(cls) as Class;
            comic = new c() as MovieClip;
            if (comic == null) return;
            MovieManager.getInstance().addMovie(comic, false);
            comic.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void
            {
               if (ev.target is flash.display.SimpleButton && ev.target.name == "cloBtn") closeComic();
            }, true);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) play();
         else
         {
            ProgressFullSprite.show();
            ResScheduler.getResource("taskres/threeHeros", play, cls, function(e:* = null):void
            {
               ProgressFullSprite.close();
               RLog.log("scene patch: no taskres/threeHeros");
            });
         }
      }

      private static var growInited:Boolean;

      private static function growSign(info:SceneInfo):void
      {
         var b:Sprite = RUI.button("亚比成长计划", function():void
         {
            ServiceContainer.instance.tryGetService("YabiLevelUpService", function(svc:*, o:Object = null):void
            {
               try
               {
                  if (svc == null) return;
                  if (!growInited)
                  {
                     growInited = true;
                     svc.init();
                  }
                  svc.showMainPanel();
               }
               catch (e:Error) { RLog.error("scene patch yabilevelup", e); }
            });
         }, 110, 30, 0x9FE07A, 0x3E9E2A, "btnYabiLevelUp");
         b.x = 24;
         b.y = 96;
         b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         info.scene.addChild(b);
      }

      /** The comic ends with its close button, or when the scene changes. */
      private static function closeComic():void
      {
         if (comic == null) return;
         try
         {
            comic.stop();
            MovieManager.getInstance().removeMovie(comic);
         }
         catch (e:Error) {}
         comic = null;
      }

      /** 星愿气球: the era BallWishService's wish panel. */
      private static function showBallWish():void
      {
         ServiceContainer.instance.tryGetService("BallWishService", function(svc:*, o:Object = null):void
         {
            try { if (svc != null) svc.showWishPanel(); } catch (e:Error) { RLog.error("scene patch ballwish", e); }
         });
      }

      private static function find(d:DisplayObject, name:String, depth:int = 4):DisplayObject
      {
         if (d == null) return null;
         if (d.name == name) return d;
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null || depth <= 0) return null;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i), name, depth - 1);
            if (f != null) return f;
         }
         return null;
      }

      /**
       * Advertisements of later years in later copies of rooms, by room: the buttons and stands
       * of their sales and rankings (none answers anything in the 2013 game).
       */
      private static const LATER_PROMOS:Object = {
         // 蓝宝石要塞 (2026): 万欲之源众望终响, 星辉币兑换商店, 蓝钻兑换, 2026 季赛, 首充蓝宝送.
         bluesquare: ["btnnianfei2026", "btnXHES", "btnLZS", "btnjifeigain26", "btnLBSC"],
         // 六芒前殿 (2025): the 典藏皮肤 sale and the 最强荣耀 stand.
         hexagrampalace1: ["btnmipandiancangpifu", "mchonor"],
         // 奇灵神树 (2020): the 元宵最强荣耀 stand.
         hexagrampalace3: ["mcHonortop"],
         // 六芒内殿 (2025): 光启召唤法阵.
         hexagrampalace4: ["btnGQSC"],
         // 龙族圣殿 (2020): the three 帝皇龙 sales and the 最强荣耀 stand.
         msevenstar2: ["btnTQZJL", "btnSLC", "btnSDEDC", "mchonor"]
      };

      private static function hide(info:SceneInfo, names:Array):void
      {
         for each (var n:String in names)
         {
            var d:DisplayObject = find(info.scene, n, 3);
            if (d == null) continue;
            d.visible = false;
            if (d is InteractiveObject) InteractiveObject(d).mouseEnabled = false;
            if (d is DisplayObjectContainer) DisplayObjectContainer(d).mouseChildren = false;
         }
      }

      private static function door(info:SceneInfo, name:String, to:String, key:String, tip:String):void
      {
         var scene:SceneBase = info.scene as SceneBase;
         var et:DisplayObject = find(info.scene, name, 3);
         if (scene == null || et == null) return;
         scene.revival::addEntranceFor(et, to, key);
         try { TipsManager.getInstance().addTips(et as InteractiveObject, tip); } catch (e:Error) {}
      }

      /**
       * Arrival points (scene coordinates) that later copies of rooms lost, by room and by
       * the key their neighbours send players with (RECONSTRUCTED: near the door they use).
       */
      private static const ARRIVALS:Object = {
         msevenstar1: {from3to1: [120, 430], from2to1: [740, 390]},
         yabitrain: {fromyabistudy: [480, 380], fromactualcombat: [890, 300]}
      };

      public static function arrival(sceneName:String, key:String):Point
      {
         var room:Object = ARRIVALS[sceneName];
         var p:Array = room && key ? room[key] as Array : null;
         return p ? new Point(p[0], p[1]) : null;
      }

      /**
       * A door drawn over a later copy's art where its 2013 door was: invisible but for a
       * faint light under the pointer (as the 副本 doors of FbEntrances), walked to and gone through.
       */
      private static function spot(info:SceneInfo, r:Rectangle, to:String, key:String, tip:String):void
      {
         var scene:SceneBase = info.scene as SceneBase;
         if (scene == null) return;
         var face:Sprite = new Sprite();
         face.name = "revivalDoor_" + to;
         var paint:Function = function(alpha:Number):void
         {
            face.graphics.clear();
            face.graphics.beginFill(0xFFFFCC, alpha);
            face.graphics.drawRoundRect(r.x, r.y, r.width, r.height, 40, 40);
            face.graphics.endFill();
         };
         paint(0.001);
         face.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { paint(0.18); });
         face.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { paint(0.001); });
         var area:Sprite = new Sprite();
         area.graphics.beginFill(0, 0);
         area.graphics.drawRect(r.x, r.y, r.width, r.height);
         area.graphics.endFill();
         scene.addChild(area);
         scene.addChild(face);
         scene.revival::addEntranceFor(area, to, key, face);
         try { TipsManager.getInstance().addTips(face, tip); } catch (e:Error) {}
      }

      /** A door a later copy moved above the room: back down so that its top is at y `top`. */
      private static function bringBack(info:SceneInfo, name:String, top:Number):void
      {
         var et:DisplayObject = find(info.scene, name, 3);
         if (et == null || et.parent == null) return;
         var r:Rectangle = et.getBounds(et.parent);
         if (r.bottom > 0) return;
         et.y += top - r.top;
      }

      /** A hotspot that opens something instead of being walked into (a door of the later scene). */
      private static function opener(info:SceneInfo, name:String, tip:String, f:Function):void
      {
         var spot:InteractiveObject = find(info.scene, name, 3) as InteractiveObject;
         if (spot == null) return;
         spot.visible = true;
         if (spot is Sprite) Sprite(spot).buttonMode = true;
         try
         {
            TipsManager.getInstance().removeTips(spot);
            TipsManager.getInstance().addTips(spot, tip);
         }
         catch (e:Error) {}
         spot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopImmediatePropagation(); }, false, 100);
         spot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            f();
         }, false, 100);
      }

      /** Answer a button before the scene's own listener does (and instead of it). */
      private static function takeOver(info:SceneInfo, name:String, f:Function):void
      {
         var btn:InteractiveObject = find(info.scene, name, 5) as InteractiveObject;
         if (btn == null) return;
         btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            f();
         }, false, 100);
      }

      private static function showGame(id:int):void
      {
         ServiceContainer.instance.tryGetService("GameManager", function(svc:*, o:Object = null):void
         {
            try { if (svc != null) svc.showGame(id); } catch (e:Error) { RLog.error("scene patch game " + id, e); }
         });
      }

      private static function lift(info:SceneInfo):void
      {
         var btn:InteractiveObject = find(info.scene, "btnLadder") as InteractiveObject;
         if (btn == null) return;
         var here:String = String(info.sceneName);
         btn.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            if (menu != null) { closeMenu(); return; }
            showMenu(btn.getBounds(LayerManager.stage), here);
         });
      }

      private static function showMenu(r:Rectangle, here:String):void
      {
         menu = new Sprite();
         menu.name = "liftMenu";
         var w:int = 112, rowH:int = 30, h:int = 30 + FLOORS.length * rowH + 6;
         menu.graphics.lineStyle(2, 0x2E86D6);
         menu.graphics.beginFill(0xEAF6FF, 0.96);
         menu.graphics.drawRoundRect(0, 0, w, h, 14, 14);
         menu.graphics.endFill();
         var title:TextField = label("去哪一层？", 13, 0x1F5F99, true);
         title.x = 8;
         title.y = 5;
         menu.addChild(title);
         for (var i:int = 0; i < FLOORS.length; i++)
         {
            var f:Array = FLOORS[i];
            menu.addChild(floorButton(f, f[1] == here, 8, 30 + i * rowH, w - 16));
         }
         menu.x = Math.max(4, Math.min(960 - w - 4, r.x + r.width / 2 - w / 2));
         menu.y = Math.max(4, r.y - h + 30);
         menu.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         LayerManager.getBaseTop().addChild(menu);
      }

      private static function floorButton(f:Array, current:Boolean, x:Number, y:Number, w:Number):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = "lift_" + f[1];
         b.graphics.beginFill(current ? 0xB8C4CF : 0x4FA8EC);
         b.graphics.drawRoundRect(0, 0, w, 26, 10, 10);
         b.graphics.endFill();
         var t:TextField = label(current ? f[0] + "（这里）" : f[0], 13, 0xFFFFFF, true);
         t.autoSize = "none";
         t.width = w;
         t.height = 22;
         t.x = 0;
         t.y = 3;
         var tf:TextFormat = t.getTextFormat();
         tf.align = "center";
         t.setTextFormat(tf);
         b.addChild(t);
         b.x = x;
         b.y = y;
         if (!current)
         {
            b.buttonMode = true;
            b.useHandCursor = true;
            b.mouseChildren = false;
            b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               e.stopImmediatePropagation();
               closeMenu();
               SceneManager.getInstance().loadScene(f[1], f[2]);
            });
         }
         return b;
      }

      private static function label(s:String, size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = "left";
         t.text = s;
         return t;
      }

      private static function closeMenu():void
      {
         if (menu != null && menu.parent != null) menu.parent.removeChild(menu);
         menu = null;
      }
   }
}
