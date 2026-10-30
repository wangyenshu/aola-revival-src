package mmo.housestorage
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.interfaces.changeable.PropertyChangeEvent;
   import mmo.interfaces.material.furniture.Furniture;

   /** REBUILT. One storage cell: the item's small picture and how many are left (later art's cell). */
   public class ItemView extends Sprite
   {
      public var txtAvailable:TextField;

      private var _data:UserMaterialWrap;
      private var sketch:MaterialSketch;
      private var cellW:Number;
      private var cellH:Number;

      public function ItemView()
      {
         super();
         buttonMode = true;
         mouseChildren = false;
         cellW = width;
         cellH = height;
         if (txtAvailable && txtAvailable.parent) removeChild(txtAvailable);
      }

      public function get data():UserMaterialWrap
      {
         return _data;
      }

      public function set data(w:UserMaterialWrap):void
      {
         if (w == _data) return;
         clear();
         _data = w;
         if (w == null) return;
         sketch = w.parent.getSketch(w, Math.max(10, cellW - 14), Math.max(10, cellH - 14));
         if (sketch)
         {
            sketch.x = 7;
            sketch.y = 7;
            addChild(sketch);
         }
         if (txtAvailable)
         {
            txtAvailable.text = String(w.available);
            addChild(txtAvailable);
         }
         var f:Furniture = w.material as Furniture;
         try { TipsManager.getInstance().addTips(this, w.material.name + (f && f.des ? "\n" + f.des : ""), 100); } catch (e:Error) {}
         w.addEventListener(PropertyChangeEvent.onPropertyChanged, onChanged);
      }

      private function onChanged(e:PropertyChangeEvent):void
      {
         if (e.property == UserMaterialWrap.propertyAvailable && txtAvailable && _data) txtAvailable.text = String(_data.available);
      }

      private function clear():void
      {
         if (_data != null) _data.removeEventListener(PropertyChangeEvent.onPropertyChanged, onChanged);
         if (sketch != null)
         {
            if (sketch.parent) sketch.parent.removeChild(sketch);
            sketch.dispose();
         }
         if (txtAvailable && txtAvailable.parent) removeChild(txtAvailable);
         try { TipsManager.getInstance().removeTips(this); } catch (e:Error) {}
         sketch = null;
         _data = null;
      }
   }
}
