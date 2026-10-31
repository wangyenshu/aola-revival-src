package mmo.common.event
{
   import flash.events.EventDispatcher;

   /**
    * REVIVAL (aola-revival). The later common library's BtEventDispatcher, which the 2013 one
    * lacks; 酷跑星世界 (game/parkour, 2015) extends it (ParkourUserData, ParkourPageComponent).
    * An EventDispatcher that remembers its listeners, so destroy() can take them all away.
    * Lives in the game SWF (the main application domain: the first definition loaded wins).
    */
   public class BtEventDispatcher extends EventDispatcher
   {
      protected var functions:Object = {};

      public function BtEventDispatcher()
      {
         super();
      }

      override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
      {
         super.addEventListener(type, listener, useCapture, priority, useWeakReference);
         if (useWeakReference) return;
         var list:Vector.<Function> = functions[type] as Vector.<Function>;
         if (list == null) functions[type] = list = new Vector.<Function>();
         if (list.indexOf(listener) < 0) list.push(listener);
      }

      override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
      {
         super.removeEventListener(type, listener, useCapture);
         var list:Vector.<Function> = functions[type] as Vector.<Function>;
         if (list == null) return;
         var i:int = list.indexOf(listener);
         if (i >= 0) list.splice(i, 1);
         if (list.length == 0) delete functions[type];
      }

      public function removeEventListeners(type:String):void
      {
         var list:Vector.<Function> = functions[type] as Vector.<Function>;
         if (list == null) return;
         for (var i:int = list.length - 1; i >= 0; i--) removeEventListener(type, list[i]);
      }

      public function removeAllEventListeners():void
      {
         var types:Array = [];
         for (var t:String in functions) types.push(t);
         for each (t in types) removeEventListeners(t);
      }

      public function destroy():void
      {
         removeAllEventListeners();
         onDestroy();
      }

      protected function onDestroy():void
      {
      }
   }
}
