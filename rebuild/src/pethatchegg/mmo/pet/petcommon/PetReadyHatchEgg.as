package mmo.pet.petcommon
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.*;
   import flash.utils.getDefinitionByName;

   /**
    * ERA pet/pethatchegg (December 2010), rebuilt from its decompiled code: an
    * egg one may put in the 亚比批量孵化器. The era code never filled nameTxt,
    * so the artwork's sample words 亚比蛋蛋蛋 stood under every egg; it now
    * shows the egg's name (mmo.materialdata.PetEggData, as 物品 names it),
    * short enough for the five characters the field holds (沙麒麟亚比蛋 ->
    * 沙麒麟蛋; the whole name is in the egg's tip).
    */
   public class PetReadyHatchEgg extends Sprite
   {
      
      public var pbc:PetSimpleView;
      
      public var mmc:MovieClip;
      
      public var nameTxt:TextField;
      
      public var obj:Object = new Object();
      
      public function PetReadyHatchEgg(param1:Object)
      {
         super();
         this.obj = param1;
         this.pbc = new PetSimpleView(param1);
         this.pbc.x = this.mmc.x;
         this.pbc.y = this.mmc.y;
         this.addChild(this.pbc);
         this.showName(int(param1.ri));
      }

      private function showName(ri:int) : void
      {
         if(this.nameTxt == null)
         {
            return;
         }
         var name:String = null;
         try
         {
            var data:Object = (getDefinitionByName("mmo.materialdata.PetEggData") as Class)["data"];
            if(data != null && data[ri] != null)
            {
               name = String(data[ri].name);
            }
         }
         catch(e:Error)
         {
         }
         if(name != null && name.length > 5)
         {
            name = name.replace(/亚比蛋$/,"");
            name = name.length <= 4 ? name + "蛋" : name.substr(0,5);
         }
         this.nameTxt.text = name || "亚比蛋";
         // Long names (埃拉多夫亚比蛋) in a smaller size, so they fit under the egg.
         var size:int = 12;
         while(this.nameTxt.textWidth > this.nameTxt.width - 4 && size > 8)
         {
            size--;
            var f:TextFormat = this.nameTxt.getTextFormat();
            f.size = size;
            this.nameTxt.setTextFormat(f);
         }
      }
      
      public function setCheckBox(param1:Boolean) : void
      {
         if(param1)
         {
            this.pbc.setkuang(true);
         }
         else
         {
            this.pbc.setkuang(false);
         }
         this.obj.isClick = param1;
      }
      
      public function dispose() : void
      {
         this.pbc.dispose();
         this.parent.removeChild(this);
      }
   }
}

