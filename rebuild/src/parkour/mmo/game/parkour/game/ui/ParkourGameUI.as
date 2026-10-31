package mmo.game.parkour.game.ui
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   import mmo.game.parkour.game.panel.ParkourPausePanel;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourGameUI
   {
      
      private var _view:MovieClip;
      
      public function ParkourGameUI()
      {
         super();
         this._view = ParkourGameResConfig.createDisplayObj(ParkourGameResConfig.ClsNameOfUI) as MovieClip;
         this._view.addEventListener(MouseEvent.CLICK,this.onClickUI);
      }
      
      public function get view() : MovieClip
      {
         return this._view;
      }
      
      public function refresh() : void
      {
         var _loc1_:TextField = this._view.getChildByName("txtScore") as TextField;
         var _loc2_:TextField = this._view.getChildByName("txtMeter") as TextField;
         var _loc3_:MovieClip = this._view.getChildByName("mcPower") as MovieClip;
         _loc1_.text = ParkourGameScene.instance.getPlayer().totalScore + "";
         _loc2_.text = ParkourGameScene.instance.moveMeter + "";
         var _loc4_:int = ParkourGameScene.instance.getPlayer().param.power * _loc3_.totalFrames / ParkourGameConfig.MaxPower + 1;
         _loc3_.gotoAndStop(_loc4_);
      }
      
      private function onClickUI(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnPause")
         {
            ParkourGameScene.instance.pause();
            new ParkourPausePanel(ParkourGameScene.instance.continueGame,ParkourGameScene.instance.showEndGamePanel).showPanel();
         }
      }
      
      private function showMessage(param1:String, param2:Function = null) : void
      {
         var msg:String = param1;
         var onClose:Function = param2;
         NewDialog.getMessageDialog(msg,function(param1:ModalDialog):void
         {
            var content:ModalDialog = param1;
            content.addEventListener(ModalDialogEvent.CLOSE,function onModalClose(param1:ModalDialogEvent):void
            {
               content.removeEventListener(ModalDialogEvent.CLOSE,onModalClose);
               ParkourHelper.applyFunc(onClose);
            });
            (content as ModalDialog).show();
         },null,NewDialog.getFailIcon());
      }
      
      public function dispose() : void
      {
         this._view.removeEventListener(MouseEvent.CLICK,this.onClickUI);
         DisplayUtil.stopAndRemove(this._view);
         this._view = null;
      }
   }
}

