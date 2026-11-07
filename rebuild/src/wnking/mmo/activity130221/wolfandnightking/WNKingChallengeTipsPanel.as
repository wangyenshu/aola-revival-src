package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.loader.scheduler.ResScheduler;
   
   public class WNKingChallengeTipsPanel extends WNKingPanelBase
   {
      
      private var index:int;
      
      private var frame:int;
      
      private var panel:Sprite;
      
      public function WNKingChallengeTipsPanel(param1:int, param2:int)
      {
         super();
         this.index = param1;
         this.frame = param2;
         this.initPanel();
      }
      
      private function initPanel() : void
      {
         var obj:Object = WNKingConfig.challengeTipsPanelArr[this.index];
         ResScheduler.getTempResource(obj.pathName,function(param1:Sprite, param2:Object = null):void
         {
            panel = param1;
            addChild(panel);
            var _loc3_:* = panel.getChildByName("mc") as MovieClip;
            _loc3_.gotoAndStop(frame);
         },obj.className);
      }
   }
}

