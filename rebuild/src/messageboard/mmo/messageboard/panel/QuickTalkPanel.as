package mmo.messageboard.panel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.loader.LoaderContainer;
   
   public class QuickTalkPanel extends Sprite
   {
      
      public static const wordArr:Array = ["我来看你啦！有空记得来我家里玩哦！","来我家里帮我浇树吧！","你的亚比好可爱哦！","做个朋友好吗？","我的亚比很厉害哦，你敢来我家挑战么？","你家好漂亮哦！"];
      
      public var btn_0:SimpleButton;
      
      public var btn_1:SimpleButton;
      
      public var btn_2:SimpleButton;
      
      public var btn_3:SimpleButton;
      
      public var btn_4:SimpleButton;
      
      public var btn_5:SimpleButton;
      
      private var container:Sprite;
      
      private var callback:Function;
      
      public function QuickTalkPanel(param1:Function = null)
      {
         super();
         this.callback = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.initBtn();
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStage);
      }
      
      private function initBtn() : void
      {
         var _loc3_:SimpleButton = null;
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < wordArr.length)
         {
            _loc3_ = this.getChildByName("btn_" + _loc2_) as SimpleButton;
            _loc3_.addEventListener(MouseEvent.CLICK,this.onClickBtn);
            _loc2_++;
         }
      }
      
      private function onAddToStage(param1:Event) : void
      {
         LoaderContainer.instance.stage.addEventListener(MouseEvent.MOUSE_MOVE,this.onStageMouseMove);
      }
      
      private function onRemoveFromStage(param1:Event) : void
      {
         LoaderContainer.instance.stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.onStageMouseMove);
      }
      
      private function onClickBtn(param1:MouseEvent) : void
      {
         this.parent.removeChild(this);
         var _loc2_:SimpleButton = param1.currentTarget as SimpleButton;
         var _loc3_:String = _loc2_.name;
         var _loc4_:String = "btn_";
         var _loc5_:int = parseInt(_loc3_.slice(_loc4_.length));
         if(this.callback != null)
         {
            this.callback.apply(null,[wordArr[_loc5_]]);
         }
      }
      
      private function onStageMouseMove(param1:MouseEvent) : void
      {
         if(this.parent == null)
         {
            return;
         }
         if(!this.hitTestPoint(param1.stageX,param1.stageY,true))
         {
            this.parent.removeChild(this);
         }
      }
   }
}

