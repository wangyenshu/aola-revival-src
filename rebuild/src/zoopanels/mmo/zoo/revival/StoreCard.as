package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;

   /** REBUILT. One square of the 动物仓库 (the era BabyAnimalContainer, MatureAnimalContainer, ZooItemContainer). */
   public class StoreCard extends MovieClip
   {
      public var backGroundMC:MovieClip;
      public var numText:TextField;
      public var pictureContainer:MovieClip;
      public var lock:MovieClip;
      public var sendBtn:SimpleButton;

      public var id:int;
      public var num:int;
      public var data:Object;

      public function StoreCard()
      {
         super();
         stop();
         for each (var n:String in ["sendBtn", "lock"]) ZooKit.hide(getChildByName(n));
      }

      /** What it holds: id (race or item), how many, its picture type and name. */
      public function setUp(o:Object, id:int, num:int, type:int, tip:String):void
      {
         data = o;
         this.id = id;
         this.num = num;
         if (numText != null)
         {
            numText.mouseEnabled = false;
            numText.text = String(num);
         }
         ZooKit.icon(id, type, pictureContainer);
         buttonMode = true;
         TipsManager.getInstance().addTips(this, tip);
      }

      public function dispose():void
      {
         TipsManager.getInstance().removeTips(this);
         if (parent != null) parent.removeChild(this);
      }

      protected function button(name:String):SimpleButton
      {
         return getChildByName(name) as SimpleButton;
      }
   }
}
