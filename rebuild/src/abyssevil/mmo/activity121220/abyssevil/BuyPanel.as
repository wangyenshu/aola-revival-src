package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.commoditybag.ICommoditybagService;
   import mmo.interfaces.material.MaterialTypes;
   
   public class BuyPanel extends Sprite implements IDispose, IShowPanel
   {
      
      public var btnclose:SimpleButton;
      
      public var btnbuy:SimpleButton;
      
      public var mcname:MovieClip;
      
      private var id:int;
      
      public function BuyPanel(param1:int, param2:int)
      {
         super();
         this.id = param1;
         MovieClip(this.getChildByName("mcname")).gotoAndStop(param2);
         addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = DisplayObject(param1.target).name;
         switch(_loc2_)
         {
            case "btnbuy":
               this.close();
               SundriesClient.logBuy("182",0,[[1,MaterialTypes.ITEM,this.id]]);
               ItemBuyHandler.buy(this.id,1,this.onBuy);
               break;
            case "btnclose":
               this.close();
         }
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function onBuy() : void
      {
         var _loc1_:ICommoditybagService = ServiceContainer.instance.getService(ICommoditybagService) as ICommoditybagService;
         _loc1_.showGetCommodityPanel(this.id,1);
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      public function showPanel() : void
      {
         SundriesClient.logOpen("182");
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }
   }
}

