package mmo.game.parkour.common.panel
{
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.loader.common.datastructures.ResourceObject;
   
   public class ParkourConfirmPanel extends ParkourPanelBase
   {
      
      private var onOk:Function = null;
      
      private var onClose:Function = null;
      
      public function ParkourConfirmPanel(param1:ResourceObject, param2:Function = null, param3:Function = null)
      {
         super(param1);
         this.onOk = param2;
         this.onClose = param3;
      }
      
      override protected function onShowPanel() : void
      {
         this.onRefresh();
         showThisPanel();
      }
      
      protected function onRefresh() : void
      {
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnOk")
         {
            ParkourHelper.applyFunc(this.onOk);
            close();
         }
      }
      
      override protected function onClickClose() : void
      {
         ParkourHelper.applyFunc(this.onClose);
      }
      
      override protected function onDispose() : void
      {
      }
   }
}

