package mmo.petUI.petselect
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;

   /**
    * 选择亚比 of the rebuilt PetUIService: the chooser of the 2012 modules (the panel the era's own
    * pet choices share: activityres/breakegg, unionevolution, phoenixnew's learnskill, squad's daily
    * task, petcollection), here its copy in activityres/breakegg: six squares (kuang0–5: the 亚比's
    * picture in pt, bian 2 when chosen), the question in its text, 确定 and 取消. The 亚比 of the
    * bag in order; those that may not be chosen grey. ok(pbi) on 确定, cancel() on 取消.
    */
   public class PetSelectPanel extends Sprite
   {
      public var kuang0:MovieClip;
      public var kuang1:MovieClip;
      public var kuang2:MovieClip;
      public var kuang3:MovieClip;
      public var kuang4:MovieClip;
      public var kuang5:MovieClip;
      public var btnOK:SimpleButton;
      public var btnCancel:SimpleButton;

      private var pets:Array;
      private var ok:Function;
      private var cancel:Function;
      private var cur:int = -1;
      private var kuang:Array = [];

      /** may: whether a 亚比 may be chosen (null: all). */
      public function PetSelectPanel(pets:Array, may:Function, question:String, title:DisplayObject, ok:Function, cancel:Function)
      {
         super();
         this.pets = pets;
         this.ok = ok;
         this.cancel = cancel;
         var field:TextField = firstText(this);
         if (title != null)
         {
            if (field != null)
            {
               field.visible = false;
               title.x = field.x;
               title.y = field.y;
            }
            addChild(title);
         }
         else if (field != null && question)
         {
            field.text = question;
         }
         for (var i:int = 0; i < 6; i++)
         {
            var k:MovieClip = find(this, "kuang" + i) as MovieClip;
            kuang.push(k);
            if (k == null) continue;
            k.mouseChildren = false;
            var bian:MovieClip = k.getChildByName("bian") as MovieClip;
            if (bian != null) bian.gotoAndStop(1);
            var p:PetBriefInfo = i < pets.length ? pets[i] as PetBriefInfo : null;
            if (p == null) continue;
            showIcon(k, p);
            TipsManager.getInstance().addComplexTips(k, "资料", "名字：" + p.name + "\n等级：" + p.level);
            if (may == null || may(p))
            {
               k.buttonMode = true;
               k.addEventListener(MouseEvent.CLICK, onPet);
            }
            else DisplayUtil.applyGray(k);
         }
         var b:SimpleButton = find(this, "btnOK") as SimpleButton;
         if (b != null) b.addEventListener(MouseEvent.CLICK, onOk);
         b = find(this, "btnCancel") as SimpleButton;
         if (b != null) b.addEventListener(MouseEvent.CLICK, onCancel);
      }

      private function showIcon(k:MovieClip, p:PetBriefInfo):void
      {
         var holder:MovieClip = k.getChildByName("pt") as MovieClip;
         if (holder == null) return;
         var w:Number = holder.width, h:Number = holder.height;
         var icon:PetIconContainer = new PetIconContainer(p.viewId, PetIconType.SMALL, false);
         icon.addEventListener(PetIconEvent.ON_ICON_LOADED, function(e:PetIconEvent):void
         {
            DisplayUtil.scaleDisplay(icon, w, h);
            holder.addChild(icon);
            var r:Rectangle = icon.getBounds(holder);
            icon.x += (w - r.width) / 2 - r.left;
            icon.y += (h - r.height) / 2 - r.top;
         });
         icon.startLoad();
      }

      private function onPet(e:MouseEvent):void
      {
         var i:int = kuang.indexOf(e.currentTarget);
         if (i < 0) return;
         if (cur >= 0 && kuang[cur] != null) MovieClip(MovieClip(kuang[cur]).getChildByName("bian")).gotoAndStop(1);
         cur = i;
         MovieClip(MovieClip(kuang[cur]).getChildByName("bian")).gotoAndStop(2);
      }

      private function onOk(e:MouseEvent):void
      {
         if (cur < 0)
         {
            NewDialog.showSucceedMessage("你还没选择亚比啊！");
            return;
         }
         ok(pets[cur]);
      }

      private function onCancel(e:MouseEvent):void
      {
         cancel();
      }

      private static function firstText(d:DisplayObject):TextField
      {
         if (d is TextField) return TextField(d);
         var c:Sprite = d as Sprite;
         for (var i:int = 0; c != null && i < c.numChildren; i++)
         {
            var child:DisplayObject = c.getChildAt(i);
            if (child is TextField) return TextField(child);
         }
         return null;
      }

      private static function find(d:DisplayObject, name:String):DisplayObject
      {
         if (d.name == name) return d;
         var c:Sprite = d as Sprite;
         for (var i:int = 0; c != null && i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i), name);
            if (f != null) return f;
         }
         return null;
      }
   }
}
