package mmo.scene.starland
{
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.play.scene.SceneManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.play.bigscene.BigSceneBase;
   import mmo.revival.RNotice;

   /**
    * REBUILT 奥拉广场 (room "starland"), bound to the July 2012 artwork of
    * bigscene/starlandcopy.swf (symbol 225) by tools/swf_transplant.py. The
    * January 2013 config names that art (starlandcopy) 流星购物街, the street
    * of the shops, whose own 2013 scene (scene/starshopping) is lost: the
    * same scene is installed as scene/starshopping too.
    *
    * Arrival points come from the surviving January 2013 neighbours, which
    * name the keys they send players with: restaurant "restostar", happyark
    * "arktoland", starsquare "squaretoland", employmenttown
    * "fromchamberofcommerce". Where each exit sits on the 2012 art is a
    * reconstruction: the art carries only one hotspot (et4, 道具店), so the
    * others are drawn here over the buildings they belong to.
    */
   public class Starland extends BigSceneBase
   {
      // Timeline instances of the art symbol.
      public var obstruction:MovieClip;
      public var foreground:MovieClip;
      public var overlap:MovieClip;
      public var background:MovieClip;
      public var topground:MovieClip;

      /** [tip, scene, location key, x, y, width, height] in scene coordinates. */
      private static const EXITS:Array = [
         ["种植园", "plantpark", "default", 200, 60, 100, 110],
         ["服装店", "clothesshop", "default", 612, 136, 86, 80],
         ["飞碟美食塔", "restaurant", "startores", 430, 200, 150, 50],
         ["快乐方舟", "happyark", "landtoark", 82, 330, 70, 60],
         ["银河商会", "employmenttown", "fromstarland", 866, 346, 72, 64]
      ];

      public function Starland()
      {
         // Points inside the walkable area of the 2012 obstruction layer.
         super(480, 330);
         addInitLocation("restostar", new Point(500, 270));
         addInitLocation("arktoland", new Point(150, 440));
         addInitLocation("squaretoland", new Point(150, 440));
         addInitLocation("fromchamberofcommerce", new Point(830, 450));
         addInitLocation("fromtoolshop", new Point(760, 360));
         addInitLocation("fromclothesshop", new Point(650, 300));
         addInitLocation("fromplantpark", new Point(280, 300));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         // The newbie-quest arrow ("到道具店里找米娜姐姐…") belongs to that quest only.
         var arrow:DisplayObject = foreground ? foreground.getChildByName("arrowMC") : null;
         if (arrow != null)
         {
            if (arrow is MovieClip) MovieClip(arrow).stop();
            arrow.visible = false;
         }
         var tips:TipsManager = TipsManager.getInstance();
         var shop:InteractiveObject = background ? background.getChildByName("et4") as InteractiveObject : null;
         if (shop != null)
         {
            tips.addTips(shop, "道具店");
            // The newbie quest buys its balls from 米娜 in the 道具店 copy; afterwards the 道具店.
            addEntrances(shop, newbieDone() ? "toolshop" : "toolshopcopy", "fromstarshopping");
            shop.alpha = 0;
         }
         for each (var e:Array in EXITS)
         {
            var area:Sprite = hotspot(e[3], e[4], e[5], e[6]);
            tips.addTips(area, e[0]);
            addEntrances(area, e[1], e[2]);
         }
         // 环保小卫士 (the recycling bin by the fountain, btnGame): the game room
         // gameRecycleGame of the January 2013 config.xml (owner starshopping).
         var bin:InteractiveObject = findNamed(this, "btnGame") as InteractiveObject;
         if (bin != null)
         {
            tips.addTips(bin, "环保小卫士");
            if (bin is Sprite) Sprite(bin).buttonMode = true;
            bin.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               e.stopImmediatePropagation();
               SceneManager.getInstance().loadGame("gameRecycleGame");
            });
         }
         var house:Sprite = hotspot(84, 258, 150, 70);
         tips.addTips(house, "小屋");
         addEntranceAction(house, goHome);
      }

      private static function findNamed(d:DisplayObject, name:String):DisplayObject
      {
         if (d == null) return null;
         if (d.name == name) return d;
         var c:flash.display.DisplayObjectContainer = d as flash.display.DisplayObjectContainer;
         for (var i:int = 0; c != null && i < c.numChildren; i++)
         {
            var f:DisplayObject = findNamed(c.getChildAt(i), name);
            if (f != null) return f;
         }
         return null;
      }

      private static function newbieDone():Boolean
      {
         try
         {
            var ts:Object = ServiceContainer.getService("TaskService");
            return ts != null && ts.isUserTaskFinish(150);
         }
         catch (e:Error) {}
         return false;
      }

      private function hotspot(x:Number, y:Number, w:Number, h:Number):Sprite
      {
         var s:Sprite = new Sprite();
         s.graphics.beginFill(0xFFFFFF, 1);
         s.graphics.drawRect(0, 0, w, h);
         s.graphics.endFill();
         s.x = x;
         s.y = y;
         s.alpha = 0;
         s.buttonMode = true;
         (background || this).addChild(s);
         return s;
      }

      /** The HOUSE door: into my home (HouseService.houseLoader, as the 2013 arrow guide does). */
      private function goHome():void
      {
         ServiceContainer.instance.tryGetService("HouseService", function(svc:IService, o:Object):void
         {
            Object(svc).houseLoader.loadHouse(SocketClient.instance.myUserName);
         });
      }
   }
}
