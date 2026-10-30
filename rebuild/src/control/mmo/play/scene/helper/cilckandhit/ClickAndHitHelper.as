package mmo.play.scene.helper.cilckandhit
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT. "Walk up to it, then act": a scene registers a clickable
    * (registerTarget(target, walk, distance)); clicking it walks my player
    * there and, on arrival (or at once when walk is false or the player is
    * already within distance), dispatches ClickAndHitEvent.ON_CLICK_AND_HIT on
    * the target. 28 surviving scenes and modules use it.
    */
   public class ClickAndHitHelper
   {
      private static var _instance:ClickAndHitHelper;

      private var targets:Dictionary = new Dictionary(true);
      private var pending:InteractiveObject;

      public static function get instance():ClickAndHitHelper
      {
         if (_instance == null) _instance = new ClickAndHitHelper();
         return _instance;
      }

      public function registerTarget(target:InteractiveObject, walk:Boolean = true, distance:int = 0):void
      {
         if (target == null) return;
         targets[target] = {walk: walk, distance: distance};
         target.addEventListener(MouseEvent.CLICK, onClick);
         target.addEventListener(MouseEvent.MOUSE_DOWN, swallow);
      }

      public function remove(target:InteractiveObject):void
      {
         if (target == null) return;
         delete targets[target];
         target.removeEventListener(MouseEvent.CLICK, onClick);
         target.removeEventListener(MouseEvent.MOUSE_DOWN, swallow);
         if (pending == target) pending = null;
      }

      /** Keep the scene's mouse strategy from also walking to the click point. */
      private function swallow(e:MouseEvent):void
      {
         e.stopPropagation();
      }

      private function onClick(e:MouseEvent):void
      {
         var target:InteractiveObject = e.currentTarget as InteractiveObject;
         var opt:Object = targets[target];
         var me:PlayerBase = PlayerManager.getInstance().myPlayer;
         if (opt == null) return;
         if (me == null || !opt.walk)
         {
            hit(target);
            return;
         }
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         var b:Rectangle = target.getBounds(target);
         var g:Point = target.localToGlobal(new Point(b.x + b.width / 2, b.y + b.height / 2));
         var p:Point = info && info.scene ? info.scene.localPointToScene(g) : me.parent.globalToLocal(g);
         if (Point.distance(p, new Point(me.x, me.y)) <= Math.max(opt.distance, 4))
         {
            hit(target);
            return;
         }
         if (opt.distance > 0)
         {
            var d:Number = Point.distance(p, new Point(me.x, me.y));
            p = Point.interpolate(new Point(me.x, me.y), p, opt.distance / d);
         }
         pending = target;
         me.addEventListener(MovableEvent.ARRIVED, onArrived);
         me.addEventListener(MovableEvent.MOVE_BEGIN, onMove);
         if (me.walkTo(int(p.x), int(p.y)) == null) onArrived(null);
      }

      private function onMove(e:MovableEvent):void
      {
         // the click on the target itself started this move; any later move cancels
         if (e.params.__clickAndHit) return;
      }

      private function onArrived(e:MovableEvent):void
      {
         var me:PlayerBase = PlayerManager.getInstance().myPlayer;
         if (me)
         {
            me.removeEventListener(MovableEvent.ARRIVED, onArrived);
            me.removeEventListener(MovableEvent.MOVE_BEGIN, onMove);
         }
         var t:InteractiveObject = pending;
         pending = null;
         if (t != null && targets[t] != null) hit(t);
      }

      private function hit(t:DisplayObject):void
      {
         t.dispatchEvent(new ClickAndHitEvent(ClickAndHitEvent.ON_CLICK_AND_HIT, {target: t}));
      }
   }
}
