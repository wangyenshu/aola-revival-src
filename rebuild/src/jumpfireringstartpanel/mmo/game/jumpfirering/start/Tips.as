package mmo.game.jumpfirering.start
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.utils.setTimeout;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /**
    * REBUILT. The lost panel's notices, as the game's other dialogs: 1 the game may not be played
    * now, 2 not while in a team (the scene checks that). Added as a modal dialog: it takes
    * itself away and shows the notice.
    */
   public class Tips extends Sprite
   {
      private var type:int;

      public function Tips(type:int = 1)
      {
         super();
         this.type = type;
         addEventListener(Event.ADDED_TO_STAGE, onAdded);
      }

      private function onAdded(e:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE, onAdded);
         var me:Tips = this;
         setTimeout(function():void
         {
            try { ModalDialogManager.getInstance().removeModalDialog(me); } catch (err:Error) { if (me.parent) me.parent.removeChild(me); }
            NewDialog.showMessage(type == 2 ? "组队的时候不能玩波鲁跳火圈哦，先离开队伍再来吧！" : "现在还不能玩波鲁跳火圈哦，等一会儿再来吧！");
         }, 0);
      }
   }
}
