package mmo.itemcatalog
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.petegg.IPetEggService;
   import mmo.interfaces.material.petegg.PetEgg;

   /**
    * One egg of the rebuilt first page (the art's symbol 25): its picture, name and price
    * (星币: the price and the 蓝宝石's half, as the book's buying takes them; or 晶币), and
    * its 购买. A button placed on a timeline keeps its name, so a clear one named
    * btnBuy_5_<id> lies over the art's: the book buys through that name (BookOpener).
    */
   public class PetEggPanel extends Sprite
   {
      public var mcPrice:MovieClip;
      public var btnBuy_5_:SimpleButton;
      public var petEggNameTxt:TextField;
      public var hotSp:MovieClip;
      public var newSp:MovieClip;

      public function PetEggPanel(id:int = 0)
      {
         super();
         var svc:IPetEggService = ServiceContainer.getService(IPetEggService) as IPetEggService;
         var egg:PetEgg = svc != null ? svc.getPetEggById(id) : null;
         petEggNameTxt.mouseEnabled = false;
         petEggNameTxt.text = egg != null ? egg.name : "";
         if (egg != null && egg.rmb > 0)
         {
            mcPrice.gotoAndStop(1);
            text("priceTxt1", String(egg.rmb));
            text("priceTxt2", String(Math.ceil(egg.rmb / 2)));
         }
         else
         {
            mcPrice.gotoAndStop(2);
            text("priceTxt", egg != null ? String(egg.price) : "");
         }
         if (hotSp) hotSp.visible = false;
         if (newSp) newSp.visible = false;
         try
         {
            var icon:DisplayObject = IMaterialService(svc).getView(id);
            icon.scaleX = icon.scaleY = 1.25;
            icon.x = -44.5;
            icon.y = -138.5;
            addChildAt(icon, 0);
         }
         catch (e:Error) {}
         if (btnBuy_5_ != null && egg != null)
         {
            var b:Rectangle = btnBuy_5_.getBounds(this);
            var hit:Sprite = new Sprite();
            hit.name = "btnBuy_5_" + id;
            hit.buttonMode = true;
            hit.graphics.beginFill(0xFFFFFF, 0);
            hit.graphics.drawRect(b.x, b.y, b.width, b.height);
            hit.graphics.endFill();
            addChild(hit);
         }
      }

      private function text(name:String, s:String):void
      {
         var t:TextField = mcPrice.getChildByName(name) as TextField;
         if (t == null) return;
         t.mouseEnabled = false;
         t.text = s;
      }
   }
}
