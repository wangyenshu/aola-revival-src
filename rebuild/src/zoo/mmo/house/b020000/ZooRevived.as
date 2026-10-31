package mmo.house.b020000
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.zoo.CatchAnimalClient;
   import mmo.housecommon.HouseBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.revival.RUI;

   /**
    * REBUILT furniture/b020000: the 动物园, reached from the 家园 by the tube
    * 进入动物园. The January 2013 zoo house is lost; this stands on the art
    * of the later copy (January 2021) with code written for the 2013 engine:
    * the planes 动物保卫战 and 动物捕捉 (the 生态园 games, as the era
    * ZooEntrancePanel opens them, coming back to the 生态园), the signs to
    * the 生态园 and back to 我的家园, the 手册, the zoo's sign with its name
    * and level, the 饲料机 (a free 喂食 for every animal), and the animals
    * themselves, which walk the lawn, fly over it or swim in the tank; a
    * click on one shows it (ZooAnimalPanel). 动物仓库 puts the 幼仔 in. The
    * later 养动物得晶豆 is of 2013's summer and hidden. Server: ZooExtension
    * (server zoo.ts); the zoo's rules are RECONSTRUCTED.
    */
   public class ZooRevived extends HouseBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var houseInside:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      private var animalsLayer:Sprite;
      private var hud:Sprite;
      private var animals:Object = {};
      private var fishPlaces:Array = [];
      private var fishUsed:Object = {};
      private var owner:String;
      private var mine:Boolean;

      public function ZooRevived()
      {
         super(300, 315);
         addInitLocation("fromGarden", new Point(300, 315));
         addInitLocation("fromecologicalpark", new Point(180, 300));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         try
         {
            owner = loader.houseInfo.owner;
            mine = loader.isMyHouse;
         }
         catch (e:Error)
         {
            owner = SocketClient.instance.myUserName;
            mine = true;
         }
         animalsLayer = new Sprite();
         animalsLayer.name = "zooAnimals";
         background.addChild(animalsLayer);
         hud = new Sprite();
         topground.addChild(hud);
         var tips:TipsManager = TipsManager.getInstance();
         clickable(background.getChildByName("feichuan"), "动物保卫战", function():void { game("gamePvZ"); });
         clickable(background.getChildByName("btnGuard"), "动物捕捉", function():void { game("gameCatchAnimal"); });
         clickable(background.getChildByName("btnZooBook"), "动物手册", ZooBook.show);
         clickable(background.getChildByName("btnZooInfo"), "动物园", function():void
         {
            wantInfo = true;
            ZooData.send("97_1", {un: owner});
         });
         var bean:DisplayObject = overlap.getChildByName("btnGetBean");
         if (bean != null) bean.visible = false;
         clickable(overlap.getChildByName("feedMachine"), "饲料机：给动物喂食", feedAll);
         clickable(overlap.getChildByName("btnEco"), "生态园", function():void { SceneManager.getInstance().loadScene("ecologicalpark", "fromzoo"); });
         clickable(overlap.getChildByName("btnHome"), "我的家园", function():void { if (loader != null) loader.loadSubHouse(GARDEN_ID, "fromZoo"); });
         // The fish tank's places (waterPoolMC.fishContainer.pointionMC_0..8).
         var pool:DisplayObjectContainer = background.getChildByName("waterPoolMC") as DisplayObjectContainer;
         var fc:DisplayObjectContainer = pool ? pool.getChildByName("fishContainer") as DisplayObjectContainer : null;
         for (var k:int = 0; fc && k < 9; k++)
         {
            var p:DisplayObject = fc.getChildByName("pointionMC_" + k);
            if (p == null) continue;
            p.visible = false;
            fishPlaces.push({holder: fc, x: p.x, y: p.y + 14});
         }
         var area:DisplayObject = fc ? fc.getChildByName("areaMC") : null;
         if (area != null) area.visible = false;
         if (mine)
         {
            var store:Sprite = RUI.button("动物仓库", function():void { ZooStore.show(onPut); }, 96, 32, 0xFFC45A, 0xF07812, "zooStoreBtn");
            store.x = 16;
            store.y = 14;
            hud.addChild(store);
         }
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("97_1", onInfo);
         sc.addEventListener("97_4", onAnimals);
         sc.addEventListener("97_7", onHarvested);
         ZooData.send("97_1", {un: owner});
         ZooData.send("97_4", {un: owner});
      }

      override protected function onLeaveRoom():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener("97_1", onInfo);
         sc.removeEventListener("97_4", onAnimals);
         sc.removeEventListener("97_7", onHarvested);
         ZooAnimalPanel.closeIfOpen();
         ZooStore.closeIfOpen();
         for each (var a:ZooAnimal in animals) a.dispose();
         animals = {};
         super.onLeaveRoom();
      }

      private function clickable(d:DisplayObject, tip:String, act:Function):void
      {
         var io:InteractiveObject = d as InteractiveObject;
         if (io == null) return;
         if (io is Sprite) Sprite(io).buttonMode = true;
         try { TipsManager.getInstance().addTips(io, tip); } catch (e:Error) {}
         io.addEventListener(MouseEvent.MOUSE_DOWN, function(ev:MouseEvent):void { ev.stopPropagation(); });
         io.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void
         {
            ev.stopImmediatePropagation();
            act();
         });
      }

      /** The 生态园 games, from the zoo's planes; one comes back to the 生态园, as from the era ZooEntrancePanel. */
      private function game(room:String):void
      {
         var team:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         if (team != null && team.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能进入游戏！");
            return;
         }
         if (room != "gameCatchAnimal")
         {
            SceneManager.getInstance().pushPreviousRoomName("ecologicalpark");
            SceneManager.getInstance().loadGame(room);
            return;
         }
         CatchAnimalClient.instance.getGameItemGame();
         SocketClient.instance.addEventListener(CatchAnimalClient.cmdEnterGame, function entered(ev:SocketClientEvent):void
         {
            SocketClient.instance.removeEventListener(CatchAnimalClient.cmdEnterGame, entered);
            if (!ev.params.res)
            {
               NewDialog.showFailMessage("进入游戏失败。");
               return;
            }
            SceneManager.getInstance().pushPreviousRoomName("ecologicalpark");
            SceneManager.getInstance().loadGame(room);
         });
         CatchAnimalClient.instance.enterGame();
      }

      private function onInfo(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (p.un != owner) return;
         var sign:DisplayObjectContainer = background.getChildByName("btnZooInfo") as DisplayObjectContainer;
         var who:String = owner;
         try { if (loader.houseInfo.desc) who = loader.houseInfo.desc; } catch (err:Error) {}
         if (sign != null)
         {
            var nm:TextField = sign.getChildByName("txtName") as TextField;
            var lv:TextField = sign.getChildByName("txtLv") as TextField;
            if (nm != null) nm.text = who + "的动物园";
            if (lv != null) lv.text = "等级:" + int(p.lv);
         }
         if (wantInfo)
         {
            wantInfo = false;
            RNotice.show(LayerManager.getBaseTop(), who + "的动物园  等级 " + int(p.lv) + "\n经验 " + int(p.exp) + " / " + int(p.next) + "    动物 " + int(p.n) + " / " + int(p.cap), 5);
         }
      }

      private var wantInfo:Boolean;

      private function onAnimals(e:SocketClientEvent):void
      {
         if (e.params.un != owner) return;
         var seen:Object = {};
         for each (var d:Object in e.params.animals as Array || [])
         {
            seen[d.id] = true;
            var a:ZooAnimal = animals[d.id];
            if (a != null) a.update(d);
            else addAnimal(d);
         }
         for (var id:String in animals)
         {
            if (!seen[id]) removeAnimal(int(id));
         }
      }

      private function addAnimal(d:Object):void
      {
         var an:Object = ZooData.animal(int(d.raceId));
         var sea:Boolean = an != null && String(an.position) == "海洋";
         var a:ZooAnimal = new ZooAnimal(d, sea ? null : walkable);
         if (sea)
         {
            var spot:Object = freeFishPlace(a.id);
            if (spot == null)
            {
               // A full tank: it swims at the tank's foot instead.
               a.place(650 + Math.random() * 60, 250);
               animalsLayer.addChild(a);
            }
            else
            {
               a.place(spot.x, spot.y);
               DisplayObjectContainer(spot.holder).addChild(a);
            }
         }
         else
         {
            var at:Point = randomLawn();
            a.place(at.x, at.y);
            animalsLayer.addChild(a);
         }
         a.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void
         {
            ev.stopImmediatePropagation();
            ZooAnimalPanel.show(a, mine, onChanged);
         });
         animals[a.id] = a;
      }

      private function freeFishPlace(id:int):Object
      {
         for (var i:int = 0; i < fishPlaces.length; i++)
         {
            if (fishUsed[i] == undefined)
            {
               fishUsed[i] = id;
               return fishPlaces[i];
            }
         }
         return null;
      }

      private function removeAnimal(id:int):void
      {
         var a:ZooAnimal = animals[id];
         if (a == null) return;
         for (var k:String in fishUsed)
         {
            if (fishUsed[k] == id) delete fishUsed[k];
         }
         a.dispose();
         delete animals[id];
      }

      /** The lawn: inside the scene's walkable area, below the planes and the tank. */
      private function walkable(x:Number, y:Number):Boolean
      {
         if (x < 130 || x > 760 || y < 225 || y > 440) return false;
         return !isBlocked(x, y);
      }

      private function randomLawn():Point
      {
         for (var i:int = 0; i < 40; i++)
         {
            var x:Number = 140 + Math.random() * 600;
            var y:Number = 235 + Math.random() * 190;
            if (walkable(x, y)) return new Point(x, y);
         }
         return new Point(420, 360);
      }

      private function onPut(p:Object):void
      {
         if (p.animal != null && animals[p.animal.id] == null) addAnimal(p.animal);
         ZooData.send("97_1", {un: owner});
      }

      private function onChanged(p:Object):void
      {
         if (int(p.res) == 1 && (p.hasOwnProperty("gain") || !p.hasOwnProperty("itemId"))) removeAnimal(int(p.id));
      }

      private function onHarvested(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (int(p.res) != 1) return;
         removeAnimal(int(p.id));
         var lvText:TextField = null;
         var sign:DisplayObjectContainer = background.getChildByName("btnZooInfo") as DisplayObjectContainer;
         if (sign != null) lvText = sign.getChildByName("txtLv") as TextField;
         if (lvText != null) lvText.text = "等级:" + int(p.lv);
         var msg:String = int(p.petRace) > 0
            ? ZooData.nameOf(int(p.raceId)) + "变异了！得到亚比 " + p.petName + "，已经放进亚比仓库。"
            : "收获了" + ZooData.nameOf(int(p.raceId), true) + "，放进了动物仓库。";
         RNotice.show(LayerManager.getBaseTop(), msg + "\n动物园经验 +" + int(p.gain), 5);
      }

      /** The 饲料机: the free 喂食 for every animal still growing. */
      private function feedAll():void
      {
         if (!mine)
         {
            RNotice.show(LayerManager.getBaseTop(), "这是别人的动物园哦。");
            return;
         }
         var n:int = 0;
         for each (var a:ZooAnimal in animals)
         {
            if (a.mature) continue;
            ZooData.send("97_12", {id: a.id, itemId: 0});
            n++;
         }
         SocketClient.instance.addEventListener("97_12", fedOne);
         fedCount = 0;
         fedAsked = n;
         RNotice.show(LayerManager.getBaseTop(), n ? "饲料机给 " + n + " 只动物喂了食。" : "没有要喂的动物。");
         if (n == 0) SocketClient.instance.removeEventListener("97_12", fedOne);
      }

      private var fedCount:int;
      private var fedAsked:int;

      private function fedOne(e:SocketClientEvent):void
      {
         var a:ZooAnimal = animals[int(e.params.id)];
         if (a != null && e.params.hasOwnProperty("raceId")) a.update(e.params);
         if (++fedCount >= fedAsked) SocketClient.instance.removeEventListener("97_12", fedOne);
      }
   }
}
