package mmo.starcoinexchange
{
   import flash.display.Sprite;
   import mmo.common.ProgressFullSprite;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   
   public class StarCoinPanelWithReturnService extends Sprite implements IShowPanel
   {
      
      public function StarCoinPanelWithReturnService()
      {
         super();
      }
      
      public function showPanel() : void
      {
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("StarCoinPanelService",function(param1:IShowPanel, param2:Object):*
         {
            ProgressFullSprite.close();
            param1.showPanel();
         });
      }
   }
}

