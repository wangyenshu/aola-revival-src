package mmo.housestorage
{
   import flash.display.Sprite;
   import flash.events.Event;
   import mmo.houseinterfaces.operate.StorageTableTypes;

   /** REBUILT. The storage's kind tabs (btn<StorageTableTypes>) of the later art. */
   public class TableBar extends Sprite
   {
      public static const onSelectChanged:String = "onSelectChanged";

      public var btn0:TableButton;
      public var btn1:TableButton;
      public var btn2:TableButton;
      public var btn3:TableButton;
      public var btn4:TableButton;
      public var btn100:TableButton;

      private var _selectType:int;

      public function TableBar()
      {
         super();
         for each (var t:int in StorageTableTypes.getTypes())
         {
            var b:TableButton = getChildByName("btn" + t) as TableButton;
            if (b) b.addEventListener(TableButton.onSelected, onSelected);
         }
      }

      private function onSelected(e:Event):void
      {
         var b:TableButton = e.target as TableButton;
         for each (var t:int in StorageTableTypes.getTypes())
         {
            var o:TableButton = getChildByName("btn" + t) as TableButton;
            if (o && o != b && o.selected) o.selected = false;
         }
         _selectType = int(b.name.replace("btn", ""));
         dispatchEvent(new Event(onSelectChanged));
      }

      public function get selectType():int
      {
         return _selectType;
      }

      public function set selectType(v:int):void
      {
         var b:TableButton = getChildByName("btn" + v) as TableButton;
         if (b == null) return;
         if (b.selected)
         {
            _selectType = v;
            dispatchEvent(new Event(onSelectChanged));
         }
         else b.selected = true;
      }
   }
}
