package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.scheduler.ResScheduler;
   
   [SWF(width="550", height="400", backgroundColor="#ffffff", frameRate="24")]
   public class WNKingManager extends MovieClip implements IShowPanel
   {
      
      public function WNKingManager()
      {
         super();
      }
      
      public function showPanel() : void
      {
         if(LocalStore.getValue("wolfandnightking_key",SocketClient.instance.myUserName))
         {
            this.showChallengePanel();
         }
         else
         {
            this.showMovie();
         }
      }
      
      private function showChallengePanel() : void
      {
         new WNKingChallengeMainPanel().showPanel();
      }
      
      private function showMovie() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getTempResource("activityres/activity130221/wolfandnightking/wolfandnightkingbeginmovie",function(param1:MovieClip, param2:Object = null):void
         {
            var mc:MovieClip = param1;
            var params:Object = param2;
            ProgressFullSprite.close();
            LocalStore.setValue("wolfandnightking_key",true,SocketClient.instance.myUserName);
            mc.addEventListener(MouseEvent.CLICK,function clickBtn(param1:MouseEvent):void
            {
               var _loc2_:* = param1.target.name as String;
               switch(_loc2_)
               {
                  case "btnClose":
                     ModalDialogManager.getInstance().removeModalDialog(mc);
                     mc.removeEventListener(MouseEvent.CLICK,clickBtn);
                     showChallengePanel();
                     break;
                  case "btnPrev":
                     mc.gotoAndStop(mc.currentFrame - 1);
                     break;
                  case "btnNext":
                     mc.gotoAndStop(mc.currentFrame + 1);
               }
            });
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc,AlignType.NONE);
            mc.gotoAndStop(1);
         },"mmo.activity130221.wolfandnightking.WNKingBeginMovie");
      }
   }
}

