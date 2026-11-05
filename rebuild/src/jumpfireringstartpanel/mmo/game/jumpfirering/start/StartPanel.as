package mmo.game.jumpfirering.start
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.utils.setTimeout;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT. What the scene shows on a click of the fire ring: the game itself, whose own start
    * page has 开始, 规则 and 关闭 (the lost panel's art is not needed for that). Added as a modal
    * dialog by the scene: it takes itself away and opens the game.
    */
   public class StartPanel extends Sprite
   {
      public static const GAME:String = "gameJumpFireRing";

      public function StartPanel()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE, onAdded);
      }

      private function onAdded(e:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE, onAdded);
         var me:StartPanel = this;
         setTimeout(function():void
         {
            try { ModalDialogManager.getInstance().removeModalDialog(me); } catch (err:Error) { if (me.parent) me.parent.removeChild(me); }
            try { SceneManager.getInstance().loadGame(GAME); } catch (err2:Error) { RLog.error("jumpfirering start", err2); }
         }, 0);
      }
   }
}
