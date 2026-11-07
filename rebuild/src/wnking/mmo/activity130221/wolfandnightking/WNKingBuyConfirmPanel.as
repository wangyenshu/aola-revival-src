package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.loader.scheduler.ResScheduler;
   
   public class WNKingBuyConfirmPanel extends WNKingPanelBase
   {
      
      private var index:int;
      
      private var frame:int;
      
      private var callBack:Function;
      
      private var panel:Sprite;
      
      public function WNKingBuyConfirmPanel(param1:int, param2:int, param3:Function = null)
      {
         super();
         this.index = param1;
         this.frame = param2;
         this.callBack = param3;
         this.initPanel();
      }
      
      private function initPanel() : void
      {
         var obj:Object = WNKingConfig.challengeStarConfirmArr[this.index];
         ProgressFullSprite.show();
         ResScheduler.getTempResource(obj.pathName,function(param1:Sprite, param2:Object = null):void
         {
            ProgressFullSprite.close();
            panel = param1;
            addChild(panel);
            var _loc3_:* = panel.getChildByName("mc") as MovieClip;
            _loc3_.gotoAndStop(frame);
         },obj.className);
      }
      
      override protected function clickBtn(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name as String;
         switch(_loc2_)
         {
            case "btnClose":
               this.closePanel();
               break;
            case "btnOk":
               this.closePanel();
               if(this.callBack != null)
               {
                  this.callBack.apply();
               }
         }
      }
   }
}

