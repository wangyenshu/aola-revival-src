package mmo.fbservice
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbID;
   import mmo.interfaces.scenearrow.ISceneArrowService;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.revival.RLog;

   /**
    * REVIVAL. The doors of the 四大副本. The rooms they stood in survive only
    * as later copies (2018–19), when the 副本 had been retired: their handlers
    * (showChooseFbPanel) are still there but nothing calls them any more. They
    * are put back here, where the later scene arrows point
    * (SceneArrowConfig fbEntrance_<fb>_<room>):
    *   aixiscene4   幻影冰宫   the ice portal of its own library (Heidong), RECONSTRUCTED spot
    *   suolide2     倒立金字塔 the pyramid (overlap.btn_pyramid; the surviving 2018 copy has lost
    *                the button: a hotspot on the pyramid drawn top left)
    *   siwude4      蚁族王朝   the throne between the two guards (drawn in the background: a hotspot)
    *   yishuzhidu6  恐龙博物馆 the overgrown machine on the left (drawn in the background: a hotspot)
    */
   public class FbEntrances
   {
      private static var placed:Array = [];

      public static function init():void
      {
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE, onUnload);
         if (SceneManager.getInstance().loadedSceneInfo != null) onSceneInited(null);
      }

      private static function onSceneInited(e:SceneManagerEvent):void
      {
         clear();
         var info:* = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null) return;
         try
         {
            switch (String(info.sceneName))
            {
               case "aixiscene4": portal(info); break;
               case "suolide2": pyramid(info); break;
               case "siwude4": hotspot(info, FbID.Siwude, new Rectangle(415, 80, 160, 165), "蚁族王朝"); break;
               case "yishuzhidu6": hotspot(info, FbID.YISHUZHIDU, new Rectangle(0, 190, 190, 270), "恐龙博物馆"); break;
            }
         }
         catch (err:Error) { RLog.error("fb entrance " + info.sceneName, err); }
      }

      private static function portal(info:*):void
      {
         var dom:ApplicationDomain = info.applicationDomain as ApplicationDomain;
         if (dom == null || !dom.hasDefinition("Heidong")) return;
         var C:Class = dom.getDefinition("Heidong") as Class;
         var mc:MovieClip = new C() as MovieClip;
         var r:Rectangle = mc.getBounds(mc);
         mc.x = 135 - (r.x + r.width / 2);
         mc.y = 215 - (r.y + r.height / 2);
         mc.name = "fbEntrance";
         Sprite(info.scene.container).addChild(mc);
         door(mc, FbID.Aixi, "幻影冰宫");
      }

      private static function pyramid(info:*):void
      {
         // The 2012 scene's overlap.btn_pyramid. The surviving copy (2018) has lost the button (its
         // onJoinRoom still hides it, and throws): then a hotspot on the pyramid drawn top left.
         var btn:InteractiveObject = null;
         for each (var layer:String in ["overlap", "container"])
         {
            var holder:Object = info.scene.hasOwnProperty(layer) ? info.scene[layer] : null;
            if (holder != null && btn == null) btn = holder.getChildByName("btn_pyramid") as InteractiveObject;
         }
         if (btn != null) door(btn, FbID.Suolide, "倒立金字塔");
         else hotspot(info, FbID.Suolide, new Rectangle(40, 30, 360, 185), "倒立金字塔");
      }

      private static function hotspot(info:*, fb:int, area:Rectangle, tip:String):void
      {
         var s:Sprite = new Sprite();
         // Drawn in the background, the door shows nothing of itself: a faint light under the
         // pointer tells it is there (with the hand cursor and the tip).
         var paint:Function = function(alpha:Number):void
         {
            s.graphics.clear();
            s.graphics.beginFill(0xFFFFCC, alpha);
            s.graphics.drawRoundRect(area.x, area.y, area.width, area.height, 40, 40);
            s.graphics.endFill();
         };
         paint(0.001);
         s.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { paint(0.18); });
         s.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { paint(0.001); });
         s.name = "fbEntrance";
         // Above the scene's layers, under the players' names and the bar.
         Sprite(info.scene).addChild(s);
         door(s, fb, tip);
      }

      private static function door(d:InteractiveObject, fb:int, tip:String):void
      {
         if (d is Sprite) Sprite(d).buttonMode = true;
         try { TipsManager.getInstance().addTips(d, tip); } catch (e0:Error) {}
         ClickAndHitHelper.instance.registerTarget(d, false, 90);
         var go:Function = function(ev:ClickAndHitEvent):void
         {
            var arrows:ISceneArrowService = ServiceContainer.getService(ISceneArrowService) as ISceneArrowService;
            try { if (arrows) arrows.removeArrow("fbEntrance_" + FbID.getFbNameById(fb) + "_" + SceneManager.getInstance().loadedSceneInfo.sceneName); } catch (e1:Error) {}
            var svc:Object = ServiceContainer.getService("FbService");
            if (svc != null) svc.showChooseFbPanel(fb);
         };
         d.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, go);
         placed.push({d: d, go: go});
         RLog.log("fb entrance: " + tip);
      }

      private static function onUnload(e:SceneManagerEvent):void
      {
         clear();
      }

      private static function clear():void
      {
         for each (var p:Object in placed)
         {
            try
            {
               ClickAndHitHelper.instance.remove(p.d);
               p.d.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, p.go);
               if (DisplayObject(p.d).name == "fbEntrance" && p.d.parent) p.d.parent.removeChild(p.d);
            }
            catch (e:Error) {}
         }
         placed = [];
      }
   }
}
