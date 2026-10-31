package mmo.scene.starland
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fly.IFlyService;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.dressily.IDressily;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RLog;

   /**
    * LATER scene/crossroad (十字大道): the 2020 scene's code on the 2013
    * engine, on that copy's art (the January 2013 scene is lost). Its doors
    * are those of the January 2013 config.xml: 生态园, 奥拉展馆
    * (xianxiazhanguan), 星光游乐场, 图书馆, and 爱心协会 (loveassociation,
    * ms="crossroad"), the building with the hearts down the 升降机, which the
    * later code had dropped (its init point "fromloveassociation" was kept).
    * The 卡牌达人馆 and the 棒棒奶酪 exchange of the later art are of later
    * years and lead nowhere. The 升降机 is the later code's: walking onto its
    * upper or lower half rides it down or up (the player rides inside the
    * lift's own animation and steps off at the other end).
    */
   public class CrossroadRevived extends SceneBase
   {
      private static const locationKey:String = "fromcrossroad";

      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      private var elevator:MovieClip;
      private var hitTestDownMc:MovieClip;
      private var hitTestUpMc:MovieClip;
      private var playerDownMc:MovieClip;
      private var playerUpMc:MovieClip;
      private var player:PlayerBase;
      private var playerParent:DisplayObjectContainer;
      private var flyService:IFlyService;
      private var destX:int;
      private var destY:int;

      public function CrossroadRevived()
      {
         super(610, 360);
         addInitLocation("fromaolatree", new Point(388, 265));
         addInitLocation("fromxianxiazhanguan", new Point(630, 360));
         addInitLocation("fromteambattleoutside", new Point(630, 360));
         addInitLocation("fromlibray", new Point(411, 279));
         addInitLocation("fromlibrary", new Point(411, 279));
         addInitLocation("fromloveassociation", new Point(275, 475));
         addInitLocation("fromecologicalpark", new Point(388, 265));
         addInitLocation("fromamusementpark", new Point(630, 400));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         var tips:TipsManager = TipsManager.getInstance();
         door(foreground.getChildByName("et1"), "生态园", "ecologicalpark", FaceDirectionTypes.FACELEFTDOWN);
         door(foreground.getChildByName("et2"), "奥拉展馆", "xianxiazhanguan", FaceDirectionTypes.FACELEFTUP);
         door(foreground.getChildByName("et3"), "星光游乐场", "amusementpark", FaceDirectionTypes.FACERIGHTDOWN);
         door(foreground.getChildByName("et4"), "图书馆", "library", "ld");
         // 爱心协会: the door of the house with the hearts, below the lift.
         var love:Sprite = new Sprite();
         love.name = "etLove";
         love.graphics.beginFill(0xFFFFFF, 0);
         love.graphics.drawRect(160, 385, 95, 60);
         love.graphics.endFill();
         foreground.addChild(love);
         door(love, "爱心协会", "loveassociation", FaceDirectionTypes.FACELEFTUP);
         // Later years': the 卡牌达人馆 (2014) and the 棒棒奶酪 exchange.
         var et6:InteractiveObject = foreground.getChildByName("et6") as InteractiveObject;
         if (et6 != null) et6.mouseEnabled = false;
         var bjf:DisplayObject = overlap ? overlap.getChildByName("btnBJF") : null;
         if (bjf != null) bjf.visible = false;
         initElevator();
      }

      private function door(area:DisplayObject, tip:String, scene:String, face:String):void
      {
         if (area == null) return;
         try { TipsManager.getInstance().addTips(area as InteractiveObject, tip); } catch (e:Error) {}
         addEntrances(area, scene, locationKey, null, face);
      }

      private function initElevator():void
      {
         try { flyService = ServiceContainer.getService(IFlyService) as IFlyService; } catch (e:Error) {}
         elevator = background.getChildByName("elevatormc") as MovieClip;
         if (elevator == null) return;
         TipsManager.getInstance().addTips(elevator, "升降机");
         hitTestDownMc = elevator.getChildByName("hittestdownmc") as MovieClip;
         hitTestUpMc = elevator.getChildByName("hittestupmc") as MovieClip;
         playerDownMc = elevator.getChildByName("playerdownmc") as MovieClip;
         playerUpMc = elevator.getChildByName("playerupmc") as MovieClip;
         hitTestDownMc.alpha = 0;
         hitTestUpMc.alpha = 0;
         elevator.gotoAndStop(1);
         player = PlayerManager.getInstance().myPlayer;
         if (player == null) return;
         playerParent = player.parent;
         addEventListener(Event.ENTER_FRAME, onEnterFrames);
      }

      private function flying():Boolean
      {
         try { return flyService != null && flyService.isFlying(); } catch (e:Error) {}
         return false;
      }

      private function onEnterFrames(e:Event):void
      {
         if (flying() || player == null || player.parent == null) return;
         var x:Number = player.currentX;
         var y:Number = player.currentY;
         // localToGlobal: the scene may be scrolled.
         var g:Point = player.parent.localToGlobal(new Point(x, y));
         if (hitTestDownMc.hitTestPoint(g.x, g.y)) ride(playerDownMc, 320, 490);
         else if (hitTestUpMc.hitTestPoint(g.x, g.y)) ride(playerUpMc, 440, 320);
      }

      /** Into the lift's animation, and out at the other end at (ox, oy), going on to where the player was going. */
      private function ride(inside:MovieClip, ox:int, oy:int):void
      {
         removeEventListener(Event.ENTER_FRAME, onEnterFrames);
         destX = player.destX;
         destY = player.destY;
         var dg:Point = playerParent.localToGlobal(new Point(destX, destY));
         if (elevator.hitTestPoint(dg.x, dg.y))
         {
            destX = ox;
            destY = oy;
         }
         player.stop();
         playerParent.removeChild(player);
         var self:CrossroadRevived = this;
         elevator.addFrameScript(elevator.totalFrames - 1, function():void
         {
            elevator.addFrameScript(elevator.totalFrames - 1, null);
            elevator.stop();
            if (player.parent) player.parent.removeChild(player);
            playerParent.addChild(player);
            player.x = ox;
            player.y = oy;
            elevator.gotoAndStop(1);
            try { player.walkTo(destX, destY); } catch (err:Error) {}
            self.addEventListener(Event.ENTER_FRAME, onEnterFrames);
         });
         try { Player(player).action(IDressily(player).getMovingState().decorateAction("ddz")); }
         catch (err:Error) { RLog.error("crossroad lift", err); }
         player.x = 0;
         player.y = 0;
         inside.addChild(player);
         elevator.gotoAndPlay(2);
      }

      override protected function onLeaveRoom():void
      {
         super.onLeaveRoom();
         removeEventListener(Event.ENTER_FRAME, onEnterFrames);
         if (elevator != null) elevator.addFrameScript(elevator.totalFrames - 1, null);
         // Leaving while riding: the player back where players live.
         if (player != null && playerParent != null && player.parent != playerParent)
         {
            if (player.parent) player.parent.removeChild(player);
            playerParent.addChild(player);
         }
      }
   }
}
