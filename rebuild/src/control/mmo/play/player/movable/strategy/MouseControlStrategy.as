package mmo.play.player.movable.strategy
{
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.utils.getTimer;
   import mmo.loader.layer.LayerManager;
   import mmo.play.player.movable.IMovable;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT. My player walks to where the scene is clicked. Clicks on a
    * scene's walk targets and entrances are left to the scene; the scene's
    * arridable(stageX, stageY) can veto a destination, as volcano does.
    */
   public class MouseControlStrategy extends AbstractMovingStrategy implements IMovingStrategy
   {
      private static const MOUSE_CLICK_INTERVAL:int = 200;
      private var _mouseClickTime:int;

      public function MouseControlStrategy()
      {
         super();
      }

      override public function setControlItem(item:IMovable):void
      {
         super.setControlItem(item);
         LayerManager.getBaseScene().addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownBoard, false, 0, true);
      }

      override public function dispose():void
      {
         LayerManager.getBaseScene().removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownBoard);
         super.dispose();
      }

      private function onMouseDownBoard(e:MouseEvent):void
      {
         RLog.log("mouse: down at " + e.stageX + "," + e.stageY + " on " + e.target);
         if (_controlItem == null || SceneManager.getInstance().isSuspend) return;
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null) return;
         var scene:SceneBase = info.scene;
         if (scene.isWalkTargetEvent(e)) return;
         var now:int = getTimer();
         if (now - _mouseClickTime < MOUSE_CLICK_INTERVAL) return;
         _mouseClickTime = now;
         if (!scene.arridable(e.stageX, e.stageY)) return;
         var p:Point = scene.localPointToScene(new Point(e.stageX, e.stageY));
         _controlItem.walkTo(int(p.x), int(p.y));
      }
   }
}
